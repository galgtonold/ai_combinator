local conf = require('config')
local cgui = require('cgui')
local event_handler = require("event_handler")
local bridge = require("bridge")

local guis = {}

local function ai_bridge_warning_window_toggle(pn, toggle_on)
	local player = game.players[pn]
	local gui_exists = player.gui.screen['mlc-ai-warning']
	if gui_exists and not toggle_on then return gui_exists.destroy()
	elseif toggle_on == false then return end
	local dw, dh, dsf = player.display_resolution.width,
		player.display_resolution.height, 1 / player.display_scale

	local gui = player.gui.screen.add{ type='frame',
		name='mlc-ai-warning', caption='AI Combinator - Launcher Required', direction='vertical' }
	gui.location = {math.max(50, (dw - 600) * dsf / 2), math.max(50, (dh - 400) * dsf / 2)}
	
	-- Main content area with light gray background (similar to AI combinator)
	local main_flow = gui.add{type='flow', direction='vertical'}
	
	local content_frame = main_flow.add{type='frame', direction='vertical', style='inside_shallow_frame'}
	content_frame.style.padding = 8
	content_frame.style.minimal_width = 450
	
	local scroll = content_frame.add{type='scroll-pane', name='mlc-ai-warning-scroll', direction='vertical'}
	scroll.style.maximal_height = (dh - 250) * dsf
	
	-- Status with red light (similar to status bar)
	local status_flow = scroll.add{type='flow', direction='horizontal'}
	status_flow.add{type='label', caption='[img=utility/status_not_working]'}
	status_flow.add{type='label', caption='[font=default-bold][color=red]AI Combinator Launcher Not Available[/color][/font]'}
	
	-- Description section
	local desc_flow = scroll.add{type='flow', direction='vertical'}
	desc_flow.style.top_margin = 8
	desc_flow.add{type='label', caption='The AI Combinator mod requires the AI Combinator Launcher to be running'}
	desc_flow.add{type='label', caption='to generate new code from text prompts.'}
	
	-- Impact section
	local impact_flow = scroll.add{type='flow', direction='vertical'}
	impact_flow.style.top_margin = 12
	impact_flow.add{type='label', caption='The AI Combinator Launcher was not detected on your system. This means:'}
	impact_flow.style.top_margin = 4
	
	local impact_list = scroll.add{type='flow', direction='vertical'}
	impact_list.style.top_margin = 4
	impact_list.style.left_margin = 12
	impact_list.add{type='label', caption='• New AI prompts will not be processed'}
	impact_list.add{type='label', caption='• Existing AI-generated combinators will continue to work normally'}
	impact_list.add{type='label', caption='• You can still edit code manually in combinators'}
	
	-- Solutions section
	local solutions_header = scroll.add{type='label', caption='[font=default-semibold][color=yellow]To resolve this issue:[/color][/font]'}
	solutions_header.style.top_margin = 12
	
	local solutions_list = scroll.add{type='flow', direction='vertical'}
	solutions_list.style.top_margin = 4
	solutions_list.style.left_margin = 12
	solutions_list.add{type='label', caption='1. Download and install the AI Combinator Launcher application'}
	solutions_list.add{type='label', caption='2. Configure the launcher with a valid LLM API key'}
	solutions_list.add{type='label', caption='3. Launch Factorio using the AI Combinator Launcher'}
	solutions_list.add{type='label', caption='4. Ensure no firewall is blocking UDP port 8889'}
	
	-- Download section
	local download_header = scroll.add{type='label', caption='[font=default-semibold][color=yellow]Download AI Combinator Launcher (select and copy):[/color][/font]'}
	download_header.style.top_margin = 12
	
	-- Add selectable download link with wider width
	local link_textfield = scroll.add{type='text-box', name='mlc-ai-warning-link', text='https://github.com/galgtonold/ai_combinator/releases'}
	link_textfield.read_only = true
	link_textfield.style.width = 450
	link_textfield.style.top_margin = 4

  -- Single button spanning full width with green style - inside the content frame
	local button = content_frame.add{type='button', name='mlc-ai-warning-close', caption='I Understand', style='green_button'}
	button.style.horizontally_stretchable = true
	button.style.top_margin = 16
	button.style.height = 35
end

local function help_window_toggle(pn, toggle_on)
	local player = game.players[pn]
	local gui_exists = player.gui.screen['mlc-help']
	if gui_exists and not toggle_on then return gui_exists.destroy()
	elseif toggle_on == false then return end
	local dw, dh, dsf = player.display_resolution.width,
		player.display_resolution.height, 1 / player.display_scale

	local gui = player.gui.screen.add{ type='frame',
		name='mlc-help', caption='Moon Logic Combinator Info', direction='vertical' }
	gui.location = {math.max(50, (dw - 800) * dsf), 20 * dsf}
	local scroll = gui.add{type='scroll-pane',  name='mlc-help-scroll', direction='vertical'}
	scroll.style.maximal_height = (dh - 200) * dsf
	local lines = {
		'Combinator has separate input and output leads, but note that you can connect them.',
		' ',
		'Special variables available/handled in Lua environment:',
		'  [color=#ffe6c0]uid[/color] (uint) -- globally-unique number of this combinator.',
		('  [color=#ffe6c0]%s[/color] {signal-name=value, ...} -- signals on the %s input wire (read-only).')
			:format(conf.red_wire_name, conf.red_wire_name),
		'    Any keys queried there are always numbers, returns 0 for missing signal.',
		('  [color=#ffe6c0]%s[/color] {signal-name=value, ...} -- same as above for %s input network.')
			:format(conf.green_wire_name, conf.green_wire_name),
		'  [color=#ffe6c0]out[/color] {signal-name=value, ...} -- table with all signals sent to networks.',
		'    They are persistent, so to remove a signal you need to set its entry',
		'      to nil or 0, or flush all signals by entering "[color=#ffe6c0]out = {}[/color]" (creates a fresh table).',
		('    Signal name can be prefixed by "%s/" or "%s/" to only output it on that specific wire,')
			:format(conf.red_wire_name, conf.green_wire_name),
		'      and will override non-prefixed signal value there, if that is used as well, until unset.',
		'  [color=#ffe6c0]var[/color] {} -- table to easily store values between code runs (per-mlc globals work too).',
		'  [color=#ffe6c0]delay[/color] (number) -- delay in ticks until next run - use for intervals or performance.',
		'    Defaults to 1 (run again on next tick), and gets reset to it before each run,',
		'      so must be set on every individual run if you want to delay the next one.',
		'  [color=#ffe6c0]irq[/color] (signal-name) -- input signal name to interrupt any delay on.',
		'    If any [color=#ffe6c0]delay[/color] value is set and this signal is non-zero on any input wire, delay gets interrupted.',
		'    Same as [color=#ffe6c0]delay[/color], gets reset before each code run, and must be set if still needed.',
		'  [color=#ffe6c0]irq_min_interval[/color] (number) -- min ticks between triggering code runs on any [color=#ffe6c0]irq[/color] signal.',
		'    To avoid complicated logic when that signal is not a pulse. Use nil or <=1 to disable (default).',
		'  [color=#ffe6c0]debug[/color] (bool) -- set to true to print debug info about next code run to factorio log.',
		'  [color=#ffe6c0]ota_update_from_uid[/color] (uint) -- copy code from another combinator with this uid.',
		'    Reset after code runs, ignored if MLC with that uid (number in a window header) does not exist.',
		'    Note that only code is updated, while persistent lua environment and outputs stay the same.',
		'  any vars with "__" prefix, e.g. __big_data -- work as normal, but won\'t clutter variables window.',
		' ',
		'Factorio APIs available, aside from general Lua stuff:',
		'  [color=#ffe6c0]game.tick[/color] -- read-only int for factorio game tick, to measure time intervals.',
		'  [color=#ffe6c0]game.log(...)[/color] -- prints passed value(s) to factorio log.',
		'  [color=#ffe6c0]game.print(...)[/color] -- prints values to an in-game console output.',
		'  [color=#ffe6c0]game.print_color(msg, c)[/color] -- for a more [color=#08c2ca]co[/color]'..
				'[color=#ed7a7e]lor[/color][color=#5cd568]ful[/color] console output, c={r[0-1],g,b}.',
		'  [color=#ffe6c0]serpent.line(...)[/color] and [color=#ffe6c0]serpent.block(...)[/color] -- dump tables to strings.',
		' ',
		'Presets - buttons with numbers on top of the UI:',
		'  Save and Load - [color=#ffe6c0]left-click[/color], Delete - [color=#ffe6c0]right-click[/color],'..
				' Overwrite - [color=#ffe6c0]right[/color] then [color=#ffe6c0]left[/color].',
		'  These are shared between all combinators, and can be used to copy code snippets.',
		'  Another way to copy code is the usual [color=#ffe6c0]shift+right-click[/color]'..
				' - [color=#ffe6c0]shift+left-click[/color] on the combinators.',
		' ',
		'Default UI hotkeys (rebindable, do not work when editing text-box is focused):',
		'  [color=#ffe6c0]Esc[/color] - unfocus/close code textbox (makes all other hotkeys work again),',
		'  [color=#ffe6c0]Ctrl-S[/color] - save/apply code changes,'..
				' [color=#ffe6c0]Ctrl-Left/Right[/color] - undo/redo last change,',
		'  [color=#ffe6c0]Ctrl-Q[/color] - close all UIs,'..
				' [color=#ffe6c0]Ctrl-Enter[/color] - save/apply and close,'..
				' [color=#ffe6c0]Ctrl-F[/color] - toggle env window.',
		'Some buttons at the top of the window also have multiple actions, see tooltips there.',
		' ',
		'To learn signal names, connect anything with signals to this combinator,',
		'  and their names will be printed as colored inputs on the right of the code window.',
		'If signal names are ambiguous (with some mods), signal type prefix can be used',
		'  ([color=#46a7f7]#[/color] - item, [color=#46a7f7]=[/color] - fluid, [color=#46a7f7]@[/color] - virtual signal)'
			..' for names that are same between multiple types.',
		' ' }
	for n, line in ipairs(lines) do scroll.add{
		type='label', name='line_'..n, direction='horizontal', caption=line } end
	gui.add{type='button', name='mlc-help-close', caption='Got it'}
