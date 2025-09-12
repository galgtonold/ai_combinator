local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")

local bridge = {}

local SERVER_PORT = 8889

-- Bridge availability check state
local bridge_check_state = {
  active = false,
  check_uid = 999999,
  timeout_tick = 0,
  pending_check = false
}

local function send_message(payload)
  helpers.send_udp(SERVER_PORT, helpers.table_to_json(payload))
end

function bridge.send_task_request(uid, task_text)
  local payload = {
    type = "task_request",
    uid = uid,
    task_text = task_text
  }
  send_message(payload)
end

function bridge.send_test_generation_request(uid, task_description, source_code)
  local payload = {
    type = "test_generation_request",
    uid = uid,
    task_description = task_description,
    source_code = source_code
  }
  send_message(payload)
end

function bridge.send_ping_request(uid)
  local payload = {
    type = "ping_request",
    uid = uid or 0,
    timestamp = game.tick
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
      uid = bridge_check_state.check_uid
    })
  end
end

local function handle_message(event)
  local payload = helpers.json_to_table(event.payload)
  if not payload or not payload.type then
    game.print("Received invalid message: " .. event.payload)
    return
  end
  if payload.type == "task_request_completed" then
    event_handler.raise_event(constants.events.on_task_request_completed, payload)
  elseif payload.type == "test_generation_completed" then
    event_handler.raise_event(constants.events.on_test_generation_completed, payload)
  elseif payload.type == "ping_response" then
    -- Check if this is a response to our bridge availability check
    if payload.uid == bridge_check_state.check_uid and bridge_check_state.active then
      -- Got a response, cancel the timeout check
      bridge_check_state.active = false
      event_handler.raise_event(constants.events.on_bridge_check_completed, {
        available = true,
        uid = payload.uid
      })
    end
    event_handler.raise_event(constants.events.on_ping_response, payload)
  end
end

event_handler.add_handler(defines.events.on_udp_packet_received, handle_message)
event_handler.add_handler(defines.events.on_tick, check_bridge_timeout)



return bridge