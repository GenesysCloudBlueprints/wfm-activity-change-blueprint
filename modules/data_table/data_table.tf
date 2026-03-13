resource "genesyscloud_architect_datatable" "wfm_status_mapping" {
  division_id = var.division_id
  name        = var.name
  properties {
    name  = "key"
    title = "ActivityCode"
    type  = "string"
  }
  properties {
    title = "Name"
    type  = "string"
    name  = "Name"
  }
  properties {
    name  = "Category"
    title = "Category"
    type  = "string"
  }
  properties {
    default = "false"
    name    = "Paid"
    title   = "Paid"
    type    = "boolean"
  }
}

# Default Activity Codes are only included. You may need to add additional rows for custom activity codes.
resource "genesyscloud_architect_datatable_row" "on_queue" {
  datatable_id = genesyscloud_architect_datatable.wfm_status_mapping.id
  key_value    = "0"
  properties_json = jsonencode({
    "Name" : "On Queue",
    "Category" : "OnQueueWork",
    "Paid" : true
  })
}

resource "genesyscloud_architect_datatable_row" "break" {
  datatable_id = genesyscloud_architect_datatable.wfm_status_mapping.id
  key_value    = "1"
  properties_json = jsonencode({
    "Name" : "Break",
    "Category" : "Break",
    "Paid" : true
  })
}

resource "genesyscloud_architect_datatable_row" "meal" {
  datatable_id = genesyscloud_architect_datatable.wfm_status_mapping.id
  key_value    = "2"
  properties_json = jsonencode({
    "Name" : "Meal",
    "Category" : "Meal",
    "Paid" : false
  })
}

resource "genesyscloud_architect_datatable_row" "meeting" {
  datatable_id = genesyscloud_architect_datatable.wfm_status_mapping.id
  key_value    = "3"
  properties_json = jsonencode({
    "Name" : "Meeting",
    "Category" : "Meeting",
    "Paid" : true
  })
}

resource "genesyscloud_architect_datatable_row" "off_queue" {
  datatable_id = genesyscloud_architect_datatable.wfm_status_mapping.id
  key_value    = "4"
  properties_json = jsonencode({
    "Name" : "Off Queue",
    "Category" : "OffQueueWork",
    "Paid" : true
  })
}

resource "genesyscloud_architect_datatable_row" "time_off" {
  datatable_id = genesyscloud_architect_datatable.wfm_status_mapping.id
  key_value    = "5"
  properties_json = jsonencode({
    "Name" : "Time Off",
    "Category" : "TimeOff",
    "Paid" : false
  })
}

resource "genesyscloud_architect_datatable_row" "training" {
  datatable_id = genesyscloud_architect_datatable.wfm_status_mapping.id
  key_value    = "6"
  properties_json = jsonencode({
    "Name" : "Training",
    "Category" : "Training",
    "Paid" : true
  })
}

resource "genesyscloud_architect_datatable_row" "unavailable" {
  datatable_id = genesyscloud_architect_datatable.wfm_status_mapping.id
  key_value    = "7"
  properties_json = jsonencode({
    "Name" : "Unavailable",
    "Category" : "Unavailable",
    "Paid" : false
  })
}