end


local function vars_window_uid(gui)
	if not gui then return end
	while gui.name ~= 'mlc-vars' do gui = gui.parent end
	return tonumber(gui.caption:match('%[(%d+)%]'))
end

local function vars_window_update(player, uid, pause_update)
	local gui = player.gui.screen['mlc-vars']
	if not gui then return end
	local gui_paused = gui.caption:match(' %-%- .+$')
	if pause_update ~= nil then gui_paused = pause_update end -- explicit pause/unpause
	if gui_paused and pause_update == nil then return end -- ignore calls from mlc updates
	local gui_st_old, gui_st = gui.caption,
		('Moon Logic Environment Variables [%s]%s'):format(uid, gui_paused and ' -- PAUSED' or '')
	if gui_st ~= gui_st_old then
		gui.caption, gui_st = gui_st, gui.children[2].children[2]
		gui_st.style = gui_paused and 'green_button' or 'button'
		gui_st.caption = gui_paused and 'Unpause' or 'Pause'
	end
	local mlc, vars_box = storage.combinators[uid], gui['mlc-vars-scroll']['mlc-vars-box']
	if gui_paused and vars_box.read_only then
		vars_box.selectable, vars_box.read_only = true, false
		vars_box.tooltip =
			'Text is editable for selection/copying while paused,\n'..
			'but changing it will not update the environment.'
	elseif not gui_paused and not vars_box.read_only then
		vars_box.selectable, vars_box.read_only, vars_box.tooltip = false, true, ''
	end

	if not mlc then vars_box.text = '--- [color=#911818]Moon Logic Combinator is Offline[/color] ---'
	else
		local text, esc, vs, c = '', function(s) return tostring(s):gsub('%[', '[ ') end
		for k, v in pairs(mlc.vars) do
			if k:match('^__') then goto skip end
			if text ~= '' then text = text..'\n' end
			vs = serpent.line(v, conf.gui_vars_serpent_opts)
			if vs:len() > conf.gui_vars_line_len_max
			then vs = serpent.block(v, conf.gui_vars_serpent_opts)
			elseif vs:len() > conf.gui_vars_line_len_max * 0.6 then vs = '\n  '..vs end
			text = text..('[color=#520007][font=default-bold]%s[/font][/color] = %s'):format(esc(k), esc(vs))
		::skip:: end
		vars_box.text = text
	end
end

local function vars_window_switch_or_toggle(pn, uid, paused, toggle_on)
	-- Switches variables-window to specified combinator or toggles it on/off
	local player, gui_k = game.players[pn], 'vars.'..pn
	local gui_exists = player.gui.screen['mlc-vars']
	if gui_exists then
		if toggle_on or (toggle_on == nil and storage.guis_player[gui_k] ~= uid) then
			storage.guis_player[gui_k] = uid
			return vars_window_update(player, uid, paused)
		elseif not toggle_on then return gui_exists.destroy() end
	elseif toggle_on == false then return end -- force off toggle

	local dw, dh, dsf = player.display_resolution.width,
		player.display_resolution.height, 1 / player.display_scale
	storage.guis_player[gui_k] = uid
	local gui = player.gui.screen.add{ type='frame',
		name='mlc-vars', caption='', direction='vertical' }
	gui.location = {math.max(50, (dw - 800) * dsf), 45 * dsf}
	local scroll = gui.add{type='scroll-pane',  name='mlc-vars-scroll', direction='vertical'}
	scroll.style.maximal_height = (dh - 300) * dsf
	local tb = scroll.add{type='text-box', name='mlc-vars-box', text=''}
	tb.style.width = conf.gui_vars_line_px
	tb.read_only, tb.selectable, tb.word_wrap = true, false, true
	local btns = gui.add{type='flow', name='mlc-vars-btns', direction='horizontal'}
	btns.add{type='button', name='mlc-vars-close', caption='Close'}
	btns.add{ type='button', name='mlc-vars-pause', caption='Pause',
		tooltip='Pausing updates also makes text editable,'..
			' so that Ctrl-A/Ctrl-C can be used there, but editing it will not change the environment.' }
	vars_window_update(player, uid, paused)
end


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

local function preset_help_tooltip(code)
	if not code then
		return '-- [ [color=#ffe6c0]left-click[/color] to save script here ] --'..
			'\nLines prefixed with "-- desc:" in the code will be used for preset tooltip'..
			(', if any, first %s code lines otheriwse.'):format(conf.code_tooltip_lines)
	end
	-- Collect/use lines tagged with "-- desc: ..." prefix
	local desc = (code:match('^%s*--%s*desc:%s*(.-)%s*\n') or '')..'\n'
	for line in code:gmatch('\n%s*--%s*desc:%s*(.-)%s*\n') do desc = desc..line..'\n' end
	desc = desc:match('^%s*(.-)%s*$')
	if desc == '' then -- use few lines from the top of the code
		local n = conf.code_tooltip_lines
		for line in code:match('^%s*(.-)%s*$'):gmatch('([^\n]*)\n?') do
			n = n - 1
			desc = desc..line..'\n'
			if n <= 0 then break end
		end
	end
	desc = '-- [[font=default-bold]'..
		' [color=#ffe6c0]left-click[/color] - [color=#73d875]load[/color],'..
		' [color=#ffe6c0]right-click[/color] - [color=#ff2a55]clear[/color] [/font]] --\n'..
		desc:match('^%s*(.-)%s*$')
	return desc
end

local function set_preset_btn_state(el, code)
	el.style = code and 'green_button' or 'button'
	for k,v in pairs{ height=20, width=27,
			top_padding=0, bottom_padding=0, left_padding=0, right_padding=0 }
		do el.style[k] = v end
	el.tooltip = preset_help_tooltip(code)
end

local function set_history_btns_state(gui_t, mlc)
	local hist_log, n = mlc.history, mlc.history_state
	if n and hist_log[n-1] then
		gui_t.mlc_back.sprite = 'mlc-back-enabled'
		gui_t.mlc_back.enabled = true
	else
		gui_t.mlc_back.sprite = 'mlc-back'
		gui_t.mlc_back.enabled = false
	end
	if n and hist_log[n+1] then
		gui_t.mlc_fwd.sprite = 'mlc-fwd-enabled'
		gui_t.mlc_fwd.enabled = true
	else
		gui_t.mlc_fwd.sprite = 'mlc-fwd'
		gui_t.mlc_fwd.enabled = false
	end
end

function create_titlebar(gui, caption, close_button_tags, extra_tags)
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
  
  local close_button_tags = close_button_tags or {}
  for k, v in pairs(extra_tags) do
    close_button_tags[k] = v
  end

  titlebar.add{
    type = "sprite-button",
    style = "frame_action_button",
    sprite = "utility/close",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    tooltip = {"gui.close-instruction"},
    tags = close_button_tags,
  }
  return titlebar
end


function format_number(num)
  if num < 0 then
    return "-" .. format_number(-num)
  end
  
  if num < 1000 then
    return tostring(num)
  elseif num < 10000 then
    return string.format("%.1fk", num / 1000):gsub("%.0+k$", "k")
  elseif num < 100000 then
    return string.format("%dk", math.floor(num / 1000))
  elseif num < 1000000 then
    return string.format("%dk", math.floor(num / 1000))
  elseif num < 10000000 then
    return string.format("%.1fM", num / 1000000):gsub("%.0+M$", "M")
  elseif num < 100000000 then
    return string.format("%dM", math.floor(num / 1000000))
  elseif num < 1000000000 then
    return string.format("%dM", math.floor(num / 1000000))
  elseif num < 10000000000 then
    return string.format("%.1fG", num / 1000000000):gsub("%.0+G$", "G")
  else
    return string.format("%dG", math.floor(num / 1000000000))
  end
end

local function draw_signal_element(parent, style, signal_with_count, count)
  local flow = parent.add{type="flow"}

  local button = flow.add{
      type="choose-elem-button",
      elem_type="signal",
      signal = signal_with_count.signal,
      style=style
  }

  local count_label = flow.add{
    type="label", 
    caption=tostring(format_number(signal_with_count.count)),
    style="count_label",
    ignored_by_interaction=true
  }
  count_label.style.top_margin = 20
  count_label.style.left_margin = -40
  count_label.style.right_margin = -40
  count_label.style.horizontal_align = "right"
  count_label.style.maximal_width = 33
  count_label.style.minimal_width = 33
  button.locked = true
end

