local dialog_manager = require("src/gui/dialogs/dialog_manager")
local constants = require("src/core/constants")
local event_handler = require("src/events/event_handler")
local help_dialog = require("src/gui/dialogs/help_dialog")

local titlebar = require('src/gui/components/titlebar')
local compact_signal_panel = require("src/gui/components/compact_signal_panel")
local test_case_header = require("src/gui/components/test_case_header")
local status_indicator = require("src/gui/components/status_indicator")
local test_case_advanced_section = require("src/gui/components/test_case_advanced_section")

local dialog = {}

local function signals_to_lookup(signal_array)
  local lookup = {}
  if not signal_array then return lookup end
  
  for _, signal in ipairs(signal_array) do
    if signal and signal.signal then
      lookup[signal.signal.name or signal.signal] = signal.count or 0
    end
  end
  return lookup
end

local function find_value_mismatch(expected_signals, actual_signals)
  for signal_name, expected_count in pairs(expected_signals) do
    local actual_count = actual_signals[signal_name] or 0
    if actual_count ~= expected_count and actual_count > 0 then
      return signal_name, actual_count, expected_count
    end
  end
  return nil
end

local function generate_failure_message(test_case)
  local failure_message = "Failed"
  
  -- Check for print output failure first (most specific)
  if test_case.expected_print and test_case.expected_print ~= "" and test_case.print_matches == false then
    return "Failed: Print output mismatch"
  end
  
  if test_case.expected_output and test_case.actual_output then
    local expected_signals = signals_to_lookup(test_case.expected_output)
    local actual_signals = signals_to_lookup(test_case.actual_output)
    
    -- Check for value mismatches
    local signal_name, actual_count, expected_count = find_value_mismatch(expected_signals, actual_signals)
    if signal_name then
      return "Failed: " .. signal_name .. " = " .. actual_count .. " (expected " .. expected_count .. ")"
    end
  end
  
  -- Check for missing/unexpected signals
  if test_case.only_in_expected and #test_case.only_in_expected > 0 then
    return "Failed: Missing " .. test_case.only_in_expected[1]
  elseif test_case.only_in_actual and #test_case.only_in_actual > 0 then
    return "Failed: Unexpected " .. test_case.only_in_actual[1]
  end
  
  return failure_message
end

local function update_status(uid, test_index)
  local gui_t = storage.guis[uid]
  if not (gui_t and gui_t.test_case_dialog and gui_t.test_case_status_flow) then
    return
  end

  local combinator = storage.combinators[uid]
  if not (combinator and combinator.test_cases and combinator.test_cases[test_index]) then
    return
  end

  local test_case = combinator.test_cases[test_index]
  local status_flow = gui_t.test_case_status_flow
  
  if test_case.success then
    status_indicator.update(status_flow, status_indicator.status.GREEN, "Passed")
  else
    local failure_message = generate_failure_message(test_case)
    status_indicator.update(status_flow, status_indicator.status.RED, failure_message)
  end
end

function dialog.show(player_index, uid, test_index)
  local player = game.players[player_index]
  local gui_t = storage.guis[uid]
  local combinator = storage.combinators[uid]
  
  if not combinator or not combinator.test_cases or not combinator.test_cases[test_index] then
    return
  end

  -- Close existing dialogs of this type or conflicting types
  if gui_t.edit_code_dialog and gui_t.edit_code_dialog.valid then
    gui_t.edit_code_dialog.destroy()
    gui_t.edit_code_dialog = nil
  end
  if gui_t.test_case_dialog and gui_t.test_case_dialog.valid then
    gui_t.test_case_dialog.destroy()
    gui_t.test_case_dialog = nil
  end
  
  local combinator_frame = gui_t.ai_combinator_gui
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
  
  local test_case = combinator.test_cases[test_index]
  local extra_buttons = {
    {
      type = "sprite-button",
      sprite = "ai-combinator-help",
      style = "frame_action_button",
      tooltip = "Help",
      tags = {show_test_case_help_button = true, uid = uid, dialog = true, test_case_dialog = true, test_index = test_index}
    }
  }
  titlebar.show(popup_frame, "Test Case", {test_case_dialog_close = true}, {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index}, extra_buttons)
  
  -- Main content frame with light gray background
  local main_content_frame = popup_frame.add{
    type = "frame",
    direction = "vertical",
    style = "entity_frame",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  main_content_frame.style.padding = 12
  main_content_frame.style.top_margin = 0

  test_case_header.show(main_content_frame, uid, test_index)


  local status_flow = status_indicator.show(main_content_frame, "utility/status_working", "Working")
  gui_t.test_case_status_flow = status_flow
  update_status(uid, test_index)

  -- Input section with minimal borders
  local input_section = main_content_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  input_section.add{type = "label", caption = "Inputs", style = "caption_label"}
  
  local inputs_flow = input_section.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  -- Red input with minimal styling
  local red_section = inputs_flow.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  red_section.style.width = 240
  
  red_section.add{type = "label", caption = "Red", style = "semibold_label"}
  
  local red_signal_panel = red_section.add{
    type = "flow",
    direction = "vertical",
    name = "red-signal-panel",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  compact_signal_panel.show(red_signal_panel, test_case.red_input or {}, uid, test_index, "red")
  
  -- Green input with minimal styling
  local green_section = inputs_flow.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  green_section.style.width = 240
  green_section.style.left_margin = 40
  
  green_section.add{type = "label", caption = "Green", style = "semibold_label"}
  
  local green_signal_panel = green_section.add{
    type = "flow",
    direction = "vertical",
    name = "green-signal-panel",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  compact_signal_panel.show(green_signal_panel, test_case.green_input or {}, uid, test_index, "green")
  
  -- Expected output section
  local expected_section = main_content_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  expected_section.add{type = "label", caption = "Expected Output", style = "caption_label"}
  
  local expected_signal_panel = expected_section.add{
    type = "flow",
    direction = "vertical",
    name = "expected-signal-panel",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  compact_signal_panel.show(expected_signal_panel, test_case.expected_output or {}, uid, test_index, "expected")
  
  -- Actual output section (read-only)
  local actual_section = main_content_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  actual_section.add{type = "label", caption = "Actual Output (Live)", style = "caption_label"}
  
  local actual_signal_panel = actual_section.add{
    type = "flow",
    direction = "vertical",
    name = "actual-signal-panel",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  compact_signal_panel.show(actual_signal_panel, test_case.actual_output or {}, uid, test_index, "actual")
  
  -- Advanced section (using component)
  test_case_advanced_section.show(main_content_frame, uid, test_index)

end

local function on_test_case_evaluated(event)
  update_status(event.uid, event.test_index)
end

local function on_gui_click(event)
  if not event.element or not event.element.valid or not event.element.tags then return end
  
  -- Handle help button click specifically for test case dialog
  if event.element.tags.show_test_case_help_button then
    help_dialog.show(event.player_index, help_dialog.HELP_TYPES.TEST_CASE)
  end
end

event_handler.add_handler(constants.events.on_test_case_evaluated, on_test_case_evaluated)
event_handler.add_handler(defines.events.on_gui_click, on_gui_click)

return dialog