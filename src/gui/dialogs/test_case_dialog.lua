local dialog_manager = require("src/gui/dialogs/dialog_manager")
local titlebar = require('src/gui/components/titlebar')
local variable_row = require("src/gui/components/variable_row")
local compact_signal_panel = require("src/gui/components/compact_signal_panel")

local compact_signal_display_panel = require("src/gui/components/compact_signal_display_panel")

local dialog = {}

function dialog.show(player_index, uid, test_index)
  local player = game.players[player_index]
  local gui_t = storage.guis[uid]
  local mlc = storage.combinators[uid]
  
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local combinator_frame = gui_t.mlc_gui
  local popup_location = {
    x = combinator_frame.location.x + 28,
    y = combinator_frame.location.y + 200
  }
  
  local popup_frame = player.gui.screen.add{
    type = "frame",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  gui_t.test_case_dialog = popup_frame
  dialog_manager.set_current_dialog(player_index, popup_frame)
  popup_frame.location = popup_location
  
  local test_case = mlc.test_cases[test_index]
  titlebar.show(popup_frame, "Edit Test Case", {test_case_dialog_close = true}, {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index})

  local content_flow = popup_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  -- Test case name
  local name_flow = content_flow.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  name_flow.add{type = "label", caption = "Name:", style = "caption_label"}
  
  local name_input = name_flow.add{
    type = "textfield",
    name = "mlc-test-case-name",
    text = test_case.name or "",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index}
  }
  name_input.style.width = 300
  name_input.style.left_margin = 8
  gui_t.test_case_name_input = name_input
  
  -- Status indicator
  local status_flow = name_flow.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  status_flow.style.left_margin = 16
  
  local status_sprite = status_flow.add{
    type = "sprite", 
    sprite = "utility/status_yellow",
    name = "test-status-sprite"
  }
  
  local status_label = status_flow.add{
    type = "label",
    caption = "No output defined",
    name = "test-status-label",
    style = "label"
  }
  status_label.style.left_margin = 4
  gui_t.test_status_sprite = status_sprite
  gui_t.test_status_label = status_label
  
  -- Main content frame with light gray background
  local main_content_frame = content_flow.add{
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  main_content_frame.style.padding = 12
  main_content_frame.style.top_margin = 8
  
  -- Status indicator and cleaner layout
  local status_flow = main_content_frame.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  local status_sprite = status_flow.add{
    type = "sprite",
    sprite = "utility/status_yellow",
    name = "test-status-sprite"
  }
  
  local status_label = status_flow.add{
    type = "label",
    caption = "No expected output defined",
    name = "test-status-label",
    style = "label"
  }
  status_label.style.left_margin = 8
  
  -- Input section with minimal borders
  local input_section = main_content_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  input_section.style.top_margin = 16
  
  input_section.add{type = "label", caption = "Inputs", style = "semibold_label"}
  
  local inputs_flow = input_section.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  inputs_flow.style.top_margin = 8
  
  -- Red input with minimal styling
  local red_section = inputs_flow.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  red_section.style.width = 260
  
  red_section.add{type = "label", caption = "Red", style = "caption_label"}
  
  local red_signal_panel = red_section.add{
    type = "flow",
    direction = "vertical",
    name = "red-signal-panel",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  red_signal_panel.style.top_margin = 4
  
  compact_signal_panel.show(red_signal_panel, test_case.red_input or {}, uid, test_index, "red")
  
  -- Green input with minimal styling
  local green_section = inputs_flow.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  green_section.style.width = 260
  green_section.style.left_margin = 16
  
  green_section.add{type = "label", caption = "Green", style = "caption_label"}
  
  local green_signal_panel = green_section.add{
    type = "flow",
    direction = "vertical",
    name = "green-signal-panel",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  green_signal_panel.style.top_margin = 4
  
  compact_signal_panel.show(green_signal_panel, test_case.green_input or {}, uid, test_index, "green")
  
  -- Expected output section
  local expected_section = main_content_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  expected_section.style.top_margin = 16
  
  expected_section.add{type = "label", caption = "Expected Output", style = "semibold_label"}
  
  local expected_signal_panel = expected_section.add{
    type = "flow",
    direction = "vertical",
    name = "expected-signal-panel",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  expected_signal_panel.style.top_margin = 8
  
  compact_signal_panel.show(expected_signal_panel, test_case.expected_output or {}, uid, test_index, "expected")
  
  -- Actual output section (read-only)
  local actual_section = main_content_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  actual_section.style.top_margin = 16
  
  actual_section.add{type = "label", caption = "Actual Output (Live)", style = "semibold_label"}
  
  local actual_signal_panel = actual_section.add{
    type = "flow",
    direction = "vertical",
    name = "actual-signal-panel",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  actual_signal_panel.style.top_margin = 8
  
  compact_signal_display_panel.show(actual_signal_panel, test_case.actual_output or {})
  
  -- Advanced section
  local advanced_section = main_content_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  advanced_section.style.top_margin = 16
  
  local advanced_header = advanced_section.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  advanced_header.add{type = "label", caption = "Advanced", style = "semibold_label"}
  
  local advanced_toggle = advanced_header.add{
    type = "checkbox",
    state = test_case.show_advanced or false,
    name = "advanced-toggle",
    tags = {uid = uid, test_index = test_index, advanced_toggle = true}
  }
  advanced_toggle.style.left_margin = 8
  
  -- Advanced content (only show if toggled)
  local advanced_content = advanced_section.add{
    type = "flow",
    direction = "vertical",
    name = "advanced-content",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  advanced_content.visible = test_case.show_advanced or false
  advanced_content.style.top_margin = 8
  
  -- Game tick input
  local tick_flow = advanced_content.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  tick_flow.add{type = "label", caption = "Game Tick:", style = "caption_label"}
  tick_flow.children[1].style.width = 120
  
  local tick_input = tick_flow.add{
    type = "textfield",
    text = tostring(test_case.game_tick or 0),
    numeric = true,
    allow_negative = false,
    name = "tick-input",
    tags = {uid = uid, test_index = test_index, test_tick_input = true}
  }
  tick_input.style.width = 100
  tick_input.style.left_margin = 8
  
  -- Variables section
  local vars_header = advanced_content.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  vars_header.style.top_margin = 12
  
  vars_header.add{type = "label", caption = "Variables:", style = "caption_label"}
  
  local add_var_btn = vars_header.add{
    type = "button",
    caption = "+",
    style = "mini_button",
    tooltip = "Add variable",
    tags = {uid = uid, test_index = test_index, add_variable = true}
  }
  add_var_btn.style.left_margin = 8
  add_var_btn.style.width = 24
  add_var_btn.style.height = 24
  
  -- Variables table enclosed in filter_slot_table style
  local vars_scroll = advanced_content.add{
    type = "scroll-pane",
    name = "variables-scroll",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  vars_scroll.style.top_margin = 4
  vars_scroll.style.maximal_height = 120
  vars_scroll.style.width = 520
  
  local vars_table = vars_scroll.add{
    type = "table",
    column_count = 3,
    style = "filter_slot_table",
    name = "variables-table",
    tags = {uid = uid, test_index = test_index}
  }
  
  -- Add existing variables
  local variables = test_case.variables or {}
  for i, var in ipairs(variables) do
    variable_row.show(vars_table, uid, test_index, i, var.name or "", var.value or 0)
  end
  
  -- Always have one empty row
  if #variables == 0 then
    variable_row.show(vars_table, uid, test_index, 1, "", 0)
  end
  
  -- Expected print output section
  local print_flow = advanced_content.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  print_flow.style.top_margin = 12
  
  print_flow.add{type = "label", caption = "Expected Print:", style = "caption_label"}
  print_flow.children[1].style.width = 120
  
  local print_input = print_flow.add{
    type = "textfield",
    text = test_case.expected_print or "",
    name = "print-input",
    tags = {uid = uid, test_index = test_index, test_print_input = true}
  }
  print_input.style.width = 300
  print_input.style.left_margin = 8
  
  -- Actual print output (read-only)
  local actual_print_flow = advanced_content.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  actual_print_flow.style.top_margin = 8
  
  actual_print_flow.add{type = "label", caption = "Actual Print:", style = "caption_label"}
  actual_print_flow.children[1].style.width = 120
  
  local actual_print_label = actual_print_flow.add{
    type = "label",
    caption = test_case.actual_print or "(none)",
    name = "actual-print-label",
    tags = {uid = uid, test_index = test_index}
  }
  actual_print_label.style.left_margin = 8
  actual_print_label.style.width = 300
  actual_print_label.style.single_line = false
  
  -- Initialize dialog state
  --guis.run_test_case(mlc, test_index)
  
  -- Button row
  local button_flow = content_flow.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  button_flow.style.top_margin = 12
  
  local spacer = button_flow.add{type = "empty-widget"}
  spacer.style.horizontally_stretchable = true
  
  local cancel_btn = button_flow.add{
    type = "button",
    caption = "Cancel",
    style = "back_button",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index, test_case_cancel = true}
  }
  
  local save_btn = button_flow.add{
    type = "button",
    caption = "Save",
    style = "confirm_button",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index, test_case_save = true}
  }
  save_btn.style.left_margin = 8
  
  -- Auto-run test when dialog opens and update status
  --guis.run_test_case_in_dialog(uid, test_index)
  --guis.update_test_status_in_dialog(uid, test_index)
end

return dialog