local function draw_signal_section(parent, signals_with_count, style)
  local button_table = parent.add{type="table", column_count=10, style="filter_slot_table"}
  local row_count = math.ceil(#signals_with_count / 10)
  button_table.style.height = 40 * row_count

  for _, signal in pairs(signals_with_count) do
    draw_signal_element(button_table, style, signal)
  end
  return row_count
end

local function draw_signals(button_frame, signals, red_signals, green_signals)
  button_frame.clear()

  local row_count = 0
  row_count = row_count + draw_signal_section(button_frame, signals, "slot")
  row_count = row_count + draw_signal_section(button_frame, red_signals, "red_slot")
  row_count = row_count + draw_signal_section(button_frame, green_signals, "green_slot")
  
  if row_count == 0 then
    row_count = 1
  end
  
  button_frame.style.height = 40 * row_count
  button_frame.style.vertically_stretchable = false
end

local function update_signals()
  for uid, gui_t in pairs(storage.guis) do
		mlc = storage.combinators[uid]

    if gui_t.input_signal_frame == nil then
      goto continue
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

    ::continue::
  end
end

local function build_header_circuit_connections(parent, red_network, green_network)
  local has_network = red_network ~= nil or green_network ~= nil

  if not has_network then
    parent.add{
      type = "label",
      caption = "Not connected",
      style = "label"
    }
    return
  end
  
  parent.add{
    type = "label",
    caption = "Connected to: ",
    style = "label"
  }
  
  if red_network then
    parent.add{
      type = "label",
      caption = "[color=red]" .. red_network.network_id .. "[/color] [img=info]",
      style = "label"
    }
  end

  if green_network then
    parent.add{
      type = "label",
      caption = "[color=green]" .. green_network.network_id .. "[/color] [img=info]",
      style = "label"
    }
  end
end

local function update_header()
  for uid, gui_t in pairs(storage.guis) do
		mlc = storage.combinators[uid]
    frame = gui_t.mlc_connections_flow
    if not frame then
      goto continue
    end
    frame.clear()
    frame.add{
      type = "label",
      caption = "Input:",
      style = "subheader_caption_label"
    }
    red_network = mlc.e.get_or_create_control_behavior().get_circuit_network(defines.wire_connector_id.combinator_input_red)
    green_network = mlc.e.get_or_create_control_behavior().get_circuit_network(defines.wire_connector_id.combinator_input_green)
    build_header_circuit_connections(frame, red_network, green_network)

    local spacer = frame.add{
      type = "empty-widget",
    }
    spacer.style.horizontally_stretchable = true

    frame.add{
      type = "label",
      caption = "Output:",
      style = "subheader_caption_label"
    }

    red_network = mlc.out_red.get_control_behavior().get_circuit_network(defines.wire_connector_id.circuit_red)
    green_network = mlc.out_green.get_control_behavior().get_circuit_network(defines.wire_connector_id.circuit_green)
    if red_network and red_network.connected_circuit_count < 3 then
      red_network = nil
    end
    if green_network and green_network.connected_circuit_count < 3 then
      green_network = nil
    end
    build_header_circuit_connections(frame, red_network, green_network)
    ::continue::
  end
end

local function update_status()
  for uid, gui_t in pairs(storage.guis) do
    local mlc = storage.combinators[uid]
    local status_flow = gui_t.mlc_status_flow
    if not status_flow then
      goto continue
    end
    -- Clear previous status elements
    status_flow.clear()
    
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
    
    if mlc.task_request_time then
      status_text = "Evaluating task"
      sprite = "utility/status_yellow"
    end

    -- Add status elements
    local status_sprite = status_flow.add{type = 'sprite', style = 'status_image', sprite = sprite}
    status_sprite.style.stretch_image_to_widget_size = true
    status_flow.add{type = 'label', name='mlc-status-text', caption=status_text}


    -- Update task request progress_bar
    local progress_bar = gui_t.mlc_progressbar
    if mlc.task_request_time then
      local elapsed_seconds = (game.tick - mlc.task_request_time) / 60
      local half_life_seconds = 7
      progress_bar.value = 1 - 0.5 ^ (elapsed_seconds / half_life_seconds)
      progress_bar.visible = true
    else
      progress_bar.visible = false
    end

    ::continue::
  end
end

local NO_TASK_SET_DESCRIPTION = 'No task set. Click to set a task.'

local function create_gui(player, entity)
	local uid = entity.unit_number
	local mlc = storage.combinators[uid]
	local mlc_err = mlc.err_parse or mlc.errun
	local dw, dh, dsf = player.display_resolution.width,
		player.display_resolution.height, 1 / player.display_scale
	local max_height = (dh - 350) * dsf

	-- Main frame
	local el_map, el = {} -- map is to check if el belonds to this gui
	local gui_t = {uid=uid, el_map=el_map}

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

  create_titlebar(gui, "AI combinator", {uid = uid, close_combinator_ui = true})

  local entity_frame = elc(gui, {type='frame', name='mlc-entity-frame', style='entity_frame', direction='vertical'})

  local connections_frame = elc(entity_frame,
    { type = 'frame', name = 'mlc-connections-frame', style = 'subheader_frame_with_text_on_the_right', direction ='horizontal' },
    { top_margin = -8, left_margin = -12, right_margin = -12, horizontally_stretchable = true, horizontally_squashable = true })

  elc(connections_frame, {type='flow', name='mlc-connections-flow', direction='horizontal', style = "player_input_horizontal_flow"})

  -- Status light and text

  local status_flow = elc(entity_frame, {type='flow', name='mlc-status-flow', direction='horizontal'}, {vertical_align='center'})
  
  -- Entity preview
  local entity_frame_border = elc(entity_frame, {type='frame', name='mlc-entity-frame-border', style='deep_frame_in_shallow_frame'})

  local entity_preview = elc(entity_frame_border, {type='entity-preview', name='mlc-entity-preview'})
  entity_preview.entity = entity
  entity_preview.style.natural_height = 152
  entity_preview.style.horizontally_stretchable = true
  
  elc(entity_frame, {type='label', name='mlc-task-title-label', caption='Task', style="semibold_label"})

  local task_label = elc(entity_frame, {type='label', name='mlc-task-label'}, {horizontally_squashable=true, single_line=false})
  task_label.caption = mlc.task or NO_TASK_SET_DESCRIPTION
  task_label.style.maximal_width = 828

  elc(entity_frame, {type='progressbar', name='mlc-progressbar', value=0, style='production_progressbar'}, {horizontally_stretchable=true})

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

  update_signals()

  -- Horizontal line and description section

  elc(entity_frame, {type='line', direction='horizontal'}, {horizontally_stretchable=true})

  local desc_container = elc(entity_frame, {type='flow', name='mlc-description-container', direction='vertical'})
  gui_t.mlc_description_container = desc_container

  -- Initialize the description UI (will be called after gui_t is stored in storage.guis)

  elc(entity_frame, {type='line', direction='horizontal'}, {horizontally_stretchable=true})

  -- Test cases section
  local test_cases_container = elc(entity_frame, {type='flow', name='mlc-test-cases-container', direction='vertical'})
  gui_t.mlc_test_cases_container = test_cases_container


  local code_text = elc( entity_frame, {type='text-box', name='mlc-code', text=mlc.code or ''},
  {maximal_height=max_height, width=400, minimal_height=300} )
  el.text = code_error_highlight(el.text, mlc_err)
  code_text.visible = false

  local error_label = elc(entity_frame, {type='label', name='mlc-errors', direction='horizontal'}, {horizontally_stretchable=true})
  error_label.visible = false

  if 1 ==1 then
    return gui_t
  end

	-- Main table
	local mt = elc(entity_frame, {type='table', column_count=2, name='mt', direction='vertical'})

	-- MT column-1
	local mt_left = elc(mt, {type='flow', name='mt-left', direction='vertical'})

	-- MT column-1: action button bar at the top
	local top_btns = elc( mt_left,
		{type='flow', name='mt-top-btns', direction='horizontal'}, {width=400} )

	local function top_btns_add(name, tooltip)
		local sz, pad = 20, 0
		return elc( top_btns,
			{type='sprite-button', name=name, sprite=name, direction='horizontal', tooltip=tooltip, style='button'},
			{height=sz, width=sz, top_padding=pad, bottom_padding=pad, left_padding=pad, right_padding=pad} )
	end

	top_btns_add( 'mlc-close',
		'Discard changes and close [[color=#e69100]Esc[/color]]\n'..
		'There\'s also Close All Windows [[color=#e69100]Ctrl-Q[/color]] hotkey' )
	top_btns_add('mlc-help', 'Toggle quick reference window')
	top_btns_add( 'mlc-vars',
		'Toggle environment window for this combinator [[color=#e69100]Ctrl-F[/color]].\n'..
		'Shift + click - open/update paused window.\n'..
		'Right-click - clear all lua environment variables on it.\n'..
		'Shift + right-click - clear "out" outputs-table.' )

	elc(top_btns, {type='flow', name='mt-top-spacer-a', direction='horizontal'}, {width=10})

	top_btns_add( 'mlc-back',
		'Undo [[color=#e69100]Ctrl-Left[/color]]\nRight-click - undo 5, right+shift - undo 50' )
	top_btns_add( 'mlc-fwd',
		'Redo [[color=#e69100]Ctrl-Right[/color]]\nRight-click - redo 5, right+shift - redo 50' )
	set_history_btns_state(gui_t, mlc)

	top_btns_add('mlc-clear', 'Clear code window')

	elc(top_btns, {type='flow', name='mt-top-spacer-b', direction='horizontal'}, {width=10})

	-- MT column-1: preset buttons at the top
	for n=0, 10 do set_preset_btn_state(
		elc(top_btns, {type='button', name='mlc-preset-'..n, caption=n, direction='horizontal'}),
		storage.presets[n] ) end

	-- MT column-1: code textbox
	elc( mt_left, {type='text-box', name='mlc-code', text=mlc.code or ''},
		{maximal_height=max_height, width=400, minimal_height=300} )
	el.text = code_error_highlight(el.text, mlc_err)

	-- MT column-1: error bar at the bottom
	elc(mt_left, {type='label', name='mlc-errors', direction='horizontal'}, {horizontally_stretchable=true})

	-- MT column-2
	local mt_right = elc(mt, {type='flow', name='mt-right', direction='vertical'})

	-- MT column-2: input signal list
	elc(mt_right, {type='label', name='signal-header', caption='Wire Signals:'}, {font='heading-2'})
	elc( mt_right, {type='scroll-pane', name='signal-pane', direction='vertical'},
		{vertically_stretchable=true, vertically_squashable=true, maximal_height=max_height} )

	-- MT column-2: input signal list
	local control_btns = elc(mt_right, {type='flow', name='mt-br-btns', direction='horizontal'})
	elc(control_btns, {type='button', name='mlc-save', caption='Save'}, {width=60})
	elc(control_btns, {type='button', name='mlc-close', caption='Close'}, {width=60})
	elc(control_btns, {type='button', name='mlc-commit', caption='Save & Close'})

	return gui_t
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
	local gui_t = create_gui(player, e)
	storage.guis[e.unit_number] = gui_t
	player.opened = gui_t.mlc_gui
	storage.guis_player[player.index] = e.unit_number
	
	-- Initialize the description UI now that gui_t is stored
	guis.update_description_ui(e.unit_number)
	
	-- Initialize the test cases UI
	guis.update_test_cases_ui(e.unit_number)
	
	return gui_t
end

function guis.close(uid)
	local gui_t = storage.guis[uid]
	local gui = gui_t and (gui_t.mlc_gui or gui_t.gui)
	if gui then gui.destroy() end
	storage.guis[uid] = nil
end

function guis.history_insert(mlc, code, gui_t)
	if code:gsub('^%s*(.-)%s*$', '%1') == '' then return end -- don't store empty state
	local hist_log, n = mlc.history, mlc.history_state
	if not hist_log then mlc.history, mlc.history_state = {code}, 1
	else
		if hist_log[n] == code then n = n
		elseif #hist_log == n then
			n = n + 1
			table.insert(hist_log, code)
		else
			n = n + 1
			hist_log[n] = code
			for a = n + 1, #hist_log do hist_log[a] = nil end
		end
		while n > conf.code_history_limit do
			n = n - 1
			table.remove(hist_log, 1)
		end
		mlc.history_state = n
	end
end

function guis.history_restore(gui_t, mlc, offset)
	if not mlc.history then return end
	local n = math.min(#mlc.history, math.max(1, mlc.history_state + offset))
	mlc.history_state = n
	gui_t.mlc_code.text = mlc.history[n]
end

local current_dialog = {}

function guis.open_set_task_dialog(player_index, uid)
  local player = game.players[player_index]
	local gui_t = storage.guis[uid]

  local combinator_frame = gui_t.mlc_gui
  local popup_location = {
    x = combinator_frame.location.x + 28,
    y = combinator_frame.location.y + 500
  }
  local popup_frame = player.gui.screen.add{
    type = "frame",
    direction = "vertical",
    tags = {uid = uid, dialog = true},
  }
  gui_t.task_dialog = popup_frame
  current_dialog[player_index] = popup_frame
  popup_frame.location = popup_location
  create_titlebar(popup_frame, "Set Task", {task_dialog_close = true}, {uid = uid, dialog = true})
  local content_flow = popup_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true},
  }

  local task_text = gui_t.mlc_task_label.caption
  if task_text == NO_TASK_SET_DESCRIPTION then
    task_text = ""
  end

  local task_textbox = content_flow.add{
    type = "text-box",
    name = "mlc-task-input",
    text = task_text,
    style = "edit_blueprint_description_textbox",
    tags = {uid = uid, dialog = true},
  }
  task_textbox.word_wrap = true
  task_textbox.style.width = 400
  task_textbox.style.bottom_margin = 8
  gui_t.task_textbox = task_textbox

  local confirm_flow = content_flow.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true},
  }
  task_textbox.focus()

  local filler = confirm_flow.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
    tags = {uid = uid, dialog = true},
  }
  filler.style.horizontally_stretchable = true
  filler.style.vertically_stretchable = true

  local confirm_button = confirm_flow.add{
    type = "button",
    caption = "Set Task",
    style = "confirm_button",
    tags = {uid = uid, set_task_button = true, dialog = true},
  }
  confirm_button.style.left_margin = 8
