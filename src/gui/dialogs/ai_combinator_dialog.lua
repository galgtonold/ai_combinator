local event_handler = require('src/events/event_handler')
local config = require('src/core/config')
local constants = require('src/core/constants')
local ai_operation_manager = require('src/core/ai_operation_manager')

local signal_table = require('src/gui/components/signal_table')
local titlebar = require('src/gui/components/titlebar')
local ai_combinator_header = require('src/gui/components/ai_combinator_header')
local test_cases_section = require('src/gui/components/test_cases_section')
local status_indicator = require('src/gui/components/status_indicator')
local help_dialog = require('src/gui/dialogs/help_dialog')

local dialog = {}

local NO_TASK_SET_DESCRIPTION = 'No task set. Click to set a task.'


local function draw_signals(button_frame, signals, red_signals, green_signals)
  button_frame.clear()

  local row_count = 0
  row_count = row_count + signal_table.show(button_frame, signals, "slot")
  row_count = row_count + signal_table.show(button_frame, red_signals, "red_slot")
  row_count = row_count + signal_table.show(button_frame, green_signals, "green_slot")

  if row_count == 0 then
    row_count = 1
  end
  
  button_frame.style.height = 40 * row_count
  button_frame.style.vertically_stretchable = false
end

local function update_signals(uid)
  local gui_t = storage.guis[uid]
	local mlc = storage.combinators[uid]

  if not gui_t or gui_t.input_signal_frame == nil then
    return
  end

  red_network = mlc.e.get_or_create_control_behavior().get_circuit_network(defines.wire_connector_id.combinator_input_red)
  green_network = mlc.e.get_or_create_control_behavior().get_circuit_network(defines.wire_connector_id.combinator_input_green)
  draw_signals(
    gui_t.input_signal_frame,
    {},
    red_network and red_network.signals or {},
    green_network and green_network.signals or {}
  )

  local signals = {}
  for _, sig in pairs(mlc.out_red.get_control_behavior().sections[1].filters or {}) do
    local new_sig = {signal=sig.value, count=sig.min}
    new_sig.signal.comparator = nil
    if new_sig.count ~= 0 then
      table.insert(signals, new_sig)
    end
  end

  draw_signals(
    gui_t.output_signal_frame,
    signals,
    {},
    {}
  )
end

local function update_ai_buttons(uid)
  local gui_t = storage.guis[uid]
  
  if not gui_t then
    return
  end
  
  -- Check if any AI operation is in progress
  local ai_operation_in_progress = ai_operation_manager.is_operation_active(uid)
  
  -- Update Set Task button if it exists
  if gui_t.mlc_set_task then
    gui_t.mlc_set_task.enabled = not ai_operation_in_progress
  end
  
  -- Update Cancel AI button if it exists
  if gui_t.mlc_cancel_ai then
    gui_t.mlc_cancel_ai.enabled = ai_operation_in_progress
  end
end

local function update_status(uid)
  local gui_t = storage.guis[uid]
  local mlc = storage.combinators[uid]
  local status_flow = gui_t.mlc_status_flow
  if not status_flow then
    return
  end
  
  -- Get entity status code
  local status_code = mlc.e.status
  local status_text = "Unknown"
  local sprite = "utility/status_working"
  
  -- Only check statuses relevant to combinators
  if status_code == defines.entity_status.working or 
      status_code == defines.entity_status.normal then
    status_text = "Working"
    sprite = "utility/status_working"
  elseif status_code == defines.entity_status.no_power then
    status_text = "No power"
    sprite = "utility/status_not_working"
  elseif status_code == defines.entity_status.low_power then
    status_text = "Low power"
    sprite = "utility/status_yellow"
  elseif status_code == defines.entity_status.disabled then
    status_text = "Disabled"
    sprite = "utility/status_disabled"
  elseif status_code == defines.entity_status.disabled_by_control_behavior then
    status_text = "Disabled by circuit network"
    sprite = "utility/status_disabled"
  elseif status_code == defines.entity_status.disabled_by_script then
    status_text = "Disabled by script"
    sprite = "utility/status_disabled"
  elseif status_code == defines.entity_status.marked_for_deconstruction then
    status_text = "Marked for deconstruction"
    sprite = "utility/status_yellow"
  end
  
  -- Check for AI operations using the new manager
  local operation_status = ai_operation_manager.get_operation_status_text(uid)
  if operation_status then
    status_text = operation_status
    sprite = "utility/status_yellow"
  end

  if mlc.state == "error" then
    status_text = "Error: " .. (mlc.err_parse or mlc.errun or "unknown error")
    sprite = "utility/status_not_working"
  end

  -- Update status using the status_indicator component
  status_indicator.update(status_flow, sprite, status_text)

  -- Update task request progress_bar using the new manager
  local progress_bar = gui_t.mlc_progressbar
  local ai_operation_in_progress = ai_operation_manager.is_operation_active(uid)
  
  if ai_operation_in_progress then
    local operation_progress = ai_operation_manager.get_operation_progress(uid)
    local operation_text = ai_operation_manager.get_operation_progress_text(uid) or "Processing..."
    progress_bar.value = operation_progress
    progress_bar.caption = operation_text
  else
    progress_bar.value = 0
    progress_bar.caption = ""
  end
  
  -- Update AI operation buttons
  update_ai_buttons(uid)
end

