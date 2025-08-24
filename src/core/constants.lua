local constants = {}

constants.events = {
  on_task_request_completed = script.generate_event_name(),
  on_ping_response = script.generate_event_name(),
  on_bridge_check_completed = script.generate_event_name(),
}

return constants