end

function guis.open_edit_code_dialog(player_index, uid)
  local player = game.players[player_index]
	local gui_t = storage.guis[uid]
	local mlc = storage.combinators[uid]

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
  current_dialog[player_index] = popup_frame
  popup_frame.location = popup_location
  create_titlebar(popup_frame, "Edit Source Code", {edit_code_dialog_close = true}, {uid = uid, dialog = true, edit_code_dialog = true})
  
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

function guis.open_set_description_dialog(player_index, uid)
  local player = game.players[player_index]
	local gui_t = storage.guis[uid]
  local mlc = storage.combinators[uid]

  local combinator_frame = gui_t.mlc_gui
  local popup_location = {
    x = combinator_frame.location.x + 28,
    y = combinator_frame.location.y + 500
  }
  local popup_frame = player.gui.screen.add{
    type = "frame",
    direction = "vertical",
    tags = {uid = uid, dialog = true, description_dialog = true},
  }
  gui_t.description_dialog = popup_frame
  current_dialog[player_index] = popup_frame
  popup_frame.location = popup_location
  create_titlebar(popup_frame, "Set Description", {description_dialog_close = true}, {uid = uid, dialog = true, description_dialog = true})
  local content_flow = popup_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {uid = uid, dialog = true, description_dialog = true},
  }

  local description_text = mlc.description or ""

  local description_textbox = content_flow.add{
    type = "text-box",
    name = "mlc-description-input",
    text = description_text,
    style = "edit_blueprint_description_textbox",
    tags = {uid = uid, dialog = true, description_dialog = true},
  }
  description_textbox.word_wrap = true
  description_textbox.style.width = 400
  description_textbox.style.bottom_margin = 8
  gui_t.description_textbox = description_textbox

  local confirm_flow = content_flow.add{
    type = "flow",
    direction = "horizontal",
    tags = {uid = uid, dialog = true, description_dialog = true},
  }
  description_textbox.focus()

  local filler = confirm_flow.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
    tags = {uid = uid, dialog = true, description_dialog = true},
  }
  filler.style.horizontally_stretchable = true
  filler.style.vertically_stretchable = true

  local confirm_button = confirm_flow.add{
    type = "button",
    caption = "Set Description",
    style = "confirm_button",
    tags = {uid = uid, set_description_button = true, dialog = true, description_dialog = true},
  }
  confirm_button.style.left_margin = 8
end

function guis.save_code(uid, code)
	local gui_t, mlc = storage.guis[uid], storage.combinators[uid]
	if not mlc then return end
	if gui_t then
		code = code_error_highlight(code or gui_t.mlc_code.text)
		gui_t.mlc_code.text = code
	end
	guis.history_insert(mlc, code, gui_t)
	load_code_from_gui(code, uid)
  mlc.task_request_time = nil -- reset task request time on code change
end

function guis.update_error_highlight(uid, mlc, err)
	local gui_t = storage.guis[uid]
	if not gui_t then return end
	gui_t.mlc_code.text = code_error_highlight(
		gui_t.mlc_code.text, err or mlc.err_parse or mlc.err_run )
end

function guis.on_gui_text_changed(ev)
	if ev.element.name ~= 'mlc-code' then 
    -- Handle test case value changes
    if ev.element.tags and ev.element.tags.test_case_value then
      guis.handle_test_case_input_change(ev)
    end
    
    -- Handle test case count field changes
    if ev.element.name and ev.element.name:match("^test%-count%-") then
      guis.handle_test_count_change(ev)
    end
    
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
	local uid, gui_t = find_gui(ev)
	if not uid then return end
	local mlc = storage.combinators[uid]
	if not mlc then return end
	guis.history_insert(mlc, ev.element.text, gui_t)
end

function guis.on_gui_elem_changed(ev)
  -- Handle test case signal selection changes
  if ev.element.tags and ev.element.tags.test_signal_elem then
    guis.handle_test_signal_change(ev)
  end
  
  -- Handle new compact test signal changes
  if ev.element.name and ev.element.name:match("^test%-signal%-") then
    guis.handle_test_signal_change(ev)
  end
end

function guis.handle_quantity_dialog_click(event)
  if not event.element.tags then
    return false
  end
  
  if event.element.tags.quantity_ok then
    local gui_t = storage.guis[event.element.tags.uid]
    if gui_t and gui_t.quantity_input then
      local quantity = tonumber(gui_t.quantity_input.text) or 0
      guis.set_signal_quantity(
        event.element.tags.uid,
        event.element.tags.test_index,
        event.element.tags.signal_type,
        event.element.tags.slot_index,
        quantity
      )
    end
    guis.close_quantity_dialog(event.player_index)
    return true
  elseif event.element.tags.quantity_cancel or event.element.tags.quantity_dialog_close then
    guis.close_quantity_dialog(event.player_index)
    return true
  elseif event.element.tags.quantity_dialog then
    return true -- Prevent closing on clicks inside
  end
  
  return false
end

function guis.close_quantity_dialog(player_index)
  local player = game.players[player_index]
  for _, gui in pairs(player.gui.screen.children) do
    if gui.valid and gui.tags and gui.tags.quantity_dialog then
      -- Clean up stored references
      local uid = gui.tags.uid
      if uid then
        local gui_t = storage.guis[uid]
        if gui_t then
          gui_t.quantity_dialog = nil
          gui_t.quantity_input = nil
        end
      end
      gui.destroy()
      break
    end
  end
