"use strict";

/**
 * Genesys Cloud WFM — Update Existing Shift (Serverless Function)
 *
 */

const platformClient = require("purecloud-platform-client-v2");
const zlib = require("zlib");
const axios = require("axios");

const LOG_LEVEL = (process.env.LOG_LEVEL || "info").toLowerCase();
const client = platformClient.ApiClient.instance;
const wfm = () => new platformClient.WorkforceManagementApi();

// ---------- Small utilities ----------

const toIso = (d) => new Date(d).toISOString();
const asMinutes = (n) => (typeof n === "string" ? parseInt(n, 10) : n);

/**
 * Best-effort body parser
 */
function parseBodySafely(event) {
  const eventTopKeys = Object.keys(event || {});
  const likelyTop = [
    "businessUnitId",
    "agentId",
    "windowStart",
    "windowEnd",
    "shiftChange",
    "clientId",
    "credentials",
  ];

  // Case 1: no body, but event itself looks like our payload
  if (!("body" in (event || {})) && event && typeof event === "object") {
    if (eventTopKeys.some((k) => likelyTop.includes(k))) {
      return {
        parsed: event,
        meta: { source: "event-top", eventTopKeys },
      };
    }
  }

  // Case 2: use event.body
  let raw = event?.body;
  let decoded = raw;

  // Base64 decode if needed
  if (typeof raw === "string" && event?.isBase64Encoded) {
    try {
      decoded = Buffer.from(raw, "base64").toString("utf8");
    } catch {
      // ignore, keep raw
    }
  }

  // First parse attempt
  let b = decoded;
  if (typeof b === "string") {
    try {
      b = JSON.parse(b);
    } catch {
      // leave as string
    }
  }

  // Handle "string of a string" up to 3 layers
  let guard = 0;
  while (typeof b === "string" && guard < 3) {
    try {
      b = JSON.parse(b);
    } catch {
      break;
    }
    guard++;
  }

  // Some gateways send { body: "JSON" } or { body: { ... } }
  if (b && typeof b.body === "string") {
    try {
      b = JSON.parse(b.body);
    } catch {
      // ignore, keep as is
    }
  } else if (
    b &&
    b.body &&
    typeof b.body === "object" &&
    Object.keys(b.body).length
  ) {
    b = b.body;
  }

  const result = b && typeof b === "object" ? b : {};

  return {
    parsed: result,
    meta: {
      source: "event.body",
      isBase64Encoded: !!event?.isBase64Encoded,
      eventTopKeys,
      bodyType: typeof raw,
      decodedType: typeof decoded,
      finalType: typeof result,
    },
  };
}

/**
 * Resolve OAuth client/secret + region from env or body.
 */
function resolveConfig(body) {
  const creds = body?.credentials || {};

  const clientId =
    process.env.GC_CLIENT_ID ||
    body?.clientId ||
    body?.gcClientId ||
    body?.GC_CLIENT_ID ||
    creds?.clientId ||
    creds?.GC_CLIENT_ID;

  const clientSecret =
    process.env.GC_CLIENT_SECRET ||
    body?.clientSecret ||
    body?.gcClientSecret ||
    body?.GC_CLIENT_SECRET ||
    creds?.clientSecret ||
    creds?.GC_CLIENT_SECRET;

  const region =
    process.env.GC_REGION || body?.gcRegion || body?.GC_REGION || creds?.region;

  return { clientId, clientSecret, region };
}

/**
 * For logging/diagnostics (no secrets).
 */
function credPresenceFlags(body, meta) {
  const creds = body?.credentials || {};
  return {
    envClientId: !!process.env.GC_CLIENT_ID,
    envClientSecret: !!process.env.GC_CLIENT_SECRET,
    bodyClientId: !!body?.clientId,
    bodyClientSecret: !!body?.clientSecret,
    bodyCredsClientId: !!creds?.clientId,
    bodyCredsClientSecret: !!creds?.clientSecret,
    regionEnv: process.env.GC_REGION || null,
    regionBody: body?.gcRegion || body?.GC_REGION || null,
    regionCreds: creds?.region || null,
    topKeys: Object.keys(body || {}),
    eventTopKeys: meta?.eventTopKeys || [],
    meta,
  };
}

function sortActivitiesByStart(acts) {
  return [...(acts || [])].sort(
    (a, b) => new Date(a.startDate) - new Date(b.startDate),
  );
}

/**
 * Simple overlap validator (assumes sorted by startDate)
 */
