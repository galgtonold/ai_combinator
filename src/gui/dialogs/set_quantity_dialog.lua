local event_handler = require("src/events/event_handler")
local titlebar = require('src/gui/components/titlebar')
local dialog_manager = require('src/gui/dialogs/dialog_manager')


local dialog = {}


function dialog.show(player_index, uid, test_index, signal_type, slot_index)
-- Simple quantity input dialog
  local player = game.players[player_index]
  local mlc = storage.combinators[uid]
  
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  -- Prevent multiple instances - close existing dialog if it exists
  local gui_t = storage.guis[uid]
  if gui_t and gui_t.quantity_dialog and gui_t.quantity_dialog.valid then
    gui_t.quantity_dialog.destroy()
    gui_t.quantity_dialog = nil
    gui_t.quantity_input = nil
  end
  
  local test_case = mlc.test_cases[test_index]
  local signal_array
  if signal_type == "red" then
    signal_array = test_case.red_input
  elseif signal_type == "green" then
    signal_array = test_case.green_input
  elseif signal_type == "expected" then
    signal_array = test_case.expected_output
  else
    return
  end
  
  local signal_data = signal_array[slot_index] or {}
  local current_count = signal_data.count or 1
  
  -- Create simple input dialog
  local quantity_frame = player.gui.screen.add{
    type = "frame",
    direction = "vertical",
    tags = {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  quantity_frame.location = {player.display_resolution.width / 2 - 100, player.display_resolution.height / 2 - 50}

  titlebar.show(quantity_frame, "Set Quantity", {quantity_dialog_close = true}, {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index})

  local content = quantity_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  
  local input_flow = content.add{
    type = "flow",
    direction = "horizontal",
    tags = {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  
  input_flow.add{type = "label", caption = "Quantity:"}
  
  local quantity_input = input_flow.add{
    type = "textfield",
    text = tostring(current_count),
    numeric = true,
    allow_negative = true,
    name = "quantity-input",
    tags = {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  quantity_input.style.width = 100
  quantity_input.style.left_margin = 8
  quantity_input.focus()
  quantity_input.select_all()
  
  local button_flow = content.add{
    type = "flow",
    direction = "horizontal",
    tags = {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  
  local ok_btn = button_flow.add{
    type = "button",
    caption = "OK",
    style = "confirm_button",
    tags = {quantity_ok = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  
  local cancel_btn = button_flow.add{
    type = "button",
    caption = "Cancel",
    style = "back_button",
    tags = {quantity_cancel = true}
  }
  cancel_btn.style.left_margin = 8
  
  -- Store references for later access
  local gui_t = storage.guis[uid]
  gui_t.quantity_dialog = quantity_frame
  gui_t.quantity_input = quantity_input
end

return dialog