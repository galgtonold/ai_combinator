local event_handler = require("src/events/event_handler")
local gui_utils = require("src/gui/gui_utils")
local constants = require("src/core/constants")

local set_test_case_name_dialog = require("src/gui/dialogs/set_test_case_name_dialog")


local component = {}

function component.show(parent, uid, test_index)
  local gui_t = storage.guis[uid]
  local combinator = storage.combinators[uid]
  local test_case = combinator.test_cases[test_index]

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

  name_heading.add{
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
    local combinator = storage.combinators[element.tags.uid]
    local current_name = combinator.test_cases[element.tags.test_index].name
    local location = gui_utils.get_position_relative_to_window(element, 25, 100)
    set_test_case_name_dialog.show(event.player_index, element.tags.uid, location, current_name, {uid = element.tags.uid, test_index = element.tags.test_index})
  end
end

local function on_test_case_updated(event)
  local gui_t = storage.guis[event.uid]
  if not gui_t or not gui_t.test_case_name_label or not gui_t.test_case_name_label.valid then return end
  
  -- Check if this update is for the test case we are displaying
  -- The label doesn't have tags, but we can check if the dialog is open for this test index
  if gui_t.test_case_dialog and gui_t.test_case_dialog.tags.test_index == event.test_index then
      local combinator = storage.combinators[event.uid]
      local test_case = combinator.test_cases[event.test_index]
      if test_case then
          gui_t.test_case_name_label.caption = test_case.name
      end
  end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)
event_handler.add_handler(constants.events.on_test_case_updated, on_test_case_updated)

return component