function validateNoOverlap(activities) {
  const acts = sortActivitiesByStart(activities);
  for (let i = 0; i < acts.length - 1; i++) {
    const A = acts[i];
    const B = acts[i + 1];

    const Astart = new Date(A.startDate);
    const Aend = new Date(Astart);
    Aend.setMinutes(Astart.getMinutes() + asMinutes(A.lengthMinutes));

    const Bstart = new Date(B.startDate);

    if (Aend > Bstart) {
      throw new Error(
        `Overlap within shift: activity[${i}] ends ${Aend.toISOString()} > next starts ${Bstart.toISOString()}`,
      );
    }
  }
}

function gzipJson(obj) {
  return new Promise((resolve, reject) => {
    zlib.gzip(JSON.stringify(obj), (err, buf) =>
      err ? reject(err) : resolve(buf),
    );
  });
}

function assertNoWorkPlanFields(uploadPayload) {
  const bad = JSON.stringify(uploadPayload).match(
    /"workPlan[a-zA-Z0-9]*"\s*:/g,
  );
  if (bad && bad.length) {
    throw new Error(
      `Payload contains work-plan fields: ${[...new Set(bad)].join(", ")}`,
    );
  }
}

async function getAgentScheduleVersion(buId, weekDateId, scheduleId, userId) {
  const data =
    await wfm().getWorkforcemanagementBusinessunitWeekScheduleHistoryAgent(
      buId,
      weekDateId,
      scheduleId,
      userId,
    );
  return (data?.changes?.length || 0) + 1;
}

async function getScheduleVersion(buId, weekDateId, scheduleId) {
  const data = await wfm().getWorkforcemanagementBusinessunitWeekSchedule(
    buId,
    weekDateId,
    scheduleId,
  );
  return data?.metadata?.version;
}

// ---------- Core updater (boundary-shift behavior) ----------

