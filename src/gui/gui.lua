local event_handler = require("src/events/event_handler")
local bridge = require("src/services/bridge")
local utils = require("src/core/utils")
local constants = require("src/core/constants")

local dialog_manager = require('src/gui/dialogs/dialog_manager')
local variable_row = require('src/gui/components/variable_row')

local vars_dialog = require('src/gui/dialogs/vars_dialog')
local set_task_dialog = require('src/gui/dialogs/set_task_dialog')
local set_description_dialog = require('src/gui/dialogs/set_description_dialog')
local edit_code_dialog = require('src/gui/dialogs/edit_code_dialog')
local test_case_dialog = require('src/gui/dialogs/test_case_dialog')
local ai_combinator_dialog = require('src/gui/dialogs/ai_combinator_dialog')


local testing = require('src/testing/testing')

local guis = {}

local function vars_window_uid(gui)
	if not gui then return end
	while gui.name ~= 'mlc-vars' do gui = gui.parent end
	return tonumber(gui.caption:match('%[(%d+)%]'))
end




-- ----- Interface for control.lua -----

local function find_gui(ev)
	-- Finds uid and gui table for specified event-target element
	if ev.entity and ev.entity.valid then
		local uid = ev.entity.unit_number
		local gui_t = storage.guis[uid]
		if gui_t then return uid, gui_t end
	end
	local el, el_chk = ev.element
	if not el then return end
	for uid, gui_t in pairs(storage.guis) do
		el_chk = gui_t.el_map[el.index]
		if el_chk and el_chk == el then return uid, gui_t end
	end
end

function guis.open(player, e)
	local uid_old = storage.guis_player[player.index]
	if uid_old then player.opened = guis.close(uid_old) end
	local gui_t = ai_combinator_dialog.show(player, e)
	player.opened = gui_t.mlc_gui
	storage.guis_player[player.index] = e.unit_number
	
	-- Initialize the description UI now that gui_t is stored
	guis.update_description_ui(e.unit_number)
	
	return gui_t
end

function guis.close(uid)
	local gui_t = storage.guis[uid]
	local gui = gui_t and (gui_t.mlc_gui or gui_t.gui)
	if gui then gui.destroy() end
	storage.guis[uid] = nil
end


function guis.save_code(uid, code)
	local gui_t, mlc = storage.guis[uid], storage.combinators[uid]
	if not mlc then return end
	load_code_from_gui(code, uid)
  mlc.task_request_time = nil -- reset task request time on code change
end

function guis.on_gui_text_changed(ev)
	if ev.element.name ~= 'mlc-code' then
    
    -- Handle advanced section text inputs
    if ev.element.tags then
      if ev.element.tags.test_tick_input then
        guis.handle_tick_input_change(ev)
      elseif ev.element.tags.test_print_input then
        guis.handle_print_input_change(ev)
      elseif ev.element.tags.var_name_input or ev.element.tags.var_value_input then
        guis.handle_variable_input_change(ev)
      end
    end
    
    return
  end
end

function guis.set_task(uid, task)
  local mlc = storage.combinators[uid]
	local gui_t = storage.guis[uid]
  mlc.task = task
  mlc.task_request_time = game.tick
  gui_t.mlc_task_label.caption = task
end

event_handler.add_handler(constants.events.on_description_updated, function(event)
  local uid = event.uid
  local description = event.description
  guis.set_description(uid, description)
end)

function guis.set_description(uid, description)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  mlc.description = description
  -- Update the UI to reflect the new description
  guis.update_description_ui(uid)
end


