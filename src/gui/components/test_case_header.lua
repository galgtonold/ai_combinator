local event_handler = require("src/events/event_handler")
local gui_utils = require("src/gui/gui_utils")
local constants = require("src/core/constants")

local set_test_case_name_dialog = require("src/gui/dialogs/set_test_case_name_dialog")


local component = {}

function component.show(parent, uid, test_index)
  local gui_t = storage.guis[uid]
  local mlc = storage.combinators[uid]
  local test_case = mlc.test_cases[test_index]

  local name_heading = parent.add{ type = 'frame', style = 'subheader_frame_with_text_on_the_right', direction ='horizontal' }
  name_heading.style.top_margin = -12
  name_heading.style.left_margin = -12
  name_heading.style.right_margin = -12
  name_heading.style.horizontally_stretchable = true
  name_heading.style.horizontally_squashable = true

  local name_label = name_heading.add{
    type = "label",
    name = "test-case-details-label-" .. uid .. "",
    caption = test_case.name,
    style = "subheader_caption_label"
  }

  gui_t.test_case_name_label = name_label

  local name_edit_button = name_heading.add{
    type = "sprite-button",
    sprite = "utility/rename_icon",
    style = "mini_button",
    tooltip = "Edit test case name",
    tags = {edit_test_case_name = true, uid = uid, test_index = test_index}
  }
end

function component.update(parent, uid, test_index)

end

local function on_gui_click(event)
  local element = event.element

  if not element.valid or not element.tags then return end

  if element.tags.edit_test_case_name then
    local location = gui_utils.get_position_relative_to_window(element, 25, 100)
    set_test_case_name_dialog.show(event.player_index, element.tags.uid, location, element.tags.edit_signal_quantity_count, {uid = element.tags.uid, test_index = element.tags.test_index})
  end
end

local function on_test_case_name_updated(event)
  local gui_t = storage.guis[event.uid]
  gui_t.test_case_name_label.caption = event.test_name

  local mlc = storage.combinators[event.uid]
  local test_case = mlc.test_cases[event.test_index]

  test_case.name = event.test_name
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)
event_handler.add_handler(constants.events.on_test_case_name_updated, on_test_case_name_updated)

return component