async function updateOneShift({
  businessUnitId,
  agentId,
  windowStart,
  windowEnd,
  shiftChange,
  gcClientId,
  gcClientSecret,
  gcRegion,
}) {
  // Region + auth

  if (gcRegion === "inindca.com") {
    client.setEnvironment("inindca.com");

    console.log("DEBUG: Attempting auth with DCA region.");
    console.log("DEBUG: Environment set to: inindca.com");
  } else {
    client.setEnvironment(platformClient.PureCloudRegionHosts[gcRegion]);

    console.log("DEBUG: Attempting auth with region:", gcRegion);
    console.log(
      "DEBUG: Environment set to:",
      platformClient.PureCloudRegionHosts[gcRegion],
    );
  }

  try {
    await client.loginClientCredentialsGrant(gcClientId, gcClientSecret);
    console.log("DEBUG: Auth successful");
  } catch (authErr) {
    console.error("DEBUG: Auth failed:", authErr?.message);
    console.error(
      "DEBUG: Auth error body:",
      JSON.stringify(authErr?.body || authErr?.response?.data),
    );
    throw authErr;
  }

  // 1) Search agent schedule for the window
  const searchBody = {
    startDate: windowStart,
    endDate: windowEnd,
    userIds: [agentId],
  };

  console.log("DEBUG: businessUnitId for search:", businessUnitId);
  console.log("DEBUG: searchBody:", JSON.stringify(searchBody));

  let searchResp;
  try {
    searchResp =
      await wfm().postWorkforcemanagementBusinessunitAgentschedulesSearch(
        businessUnitId,
        { body: searchBody },
      );
    console.log("DEBUG: Search successful");
  } catch (searchErr) {
    console.error("DEBUG: Search failed:", searchErr?.message);
    console.error(
      "DEBUG: Search error body:",
      JSON.stringify(searchErr?.body || searchErr?.response?.data),
    );
    throw searchErr;
  }

  const agentSched = searchResp?.result?.agentSchedules?.[0];
  if (!agentSched?.shifts?.length) {
    throw new Error("No shifts found for agent in the requested range.");
  }
  console.log("DEBUG: Found", agentSched.shifts.length, "shifts for agent");

  // 2) Find the shift/activity we want to adjust by its current startDate
  const targetStartIso = toIso(shiftChange.startDate);
  console.log("DEBUG: Looking for activity starting at:", targetStartIso);
  let targetShiftId = null;
  let activities = null;
  let targetIndex = -1;

  for (const sh of agentSched.shifts) {
    const acts = sortActivitiesByStart(sh.activities || []);
    const idx = acts.findIndex((a) => toIso(a.startDate) === targetStartIso);
    if (idx !== -1) {
      targetShiftId = sh.id;
      activities = acts;
      targetIndex = idx;
      break;
    }
  }

  if (!activities || targetIndex === -1 || !targetShiftId) {
    // Log available activity start times for debugging
    console.error("DEBUG: Available activity start times:");
    for (const sh of agentSched.shifts) {
      for (const a of sh.activities || []) {
        console.error("  -", toIso(a.startDate));
      }
    }
    throw new Error("Could not find target activity/shift at given startDate.");
  }
  console.log(
    "DEBUG: Found target shift:",
    targetShiftId,
    "activity index:",
    targetIndex,
  );

  // lengthMinutes is now the delta in minutes (positive or negative)
  const deltaMinutes = asMinutes(shiftChange.lengthMinutes);
  if (!Number.isFinite(deltaMinutes) || deltaMinutes === 0) {
    throw new Error(
      "shiftChange.lengthMinutes must be a non-zero number (delta minutes).",
    );
  }

  // Clone to avoid mutating original
  const updatedActivities = activities.map((a) => ({ ...a }));

  // Adjust boundary + subsequent activities
  if (targetIndex === 0) {
    // First activity: move its start by delta; keep its duration the same.
    const curr = updatedActivities[0];
    const oldStart = new Date(curr.startDate);
    const newStart = new Date(oldStart);
    newStart.setMinutes(newStart.getMinutes() + deltaMinutes);

    curr.startDate = newStart.toISOString();
    // duration unchanged

    // Shift all subsequent activities' start times by the same delta
    for (let i = 1; i < updatedActivities.length; i++) {
      const act = updatedActivities[i];
      const s = new Date(act.startDate);
      s.setMinutes(s.getMinutes() + deltaMinutes);
      act.startDate = s.toISOString();
      // lengths unchanged
    }
  } else {
    // Has a previous activity; slide the boundary between prev and current
    const prev = updatedActivities[targetIndex - 1];
    const curr = updatedActivities[targetIndex];

    const prevStart = new Date(prev.startDate);

    const currStart = new Date(curr.startDate);
    const currEnd = new Date(currStart);
    currEnd.setMinutes(currEnd.getMinutes() + asMinutes(curr.lengthMinutes));

    // New current start = old current start + delta
    const newCurrStart = new Date(currStart);
    newCurrStart.setMinutes(newCurrStart.getMinutes() + deltaMinutes);

    // Previous activity now ends at new current start
    const newPrevLen = (newCurrStart - prevStart) / 60000;

    if (newPrevLen <= 0) {
      throw new Error(
        "Adjustment would result in non-positive duration for previous activity.",
      );
    }

    // Apply boundary changes
    prev.lengthMinutes = newPrevLen;
    curr.startDate = newCurrStart.toISOString();
    // curr.lengthMinutes stays the same (total time of selected activity preserved)

    // Shift all subsequent activities' starts by the same delta
    for (let i = targetIndex + 1; i < updatedActivities.length; i++) {
      const act = updatedActivities[i];
      const s = new Date(act.startDate);
      s.setMinutes(s.getMinutes() + deltaMinutes);
      act.startDate = s.toISOString();
      // durations unchanged
    }
  }

  // Optional metadata overrides for the target activity only
  const target = updatedActivities[targetIndex];
  if (shiftChange.description != null) {
    target.description = shiftChange.description;
  }
  if (shiftChange.activityCodeId != null) {
    target.activityCodeId = String(shiftChange.activityCodeId);
  }
  if (typeof shiftChange.paid === "boolean") {
    target.paid = shiftChange.paid;
  }

  // Validate no overlaps after adjustment
  validateNoOverlap(updatedActivities);

  // 3) Pull published schedule identifiers
  const pub = searchResp?.result?.publishedSchedules?.[0];
  console.log("DEBUG: Published schedule info:", JSON.stringify(pub));
  if (!pub?.id || !pub?.weekDate) {
    throw new Error("Missing publishedSchedules info (scheduleId/weekDate).");
  }
  const scheduleId = pub.id;
  const weekDateId = pub.weekDate; // yyyy-MM-dd
  console.log("DEBUG: scheduleId:", scheduleId, "weekDateId:", weekDateId);

  // 4) Versions
  console.log("DEBUG: Fetching versions...");
  const [agentVersion, scheduleVersion] = await Promise.all([
    getAgentScheduleVersion(businessUnitId, weekDateId, scheduleId, agentId),
    getScheduleVersion(businessUnitId, weekDateId, scheduleId),
  ]);
  console.log(
    "DEBUG: agentVersion:",
    agentVersion,
    "scheduleVersion:",
    scheduleVersion,
  );

  // 5) Build minimal update payload
  const minimalShift = {
    id: targetShiftId,
    activities: sortActivitiesByStart(updatedActivities).map((a) => {
      const act = {
        startDate: toIso(a.startDate),
        lengthMinutes: asMinutes(a.lengthMinutes),
      };
      if (a.activityCodeId != null)
        act.activityCodeId = String(a.activityCodeId);
      if (a.description != null) act.description = a.description;
      if (typeof a.paid === "boolean") act.paid = a.paid;
      return act;
    }),
    manuallyEdited: true,
  };

  const uploadPayload = {
    metadata: { version: scheduleVersion },
    agentSchedules: [
      {
        userId: agentId,
        shifts: [minimalShift],
        metadata: { version: agentVersion },
      },
    ],
  };

  assertNoWorkPlanFields(uploadPayload);

  // 6) Upload to S3 URL + start update
  const gz = await gzipJson(uploadPayload);
  console.log("DEBUG: Gzipped payload size:", gz.length);

  let uploadTicket;
  try {
    uploadTicket =
      await wfm().postWorkforcemanagementBusinessunitWeekScheduleUpdateUploadurl(
        businessUnitId,
        weekDateId,
        scheduleId,
        { contentLengthBytes: gz.length },
      );
    console.log("DEBUG: Got upload ticket");
  } catch (uploadUrlErr) {
    console.error("DEBUG: Upload URL request failed:", uploadUrlErr?.message);
    console.error(
      "DEBUG: Upload URL error details:",
      JSON.stringify(uploadUrlErr),
    );
    throw uploadUrlErr;
  }

  try {
    await axios.put(uploadTicket.url, gz, { headers: uploadTicket.headers });
    console.log("DEBUG: S3 upload successful");
  } catch (s3Err) {
    console.error("DEBUG: S3 upload failed:", s3Err?.message);
    throw s3Err;
  }

  let startResp;
  try {
    startResp =
      await wfm().postWorkforcemanagementBusinessunitWeekScheduleUpdate(
        businessUnitId,
        weekDateId,
        scheduleId,
        { uploadKey: uploadTicket.uploadKey },
      );
    console.log(
      "DEBUG: Schedule update started, operationId:",
      startResp?.operationId,
    );
  } catch (updateErr) {
    console.error("DEBUG: Schedule update failed:", updateErr?.message);
    console.error(
      "DEBUG: Schedule update error details:",
      JSON.stringify(updateErr),
    );
    throw updateErr;
  }

  return { operationId: startResp.operationId };
}