function guis.create_test_signal_display_panel(parent, signals)
  -- Create read-only display of actual output signals
  local signal_table = parent.add{
    type = "table",
    column_count = 10,
    style = "filter_slot_table",
    name = "actual-signal-table"
  }
  signal_table.style.height = 160
  
  -- Convert signals to array for display
  local signal_array = {}
  for signal_name, count in pairs(signals) do
    if count ~= 0 then
      table.insert(signal_array, {signal_name = signal_name, count = count})
    end
  end
  
  -- Fill up to 40 slots (10x4)
  for i = 1, 40 do
    local signal_data = signal_array[i]
    local slot_flow = signal_table.add{
      type = "flow",
      direction = "vertical",
      name = "actual-slot-" .. i
    }
    slot_flow.style.width = 40
    slot_flow.style.height = 40
    
    if signal_data then
      -- Try to parse the signal name back to a signal object
      local signal_obj = nil
      if storage.signals and storage.signals[signal_data.signal_name] then
        signal_obj = storage.signals[signal_data.signal_name]
      end
      
      local signal_button = slot_flow.add{
        type = "choose-elem-button",
        elem_type = "signal",
        signal = signal_obj,
        locked = true,
        name = "actual-signal-" .. i
      }
      signal_button.style.width = 40
      signal_button.style.height = 40
      
      -- Count label overlay
      local count_label = slot_flow.add{
        type = "label",
        caption = utils.format_number(signal_data.count),
        style = "count_label",
        ignored_by_interaction = true
      }
      count_label.style.top_margin = -40
      count_label.style.horizontal_align = "right"
      count_label.style.maximal_width = 38
    else
      -- Empty slot
      local empty_button = slot_flow.add{
        type = "choose-elem-button",
        elem_type = "signal",
        locked = true,
        name = "empty-actual-" .. i
      }
      empty_button.style.width = 40
      empty_button.style.height = 40
    end
  end
end

function guis.update_test_status_in_dialog(uid, test_index)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] or not gui_t or not gui_t.test_status_sprite then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  local actual_output = test_case.actual_output or {}
  local expected_output = test_case.expected_output or {}

  local signals_match = testing.test_case_matches(expected_output, actual_output)

  -- Check print output if expected
  local print_matches = true
  if test_case.expected_print and test_case.expected_print ~= "" then
    local actual_print = test_case.actual_print or ""
    print_matches = actual_print:find(test_case.expected_print, 1, true) ~= nil
  end
  
  local overall_match = signals_match and print_matches
  
  if (not expected_output or next(expected_output) == nil) and (not test_case.expected_print or test_case.expected_print == "") then
    gui_t.test_status_sprite.sprite = "utility/status_yellow"
    gui_t.test_status_label.caption = "No expected output defined"
    gui_t.test_status_label.style.font_color = {0.8, 0.8, 0.3}
  elseif overall_match then
    gui_t.test_status_sprite.sprite = "utility/status_working"
    gui_t.test_status_label.caption = "Test passing"
    gui_t.test_status_label.style.font_color = {0.3, 0.8, 0.3}
  else
    gui_t.test_status_sprite.sprite = "utility/status_not_working"
    local reasons = {}
    if not signals_match then table.insert(reasons, "signals") end
    if not print_matches then table.insert(reasons, "print") end
    gui_t.test_status_label.caption = "Test failing (" .. table.concat(reasons, ", ") .. ")"
    gui_t.test_status_label.style.font_color = {0.8, 0.3, 0.3}
  end
end

function guis.save_test_case_from_dialog(uid, test_index, player_index)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] or not gui_t.test_case_dialog then
    return
  end
  
  local test_case = mlc.test_cases[test_index]

  if not gui_t.test_case_name_input.valid then
    return
  end

  -- Save the test case name
  if gui_t.test_case_name_input then
    test_case.name = gui_t.test_case_name_input.text
  end
  
end

function guis.handle_test_count_change(event)
  local element = event.element
  if not element.tags then return end
  
  local uid = element.tags.uid
  local test_index = element.tags.test_index
  local signal_type = element.tags.signal_type
  local signal_index = element.tags.signal_index
  
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  local test_case = mlc.test_cases[test_index]
  
  -- Determine which signal array to update
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
  
  -- Ensure the array is large enough
  while #signal_array < signal_index do
    table.insert(signal_array, {})
  end
  
  if not signal_array[signal_index] then
    signal_array[signal_index] = {}
  end
  
  -- Update the count
  local count = tonumber(element.text) or 0
  signal_array[signal_index].count = count
  
  -- Clean up empty entries
  for i = #signal_array, 1, -1 do
    local entry = signal_array[i]
    if not entry.signal or not entry.count or entry.count == 0 then
      table.remove(signal_array, i)
    end
  end
  
  -- Auto-run the test
  guis.run_test_case(mlc, test_index)
end

