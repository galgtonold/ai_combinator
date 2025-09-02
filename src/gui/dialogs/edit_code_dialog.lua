local dialog_manager = require("src/gui/dialogs/dialog_manager")
local titlebar = require('src/gui/components/titlebar')
local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")

local help_dialog = require("src/gui/dialogs/help_dialog")

local dialog = {}


local err_icon_sub_add = '[color=#c02a2a]%1[/color]'
local err_icon_sub_clear = '%[color=#c02a2a%]([^\n]+)%[/color%]'
local function code_error_highlight(text, line_err)
	-- Add/strip rich error highlight tags
	if type(line_err) == 'string'
		then line_err = line_err:match(':(%d+):') end
	text = text:gsub(err_icon_sub_clear, '%1')
	text = text:match('^(.-)%s*$') -- strip trailing newlines/spaces
	line_err = tonumber(line_err)
	if not line_err then return text end
	local _, line_count = text:gsub('([^\n]*)\n?','')
	if string.sub(text, -1) == '\n'
		then line_count = line_count + 1 end
	local n, result = 0, ''
	for line in text:gmatch('([^\n]*)\n?') do
		n = n + 1
		if n == line_err
			then line = line:gsub('^(.+)$', err_icon_sub_add) end
		if n < line_count or line ~= '' then result = result..line..'\n' end
	end
	return result
end

function dialog.show(player_index, uid)
  local player = game.players[player_index]
	local gui_t = storage.guis[uid]
	local mlc = storage.combinators[uid]
	local mlc_err = mlc.err_parse or mlc.errun


  local combinator_frame = gui_t.mlc_gui
  local popup_location = {
    x = combinator_frame.location.x + 28,
    y = combinator_frame.location.y + 500
  }
  local popup_frame = player.gui.screen.add{
    type = "frame",
    direction = "vertical",
    tags = {uid = uid, dialog = true, edit_code_dialog = true},
  }
  gui_t.edit_code_dialog = popup_frame
  dialog_manager.set_current_dialog(player_index, popup_frame)

  local extra_buttons = {{
      type = "sprite-button",
      style = "frame_action_button",
      sprite = "mlc-help",
      tooltip = "Show help",
      tags = {show_help_button = true}
    }
  }
  titlebar.show(popup_frame, "Edit Source Code", {edit_code_dialog_close = true}, {uid = uid, dialog = true, edit_code_dialog = true}, extra_buttons)

  local content_flow = popup_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, edit_code_dialog = true},
  }

  -- Get current code from the combinator
  local current_code = mlc.code or ""

  local code_textbox = content_flow.add{
    type = "text-box",
    name = "mlc-edit-code-input",
    text = current_code,
    style = "edit_blueprint_description_textbox",
    tags = {uid = uid, dialog = true, edit_code_dialog = true},
  }
  code_textbox.text = code_error_highlight(code_textbox.text, mlc_err)

  code_textbox.word_wrap = true
  code_textbox.style.width = 600
  code_textbox.style.height = 400
  code_textbox.style.bottom_margin = 8
  gui_t.edit_code_textbox = code_textbox

  local button_flow = content_flow.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, edit_code_dialog = true},
  }
  
  local filler = button_flow.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
    tags = {uid = uid, dialog = true, edit_code_dialog = true},
  }
  filler.style.horizontally_stretchable = true
  filler.style.vertically_stretchable = true

  local cancel_button = button_flow.add{
    type = "button",
    caption = "Cancel",
    style = "back_button",
    tags = {uid = uid, edit_code_cancel = true, dialog = true, edit_code_dialog = true},
  }
  cancel_button.style.left_margin = 8

  local apply_button = button_flow.add{
    type = "button",
    caption = "Apply Code",
    style = "confirm_button",
    tags = {uid = uid, edit_code_apply = true, dialog = true, edit_code_dialog = true},
  }
  apply_button.style.left_margin = 8
  
  code_textbox.focus()
end

function on_gui_click(event)
	local el = event.element

  if not el.valid or not el.tags then return end

  local uid = event.element.tags.uid
  gui = storage.guis[uid]

  if event.element.tags.edit_code_cancel then
    dialog_manager.close_dialog(event.player_index)
  elseif event.element.tags.edit_code_apply then
    local code_input = gui.edit_code_textbox
    local code_text = code_error_highlight(code_input.text)
    event_handler.raise_event(constants.events.on_code_updated, {player_index = event.player_index, uid = uid, code = code_text})
    dialog_manager.close_dialog(event.player_index)
  elseif event.element.tags.show_help_button then
    help_dialog.show(event.player_index)
  end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)

return dialog