// ---------- Lambda / GC entry point ----------

module.exports.updateSchedule = async (event) => {
  try {
    console.log("DEBUG: RAW EVENT:", JSON.stringify(event));

    const { parsed: body, meta } = parseBodySafely(event);

    console.log("DEBUG: PARSED BODY:", JSON.stringify(body));
    console.log("DEBUG: META:", JSON.stringify(meta));

    const flags = credPresenceFlags(body, meta);
    console.log("DEBUG: CRED FLAGS:", JSON.stringify(flags));

    const { clientId, clientSecret, region } = resolveConfig(body);

    if (!clientId || !clientSecret) {
      return {
        statusCode: 500,
        body: JSON.stringify({
          error: "Missing clientId/clientSecret",
          whereWeLooked: flags,
        }),
      };
    }

    const businessUnitId =
      body.businessUnitId || process.env.DEFAULT_BUSINESS_UNIT_ID;
    if (!businessUnitId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "businessUnitId is required" }),
      };
    }
    if (!body.agentId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "agentId is required" }),
      };
    }
    if (!body.windowStart || !body.windowEnd) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "windowStart/windowEnd required" }),
      };
    }
    if (!body.shiftChange?.startDate) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: "shiftChange.startDate is required",
        }),
      };
    }
    if (
      body.shiftChange?.lengthMinutes === undefined ||
      body.shiftChange?.lengthMinutes === null
    ) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: "shiftChange.lengthMinutes is required (delta minutes)",
        }),
      };
    }

    const result = await updateOneShift({
      businessUnitId,
      agentId: body.agentId,
      windowStart: body.windowStart,
      windowEnd: body.windowEnd,
      shiftChange: body.shiftChange,
      gcClientId: clientId,
      gcClientSecret: clientSecret,
      gcRegion: region,
    });

    return {
      statusCode: 200,
      body: JSON.stringify({ ok: true, ...result }),
    };
  } catch (err) {
    // Extract detailed error info from SDK/Axios errors
    const errBody = err?.body || err?.response?.data || err?.response?.body;
    const errStatus = err?.status || err?.response?.status || err?.statusCode;

    console.error("Handler error:", err?.message || err);
    console.error("Error status:", errStatus);
    console.error("Error body:", JSON.stringify(errBody));
    console.error(
      "Full error:",
      JSON.stringify(err, Object.getOwnPropertyNames(err)),
    );

    return {
      statusCode: errStatus || 500,
      body: JSON.stringify({
        error: err?.message || "Internal error",
        details: errBody,
        status: errStatus,
      }),
    };
  }
};

// For handler path "package/handler.handler" or "handler.handler"
module.exports.handler = module.exports.updateSchedule;