-- Toggle advanced section visibility
function guis.toggle_advanced_section(uid, test_index, state)
  local gui_t = storage.guis[uid]
  if not gui_t or not gui_t.test_case_dialog or not gui_t.test_case_dialog.valid then return end
  
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  mlc.test_cases[test_index].show_advanced = state
  
  -- Find the advanced-content element by searching through the dialog
  local function find_element_by_name(parent, name)
    if parent.name == name then return parent end
    for _, child in pairs(parent.children) do
      local found = find_element_by_name(child, name)
      if found then return found end
    end
    return nil
  end
  
  local advanced_content = find_element_by_name(gui_t.test_case_dialog, "advanced-content")
  if advanced_content then
    advanced_content.visible = state
  end
end

-- Add a new variable row
function guis.add_variable_row(uid, test_index)
  local gui_t = storage.guis[uid]
  if not gui_t or not gui_t.test_case_dialog or not gui_t.test_case_dialog.valid then return end
  
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  local test_case = mlc.test_cases[test_index]
  if not test_case.variables then test_case.variables = {} end
  
  table.insert(test_case.variables, {name = "", value = 0})
  
  -- Refresh variables table
  local function find_element_by_name(parent, name)
    if parent.name == name then return parent end
    for _, child in pairs(parent.children) do
      local found = find_element_by_name(child, name)
      if found then return found end
    end
    return nil
  end
  
  local vars_table = find_element_by_name(gui_t.test_case_dialog, "variables-table")
  if vars_table then
    vars_table.clear()
    for i, var in ipairs(test_case.variables) do
      variable_row.show(vars_table, uid, test_index, i, var.name or "", var.value or 0)
    end
  end
end

-- Delete a variable row
function guis.delete_variable_row(uid, test_index, row_index)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  local test_case = mlc.test_cases[test_index]
  if not test_case.variables then return end
  
  table.remove(test_case.variables, row_index)
  
  -- Refresh variables table
  local gui_t = storage.guis[uid]
  if gui_t and gui_t.test_case_dialog and gui_t.test_case_dialog.valid then
    local function find_element_by_name(parent, name)
      if parent.name == name then return parent end
      for _, child in pairs(parent.children) do
        local found = find_element_by_name(child, name)
        if found then return found end
      end
      return nil
    end
    
    local vars_table = find_element_by_name(gui_t.test_case_dialog, "variables-table")
    if vars_table then
      vars_table.clear()
      for i, var in ipairs(test_case.variables) do
        variable_row.show(vars_table, uid, test_index, i, var.name or "", var.value or 0)
      end
      -- Always have at least one empty row
      if #test_case.variables == 0 then
        variable_row.show(vars_table, uid, test_index, 1, "", 0)
      end
    end
  end
end

-- Handle game tick input changes
function guis.handle_tick_input_change(event)
  local uid = event.element.tags.uid
  local test_index = event.element.tags.test_index
  
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  local tick = tonumber(event.element.text) or 0
  mlc.test_cases[test_index].game_tick = tick
  
end

-- Handle expected print input changes  
function guis.handle_print_input_change(event)
  local uid = event.element.tags.uid
  local test_index = event.element.tags.test_index
  
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  mlc.test_cases[test_index].expected_print = event.element.text
  
end

