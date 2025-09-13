local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")

local component = {}

function component.show(parent, uid, test_index)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  
  -- Helper function to add elements to the el_map
  local function add_to_map(element)
    if element.name then
      gui_t.el_map[element.index] = element
    end
    return element
  end
  
  -- Advanced section
  local advanced_section = parent.add{
    type = "flow",
    direction = "vertical",
    name = "test-case-advanced-section",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  advanced_section.style.top_margin = 8
  
  local advanced_toggle = advanced_section.add{
    type = "checkbox",
    style = "caption_checkbox",
    caption = "Advanced options",
    state = test_case.show_advanced or false,
    name = "advanced-toggle",
    tags = {uid = uid, test_index = test_index, advanced_toggle = true}
  }
  add_to_map(advanced_toggle)
  
  -- Advanced content (only show if toggled)
  local advanced_content = advanced_section.add{
    type = "flow",
    direction = "vertical",
    name = "advanced-content",
    style = "packed_vertical_flow",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  advanced_content.visible = test_case.show_advanced or false
  
  -- Store reference for updates
  gui_t.test_case_advanced_content = advanced_content
  
  component.update_content(advanced_content, uid, test_index)
  
  return advanced_section
end

function component.update_content(advanced_content, uid, test_index)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  
  -- Helper function to add elements to the el_map
  local function add_to_map(element)
    if element.name then
      gui_t.el_map[element.index] = element
    end
    return element
  end
  
  -- Clear existing content
  advanced_content.clear()
  
  -- Variables section
  local vars_header = advanced_content.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  
  vars_header.add{type = "label", caption = "Variables [img=info]", style = "label", tooltip = "Internal variables that can be used to keep state. Look at the implementation for available variables."}
  
  local add_var_btn = vars_header.add{
    type = "sprite-button",
    sprite = "utility/add",
    style = "mini_button_aligned_to_text_vertically",
    tooltip = "Add variable",
    name = "add-variable-btn",
    tags = {uid = uid, test_index = test_index, add_variable = true}
  }
  add_var_btn.style.left_margin = 8
  add_to_map(add_var_btn)
  
  -- Variables list with individual frames (similar to test_cases_section)
  local variables = test_case.variables or {}
  if #variables > 0 then
    local vars_scroll = advanced_content.add{
      type = "scroll-pane",
      name = "variables-scroll",
      direction = "vertical",
      horizontal_scroll_policy = "never",
      style = "shallow_scroll_pane",
      tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
    }
    vars_scroll.style.top_margin = 4
    vars_scroll.style.bottom_margin = 4
    vars_scroll.style.maximal_height = 120
    vars_scroll.style.horizontally_stretchable = true
    
    for i, var in ipairs(variables) do
      local var_frame = vars_scroll.add{
        type = "frame",
        direction = "horizontal",
        style = "subheader_frame",
        name = "variable-frame-" .. i,
        tags = {uid = uid, test_index = test_index}
      }
      var_frame.style.horizontally_stretchable = true
      var_frame.style.padding = 4
      
      -- Variable name input
      local name_input = var_frame.add{
        type = "textfield",
        text = var.name or "",
        name = "var-name-" .. i,
        tooltip = "Variable name",
        tags = {uid = uid, test_index = test_index, var_row = i, var_name_input = true}
      }
      name_input.style.width = 150
      name_input.style.right_margin = 8
      add_to_map(name_input)
      
      -- Equals label
      local equals_label = var_frame.add{
        type = "label",
        caption = "=",
        style = "label"
      }
      equals_label.style.right_margin = 8
      
      -- Variable value input
      local value_input = var_frame.add{
        type = "textfield",
        text = tostring(var.value or 0),
        numeric = true,
        allow_negative = true,
        name = "var-value-" .. i,
        tooltip = "Variable value",
        tags = {uid = uid, test_index = test_index, var_row = i, var_value_input = true}
      }
      value_input.style.width = 100
      add_to_map(value_input)
      
      local spacer = var_frame.add{
        type = "empty-widget"
      }
      spacer.style.horizontally_stretchable = true
      
      -- Delete button
      local delete_btn = var_frame.add{
        type = "sprite-button",
        name = "var-delete-" .. i,
        sprite = "utility/trash",
        tooltip = "Delete variable",
        style = "tool_button_red",
        tags = {uid = uid, test_index = test_index, var_row = i, delete_variable = true}
      }
      delete_btn.style.top_margin = 2
      delete_btn.style.right_margin = 1
      add_to_map(delete_btn)
    end
  else
    local empty_label = advanced_content.add{
      type = "label",
      caption = "No variables defined. Click + to add one.",
      style = "label",
      name = "empty-variables-label"
    }
    empty_label.style.font_color = {0.5, 0.5, 0.5}
    empty_label.style.top_margin = 4
    empty_label.style.bottom_margin = 4
  end
  
  -- Create a table for Game Tick, Expected Print, and Actual Print
  local print_table = advanced_content.add{
    type = "table",
    column_count = 3,
    name = "print-table",
    tags = {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index},
  }
  print_table.style.top_margin = 8
  print_table.style.horizontal_spacing = 4
  print_table.style.vertical_spacing = 2
  
  -- Row 1: Labels
  local tick_label = print_table.add{
    type = "label",
    caption = "Game Tick [img=info]",
    style = "label",
    tooltip = "The game tick at which the test case should be evaluated."
  }
  tick_label.style.width = 120
  
  local expected_label = print_table.add{
    type = "label",
    caption = "Expected Print [img=info]",
    style = "label",
    tooltip = "Text that is expected to be contained in the print output of the combinator.\nAlways passes when empty."
  }
  expected_label.style.width = 200
  
  local actual_label = print_table.add{
    type = "label",
    caption = "Actual Print [img=info]",
    style = "label",
    tooltip = "The actual print output the combinator would produce for this test case."
  }
  actual_label.style.width = 200
  
  -- Row 2: Inputs/Values
  local tick_input = print_table.add{
    type = "textfield",
    text = tostring(test_case.game_tick or 0),
    numeric = true,
    allow_negative = false,
    name = "tick-input",
    tags = {uid = uid, test_index = test_index, test_tick_input = true}
  }
  tick_input.style.width = 120
  add_to_map(tick_input)
  
  local print_input = print_table.add{
    type = "textfield",
    text = test_case.expected_print or "",
    name = "print-input",
    tags = {uid = uid, test_index = test_index, test_print_input = true}
  }
  print_input.style.width = 200
  add_to_map(print_input)
  
  local actual_print_label = print_table.add{
    type = "label",
    caption = test_case.actual_print or "(none)",
    name = "actual-print-label",
    tags = {uid = uid, test_index = test_index}
  }
  actual_print_label.style.width = 200
  actual_print_label.style.single_line = false
  add_to_map(actual_print_label)
end

function component.update(uid, test_index)
  local gui_t = storage.guis[uid]
  if not gui_t or not gui_t.test_case_advanced_content then
    return
  end

  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end

  local test_case = mlc.test_cases[test_index]
  local advanced_content = gui_t.test_case_advanced_content
  
  if advanced_content and advanced_content.valid then
    -- Try to find and update only the actual print label to avoid focus loss
    local actual_print_element = nil
    for _, element in pairs(gui_t.el_map) do
      if element.valid and element.name == "actual-print-label" and element.tags and element.tags.test_index == test_index then
        actual_print_element = element
        break
      end
    end
    
    if actual_print_element then
      -- Only update the actual print output, preserving all other UI state
      actual_print_element.caption = test_case.actual_print or "(none)"
    else
      -- Fallback to full rebuild only if we can't find the element
      -- This preserves the old behavior as a safety net
      component.update_content(advanced_content, uid, test_index)
    end
  end
end

function component.rebuild(uid, test_index)
  local gui_t = storage.guis[uid]
  if not gui_t or not gui_t.test_case_advanced_content then
    return
  end
  
  local advanced_content = gui_t.test_case_advanced_content
  if advanced_content and advanced_content.valid then
    component.update_content(advanced_content, uid, test_index)
  end
end

local function toggle_advanced_section(uid, test_index, show_advanced)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  test_case.show_advanced = show_advanced
  
  if gui_t and gui_t.test_case_advanced_content and gui_t.test_case_advanced_content.valid then
    gui_t.test_case_advanced_content.visible = show_advanced
  end
end

local function add_variable(uid, test_index)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  if not test_case.variables then
    test_case.variables = {}
  end
  
  local new_var_index = #test_case.variables + 1
  table.insert(test_case.variables, {
    name = "var" .. new_var_index,
    value = 0
  })
  component.rebuild(uid, test_index)
  
  -- Trigger test case re-evaluation
  event_handler.raise_event(constants.events.on_test_case_updated, {
    uid = uid,
    test_index = test_index
  })
end

local function delete_variable(uid, test_index, var_index)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  if test_case.variables and test_case.variables[var_index] then
    table.remove(test_case.variables, var_index)
    component.rebuild(uid, test_index)
    
    -- Trigger test case re-evaluation
    event_handler.raise_event(constants.events.on_test_case_updated, {
      uid = uid,
      test_index = test_index
    })
  end
end

local function update_variable_name(uid, test_index, var_index, name)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  if not test_case.variables or not test_case.variables[var_index] then
    return
  end
  
  test_case.variables[var_index].name = name
  
  -- Trigger test case re-evaluation
  event_handler.raise_event(constants.events.on_test_case_updated, {
    uid = uid,
    test_index = test_index
  })
end

local function update_variable_value(uid, test_index, var_index, value)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  if not test_case.variables or not test_case.variables[var_index] then
    return
  end
  
  test_case.variables[var_index].value = tonumber(value) or 0
  
  -- Trigger test case re-evaluation
  event_handler.raise_event(constants.events.on_test_case_updated, {
    uid = uid,
    test_index = test_index
  })
end

local function update_game_tick(uid, test_index, tick)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  test_case.game_tick = tonumber(tick) or 0
  
  -- Trigger test case re-evaluation
  event_handler.raise_event(constants.events.on_test_case_updated, {
    uid = uid,
    test_index = test_index
  })
end

local function update_expected_print(uid, test_index, expected_print)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  test_case.expected_print = expected_print
  
  -- Trigger test case re-evaluation
  event_handler.raise_event(constants.events.on_test_case_updated, {
    uid = uid,
    test_index = test_index
  })
end

-- Event handlers
local function on_gui_click(event)
  if not event.element or not event.element.valid or not event.element.tags then return end
  
  local tags = event.element.tags
  
  if tags.advanced_toggle ~= nil then
    toggle_advanced_section(tags.uid, tags.test_index, event.element.state)
  elseif tags.add_variable then
    add_variable(tags.uid, tags.test_index)
  elseif tags.delete_variable then
    delete_variable(tags.uid, tags.test_index, tags.var_row)
  end
end

local function on_gui_text_changed(event)
  if not event.element or not event.element.valid or not event.element.tags then return end
  
  local tags = event.element.tags
  
  if tags.var_name_input then
    update_variable_name(tags.uid, tags.test_index, tags.var_row, event.element.text)
  elseif tags.var_value_input then
    update_variable_value(tags.uid, tags.test_index, tags.var_row, event.element.text)
  elseif tags.test_tick_input then
    update_game_tick(tags.uid, tags.test_index, event.element.text)
  elseif tags.test_print_input then
    update_expected_print(tags.uid, tags.test_index, event.element.text)
  end
end

local function on_test_case_evaluated(event)
  component.update(event.uid, event.test_index)
end

-- Register event handlers
event_handler.add_handler(defines.events.on_gui_click, on_gui_click)
event_handler.add_handler(defines.events.on_gui_text_changed, on_gui_text_changed)
event_handler.add_handler(constants.events.on_test_case_evaluated, on_test_case_evaluated)

return component