end

function guis.set_signal_quantity(uid, test_index, signal_type, slot_index, quantity)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
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
  
  -- Ensure array is large enough
  while #signal_array < slot_index do
    table.insert(signal_array, {})
  end
  
  if not signal_array[slot_index] then
    signal_array[slot_index] = {}
  end
  
  signal_array[slot_index].count = quantity
  
  -- Clean up empty entries
  for i = #signal_array, 1, -1 do
    local entry = signal_array[i]
    if not entry.signal or not entry.count or entry.count == 0 then
      table.remove(signal_array, i)
    end
  end
  
  -- Refresh the dialog if it's open
  local gui_t = storage.guis[uid]
  if gui_t and gui_t.test_case_dialog and gui_t.test_case_dialog.valid then
    -- Find and refresh the appropriate signal panel
    local panel_name = signal_type .. "-signal-panel"
    local panel = gui_t.test_case_dialog[panel_name]
    if panel then
      panel.clear()
      guis.create_test_signal_panel(panel, signal_array, uid, test_index, signal_type)
    end
    
    -- Auto-run test if inputs or expected output changed
    if signal_type == "red" or signal_type == "green" or signal_type == "expected" then
      guis.run_test_case_in_dialog(uid, test_index)
    end
  end
end

function guis.close_dialog(player_index)
  if current_dialog[player_index] and current_dialog[player_index].valid then
    current_dialog[player_index].destroy()
    current_dialog[player_index] = nil
  end
end

function guis.set_task(uid, task)
  local mlc = storage.combinators[uid]
	local gui_t = storage.guis[uid]
  mlc.task = task
  mlc.task_request_time = game.tick
  gui_t.mlc_task_label.caption = task
end

function guis.set_description(uid, description)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  mlc.description = description
  -- Update the UI to reflect the new description
  guis.update_description_ui(uid)
end

function guis.add_test_case(uid)
  local mlc = storage.combinators[uid]
  if not mlc then return end
  
  if not mlc.test_cases then
    mlc.test_cases = {}
  end
  
  local new_test_index = #mlc.test_cases + 1
  table.insert(mlc.test_cases, {
    name = "Test Case " .. new_test_index,
    red_input = {},
    green_input = {},
    expected_output = {},
    actual_output = {}
  })
  
  -- Auto-run the new test case
  guis.run_test_case(mlc, new_test_index)
  
  guis.update_test_cases_ui(uid)
end

function guis.auto_generate_test_cases(uid)
  -- Placeholder for auto-generation logic
  local mlc = storage.combinators[uid]
  if not mlc then return end
  
  -- TODO: Implement auto-generation based on current inputs/outputs
  -- For now, just add a placeholder test case and auto-run it
  guis.add_test_case(uid)
end

function guis.open_test_case_dialog(player_index, uid, test_index)
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
  current_dialog[player_index] = popup_frame
  popup_frame.location = popup_location
  
  local test_case = mlc.test_cases[test_index]
  create_titlebar(popup_frame, "Edit Test Case", {test_case_dialog_close = true}, {uid = uid, dialog = true, test_case_dialog = true, test_index = test_index})
  
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
  
  guis.create_compact_signal_panel(red_signal_panel, test_case.red_input or {}, uid, test_index, "red")
  
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
  
  guis.create_compact_signal_panel(green_signal_panel, test_case.green_input or {}, uid, test_index, "green")
  
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
  
  guis.create_compact_signal_panel(expected_signal_panel, test_case.expected_output or {}, uid, test_index, "expected")
  
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
  
  guis.create_compact_signal_display_panel(actual_signal_panel, test_case.actual_output or {})
  
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
    guis.create_variable_row(vars_table, uid, test_index, i, var.name or "", var.value or 0)
  end
  
  -- Always have one empty row
  if #variables == 0 then
    guis.create_variable_row(vars_table, uid, test_index, 1, "", 0)
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
  guis.run_test_case(mlc, test_index)
  
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
  guis.run_test_case_in_dialog(uid, test_index)
  guis.update_test_status_in_dialog(uid, test_index)
end

-- Create compact signal panel with 6 elements per row max, using slot-based design
function guis.create_compact_signal_panel(parent, signals, uid, test_index, signal_type)
  -- Create a compact 6-column grid of signal slots
  local signal_table = parent.add{
    type = "table",
    column_count = 6,
    style = "filter_slot_table",
    name = "signal-table-" .. signal_type,
    tags = {uid = uid, test_index = test_index, signal_type = signal_type}
  }
  
  -- Convert signal array to lookup table for easier access
  local signal_lookup = {}
  for i, signal_data in ipairs(signals) do
    if signal_data.signal then
      signal_lookup[i] = signal_data
    end
  end
  
  -- Calculate how many rows we need (minimum 1, expand when last slot of a row is filled)
  local max_filled_slot = 0
  for i = 1, 60 do
    if signal_lookup[i] and signal_lookup[i].signal then
      max_filled_slot = i
    end
  end
  
  -- Always show at least one empty row, and add a new row if the last slot of the current row is filled
  local rows_needed = math.max(1, math.ceil(max_filled_slot / 6))
  if max_filled_slot > 0 and max_filled_slot % 6 == 0 then
    rows_needed = rows_needed + 1 -- Add one more row if last slot of current row is filled
  end
  local total_slots = rows_needed * 6
  
  -- Create slots
  for i = 1, total_slots do
    local signal_data = signal_lookup[i] or {}
    local slot_flow = signal_table.add{
      type = "flow",
      direction = "vertical",
      name = "slot-" .. i,
      tags = {uid = uid, test_index = test_index, signal_type = signal_type, slot_index = i}
    }
    
    -- Signal chooser button
    local signal_button = slot_flow.add{
      type = "choose-elem-button",
      elem_type = "signal",
      signal = signal_data.signal,
      name = "signal-button-" .. i,
      tags = {
        uid = uid,
        test_index = test_index,
        signal_type = signal_type,
        slot_index = i,
        test_signal_elem = true
      }
    }
    signal_button.style.width = 40
    signal_button.style.height = 40
    
    -- Overlay count label (positioned like in the base game)
    if signal_data.count and signal_data.count ~= 0 then
      local count_label = slot_flow.add{
        type = "label",
        caption = format_number(signal_data.count),
        style = "count_label",
        name = "count-label-" .. i,
        ignored_by_interaction = true,
        tags = {uid = uid, test_index = test_index, signal_type = signal_type, slot_index = i}
      }
      count_label.style.top_margin = -40
      count_label.style.left_margin = 0
      count_label.style.right_margin = 0
      count_label.style.horizontal_align = "right"
      count_label.style.maximal_width = 38
      count_label.style.minimal_width = 38
    end
    
    -- Overlay edit button (small button in corner for editing quantity)
    if signal_data.signal then
      local edit_button = slot_flow.add{
        type = "sprite-button",
        sprite = "utility/rename_icon",
        name = "edit-button-" .. i,
        style = "mini_button",
        tooltip = "Edit quantity",
        tags = {
          uid = uid,
          test_index = test_index,
          signal_type = signal_type,
          slot_index = i,
          edit_signal_quantity = true
        }
      }
      edit_button.style.width = 16
      edit_button.style.height = 16
      edit_button.style.top_margin = -20
      edit_button.style.left_margin = 22
    end
  end
  
  signal_table.style.height = 40 * rows_needed
end

