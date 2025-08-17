local event_handler = require("event_handler")
local constants = require("constants")

local bridge = {}

local SERVER_PORT = 8889

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

local function handle_message(event)
  local payload = helpers.json_to_table(event.payload)
  if not payload or not payload.type then
    game.print("Received invalid message: " .. event.payload)
    return
  end
  if payload.type == "task_request_completed" then
    event_handler.raise_event(constants.events.on_task_request_completed, payload)
  end
end

event_handler.add_handler(defines.events.on_udp_packet_received, handle_message)



return bridge