local constants = {}

constants.events = {
  on_task_request_completed = script.generate_event_name(),
  on_ping_response = script.generate_event_name(),
  on_bridge_check_completed = script.generate_event_name(),
  
  on_description_updated = script.generate_event_name(),
  on_code_updated = script.generate_event_name(),

  on_test_case_updated = script.generate_event_name(),
  on_quantity_set = script.generate_event_name(),
  on_test_case_evaluated = script.generate_event_name(),
  on_test_case_name_updated = script.generate_event_name(),
  on_test_generation_completed = script.generate_event_name(),
  on_ai_operation_state_changed = script.generate_event_name(),

  entity_removed_events = {
      defines.events.on_pre_player_mined_item,
      defines.events.on_robot_pre_mined,
      defines.events.on_entity_died,
      defines.events.script_raised_destroy
  },
  entity_created_events = {
      defines.events.on_built_entity,
      defines.events.on_robot_built_entity,
      defines.events.script_raised_revive,
      defines.events.script_raised_built,
      defines.events.on_space_platform_built_entity
  }  
}

return constants