function dialog.show(player, entity)
  local uid = entity.unit_number
	local mlc = storage.combinators[uid]
	local mlc_err = mlc.err_parse or mlc.errun
	local dw, dh, dsf = player.display_resolution.width,
		player.display_resolution.height, 1 / player.display_scale
	local max_height = (dh - 350) * dsf

	-- Main frame
	local el_map = {} -- map is to check if el belonds to this gui
  local el = nil
	local gui_t = {uid=uid, el_map=el_map}
	storage.guis[entity.unit_number] = gui_t


	local function elc(parent, props, style_tweaks)
		el = parent.add(props)
		for k,v in pairs(style_tweaks or {}) do el.style[k] = v end
    if props.name then
      gui_t[props.name:gsub('%-', '_')], el_map[el.index] = el, el
    end
		return el
	end

	local gui = elc( player.gui.screen,
		{ type='frame', name='mlc-gui', direction='vertical'})
	gui.location = {20 * dsf, 150 * dsf} -- doesn't work from initial props

  local extra_buttons = {{
      type = "sprite-button",
      style = "frame_action_button",
      sprite = "mlc-help",
      tooltip = "Show help",
      tags = {show_ai_combinator_help_button = true}
    }
  }
  titlebar.show(gui, "AI combinator", {uid = uid, close_combinator_ui = true}, nil, extra_buttons)

  local entity_frame = elc(gui, {type='frame', name='mlc-entity-frame', style='entity_frame', direction='vertical'})

  local connections_frame = elc(entity_frame,
    { type = 'frame', name = 'mlc-connections-frame', style = 'subheader_frame_with_text_on_the_right', direction ='horizontal' },
    { top_margin = -8, left_margin = -12, right_margin = -12, horizontally_stretchable = true, horizontally_squashable = true })

  elc(connections_frame, {type='flow', name='mlc-connections-flow', direction='horizontal', style = "player_input_horizontal_flow"})

  -- Status light and text
  local status_flow = status_indicator.show(entity_frame, "utility/status_working", "Working")
  gui_t.mlc_status_flow = status_flow
  
  -- Entity preview
  local entity_frame_border = elc(entity_frame, {type='frame', name='mlc-entity-frame-border', style='deep_frame_in_shallow_frame'})

  local entity_preview = elc(entity_frame_border, {type='entity-preview', name='mlc-entity-preview'})
  entity_preview.entity = entity
  entity_preview.style.natural_height = 152
  entity_preview.style.horizontally_stretchable = true
  
  
  -- Progress bar with cancel button
  local progress_flow = elc(entity_frame, {type='flow', name='mlc-progress-flow', direction='horizontal'}, {horizontally_stretchable=true, height=30})
  local progress_bar = elc(progress_flow, {type='progressbar', name='mlc-progressbar', value=0, style='production_progressbar', caption=''}, {horizontally_stretchable=true})
  progress_bar.style.horizontal_align = "center"
  elc(progress_flow, {type='button', name='mlc-cancel-ai', caption='Cancel', style='red_button', tooltip='Cancel the current AI operation'}, {width=80, left_margin=4, height=25})
  
  elc(entity_frame, {type='label', name='mlc-task-title-label', caption='Task', style="semibold_label"})

  local task_label = elc(entity_frame, {type='label', name='mlc-task-label'}, {horizontally_squashable=true, single_line=false})
  task_label.caption = mlc.task or NO_TASK_SET_DESCRIPTION
  task_label.style.maximal_width = 828

  elc(entity_frame, {type="button", style="green_button", name='mlc-set-task', caption='Set Task'}, {horizontally_stretchable=true})

  elc(entity_frame, {type="button", style="button", name='mlc-edit-code', caption='Edit Source Code'}, {horizontally_stretchable=true})

  elc(entity_frame, {type='line', direction='horizontal'}, {horizontally_stretchable=true})

  -- input and output signals
  local input_output_flow = elc(entity_frame, {type='flow', name='mlc-input-output-flow', direction='horizontal', style="inset_frame_container_horizontal_flow"})
  local input_flow = elc(input_output_flow, {type='flow', name='mlc-input-flow', direction='vertical'})
  local output_flow = elc(input_output_flow, {type='flow', name='mlc-output-flow', direction='vertical'})

  elc(input_flow, {type='label', name='mlc-input-label', caption='Input Signals', style="semibold_label"})
  elc(output_flow, {type='label', name='mlc-output-label', caption='Output Signals', style="semibold_label"})

  elc(input_flow, {type="frame", direction="vertical", style="ugg_deep_frame", name='input-signal-frame'})
  elc(output_flow, {type="frame", direction="vertical", style="ugg_deep_frame", name='output-signal-frame'})

  update_signals(uid)

  elc(entity_frame, {type='line', direction='horizontal'}, {horizontally_stretchable=true})

  -- Test cases section
  test_cases_section.show(entity_frame, uid)

  -- Horizontal line and description section

  elc(entity_frame, {type='line', direction='horizontal'}, {horizontally_stretchable=true})

  local desc_container = elc(entity_frame, {type='flow', name='mlc-description-container', direction='vertical'})
  gui_t.mlc_description_container = desc_container

  -- Initialize AI button states
  update_ai_buttons(uid)

	return gui_t
end



function dialog.update()
  if not (next(storage.guis) and game.tick % config.gui_signals_update_interval == 0) then
    return
  end

  -- Update header
  for uid, gui_t in pairs(storage.guis) do
    update_signals(uid)
    update_status(uid)
    ai_combinator_header.update(uid)
  end

end

-- Event handlers for AI operation state changes
local function on_ai_operation_state_changed(event)
  update_ai_buttons(event.uid)
end

event_handler.add_handler(defines.events.on_tick, dialog.update)
event_handler.add_handler(constants.events.on_ai_operation_state_changed, on_ai_operation_state_changed)


return dialog