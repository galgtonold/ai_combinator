local event_handler = require("src/events/event_handler")
local bridge = require("src/services/bridge")
local utils = require("src/core/utils")
local constants = require("src/core/constants")
local ai_operation_manager = require('src/core/ai_operation_manager')

local memory = require('src/ai_combinator/memory')
local update = require('src/ai_combinator/update')
local code_manager = require('src/ai_combinator/code_manager')
local init = require('src/ai_combinator/init')

local dialog_manager = require('src/gui/dialogs/dialog_manager')
local variable_row = require('src/gui/components/variable_row')

local vars_dialog = require('src/gui/dialogs/vars_dialog')
local set_task_dialog = require('src/gui/dialogs/set_task_dialog')
local set_description_dialog = require('src/gui/dialogs/set_description_dialog')
local edit_code_dialog = require('src/gui/dialogs/edit_code_dialog')
local ai_combinator_dialog = require('src/gui/dialogs/ai_combinator_dialog')
local help_dialog = require('src/gui/dialogs/help_dialog')


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


function guis.save_code(uid, code, source_type)
	local gui_t, mlc = storage.guis[uid], storage.combinators[uid]
	if not mlc then return end
	local action = code_manager.load_code(code, uid, source_type)
	if action == "remove" then
		return init.mlc_remove(uid)
	elseif action == "init" then
		init.mlc_init(mlc.e)
	end
  
  ai_operation_manager.complete_operation(uid)
end

function guis.navigate_code_history(uid, direction)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.code_history or #mlc.code_history == 0 then
    return false
  end
  
  local current_index = mlc.code_history_index or #mlc.code_history
  local new_index
  
  if direction == "previous" then
    new_index = math.max(1, current_index - 1)
  elseif direction == "next" then
    new_index = math.min(#mlc.code_history, current_index + 1)
  else
    return false
  end
  
  if new_index == current_index then
    return false -- No change possible
  end
  
  mlc.code_history_index = new_index
  
  -- Load the selected version
  local historical_entry = mlc.code_history[new_index]
  if historical_entry then
    mlc.code = historical_entry.code
    local mlc_env = memory.combinators[uid]
    if mlc_env then
      update.mlc_update_code(mlc, mlc_env, memory.combinator_env[mlc_env._uid])
    end
    return true
  end
  
  return false
end

function guis.get_code_history_info(uid)
  local mlc = storage.combinators[uid]
  if not mlc then
    return nil
  end
  
  if not mlc.code_history then
    mlc.code_history = {}
  end
  
  local total_versions = #mlc.code_history
  local current_index = mlc.code_history_index or total_versions
  
  -- Ensure index is valid
  if current_index < 1 then current_index = total_versions end
  if current_index > total_versions then current_index = total_versions end
  
  local current_entry = nil
  if current_index >= 1 and current_index <= total_versions then
    current_entry = mlc.code_history[current_index]
  end
  
  return {
    current_index = current_index,
    total_versions = total_versions,
    can_go_back = current_index > 1,
    can_go_forward = current_index < total_versions,
    current_entry = current_entry,
    is_latest = current_index == total_versions
  }
end

function guis.set_task(uid, task)
  local mlc = storage.combinators[uid]
	local gui_t = storage.guis[uid]
  mlc.task = task
  gui_t.mlc_task_label.caption = task
  
  -- Note: AI operation is started by the caller when sending the request
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

local function update_all_test_cases(uid)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases then return end
  for i, _ in ipairs(mlc.test_cases) do
    event_handler.raise_event(constants.events.on_test_case_updated, {
      uid = uid,
      test_index = i,
    })
  end
end


event_handler.add_handler(constants.events.on_code_updated, function(event)
  guis.save_code(event.uid, event.code, event.source_type)

  update_all_test_cases(event.uid)
end)

event_handler.add_handler(constants.events.on_task_request_completed, function(event) 
  -- Regular task completion - update test cases
  update_all_test_cases(event.uid)
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
    
    -- Start AI operation and get correlation ID
    local success, correlation_id = ai_operation_manager.start_operation(uid, ai_operation_manager.OPERATION_TYPES.TASK_EVALUATION)
    if success then
      bridge.send_task_request(uid, task_input.text)
    end
    
    dialog_manager.close_dialog(event.player_index)
    return true
  elseif event.element.tags.set_description_button then
    local description_input = gui.description_textbox
    guis.set_description(uid, description_input.text)
    dialog_manager.close_dialog(event.player_index)
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
  end

	local uid, gui_t = find_gui(event)
	if not uid then return end

	local mlc = storage.combinators[uid]
	if not mlc then return guis.close(uid) end
	local el_id = element.name
	local rmb = defines.mouse_button_type.right

  if el_id == 'mlc-set-task' then 
    set_task_dialog.show(event.player_index, uid)
  elseif el_id == 'mlc-cancel-ai' then
    ai_operation_manager.cancel_operation(uid)
  elseif el_id == 'mlc-desc-btn-flow' then set_description_dialog.show(event.player_index, uid)
  elseif el_id == 'mlc-edit-code' then edit_code_dialog.show(event.player_index, uid)
	elseif el_id == 'mlc-save' then guis.save_code(uid)
	elseif el_id == 'mlc-commit' then guis.save_code(uid); guis.close(uid)
	elseif el_id == 'mlc-close' then guis.close(uid)
	elseif el_id == 'mlc-vars' then
		if event.button == rmb then
			if event.shift then code_manager.clear_outputs(uid)
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
	guis.close(uid)
end

function guis.vars_window_toggle(pn, toggle_on)
	local gui = game.players[pn].gui.screen['mlc-gui']
	local uid, gui_t = find_gui{element=g}
	if not uid then uid = storage.guis_player['vars.'..pn] end
	if not uid then return end
	vars_dialog.show(pn, uid, nil, toggle_on)
end


event_handler.add_handler(defines.events.on_gui_click, guis.on_gui_click)
event_handler.add_handler(defines.events.on_gui_closed, guis.on_gui_close)

return guis
