local event_handler = require("src/events/event_handler")
local dialog_manager = require("src/gui/dialogs/dialog_manager")
local utils = require("src/core/utils")

local tbar = {}

function tbar.show(gui, caption, close_button_tags, extra_tags, extra_buttons)
  extra_tags = extra_tags or {}

  local titlebar = gui.add{type = "flow", style = "frame_header_flow", tags = extra_tags}
  titlebar.drag_target = gui
  local title_label = titlebar.add{
    type = "label",
    style = "frame_title",
    caption = caption,
    ignored_by_interaction = true,
    tags = extra_tags,
  }
  title_label.style.bottom_padding = 3
  title_label.style.top_margin = -3
  local filler = titlebar.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
    tags = extra_tags,
  }
  filler.style.height = 24
  filler.style.horizontally_stretchable = true
  filler.style.right_margin = 5

  if extra_buttons then
    for _, button in ipairs(extra_buttons) do
      titlebar.add(button)
    end
  end  

  local close_button_tags = close_button_tags or {}
  for k, v in pairs(extra_tags) do
    close_button_tags[k] = v
  end

  titlebar.add{
    type = "sprite-button",
    style = "frame_action_button",
    sprite = "utility/close",
    tooltip = {"gui.close-instruction"},
    tags = utils.merge(close_button_tags, {close_button = true})
  }
  return titlebar
end

local function on_gui_click(event)
	local el = event.element

  if not el.valid or not el.tags then return end

  if event.element.tags.close_button then
    -- If this is the main combinator UI close, let gui.lua handle it
    if event.element.tags.close_combinator_ui then
      return -- Handled by guis.on_gui_click
    end
    
    -- Find the parent dialog frame (walk up until we find a frame)
    local dialog_frame = el.parent
    while dialog_frame and dialog_frame.valid do
      if dialog_frame.type == "frame" and dialog_frame.parent and dialog_frame.parent.name == "screen" then
        break
      end
      dialog_frame = dialog_frame.parent
    end
    
    -- Close this dialog and all child dialogs (dialogs opened after this one)
    if dialog_frame and dialog_frame.valid then
      dialog_manager.close_dialog_and_children(event.player_index, dialog_frame)
    else
      -- Fallback to just closing the topmost dialog
      dialog_manager.close_dialog(event.player_index)
    end
  end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)

return tbar