-- Handle variable input changes
function guis.handle_variable_input_change(event)
  local uid = event.element.tags.uid
  local test_index = event.element.tags.test_index
  local row_index = event.element.tags.var_row
  
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  local test_case = mlc.test_cases[test_index]
  if not test_case.variables then test_case.variables = {} end
  
  -- Ensure we have enough rows
  while #test_case.variables < row_index do
    table.insert(test_case.variables, {name = "", value = 0})
  end
  
  if not test_case.variables[row_index] then
    test_case.variables[row_index] = {name = "", value = 0}
  end
  
  if event.element.tags.var_name_input then
    test_case.variables[row_index].name = event.element.text
  elseif event.element.tags.var_value_input then
    test_case.variables[row_index].value = tonumber(event.element.text) or 0
  end
  
  -- Check if we need to add a new row (if last row was just filled)
  local last_var = test_case.variables[#test_case.variables]
  if last_var and last_var.name ~= "" and #test_case.variables == row_index then
    guis.add_variable_row(uid, test_index)
  end
  
  -- Update delete button visibility
  local gui_t = storage.guis[uid]
  if gui_t and gui_t.test_case_dialog and gui_t.test_case_dialog.valid then
    local function find_element_by_name(parent, name)
      if parent.name == name then return parent end
      for _, child in pairs(parent.children) do
        local found = find_element_by_name(child, name)
        if found then return found end
      end
      return nil
    end
    
    local delete_btn = find_element_by_name(gui_t.test_case_dialog, "var-delete-" .. row_index)
    if delete_btn then
      local var = test_case.variables[row_index]
      delete_btn.visible = var and (var.name ~= "" or var.value ~= 0)
    end
  end
  
end


function guis.run_test_case(uid, test_index)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  local test_case = mlc.test_cases[test_index]
  
  -- Calculate actual output with advanced options
  local result = guis.calculate_test_output_advanced(uid, test_case)
  test_case.actual_output = result.output
  test_case.actual_print = result.print_output
  
end

function guis.calculate_test_output(uid, red_input, green_input)
  -- Call the test execution function from control.lua
  return execute_test_case(uid, red_input, green_input) or {}
end

function guis.calculate_test_output_advanced(uid, test_case)
  -- Call the advanced test execution function from control.lua with all options
  local result = execute_test_case_advanced(uid, {
    red_input = test_case.red_input or {},
    green_input = test_case.green_input or {},
    game_tick = test_case.game_tick or 0,
    variables = test_case.variables or {},
    expected_print = test_case.expected_print or ""
  })
  
  return result or {output = {}, print_output = ""}
end

function guis.create_signal_inputs(parent, signals, uid, test_index, signal_type, gui_t)
  -- Create editable signal input fields
  for i = 1, math.max(3, #signals + 1) do
    local signal_data = signals[i] or {}
    
    local signal_flow = parent.add{type = "flow", direction = "horizontal"}
    signal_flow.style.vertical_align = "center"
    
    -- Signal chooser
    local signal_chooser = signal_flow.add{
      type = "choose-elem-button",
      elem_type = "signal",
      signal = signal_data.signal,
      name = "mlc-test-signal-" .. test_index .. "-" .. signal_type .. "-" .. i,
      tags = {
        uid = uid,
        test_case_signal = true,
        test_index = test_index,
        signal_type = signal_type,
        signal_index = i
      }
    }
    signal_chooser.style.width = 40
    signal_chooser.style.height = 40
    
    -- Add to element map for GUI tracking
    if gui_t and gui_t.el_map then
      gui_t.el_map[signal_chooser.index] = signal_chooser
    end
    
    -- Value input
    local value_input = signal_flow.add{
      type = "textfield",
      name = "mlc-test-value-" .. test_index .. "-" .. signal_type .. "-" .. i,
      text = signal_data.count and tostring(signal_data.count) or "",
      numeric = true,
      allow_negative = true,
      tags = {
        uid = uid,
        test_case_value = true,
        test_index = test_index,
        signal_type = signal_type,
        signal_index = i
      }
    }
    value_input.style.width = 80
    value_input.style.left_margin = 4
    
    -- Add to element map for GUI tracking
    if gui_t and gui_t.el_map then
      gui_t.el_map[value_input.index] = value_input
    end
  end
end

function guis.create_signal_display(parent, signals)
  -- Create read-only signal display
  for signal_name, count in pairs(signals) do
    if count ~= 0 then
      local signal_flow = parent.add{type = "flow", direction = "horizontal"}
      signal_flow.style.vertical_align = "center"
      
      -- Parse the signal name to get the actual signal object
      local signal_obj = nil
      
      -- Try to get the signal from the storage.signals table
      if storage and storage.signals and storage.signals[signal_name] then
        signal_obj = storage.signals[signal_name]
      else
        -- Handle prefixed signals like @signal-name, #item-name, =fluid-name
        local signal_type = "item"  -- default
        local clean_name = signal_name
        
        if signal_name:sub(1,1) == "@" then
          signal_type = "virtual"
          clean_name = signal_name:sub(2)
        elseif signal_name:sub(1,1) == "#" then
          signal_type = "item"
          clean_name = signal_name:sub(2)
        elseif signal_name:sub(1,1) == "=" then
          signal_type = "fluid"
          clean_name = signal_name:sub(2)
        elseif signal_name:sub(1,1) == "~" then
          signal_type = "recipe"
          clean_name = signal_name:sub(2)
        end
        
        signal_obj = {type = signal_type, name = clean_name}
      end
      
      local signal_display = signal_flow.add{
        type = "choose-elem-button",
        elem_type = "signal",
        signal = signal_obj,
        locked = true
      }
      signal_display.style.width = 40
      signal_display.style.height = 40
      
      local count_label = signal_flow.add{
        type = "label",
        caption = utils.format_number(count)
      }
      count_label.style.left_margin = 4
      count_label.style.vertical_align = "center"
    end
  end
end




function guis.update_description_ui(uid)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  if not mlc then
    return
  end
  
  if not gui_t then
    return
  end
  
  if not gui_t.mlc_description_container then
    return
  end
  
  local container = gui_t.mlc_description_container
  container.clear()
  
  -- Helper function to add elements to the el_map
  local function add_to_map(element)
    if element.name then
      gui_t.el_map[element.index] = element
    end
    return element
  end
  
  if mlc.description and mlc.description ~= "" then
    -- Show description with edit button
    local header_flow = container.add{
      type = "flow",
      direction = "horizontal",
      name = "mlc-description-header"
    }
    add_to_map(header_flow)
    
    header_flow.add{
      type = "label",
      caption = "Description",
      style = "semibold_label"
    }
    
    local edit_btn = header_flow.add{
      type = "sprite-button",
      name = "mlc-desc-btn-flow",
      sprite = "utility/rename_icon",
      tooltip = "Edit description",
      style = "mini_button_aligned_to_text_vertically",
      tags = {uid = uid, description_edit = true}
    }
    --edit_btn.style.left_margin = 8

    add_to_map(edit_btn)
    
    local desc_text = container.add{
      type = "label",
      caption = mlc.description,
      style = "label"
    }
    desc_text.style.single_line = false
    desc_text.style.maximal_width = 380
  else
    -- Show "Add Description" button
    local desc_btn = container.add{
      type = "button",
      name = "mlc-desc-btn-flow",
      caption = "Add Description",
      tags = {uid = uid, description_add = true}
    }
    add_to_map(desc_btn)
  end
end


event_handler.add_handler(constants.events.on_code_updated, function(event)
  guis.save_code(event.uid, event.code)

  -- raise test case update for every test case
  local mlc = storage.combinators[event.uid]
  if mlc and mlc.test_cases then
    for i, _ in ipairs(mlc.test_cases) do
      event_handler.raise_event(constants.events.on_test_case_updated, {
        uid = event.uid,
        test_index = i,
      })
    end
  end
end)

function guis.handle_task_dialog_click(event)
  local gui

  if not event.element.valid or not event.element.tags then
    return
  end
  local uid = event.element.tags.uid
  gui = storage.guis[uid]

  if event.element.tags.set_task_button then
    local task_input = gui.task_textbox
    guis.set_task(uid, task_input.text)
    -- Check bridge availability before sending task request
    bridge.check_bridge_availability()
    bridge.send_task_request(uid, task_input.text)
    dialog_manager.close_dialog(event.player_index)
    return true
  elseif event.element.tags.set_description_button then
    local description_input = gui.description_textbox
    guis.set_description(uid, description_input.text)
    dialog_manager.close_dialog(event.player_index)
    return true
  elseif event.element.tags.advanced_toggle then
    guis.toggle_advanced_section(uid, event.element.tags.test_index, event.element.state)
    return true
  elseif event.element.tags.add_variable then
    guis.add_variable_row(uid, event.element.tags.test_index)
    return true
  elseif event.element.tags.delete_variable then
    guis.delete_variable_row(uid, event.element.tags.test_index, event.element.tags.var_row)
    return true
  elseif event.element.tags.task_dialog_close then
    -- Don't do anything as close is default option for other clicks not in dialog
  elseif event.element.tags.description_dialog_close then
    -- Don't do anything as close is default option for other clicks not in dialog
  elseif event.element.tags.edit_code_dialog_close then
    -- Don't do anything as close is default option for other clicks not in dialog
  elseif event.element.tags.test_case_dialog_close then
    -- Don't do anything as close is default option for other clicks not in dialog
  elseif event.element.tags.dialog then
    return true -- Any clicks inside dialog should not close it
  end
end

function guis.on_gui_click(event)
  if guis.handle_task_dialog_click(event) then
    return
  end

  --dialog_manager.close_background_dialogs(event)
  
	local element = event.element

  if not element.valid then return end

	-- Separate "help" and "vars" windows, not tracked in globals (storage), unlike main MLC gui
	if element.name == 'mlc-help-close' then return element.parent.destroy()
	elseif element.name == 'mlc-vars-close' then
		return (element.parent.paent or element.parent).destroy()
	elseif element.name == 'mlc-vars-pause' then
		return vars_dialog.show( event.player_index, vars_window_uid(element), element.style.name ~= 'green_button', true)
	end

  if element.tags and element.tags.close_combinator_ui then
    guis.close(element.tags.uid)
    return
  end

  -- Handle description buttons that have tags with uid
  if element.tags and element.tags.uid then
    if element.tags.description_add or element.tags.description_edit then
      set_description_dialog.show(event.player_index, element.tags.uid)
      return
    end
        
    if element.tags.auto_generate_tests then
      guis.auto_generate_test_cases(element.tags.uid)
      return
    end
    
    if element.tags.edit_test_case then
      test_case_dialog.show(event.player_index, element.tags.uid, element.tags.edit_test_case)
      return
    end
    
    if element.tags.delete_test_case then
      guis.delete_test_case(element.tags.uid, element.tags.delete_test_case)
      return
    end
  end

	local uid, gui_t = find_gui(event)
	if not uid then return end

	local mlc = storage.combinators[uid]
	if not mlc then return guis.close(uid) end
	local el_id = element.name
	local rmb = defines.mouse_button_type.right

	if el_id == 'mlc-code' then
		if not gui_t.code_focused then
			-- Removing rich-text tags also screws with the cursor position, so try to avoid it
			local clean_code = code_error_highlight(gui_t.mlc_code.text)
			if clean_code ~= gui_t.mlc_code.text then gui_t.mlc_code.text = clean_code end
		end
		gui_t.code_focused = true -- disables hotkeys and repeating cleanup above
  elseif el_id == 'mlc-set-task' then 
    set_task_dialog.show(event.player_index, uid)
  elseif el_id == 'mlc-desc-btn-flow' then set_description_dialog.show(event.player_index, uid)
  elseif el_id == 'mlc-edit-code' then edit_code_dialog.show(event.player_index, uid)
	elseif el_id == 'mlc-save' then guis.save_code(uid)
	elseif el_id == 'mlc-commit' then guis.save_code(uid); guis.close(uid)
	elseif el_id == 'mlc-clear' then
		guis.save_code(uid, '')
		guis.on_gui_text_changed{element=gui_t.mlc_code}
	elseif el_id == 'mlc-close' then guis.close(uid)
	elseif el_id == 'mlc-vars' then
		if event.button == rmb then
			if event.shift then clear_outputs_from_gui(uid)
			else -- clear env
				for k, _ in pairs(mlc.vars) do mlc.vars[k] = nil end
				vars_dialog.update(game.players[event.player_index], uid)
			end
		else 
      vars_dialog.show(event.player_index, uid, event.shift, event.shift or nil)
    end
  end
end

function guis.on_gui_close(ev)
  if dialog_manager.handle_dialog_closed(ev.player_index) then
    return
  end
	
	local uid, gui_t = find_gui(ev)
	if not uid then return end
	local p = game.players[ev.player_index]
	if p.valid and gui_t.code_focused then
		gui_t.mlc_gui.focus()
		p.opened, gui_t.code_focused = gui_t.mlc_gui
	else guis.close(uid) end
end

function guis.vars_window_toggle(pn, toggle_on)
	local gui = game.players[pn].gui.screen['mlc-gui']
	local uid, gui_t = find_gui{element=g}
	if not uid then uid = storage.guis_player['vars.'..pn] end
	if not uid then return end
	vars_dialog.show(pn, uid, nil, toggle_on)
end

function guis.on_gui_checked_state_changed(event)
  if not event.element.tags then return end
  
  local uid = event.element.tags.uid
  if not uid then return end
  
  if event.element.tags.advanced_toggle then
    guis.toggle_advanced_section(uid, event.element.tags.test_index, event.element.state)
  end
end

event_handler.add_handler(defines.events.on_gui_click, guis.on_gui_click)
event_handler.add_handler(defines.events.on_gui_closed, guis.on_gui_close)
event_handler.add_handler(defines.events.on_gui_text_changed, guis.on_gui_text_changed)
event_handler.add_handler(defines.events.on_gui_checked_state_changed, guis.on_gui_checked_state_changed)

return guis
