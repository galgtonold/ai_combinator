local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")
local progress_messages = require("src/core/progress_messages")

local ai_operation_manager = {}

-- AI operation types
local OPERATION_TYPES = {
  TASK_EVALUATION = "task_evaluation",
  TEST_GENERATION = "test_generation",
  TEST_FIXING = "test_fixing"
}

ai_operation_manager.OPERATION_TYPES = OPERATION_TYPES

-- Canceled operation IDs - store correlation IDs that have been canceled by UID
local canceled_operations = {}

-- Clean up old canceled operations to prevent memory leaks
local function cleanup_canceled_operations()
  -- Remove entries for UIDs that no longer exist or have newer operations
  for uid, canceled_correlation_id in pairs(canceled_operations) do
    local mlc = storage.combinators[uid]
    if not mlc then
      -- Combinator no longer exists, remove from canceled operations
      canceled_operations[uid] = nil
    elseif mlc.ai_operation_correlation_id and mlc.ai_operation_correlation_id > canceled_correlation_id then
      -- There's a newer operation, remove the old canceled one
      canceled_operations[uid] = nil
    end
  end
end

-- Generate a unique correlation ID for operations
local function generate_correlation_id()
  if not storage.correlation_counter then
    storage.correlation_counter = 1
  else
    storage.correlation_counter = storage.correlation_counter + 1
  end
  return storage.correlation_counter
end

-- Start an AI operation for a combinator
function ai_operation_manager.start_operation(uid, operation_type)
  local mlc = storage.combinators[uid]
  if not mlc then return false, nil end
  
  -- If there's already an active operation, cancel it first
  if mlc.ai_operation_start_time then
    ai_operation_manager.cancel_operation(uid)
  end
  
  -- Generate a unique correlation ID for this operation
  local correlation_id = generate_correlation_id()
  
  -- Set new operation state
  mlc.ai_operation_start_time = game.tick
  mlc.ai_operation_type = operation_type
  mlc.ai_operation_correlation_id = correlation_id
  
  -- Remove from canceled operations if it was there
  canceled_operations[uid] = nil
  
  -- Emit state change event
  event_handler.raise_event(constants.events.on_ai_operation_state_changed, {
    uid = uid,
    operation_type = operation_type,
    start_time = game.tick,
    correlation_id = correlation_id,
    is_active = true
  })
  
  return true, correlation_id
end

-- Complete an AI operation for a combinator
function ai_operation_manager.complete_operation(uid)
  local mlc = storage.combinators[uid]
  if not mlc then return false end
  
  local was_active = mlc.ai_operation_start_time ~= nil
  local operation_type = mlc.ai_operation_type
  local correlation_id = mlc.ai_operation_correlation_id
  
  -- Clear operation state
  mlc.ai_operation_start_time = nil
  mlc.ai_operation_type = nil
  mlc.ai_operation_correlation_id = nil
  
  -- Remove from canceled operations
  canceled_operations[uid] = nil
  
  if was_active then
    -- Emit state change event
    event_handler.raise_event(constants.events.on_ai_operation_state_changed, {
      uid = uid,
      operation_type = operation_type,
      correlation_id = correlation_id,
      start_time = nil,
      is_active = false
    })
  end
  
  return was_active
end

-- Cancel an AI operation for a combinator
function ai_operation_manager.cancel_operation(uid)
  local mlc = storage.combinators[uid]
  if not mlc then return false end
  
  local was_active = mlc.ai_operation_start_time ~= nil
  local operation_type = mlc.ai_operation_type
  local correlation_id = mlc.ai_operation_correlation_id
  
  if was_active then
    -- Mark as canceled
    canceled_operations[uid] = correlation_id
    
    -- Clear operation state
    mlc.ai_operation_start_time = nil
    mlc.ai_operation_type = nil
    mlc.ai_operation_correlation_id = nil
    
    -- Emit state change event
    event_handler.raise_event(constants.events.on_ai_operation_state_changed, {
      uid = uid,
      operation_type = operation_type,
      correlation_id = correlation_id,
      start_time = nil,
      is_active = false,
      canceled = true
    })
  end
  
  return was_active
end

-- Check if a response should be ignored due to cancellation or operation mismatch
function ai_operation_manager.is_response_canceled(uid, correlation_id)
  -- First check if this specific correlation ID was canceled
  if canceled_operations[uid] == correlation_id then
    return true
  end
  
  -- Then check if there's a current active operation with a different correlation ID
  local mlc = storage.combinators[uid]
  if mlc and mlc.ai_operation_correlation_id and mlc.ai_operation_correlation_id ~= correlation_id then
    -- There's a different active operation, so this response is outdated
    return true
  end
  
  return false
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
      correlation_id = mlc.ai_operation_correlation_id,
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

-- Get status text for current operation (simple, for status indicator)
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

-- Get progress bar text for current operation (entertaining messages)
function ai_operation_manager.get_operation_progress_text(uid)
  local info = ai_operation_manager.get_operation_info(uid)
  if not info then return nil end
  
  -- Get messages for the operation type
  local messages = nil
  if info.type == OPERATION_TYPES.TASK_EVALUATION then
    messages = progress_messages.TASK_EVALUATION
  elseif info.type == OPERATION_TYPES.TEST_GENERATION then
    messages = progress_messages.TEST_GENERATION
  elseif info.type == OPERATION_TYPES.TEST_FIXING then
    messages = progress_messages.TEST_FIXING
  end
  
  if messages and #messages > 0 then
    -- Use correlation_id combined with current game tick for dynamic but consistent selection
    -- Divide by 180 so message changes every 3 seconds (60 ticks/second * 3)
    local seed = (info.correlation_id or 1) + math.floor(game.tick / 180)
    local index = (seed % #messages) + 1
    return messages[index]
  end
  
  return "Processing..."
end

-- Clean up old canceled operations (call periodically to prevent memory leaks)
function ai_operation_manager.cleanup_canceled_operations()
  cleanup_canceled_operations()
end

return ai_operation_manager