-- Create compact signal display panel (read-only)
function guis.create_compact_signal_display_panel(parent, signals)
  -- Create a 6-column grid for displaying actual output signals
  local signal_table = parent.add{
    type = "table",
    column_count = 6,
    style = "filter_slot_table",
    name = "actual-signal-table"
  }
  
  -- Convert signals to array for display
  local signal_array = {}
  for signal_name, count in pairs(signals or {}) do
    if count ~= 0 then
      table.insert(signal_array, {signal_name = signal_name, count = count})
    end
  end
  
  -- Show "No output" if empty
  if #signal_array == 0 then
    local empty_slot = signal_table.add{
      type = "flow",
      direction = "vertical",
      name = "empty-slot"
    }
    
    local empty_button = empty_slot.add{
      type = "choose-elem-button",
      elem_type = "signal",
      locked = true
    }
    empty_button.style.width = 40
    empty_button.style.height = 40
    
    -- Add a few more empty slots to fill the first row
    for i = 2, 6 do
      local empty_slot2 = signal_table.add{
        type = "flow",
        direction = "vertical"
      }
      local empty_button2 = empty_slot2.add{
        type = "choose-elem-button",
        elem_type = "signal",
        locked = true
      }
      empty_button2.style.width = 40
      empty_button2.style.height = 40
    end
  else
    -- Calculate rows needed
    local rows_needed = math.max(1, math.ceil(#signal_array / 6))
    local total_slots = rows_needed * 6
    
    -- Fill slots with signals and empty slots
    for i = 1, total_slots do
      local signal_data = signal_array[i]
      local slot_flow = signal_table.add{
        type = "flow",
        direction = "vertical",
        name = "actual-slot-" .. i
      }
      
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
          caption = format_number(signal_data.count),
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
    
    signal_table.style.height = 40 * rows_needed
  end
end

function guis.create_test_signal_panel(parent, signals, uid, test_index, signal_type)
  -- Create a 10x4 grid of signal slots (smaller for the new layout)
  local signal_table = parent.add{
    type = "table",
    column_count = 10,
    style = "filter_slot_table",
    name = "signal-table-" .. signal_type,
    tags = {uid = uid, test_index = test_index, signal_type = signal_type}
  }
  signal_table.style.height = 160
  
  -- Convert signal array to lookup table for easier access
  local signal_lookup = {}
  for i, signal_data in ipairs(signals) do
    if signal_data.signal and signal_data.count then
      signal_lookup[i] = signal_data
    end
  end
  
  -- Create 40 slots (10x4)
  for i = 1, 40 do
    local signal_data = signal_lookup[i] or {}
    
    -- Create a container flow for proper layering
    local container_flow = signal_table.add{
      type = "flow",
      direction = "vertical",
      name = "container-" .. i,
      tags = {uid = uid, test_index = test_index, signal_type = signal_type, slot_index = i}
    }
    container_flow.style.width = 40
    container_flow.style.height = 40
    
    -- Signal chooser button
    local signal_button = container_flow.add{
      type = "choose-elem-button",
      elem_type = "signal",
      signal = signal_data.signal,
      name = "signal-button-" .. i,
      tags = {
        uid = uid,
        test_index = test_index,
        signal_type = signal_type,
        slot_index = i,
        test_signal_elem = true
      }
    }
    signal_button.style.width = 40
    signal_button.style.height = 40
    
    -- Create overlay elements in a separate overlay flow
    local overlay_flow = container_flow.add{
      type = "flow",
      direction = "horizontal",
      name = "overlay-" .. i,
      ignored_by_interaction = true
    }
    overlay_flow.style.top_margin = -40
    overlay_flow.style.width = 40
    overlay_flow.style.height = 40
    
    -- Spacer to push elements to the right
    local overlay_spacer = overlay_flow.add{
      type = "empty-widget",
      ignored_by_interaction = true
    }
    overlay_spacer.style.horizontally_stretchable = true
    
    -- Right side container for count and edit button
    local right_overlay = overlay_flow.add{
      type = "flow",
      direction = "vertical",
      ignored_by_interaction = true
    }
    right_overlay.style.vertical_align = "bottom"
    
    -- Edit button (always present but invisible if no signal)
    local edit_button = right_overlay.add{
      type = "sprite-button",
      sprite = "utility/rename_icon",
      name = "edit-button-" .. i,
      style = "mini_button",
      tooltip = "Edit quantity",
      tags = {
        uid = uid,
        test_index = test_index,
        signal_type = signal_type,
        slot_index = i,
        edit_signal_quantity = true
      }
    }
    edit_button.style.width = 16
    edit_button.style.height = 16
    edit_button.visible = signal_data.signal ~= nil
    
    -- Count label (overlaid on the button)
    if signal_data.count and signal_data.count ~= 0 then
      local count_label = right_overlay.add{
        type = "label",
        caption = format_number(signal_data.count),
        style = "count_label",
        name = "count-label-" .. i,
        ignored_by_interaction = true
      }
      count_label.style.top_margin = -20
      count_label.style.horizontal_align = "right"
      count_label.style.maximal_width = 38
      count_label.style.minimal_width = 38
    end
  end
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
        caption = format_number(signal_data.count),
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
  
  local signals_match = guis.test_case_matches(expected_output, actual_output)
  
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

function guis.run_test_case_in_dialog(uid, test_index)
  -- Run the test case and update the actual output display in the dialog
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  
  -- Calculate actual output with advanced options
  local result = guis.calculate_test_output_advanced(uid, test_case)
  test_case.actual_output = result.output
  test_case.actual_print = result.print_output
  
  -- Update the actual output panel in the dialog if it's open
  local gui_t = storage.guis[uid]
  if gui_t and gui_t.test_case_dialog and gui_t.test_case_dialog.valid then
    local actual_panel = gui_t.test_case_dialog["actual-signal-panel"]
    if actual_panel then
      actual_panel.clear()
      guis.create_test_signal_display_panel(actual_panel, test_case.actual_output)
    end
    
    -- Update actual print output
    local actual_print_label = gui_t.test_case_dialog["actual-print-label"]
    if actual_print_label then
      actual_print_label.caption = test_case.actual_print or "(none)"
    end
    
    -- Update the status indicator
    guis.update_test_status_in_dialog(uid, test_index)
  end
end

function guis.save_test_case_from_dialog(uid, test_index, player_index)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] or not gui_t.test_case_dialog then
    return
  end
  
  local test_case = mlc.test_cases[test_index]
  
  -- Save the test case name
  if gui_t.test_case_name_input then
    test_case.name = gui_t.test_case_name_input.text
  end
  
  -- The signal data is already saved through the element change handlers
  -- Just update the main UI
  guis.update_test_cases_ui(uid)
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

function guis.handle_test_signal_change(event)
  local element = event.element
  if not element.tags then return end
  
  local uid = element.tags.uid
  local test_index = element.tags.test_index
  local signal_type = element.tags.signal_type
  local slot_index = element.tags.slot_index
  
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
  while #signal_array < slot_index do
    table.insert(signal_array, {})
  end
  
  -- Update the signal
  if not signal_array[slot_index] then
    signal_array[slot_index] = {}
  end
  
  signal_array[slot_index].signal = element.elem_value
  
  -- If signal was cleared, also clear the count
  if not element.elem_value then
    signal_array[slot_index].count = nil
  elseif not signal_array[slot_index].count then
    signal_array[slot_index].count = 1 -- Default count
  end
  
  -- Clean up empty entries
  for i = #signal_array, 1, -1 do
    local entry = signal_array[i]
    if not entry.signal or not entry.count or entry.count == 0 then
      table.remove(signal_array, i)
    end
  end
  
  -- Refresh the dialog to show/hide edit buttons properly and expand rows if needed
  local gui_t = storage.guis[uid]
  if gui_t and gui_t.test_case_dialog and gui_t.test_case_dialog.valid then
    local panel_name = signal_type .. "-signal-panel"
    local panel = gui_t.test_case_dialog[panel_name]
    if panel then
      panel.clear()
      guis.create_compact_signal_panel(panel, signal_array, uid, test_index, signal_type)
    end
  end
  
  -- Auto-run the test after signal changes
  if signal_type == "red" or signal_type == "green" then
    guis.run_test_case_in_dialog(uid, test_index)
  end
end

function guis.open_quantity_dialog(player_index, uid, test_index, signal_type, slot_index)
  -- Simple quantity input dialog
  local player = game.players[player_index]
  local mlc = storage.combinators[uid]
  
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then
    return
  end
  
  -- Prevent multiple instances - close existing dialog if it exists
  local gui_t = storage.guis[uid]
  if gui_t and gui_t.quantity_dialog and gui_t.quantity_dialog.valid then
    gui_t.quantity_dialog.destroy()
    gui_t.quantity_dialog = nil
    gui_t.quantity_input = nil
  end
  
  local test_case = mlc.test_cases[test_index]
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
  
  local signal_data = signal_array[slot_index] or {}
  local current_count = signal_data.count or 1
  
  -- Create simple input dialog
  local quantity_frame = player.gui.screen.add{
    type = "frame",
    direction = "vertical",
    tags = {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  quantity_frame.location = {player.display_resolution.width / 2 - 100, player.display_resolution.height / 2 - 50}
  
  create_titlebar(quantity_frame, "Set Quantity", {quantity_dialog_close = true}, {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index})
  
  local content = quantity_frame.add{
    type = "flow",
    direction = "vertical",
    tags = {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  
  local input_flow = content.add{
    type = "flow",
    direction = "horizontal",
    tags = {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  
  input_flow.add{type = "label", caption = "Quantity:"}
  
  local quantity_input = input_flow.add{
    type = "textfield",
    text = tostring(current_count),
    numeric = true,
    allow_negative = true,
    name = "quantity-input",
    tags = {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  quantity_input.style.width = 100
  quantity_input.style.left_margin = 8
  quantity_input.focus()
  quantity_input.select_all()
  
  local button_flow = content.add{
    type = "flow",
    direction = "horizontal",
    tags = {quantity_dialog = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  
  local ok_btn = button_flow.add{
    type = "button",
    caption = "OK",
    style = "confirm_button",
    tags = {quantity_ok = true, uid = uid, test_index = test_index, signal_type = signal_type, slot_index = slot_index}
  }
  
  local cancel_btn = button_flow.add{
    type = "button",
    caption = "Cancel",
    style = "back_button",
    tags = {quantity_cancel = true}
  }
  cancel_btn.style.left_margin = 8
  
  -- Store references for later access
  local gui_t = storage.guis[uid]
  gui_t.quantity_dialog = quantity_frame
  gui_t.quantity_input = quantity_input
end

-- Create a variable row in the variables table
function guis.create_variable_row(table, uid, test_index, row_index, name, value)
  -- Variable name input
  local name_input = table.add{
    type = "textfield",
    text = name,
    name = "var-name-" .. row_index,
    tags = {uid = uid, test_index = test_index, var_row = row_index, var_name_input = true}
  }
  name_input.style.width = 150
  
  -- Variable value input
  local value_input = table.add{
    type = "textfield",
    text = tostring(value),
    numeric = true,
    allow_negative = true,
    name = "var-value-" .. row_index,
    tags = {uid = uid, test_index = test_index, var_row = row_index, var_value_input = true}
  }
  value_input.style.width = 100
  
  -- Delete button (only show for non-empty rows)
  local delete_btn = table.add{
    type = "sprite-button",
    sprite = "utility/trash",
    name = "var-delete-" .. row_index,
    style = "tool_button_red",
    tooltip = "Delete variable",
    tags = {uid = uid, test_index = test_index, var_row = row_index, delete_variable = true}
  }
  delete_btn.style.width = 24
  delete_btn.style.height = 24
  delete_btn.visible = name ~= "" or value ~= 0
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
      guis.create_variable_row(vars_table, uid, test_index, i, var.name or "", var.value or 0)
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
        guis.create_variable_row(vars_table, uid, test_index, i, var.name or "", var.value or 0)
      end
      -- Always have at least one empty row
      if #test_case.variables == 0 then
        guis.create_variable_row(vars_table, uid, test_index, 1, "", 0)
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
  
  -- Auto-run test case
  guis.run_test_case_in_dialog(uid, test_index)
end

-- Handle expected print input changes  
function guis.handle_print_input_change(event)
  local uid = event.element.tags.uid
  local test_index = event.element.tags.test_index
  
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  mlc.test_cases[test_index].expected_print = event.element.text
  
  -- Auto-run test case
  guis.run_test_case_in_dialog(uid, test_index)
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
  
  -- Auto-run test case
  guis.run_test_case_in_dialog(uid, test_index)
end

function guis.delete_test_case(uid, test_index)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases then return end
  
  table.remove(mlc.test_cases, test_index)
  guis.update_test_cases_ui(uid)
end

function guis.run_test_case(uid, test_index)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  local test_case = mlc.test_cases[test_index]
  
  -- Calculate actual output with advanced options
  local result = guis.calculate_test_output_advanced(uid, test_case)
  test_case.actual_output = result.output
  test_case.actual_print = result.print_output
  
  guis.update_test_cases_ui(uid)
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

function guis.handle_test_case_input_change(event)
  local element = event.element
  if not element.tags then return end
  
  local uid = element.tags.uid
  local test_index = element.tags.test_index
  local signal_type = element.tags.signal_type
  local signal_index = element.tags.signal_index
  
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return end
  
  local test_case = mlc.test_cases[test_index]
  
  -- Determine which input array to update
  local input_array
  if signal_type == "red" then
    input_array = test_case.red_input
  elseif signal_type == "green" then
    input_array = test_case.green_input
  elseif signal_type == "expected" then
    input_array = test_case.expected_output
  else
    return
  end
  
  -- Ensure the array is large enough
  while #input_array < signal_index do
    table.insert(input_array, {})
  end
  
  if element.tags.test_case_signal then
    -- Signal selection changed
    if not input_array[signal_index] then
      input_array[signal_index] = {}
    end
    input_array[signal_index].signal = element.elem_value
  elseif element.tags.test_case_value then
    -- Value changed
    local value = tonumber(element.text)
    if value == nil and element.text ~= "" then
      -- If the text is not a valid number and not empty, reset to 0
      element.text = "0"
      value = 0
    elseif value == nil then
      value = 0
    end
    
    if not input_array[signal_index] then
      input_array[signal_index] = {}
    end
    input_array[signal_index].count = value
  end
  
  -- Clean up empty entries
  for i = #input_array, 1, -1 do
    local entry = input_array[i]
    if not entry.signal or not entry.count or entry.count == 0 then
      table.remove(input_array, i)
    end
  end
  
  -- If this was a change to inputs, automatically run the test case
  if signal_type == "red" or signal_type == "green" then
    guis.run_test_case(uid, test_index)
  else
    -- Just update the UI for expected output changes
    guis.update_test_cases_ui(uid)
  end
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
        caption = format_number(count)
      }
      count_label.style.left_margin = 4
      count_label.style.vertical_align = "center"
    end
  end
end

function guis.test_case_matches(expected, actual)
  -- Check if expected output matches actual output
  if not expected or not actual then
    return false
  end
  
  -- Check all expected signals are present with correct values
  for signal, expected_count in pairs(expected) do
    if expected_count ~= 0 then
      local actual_count = actual[signal] or 0
      if actual_count ~= expected_count then
        return false
      end
    end
  end
  
  -- Check no unexpected signals are present
  for signal, actual_count in pairs(actual) do
    if actual_count ~= 0 then
      local expected_count = expected[signal] or 0
      if expected_count == 0 then
        return false
      end
    end
  end
  
  return true
end

function guis.update_test_cases_ui(uid)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  if not mlc or not gui_t or not gui_t.mlc_test_cases_container then
    return
  end
  
  local container = gui_t.mlc_test_cases_container
  container.clear()
  
  -- Helper function to add elements to the el_map
  local function add_to_map(element)
    if element.name then
      gui_t.el_map[element.index] = element
    end
    return element
  end
  
  -- Initialize test cases if not present
  if not mlc.test_cases then
    mlc.test_cases = {}
  end
  
  -- Header with summary and buttons
  local header_flow = container.add{
    type = "flow",
    direction = "horizontal",
    name = "mlc-test-cases-header"
  }
  add_to_map(header_flow)
  
  local title_flow = header_flow.add{
    type = "flow",
    direction = "horizontal"
  }
  
  local header_label = title_flow.add{
    type = "label",
    caption = "Test Cases",
    style = "semibold_label"
  }
  
  local add_test_btn = title_flow.add{
    type = "sprite-button",
    name = "mlc-add-test-case",
    sprite = "utility/add",
    tooltip = "Add test case",
    style = "mini_button_aligned_to_text_vertically",
    tags = {uid = uid, add_test_case = true}
  }
  add_test_btn.style.left_margin = 8
  add_to_map(add_test_btn)
  
  -- Calculate test case summary
  local total_tests = #mlc.test_cases
  local passed_tests = 0
  for _, test_case in ipairs(mlc.test_cases) do
    -- Check signal output match
    local signals_match = true
    if test_case.expected_output and next(test_case.expected_output) then
      signals_match = guis.test_case_matches(test_case.expected_output, test_case.actual_output or {})
    end
    
    -- Check print output match
    local print_matches = true
    if test_case.expected_print and test_case.expected_print ~= "" then
      local actual_print = test_case.actual_print or ""
      print_matches = actual_print:find(test_case.expected_print, 1, true) ~= nil
    end
    
    -- Test passes only if both signal and print outputs match (or are not specified)
    if signals_match and print_matches then
      passed_tests = passed_tests + 1
    end
  end
  
  if total_tests > 0 then
    local summary_label = title_flow.add{
      type = "label",
      caption = string.format("(%d/%d passing)", passed_tests, total_tests),
      style = "label"
    }
    summary_label.style.left_margin = 8
    summary_label.style.font_color = passed_tests == total_tests and {0.3, 0.8, 0.3} or {0.8, 0.8, 0.3}
  end
  
  local spacer = header_flow.add{type = "empty-widget"}
  spacer.style.horizontally_stretchable = true
  
  local auto_generate_btn = header_flow.add{
    type = "button",
    name = "mlc-auto-generate-tests",
    caption = "Auto Generate",
    tooltip = "Automatically generate test cases based on current inputs",
    style = "button",
    tags = {uid = uid, auto_generate_tests = true}
  }
  add_to_map(auto_generate_btn)
  
  -- Condensed test cases list
  if #mlc.test_cases > 0 then
    local test_scroll = container.add{
      type = "scroll-pane",
      name = "mlc-test-cases-scroll",
      direction = "vertical"
    }
    test_scroll.style.maximal_height = 200
    test_scroll.style.horizontally_stretchable = true
    add_to_map(test_scroll)
    
    for i, test_case in ipairs(mlc.test_cases) do
      local test_frame = test_scroll.add{
        type = "frame",
        direction = "horizontal",
        style = "subheader_frame",
        name = "test-case-frame-" .. i,
        tags = {uid = uid, edit_test_case = i}
      }
      test_frame.style.horizontally_stretchable = true
      test_frame.style.padding = 4
      
      -- Status indicator
      local status_sprite = test_frame.add{
        type = "sprite", 
        sprite = "utility/status_working",
        tags = {uid = uid, edit_test_case = i}
      }
      local actual_output = test_case.actual_output or {}
      local status_matches = guis.test_case_matches(test_case.expected_output or {}, actual_output)
      
      if test_case.expected_output then
        if status_matches then
          status_sprite.sprite = "utility/status_working"
          status_sprite.tooltip = "Test passes"
        else
          status_sprite.sprite = "utility/status_not_working"
          status_sprite.tooltip = "Test fails"
        end
      else
        status_sprite.sprite = "utility/status_yellow"
        status_sprite.tooltip = "No expected output defined"
      end
      
      -- Test name
      local name_label = test_frame.add{
        type = "label",
        caption = test_case.name or ("Test Case " .. i),
        style = "label",
        tags = {uid = uid, edit_test_case = i}
      }
      name_label.style.left_margin = 8
      
      local spacer = test_frame.add{
        type = "empty-widget",
        tags = {uid = uid, edit_test_case = i}
      }
      spacer.style.horizontally_stretchable = true
      
      -- Only delete button - edit is handled by clicking anywhere on the frame
      local delete_btn = test_frame.add{
        type = "sprite-button", 
        name = "mlc-delete-test-case-" .. i,
        sprite = "utility/trash",
        tooltip = "Delete test case",
        style = "mini_button",
        tags = {uid = uid, delete_test_case = i}
      }
      delete_btn.style.left_margin = 2
      add_to_map(delete_btn)
    end
  else
    local empty_label = container.add{
      type = "label",
      caption = "No test cases defined. Click + to add one or use Auto Generate.",
      style = "label"
    }
    empty_label.style.font_color = {0.6, 0.6, 0.6}
    empty_label.style.top_margin = 8
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
    
    local desc_label = header_flow.add{
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

function guis.handle_task_dialog_click(event)
  local gui
  if not event.element.tags then
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
    guis.close_dialog(event.player_index)
    return true
  elseif event.element.tags.set_description_button then
    local description_input = gui.description_textbox
    guis.set_description(uid, description_input.text)
    guis.close_dialog(event.player_index)
    return true
  elseif event.element.tags.edit_code_apply then
    local code_input = gui.edit_code_textbox
    guis.save_code(uid, code_input.text)
    guis.close_dialog(event.player_index)
    return true
  elseif event.element.tags.edit_code_cancel then
    guis.close_dialog(event.player_index)
    return true
  elseif event.element.tags.test_case_save then
    guis.save_test_case_from_dialog(uid, event.element.tags.test_index, event.player_index)
    guis.close_dialog(event.player_index)
    return true
  elseif event.element.tags.test_case_cancel then
    guis.close_dialog(event.player_index)
    return true
  elseif event.element.tags.run_test_dialog then
    guis.run_test_case_in_dialog(uid, event.element.tags.test_index)
    return true
  elseif event.element.tags.edit_signal_quantity then
    guis.open_quantity_dialog(event.player_index, uid, event.element.tags.test_index, event.element.tags.signal_type, event.element.tags.slot_index)
    return true
  elseif event.element.tags.test_signal_elem then
    -- Handle signal element changes in test dialog
    guis.handle_test_signal_change(event)
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

function guis.on_gui_click(ev)
  if guis.handle_task_dialog_click(ev) then
    return
  end
  
  if guis.handle_quantity_dialog_click(ev) then
    return
  end

  guis.close_dialog(ev.player_index)
  guis.close_quantity_dialog(ev.player_index)
  
	local el = ev.element

  if not el.valid then return end

	-- Separate "help" and "vars" windows, not tracked in globals (storage), unlike main MLC gui
	if el.name == 'mlc-copy-close' then return cgui.close()
	elseif el.name == 'mlc-help-close' then return el.parent.destroy()
	elseif el.name == 'mlc-ai-warning-close' then 
		-- Find and destroy the warning window by name
		local player = game.players[ev.player_index]
		local warning_window = player.gui.screen['mlc-ai-warning']
		if warning_window then
			return warning_window.destroy()
		end
	elseif el.name == 'mlc-vars-close' then
		return (el.parent.paent or el.parent).destroy()
	elseif el.name == 'mlc-vars-pause' then
		return vars_window_switch_or_toggle( ev.player_index,
			vars_window_uid(el), el.style.name ~= 'green_button', true )
	elseif string.sub(el.name,1,8) == "mlc-sig-" then
		if (ev.element.tags["signal"] ~= nil) then
			cgui.open(game.players[ev.player_index], ev.element.tags["signal"])
		end
	end

  if el.tags and el.tags.close_combinator_ui then
    guis.close(el.tags.uid)
    return
  end

  -- Handle description buttons that have tags with uid
  if el.tags and el.tags.uid then
    if el.tags.description_add or el.tags.description_edit then
      guis.open_set_description_dialog(ev.player_index, el.tags.uid)
      return
    end
    
    -- Handle test case buttons
    if el.tags.add_test_case then
      guis.add_test_case(el.tags.uid)
      return
    end
    
    if el.tags.auto_generate_tests then
      guis.auto_generate_test_cases(el.tags.uid)
      return
    end
    
    if el.tags.edit_test_case then
      guis.open_test_case_dialog(ev.player_index, el.tags.uid, el.tags.edit_test_case)
      return
    end
    
    if el.tags.delete_test_case then
      guis.delete_test_case(el.tags.uid, el.tags.delete_test_case)
      return
    end
  end

	local uid, gui_t = find_gui(ev)
	if not uid then return end

	local mlc = storage.combinators[uid]
	if not mlc then return guis.close(uid) end
	local el_id = el.name
	local preset_n = tonumber(el_id:match('^mlc%-preset%-(%d+)$'))
	local rmb = defines.mouse_button_type.right

	if el_id == 'mlc-code' then
		if not gui_t.code_focused then
			-- Removing rich-text tags also screws with the cursor position, so try to avoid it
			local clean_code = code_error_highlight(gui_t.mlc_code.text)
			if clean_code ~= gui_t.mlc_code.text then gui_t.mlc_code.text = clean_code end
		end
		gui_t.code_focused = true -- disables hotkeys and repeating cleanup above
  elseif el_id == 'mlc-set-task' then guis.open_set_task_dialog(ev.player_index, uid)
  elseif el_id == 'mlc-desc-btn-flow' then guis.open_set_description_dialog(ev.player_index, uid)
  elseif el_id == 'mlc-edit-code' then guis.open_edit_code_dialog(ev.player_index, uid)
	elseif el_id == 'mlc-save' then guis.save_code(uid)
	elseif el_id == 'mlc-commit' then guis.save_code(uid); guis.close(uid)
	elseif el_id == 'mlc-clear' then
		guis.save_code(uid, '')
		guis.on_gui_text_changed{element=gui_t.mlc_code}
	elseif el_id == 'mlc-close' then guis.close(uid)
	elseif el_id == 'mlc-help' then help_window_toggle(ev.player_index)

	elseif el_id == 'mlc-vars' then
		if ev.button == rmb then
			if ev.shift then clear_outputs_from_gui(uid)
			else -- clear env
				for k, _ in pairs(mlc.vars) do mlc.vars[k] = nil end
				vars_window_update(game.players[ev.player_index], uid)
			end
		else vars_window_switch_or_toggle(ev.player_index, uid, ev.shift, ev.shift or nil) end

	elseif preset_n then
		if ev.button == defines.mouse_button_type.left then
			if storage.presets[preset_n] then
				gui_t.mlc_code.text = storage.presets[preset_n]
				guis.history_insert(mlc, gui_t.mlc_code.text, gui_t)
			else
				storage.presets[preset_n] = gui_t.mlc_code.text
				set_preset_btn_state(el, storage.presets[preset_n])
			end
		elseif ev.button == rmb then
			storage.presets[preset_n] = nil
			set_preset_btn_state(el, storage.presets[preset_n])
		end

	elseif el_id == 'mlc-back' then
		if ev.button == rmb and ev.shift then guis.history_restore(gui_t, mlc, -50)
		elseif ev.button == rmb then guis.history_restore(gui_t, mlc, -5)
		else guis.history_restore(gui_t, mlc, -1) end
	elseif el_id == 'mlc-fwd' then
		if ev.button == rmb and ev.shift then guis.history_restore(gui_t, mlc, 50)
		elseif ev.button == rmb then guis.history_restore(gui_t, mlc, 5)
		else guis.history_restore(gui_t, mlc, 1) end
	end
end

function guis.on_gui_close(ev)
	-- Also fired for original auto-closed combinator GUI, which is ignored due to uid=gui_t=nil
	-- How unfocus/close sequence works:
	--  - click on code -  sets "code_focused = true", and game suppresses hotkeys except for esc
	--  - esc - with code_focused set, it is cleared, unfocus(), player.opened re-set to this gui again
	--  - esc again - as gui_t.code_focused is unset now, gui is simply closed here
	
	-- Check if there's a set task dialog open and close it first
	if current_dialog[ev.player_index] and current_dialog[ev.player_index].valid then
		-- Get the uid from the dialog tags to find the main combinator window
		local dialog_uid = current_dialog[ev.player_index].tags and current_dialog[ev.player_index].tags.uid
		guis.close_dialog(ev.player_index)
		-- Refocus the main combinator window so next escape will close it
		if dialog_uid then
			local gui_t = storage.guis[dialog_uid]
			if gui_t and gui_t.mlc_gui and gui_t.mlc_gui.valid then
				local p = game.players[ev.player_index]
				p.opened = gui_t.mlc_gui
			end
		end
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

function guis.help_window_toggle(pn, toggle_on)
	help_window_toggle(pn, toggle_on)
end

function guis.vars_window_update(pn, uid)
	local player, vars_uid = game.players[pn], storage.guis_player['vars.'..pn]
	if not player or vars_uid ~= uid then return end
	vars_window_update(player, uid)
end

function guis.vars_window_toggle(pn, toggle_on)
	local gui = game.players[pn].gui.screen['mlc-gui']
	local uid, gui_t = find_gui{element=g}
	if not uid then uid = storage.guis_player['vars.'..pn] end
	if not uid then return end
	vars_window_switch_or_toggle(pn, uid, nil, toggle_on)
end

function guis.ai_bridge_warning_window_toggle(pn, toggle_on)
	ai_bridge_warning_window_toggle(pn, toggle_on)
end


local function update_gui(event)
  if not (next(storage.guis) and game.tick % conf.gui_signals_update_interval == 0) then
    return
  end

  update_signals()
  update_header()
  update_status()
end

function guis.on_gui_checked_state_changed(event)
  if not event.element.tags then return end
  
  local uid = event.element.tags.uid
  if not uid then return end
  
  if event.element.tags.advanced_toggle then
    guis.toggle_advanced_section(uid, event.element.tags.test_index, event.element.state)
  end
end

event_handler.add_handler(defines.events.on_tick, update_gui)
event_handler.add_handler(defines.events.on_gui_click, guis.on_gui_click)
event_handler.add_handler(defines.events.on_gui_closed, guis.on_gui_close)
event_handler.add_handler(defines.events.on_gui_text_changed, guis.on_gui_text_changed)
event_handler.add_handler(defines.events.on_gui_elem_changed, guis.on_gui_elem_changed)
event_handler.add_handler(defines.events.on_gui_checked_state_changed, guis.on_gui_checked_state_changed)

return guis
