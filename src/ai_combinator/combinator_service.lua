-- src/ai_combinator/combinator_service.lua
-- Service layer for AI Combinator business logic.
-- Handles state modifications and raises events for the view layer.

local constants = require('src/core/constants')
local event_handler = require('src/events/event_handler')
local code_manager = require('src/ai_combinator/code_manager')
local init = require('src/ai_combinator/init')
local ai_operation_manager = require('src/core/ai_operation_manager')
local memory = require('src/ai_combinator/memory')
local update = require('src/ai_combinator/update')

local combinator_service = {}

--- Save code to a combinator
---@param uid number
---@param code string|nil
---@param source_type string|nil
function combinator_service.save_code(uid, code, source_type)
    local combinator = storage.combinators[uid]
    if not combinator then return end

    -- If code is nil, use current code (just saving/committing existing state)
    -- But code_manager.load_code expects the code to be passed if we want to update history
    -- If we just want to trigger a save/init without changing code, we might need to handle that.
    -- Looking at gui.lua, it passes `code` from event or nil.
    -- If code is passed, we use it. If not, we might be just re-initializing?
    -- Actually gui.save_code(uid) calls code_manager.load_code(code, uid, source_type) where code is nil.
    -- code_manager.load_code handles nil code by using '' but checks against current code.
    
    -- Let's stick to the existing logic: pass what we have.
    -- If the caller didn't provide code, we probably want to save the *current* code?
    -- But code_manager.load_code(nil) treats it as ''. 
    -- Wait, gui.lua: `guis.save_code(uid, code, source_type)`
    -- If called from hotkey `on_code_save`, code is nil.
    -- If called from `on_code_updated` event, code is provided.
    
    -- If code is NOT provided, we should probably fetch it from the entity if we were in a GUI context,
    -- but here we are in the service layer. We assume the intention is to "commit" the current state 
    -- or update it if `code` is provided.
    
    -- However, `code_manager.load_code` has a check: `if new_code ~= '' and new_code ~= (combinator.code or '') then ...`
    -- So if we pass nil, it becomes '', and if current code is not empty, it won't update history.
    -- This seems to imply `save_code` without arguments is just "re-run/init".
    
    local action = code_manager.load_code(code, uid, source_type)
    
    if action == "remove" then
        return init.combinator_remove(uid)
    elseif action == "init" then
        init.combinator_init(combinator.e)
    end
  
    ai_operation_manager.complete_operation(uid)
    
    -- Raise event that code has been saved/updated
    event_handler.raise_event(constants.events.on_code_changed, {
        uid = uid,
        code = combinator.code,
        source_type = source_type
    })
end

--- Set the task for a combinator
---@param uid number
---@param task string
function combinator_service.set_task(uid, task)
    local combinator = storage.combinators[uid]
    if not combinator then return end
    
    combinator.task = task
    
    event_handler.raise_event(constants.events.on_task_updated, {
        uid = uid,
        task = task
    })
end

--- Set the description for a combinator
---@param uid number
---@param description string
function combinator_service.set_description(uid, description)
    local combinator = storage.combinators[uid]
    if not combinator then return end
    
    combinator.description = description
    
    event_handler.raise_event(constants.events.on_description_updated, {
        uid = uid,
        description = description
    })
end

--- Navigate code history
---@param uid number
---@param direction string "previous" or "next"
---@return boolean success
function combinator_service.navigate_code_history(uid, direction)
    local combinator = storage.combinators[uid]
    if not combinator or not combinator.code_history or #combinator.code_history == 0 then
        return false
    end
  
    local current_index = combinator.code_history_index or #combinator.code_history
    local new_index
  
    if direction == "previous" then
        new_index = math.max(1, current_index - 1)
    elseif direction == "next" then
        new_index = math.min(#combinator.code_history, current_index + 1)
    else
        return false
    end
  
    if new_index == current_index then
        return false -- No change possible
    end
  
    combinator.code_history_index = new_index
  
    -- Load the selected version
    local historical_entry = combinator.code_history[new_index]
    if historical_entry then
        combinator.code = historical_entry.code
        local combinator_env = memory.combinators[uid]
        if combinator_env then
            update.update_code(combinator, combinator_env, memory.combinator_env[combinator_env._uid])
        end
        
        event_handler.raise_event(constants.events.on_code_history_changed, {
            uid = uid,
            index = new_index,
            entry = historical_entry
        })
        return true
    end
  
    return false
end

--- Get information about code history
---@param uid number
---@return table|nil info
function combinator_service.get_code_history_info(uid)
    local combinator = storage.combinators[uid]
    if not combinator then
        return nil
    end
  
    if not combinator.code_history then
        combinator.code_history = {}
    end
  
    local total_versions = #combinator.code_history
    local current_index = combinator.code_history_index or total_versions
  
    -- Ensure index is valid
    if current_index < 1 then current_index = total_versions end
    if current_index > total_versions then current_index = total_versions end
  
    local current_entry = nil
    if current_index >= 1 and current_index <= total_versions then
        current_entry = combinator.code_history[current_index]
    end
  
    return {
        current_index = current_index,
        total_versions = total_versions,
        can_go_back = current_index > 1,
        can_go_forward = current_index < total_versions,
        current_entry = current_entry,
        is_latest = current_index == total_versions
    }
end

--- Add a new test case
---@param uid number
---@return number index The index of the new test case
function combinator_service.add_test_case(uid)
    local combinator = storage.combinators[uid]
    if not combinator then return end
    
    if not combinator.test_cases then
        combinator.test_cases = {}
    end
    
    local new_test_index = #combinator.test_cases + 1
    table.insert(combinator.test_cases, {
        name = "Test Case " .. new_test_index,
        red_input = {},
        green_input = {},
        expected_output = {},
        actual_output = {},
        success = false
    })
    
    event_handler.raise_event(constants.events.on_test_case_updated, {
        uid = uid,
        test_index = new_test_index
    })
    
    return new_test_index
end

--- Remove a test case
---@param uid number
---@param index number
function combinator_service.remove_test_case(uid, index)
    local combinator = storage.combinators[uid]
    if not combinator or not combinator.test_cases then return end

    table.remove(combinator.test_cases, index)
    
    -- We need to notify that the list changed, effectively invalidating indices
    -- For now, we can raise an event that triggers a full refresh
    event_handler.raise_event(constants.events.on_test_case_evaluated, {
        uid = uid
    })
end

--- Update a test case
---@param uid number
---@param index number
---@param data table The new data for the test case (merged)
function combinator_service.update_test_case(uid, index, data)
    local combinator = storage.combinators[uid]
    if not combinator or not combinator.test_cases then return end
    
    local test_case = combinator.test_cases[index]
    if not test_case then return end
    
    for k, v in pairs(data) do
        test_case[k] = v
    end
    
    event_handler.raise_event(constants.events.on_test_case_updated, {
        uid = uid,
        test_index = index
    })
end

return combinator_service
