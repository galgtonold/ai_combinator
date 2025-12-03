local constants = {}

-- ===== Network Configuration =====
-- UDP port for AI Bridge communication
constants.AI_BRIDGE_PORT = 8889

-- Special UID used for bridge availability checks (not associated with any combinator)
constants.BRIDGE_CHECK_UID = 999999

-- ===== Code History =====
-- Maximum number of code history entries to keep per combinator
constants.MAX_CODE_HISTORY_SIZE = 20

-- ===== Integer Conversion =====
-- Used for int32 <-> uint32 conversion in Factorio signal handling
constants.INT32_TO_UINT32_OFFSET = 0x100000000  -- 2^32
constants.INT32_SIGN_BIT = 0x80000000           -- 2^31

-- ===== Wire Configuration =====
constants.RED_WIRE_NAME = 'red'
constants.GREEN_WIRE_NAME = 'green'

function constants.get_wire_label(k) 
  return k == 'red' and constants.RED_WIRE_NAME or constants.GREEN_WIRE_NAME 
end

-- ===== Timing Intervals (in ticks, 60 ticks = 1 second) =====
-- Interval between raising global alerts on lua errors
constants.LOGIC_ALERT_INTERVAL = 10 * 60

-- LED state indication - avoids flipping between sleep/run too often
constants.LED_SLEEP_MIN = 5 * 60

-- Energy failure delay - when to re-check energy level
constants.ENERGY_FAIL_DELAY = 2 * 60

-- ===== Energy Thresholds =====
-- entity.energy threshold when combinator shuts down
-- Full e-buffer of arithmetic combinator is 34.44, "red" level in UI is half of it
constants.ENERGY_FAIL_LEVEL = 34.44 / 2

-- ===== Custom Events =====
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
  on_fix_completed = script.generate_event_name(),
  
  on_task_updated = script.generate_event_name(),
  on_code_history_changed = script.generate_event_name(),
  on_code_changed = script.generate_event_name(),

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
