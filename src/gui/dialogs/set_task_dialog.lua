local event_handler = require("src/events/event_handler")
local titlebar = require('src/gui/titlebar')
local dialog_manager = require('src/gui/dialogs/dialog_manager')


local dialog = {}

local NO_TASK_SET_DESCRIPTION = 'No task set. Click to set a task.'

function dialog.show(player_index, uid)
  local player = game.players[player_index]
	local gui_t = storage.guis[uid]

  local combinator_frame = gui_t.mlc_gui
  local popup_location = {
    x = combinator_frame.location.x + 28,
    y = combinator_frame.location.y + 500
  }
  local popup_frame = player.gui.screen.add{
    type = "frame",
    direction = "vertical",
    tags = {uid = uid, dialog = true},
  }
  gui_t.task_dialog = popup_frame
  dialog_manager.set_current_dialog(player_index, popup_frame)
  popup_frame.location = popup_location
  titlebar.show(popup_frame, "Set Task", {task_dialog_close = true}, {uid = uid, dialog = true})
  local content_flow = popup_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true},
  }

  local task_text = gui_t.mlc_task_label.caption
  if task_text == NO_TASK_SET_DESCRIPTION then
    task_text = ""
  end

  local task_textbox = content_flow.add{
    type = "text-box",
    name = "mlc-task-input",
    text = task_text,
    style = "edit_blueprint_description_textbox",
    tags = {uid = uid, dialog = true},
  }
  task_textbox.word_wrap = true
  task_textbox.style.width = 400
  task_textbox.style.bottom_margin = 8
  gui_t.task_textbox = task_textbox

  local confirm_flow = content_flow.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true},
  }
  task_textbox.focus()

  local filler = confirm_flow.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
    tags = {uid = uid, dialog = true},
  }
  filler.style.horizontally_stretchable = true
  filler.style.vertically_stretchable = true

  local confirm_button = confirm_flow.add{
    type = "button",
    caption = "Set Task",
    style = "confirm_button",
    tags = {uid = uid, set_task_button = true, dialog = true},
  }
  confirm_button.style.left_margin = 8
end

return dialog