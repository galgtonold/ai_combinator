local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")

local ai_operation_manager = {}

-- AI operation types
local OPERATION_TYPES = {
  TASK_EVALUATION = "task_evaluation",
  TEST_GENERATION = "test_generation",
  TEST_FIXING = "test_fixing"
}

ai_operation_manager.OPERATION_TYPES = OPERATION_TYPES

-- Start an AI operation for a combinator
function ai_operation_manager.start_operation(uid, operation_type)
  local mlc = storage.combinators[uid]
  if not mlc then return false end
  
  -- Set new operation state
  mlc.ai_operation_start_time = game.tick
  mlc.ai_operation_type = operation_type
  
  -- Emit state change event
  event_handler.raise_event(constants.events.on_ai_operation_state_changed, {
    uid = uid,
    operation_type = operation_type,
    start_time = game.tick,
    is_active = true
  })
  
  return true
end

-- Complete an AI operation for a combinator
function ai_operation_manager.complete_operation(uid)
  local mlc = storage.combinators[uid]
  if not mlc then return false end
  
  local was_active = mlc.ai_operation_start_time ~= nil
  local operation_type = mlc.ai_operation_type
  
  -- Clear operation state
  mlc.ai_operation_start_time = nil
  mlc.ai_operation_type = nil
  
  if was_active then
    -- Emit state change event
    event_handler.raise_event(constants.events.on_ai_operation_state_changed, {
      uid = uid,
      operation_type = operation_type,
      start_time = nil,
      is_active = false
    })
  end
  
  return was_active
end

-- Check if a combinator has an active AI operation
function ai_operation_manager.is_operation_active(uid)
  local mlc = storage.combinators[uid]
  if not mlc then return false end
  
  return mlc.ai_operation_start_time ~= nil
end

-- Get the current operation info for a combinator
function ai_operation_manager.get_operation_info(uid)
  local mlc = storage.combinators[uid]
  if not mlc then return nil end
  
  if mlc.ai_operation_start_time then
    return {
      type = mlc.ai_operation_type,
      start_time = mlc.ai_operation_start_time,
      elapsed_seconds = (game.tick - mlc.ai_operation_start_time) / 60
    }
  end
  
  return nil
end

-- Get progress value (0-1) for current operation
function ai_operation_manager.get_operation_progress(uid)
  local info = ai_operation_manager.get_operation_info(uid)
  if not info then return 0 end
  
  local half_life_seconds = 7
  return 1 - 0.5 ^ (info.elapsed_seconds / half_life_seconds)
end

-- Get status text for current operation
function ai_operation_manager.get_operation_status_text(uid)
  local info = ai_operation_manager.get_operation_info(uid)
  if not info then return nil end
  
  if info.type == OPERATION_TYPES.TASK_EVALUATION then
    return "Evaluating task"
  elseif info.type == OPERATION_TYPES.TEST_GENERATION then
    return "Generating test cases"
  elseif info.type == OPERATION_TYPES.TEST_FIXING then
    return "Fixing implementation"
  end
  
  return "AI operation in progress"
end

return ai_operation_manager
