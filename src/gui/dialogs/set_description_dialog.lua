local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")
local titlebar = require('src/gui/titlebar')
local dialog_manager = require('src/gui/dialogs/dialog_manager')

local dialog = {}

function dialog.show(player_index, uid)
  local player = game.players[player_index]
	local gui_t = storage.guis[uid]
  local mlc = storage.combinators[uid]

  local combinator_frame = gui_t.mlc_gui
  local popup_location = {
    x = combinator_frame.location.x + 28,
    y = combinator_frame.location.y + 500
  }
  local popup_frame = player.gui.screen.add{
    type = "frame",
    direction = "vertical",
    tags = {uid = uid, dialog = true, description_dialog = true},
  }
  gui_t.description_dialog = popup_frame
  dialog_manager.set_current_dialog(player_index, popup_frame)
  popup_frame.location = popup_location
  titlebar.show(popup_frame, "Set Description", {description_dialog_close = true}, {uid = uid, dialog = true, description_dialog = true})
  local content_flow = popup_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, description_dialog = true},
  }

  local description_text = mlc.description or ""

  local description_textbox = content_flow.add{
    type = "text-box",
    name = "mlc-description-input",
    text = description_text,
    style = "edit_blueprint_description_textbox",
    tags = {uid = uid, dialog = true, description_dialog = true},
  }
  description_textbox.word_wrap = true
  description_textbox.style.width = 400
  description_textbox.style.bottom_margin = 8
  gui_t.description_textbox = description_textbox

  local confirm_flow = content_flow.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, description_dialog = true},
  }
  description_textbox.focus()

  local filler = confirm_flow.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
    tags = {uid = uid, dialog = true, description_dialog = true},
  }
  filler.style.horizontally_stretchable = true
  filler.style.vertically_stretchable = true

  local confirm_button = confirm_flow.add{
    type = "button",
    caption = "Set Description",
    style = "confirm_button",
    tags = {uid = uid, set_description_button = true, dialog = true, description_dialog = true},
  }
  confirm_button.style.left_margin = 8
end

function on_gui_click(event)
	local el = event.element

  if not el.valid or not el.tags then return end

  local uid = event.element.tags.uid
  gui = storage.guis[uid]

  if event.element.tags.set_description_button then
    local description_input = gui.description_textbox
    event_handler.raise_event(constants.events.on_description_updated, {player_index = event.player_index, uid = uid, description = description_input.text})
    dialog_manager.close_dialog(event.player_index)
  end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)

return dialog