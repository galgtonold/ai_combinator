local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")
local ai_operation_manager = require("src/core/ai_operation_manager")

local bridge = {}

-- Bridge availability check state
local bridge_check_state = {
    active = false,
    check_uid = constants.BRIDGE_CHECK_UID,
    timeout_tick = 0,
    pending_check = false,
}

local function send_message(payload)
    helpers.send_udp(constants.AI_BRIDGE_PORT, helpers.table_to_json(payload))
end

function bridge.send_task_request(uid, task_text)
    -- Get correlation ID from the operation manager
    local operation_info = ai_operation_manager.get_operation_info(uid)
    local correlation_id = operation_info and operation_info.correlation_id or uid

    local payload = {
        type = "task_request",
        uid = uid,
        correlation_id = correlation_id,
        task_text = task_text,
    }
    send_message(payload)
end

function bridge.send_test_generation_request(uid, task_description, source_code)
    -- Get correlation ID from the operation manager
    local operation_info = ai_operation_manager.get_operation_info(uid)
    local correlation_id = operation_info and operation_info.correlation_id or uid

    local payload = {
        type = "test_generation_request",
        uid = uid,
        correlation_id = correlation_id,
        task_description = task_description,
        source_code = source_code,
    }
    send_message(payload)
end

function bridge.send_fix_request(uid, task_description, current_code, test_cases, errors)
    -- Get correlation ID from the operation manager
    local operation_info = ai_operation_manager.get_operation_info(uid)
    local correlation_id = operation_info and operation_info.correlation_id or uid

    -- Build comprehensive fix prompt using existing task_request type
    local fix_prompt = "FIX REQUEST - Please fix the following Lua code to make all tests pass.\n\n"

    fix_prompt = fix_prompt .. "ORIGINAL TASK:\n" .. (task_description or "No task description available") .. "\n\n"

    -- Include any syntax or runtime errors
    if errors and (errors.parse or errors.run or errors.out) then
        fix_prompt = fix_prompt .. "CODE ERRORS (must be fixed):\n"
        if errors.parse then
            fix_prompt = fix_prompt .. "  Syntax Error: " .. errors.parse .. "\n"
        end
        if errors.run then
            fix_prompt = fix_prompt .. "  Runtime Error: " .. errors.run .. "\n"
        end
        if errors.out then
            fix_prompt = fix_prompt .. "  Output Error: " .. errors.out .. "\n"
        end
        fix_prompt = fix_prompt .. "\n"
    end

    fix_prompt = fix_prompt .. "CURRENT CODE TO FIX:\n" .. (current_code or "No code available") .. "\n\n"

    if test_cases and #test_cases > 0 then
        fix_prompt = fix_prompt .. "TEST RESULTS:\n"
        for i, test_case in ipairs(test_cases) do
            local status = test_case.success and "PASSED" or "FAILED"
            fix_prompt = fix_prompt .. string.format("Test %d: %s [%s]\n", i, test_case.name or "Unnamed Test", status)

            fix_prompt = fix_prompt .. "  Red inputs: "
            if test_case.red_input and #test_case.red_input > 0 then
                for _, signal in ipairs(test_case.red_input) do
                    fix_prompt = fix_prompt .. string.format("%s=%d ", signal.signal.name or signal.signal, signal.count)
                end
            else
                fix_prompt = fix_prompt .. "None"
            end
            fix_prompt = fix_prompt .. "\n"

            fix_prompt = fix_prompt .. "  Green inputs: "
            if test_case.green_input and #test_case.green_input > 0 then
                for _, signal in ipairs(test_case.green_input) do
                    fix_prompt = fix_prompt .. string.format("%s=%d ", signal.signal.name or signal.signal, signal.count)
                end
            else
                fix_prompt = fix_prompt .. "None"
            end
            fix_prompt = fix_prompt .. "\n"

            fix_prompt = fix_prompt .. "  Expected outputs: "
            if test_case.expected_output and #test_case.expected_output > 0 then
                for _, signal in ipairs(test_case.expected_output) do
                    fix_prompt = fix_prompt .. string.format("%s=%d ", signal.signal.name or signal.signal, signal.count)
                end
            else
                fix_prompt = fix_prompt .. "None"
            end
            fix_prompt = fix_prompt .. "\n"

            fix_prompt = fix_prompt .. "  Actual outputs: "
            if test_case.actual_output and #test_case.actual_output > 0 then
                for _, signal in ipairs(test_case.actual_output) do
                    fix_prompt = fix_prompt .. string.format("%s=%d ", signal.signal.name or signal.signal, signal.count)
                end
            else
                fix_prompt = fix_prompt .. "None"
            end
            fix_prompt = fix_prompt .. "\n"

            if test_case.expected_print and test_case.expected_print ~= "" then
                fix_prompt = fix_prompt .. "  Expected print: " .. test_case.expected_print .. "\n"
            end

            if test_case.actual_print and test_case.actual_print ~= "" then
                fix_prompt = fix_prompt .. "  Actual print: " .. test_case.actual_print .. "\n"
            end

            fix_prompt = fix_prompt .. "  Variables: "
            if test_case.variables and #test_case.variables > 0 then
                for _, var in ipairs(test_case.variables) do
                    fix_prompt = fix_prompt .. string.format("%s=%s ", var.name, tostring(var.value))
                end
            else
                fix_prompt = fix_prompt .. "None"
            end
            fix_prompt = fix_prompt .. "\n"

            fix_prompt = fix_prompt .. "  Game tick: " .. (test_case.game_tick or 1) .. "\n"

            fix_prompt = fix_prompt .. "\n"
        end
    end

    fix_prompt = fix_prompt .. "Please provide ONLY the corrected Lua code that will make all tests pass. "
    fix_prompt = fix_prompt .. "If the tests are incompatible with the task description, respond with ERROR: <explanation of the issue>."

    local payload = {
        type = "fix_request",
        uid = uid,
        correlation_id = correlation_id,
        task_text = fix_prompt,
    }
    send_message(payload)
