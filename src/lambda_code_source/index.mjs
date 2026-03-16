import axios from "axios";

export const handler = async (event, context) => {
  try {
    // NOTE: No webhook secret is included in this example for simplicity, but you should implement verification of incoming webhook requests in production for security purposes.
    // Parse the incoming webhook message
    const incomingMessage =
      typeof event.body === "string"
        ? JSON.parse(event.body)
        : event.body || {};

    // Extract the text from incoming message
    const messageText = incomingMessage.text || "";

    // Create the outbound message format
    const outboundMessage = {
      message: messageText,
      metadata: "webhook-translation", // You can customize this metadata value
    };

    console.log("outboundMessage: " + JSON.stringify(outboundMessage));

    // Destination webhook URL - set this in your Lambda environment variables
    const webhookUrl = process.env.DESTINATION_WEBHOOK_URL;

    // Send POST request to destination webhook
    const response = await axios.post(webhookUrl, outboundMessage, {
      headers: {
        "Content-Type": "application/json",
      },
    });

    console.log("Webhook forwarded successfully: " + response.status);
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Webhook forwarded successfully",
        status: "success",
      }),
    };
  } catch (error) {
    console.log("Error forwarding webhook: " + error.message);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: `Error: ${error.message}`,
        status: "error",
      }),
    };
  }
};