end

function bridge.send_ping_request(uid)
    local payload = {
        type = "ping_request",
        uid = uid or 0,
        timestamp = game.tick,
    }
    send_message(payload)
end

function bridge.check_bridge_availability()
    -- Set flag to trigger the actual check later when game is available
    bridge_check_state.pending_check = true
end

local function perform_bridge_check()
    -- Actually perform the bridge check now that game is available
    bridge_check_state.pending_check = false
    bridge_check_state.active = true
    bridge_check_state.timeout_tick = game.tick + 60 -- 1 second timeout
    bridge.send_ping_request(bridge_check_state.check_uid)
end

local function check_bridge_timeout()
    -- Handle pending check first
    if bridge_check_state.pending_check then
        perform_bridge_check()
        return
    end

    -- Return early if no check is active
    if not bridge_check_state.active then
        return
    end

    -- Check if timeout has been reached
    if game.tick >= bridge_check_state.timeout_tick then
        -- Timeout reached, bridge is not available
        bridge_check_state.active = false
        event_handler.raise_event(constants.events.on_bridge_check_completed, {
            available = false,
            uid = bridge_check_state.check_uid,
        })
    end
end

local function handle_message(event)
    local payload = helpers.json_to_table(event.payload)
    if not payload or not payload.type then
        game.print("Received invalid message: " .. event.payload)
        return
    end

    -- Check if this response should be ignored due to cancellation
    if payload.uid and payload.correlation_id then
        if ai_operation_manager.is_response_canceled(payload.uid, payload.correlation_id) then
            return
        end
    end

    if payload.type == "task_request_completed" then
        event_handler.raise_event(constants.events.on_task_request_completed, payload)
    elseif payload.type == "test_generation_completed" then
        event_handler.raise_event(constants.events.on_test_generation_completed, payload)
    elseif payload.type == "fix_completed" then
        -- if response starts with "ERROR: ", treat as error
        payload.success = not (type(payload.response) == "string" and string.sub(payload.response, 1, 6) == "ERROR:")
        payload.code = payload.response
        payload.error_message = payload.success and nil or payload.response

        event_handler.raise_event(constants.events.on_fix_completed, payload)
    elseif payload.type == "ping_response" then
        -- Check if this is a response to our bridge availability check
        if payload.uid == bridge_check_state.check_uid and bridge_check_state.active then
            -- Got a response, cancel the timeout check
            bridge_check_state.active = false
            event_handler.raise_event(constants.events.on_bridge_check_completed, {
                available = true,
                uid = payload.uid,
            })
        end
        event_handler.raise_event(constants.events.on_ping_response, payload)
    end
end

event_handler.add_handler(defines.events.on_udp_packet_received, handle_message)
event_handler.add_handler(defines.events.on_tick, check_bridge_timeout)

return bridge
