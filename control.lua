local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")
local bridge = require('src/services/bridge')
local init = require('src/ai_combinator/init')
local update = require('src/ai_combinator/update')
local circuit_network = require('src/core/circuit_network')
local memory = require('src/ai_combinator/memory')
local ai_operation_manager = require('src/core/ai_operation_manager')

-- Event modules
local blueprint_events = require('src/events/blueprint_events')
local entity_events = require('src/events/entity_events')
local hotkey_events = require('src/events/hotkey_events')

local guis = require('src/gui/gui')
local dialog_manager = require('src/gui/dialogs/dialog_manager')

local ai_bridge_warning_dialog = require('src/gui/dialogs/ai_bridge_warning_dialog')
local vars_dialog = require('src/gui/dialogs/vars_dialog')


local util = require('src/core/utils')


-- ----- MLC update processing -----

local mlc_err_sig = {type='virtual', name='mlc-error'}

-- ----- Register entity and blueprint event handlers -----

blueprint_events.register()
entity_events.register()
hotkey_events.register()


-- ----- on_tick handling - lua code, gui updates -----

local function format_mlc_err_msg(mlc)
	if not (mlc.err_parse or mlc.err_run or mlc.err_out) then return end
	local err_msg = ''
	for prefix, err in pairs{ ParserError=mlc.err_parse,
			RuntimeError=mlc.err_run, OutputError=mlc.err_out } do
		if not err then goto skip end
		if err_msg ~= '' then err_msg = err_msg..' :: ' end
		err_msg = err_msg..('%s: %s'):format(prefix, err)
	::skip:: end
	return err_msg
end

local function signal_icon_tag(sig)
	local sig = storage.signals[sig]
	if not sig then return '' end
	if sig.type == 'virtual' then return '[virtual-signal='..sig.name..'] ' end
	if (sig.type == nil)then return ""	end
	if helpers.is_valid_sprite_path(sig.type..'/'..sig.name)
		then return '[img='..sig.type..'/'..sig.name..'] ' end
end

local function quality_icon_tag(qname)
	if not qname then return '' end
	if helpers.is_valid_sprite_path('quality/'..qname)
		then return '[img=quality/'..qname..']' end
end

local function update_signals_in_guis()
	local gui_flow, label, mlc, cb, sig, mlc_out, mlc_out_idx, mlc_out_err
	local colors = {red={1,0.3,0.3}, green={0.3,1,0.3}}
	for uid, gui_t in pairs(storage.guis) do
		mlc = storage.combinators[uid]
		if not (mlc and mlc.e.valid) then init.mlc_remove(uid); goto skip end
		gui_flow = gui_t.signal_pane
		if not (gui_flow and gui_flow.valid) then goto skip end
		gui_flow.clear()

		-- Inputs
		for k, color in pairs(colors) do
			cb = circuit_network.cn_wire_signals(mlc.e, defines.wire_type[k])
			for sig, v in pairs(cb) do
				if v == 0 then goto skip end
				if not sig then goto skip end
				local signame, qname = circuit_network.cn_sig_quality(sig)
				local icon = signal_icon_tag(circuit_network.cn_sig_str(signame))
				if qname then
					icon = quality_icon_tag(qname) .. icon
				end
				label = gui_flow.add{
					type='label', name='mlc-sig-in-'..k..'-'..sig,
					caption=('[%s] %s%s = %s'):format(
						constants.get_wire_label(k), icon, sig, v ) }
				label.style.font_color = color
				label.tags = {signal=sig}
		::skip:: end end

		-- Outputs
		mlc_out, mlc_out_idx, mlc_out_err = {}, {}, util.shallow_copy((memory.combinators[uid] or {})._out or {})
		for k, cb in pairs{red=mlc.out_red, green=mlc.out_green} do
			cb = cb.get_control_behavior()
			for _, cbs in pairs(cb.sections[1].filters or {}) do
				sig, label = cbs.value.name, constants.get_wire_label(k)
				if not sig then goto cb_slots_end end
				if cbs.value.quality ~= nil and cbs.value.quality ~= "normal" then
					sig = cbs.value.quality.."/"..sig
				end
				mlc_out_err[sig], mlc_out_err[('%s/%s'):format(k, sig)] = nil, nil
				mlc_out_err[('%s/%s'):format(label, sig)] = nil
				sig = circuit_network.cn_sig_str(cbs.value)
				mlc_out_err[sig], mlc_out_err[('%s/%s'):format(k, sig)] = nil, nil
				mlc_out_err[('%s/%s'):format(label, sig)] = nil
				if cbs.min ~= 0 then
					if not mlc_out[sig] then mlc_out_idx[#mlc_out_idx+1], mlc_out[sig] = sig, {} end
					mlc_out[sig][k] = cbs.min
        end
		end ::cb_slots_end:: end
		table.sort(mlc_out_idx)
		for val, k in pairs(mlc_out_idx) do
			local signame, qname = circuit_network.cn_sig_quality(k)
			val, sig, label = mlc_out[k], storage.signals[signame].name, signal_icon_tag(signame)
			if string.sub(signame,1,1)== '~' then
				sig = "~"..sig
			end
			if qname then
				label = quality_icon_tag(qname) .. label
				sig = qname.."/"..sig
			end
			if val['red'] == val['green'] then
				k = gui_flow.add{ type='label', name='mlc-sig-out-'..sig,
					caption=('[out] %s%s = %s'):format(label, sig, val['red'] or 0) }
				k.tags = {signal=sig}
			else for k, color in pairs(colors) do
				k = gui_flow.add{ type='label', name='mlc-sig-out/'..k..'-'..sig,
					caption=('[out/%s] %s%s = %s'):format(constants.get_wire_label(k), label, sig, val[k] or 0) }
				k.style.font_color = color
				k.tags = {signal=sig}
		end end end

		-- Remaining invalid signals and errors
		local n = 0 -- to dedup bogus non-string signal keys that have same string repr
		for sig, val in pairs(mlc_out_err) do
			cb, val = pcall(serpent.line, val, {compact=true, nohuge=false})
			if not cb then val = '<err>' end
			if val:len() > 8 then val = val:sub(1, 8)..'+' end
			gui_flow.add{ type='label', name=('mlc-sig-out/err-%d-%s'):format(n, sig),
				caption=('[color=#ce9f7f][out-invalid] %s = %s[/color]'):format(sig, val) }
			n = n + 1
		end
		gui_t.mlc_errors.caption = format_mlc_err_msg(mlc) or ''
	::skip:: end
end

local function alert_about_mlc_error(mlc_env, err_msg)
	local p = mlc_env._e.last_user
	if p.valid and p.connected
		then p = {p} else p = p.force.connected_players end
	mlc_env._alert = p
	for _, p in ipairs(p) do
		p.add_custom_alert( mlc_env._e, mlc_err_sig,
			'Moon Logic Error ['..mlc_env._uid..']: '..err_msg, true )
	end
end

local function alert_clear(mlc_env)
	local p = mlc_env._alert or {}
	for _, p in ipairs(p) do
		if p.valid and p.connected then p.remove_alert{icon=mlc_err_sig} end
	end
	mlc_env._alert = nil
end

local function run_moon_logic_tick(mlc, mlc_env, tick)
	-- Runs logic of the specified combinator, reading its input and setting outputs
	local out_tick, out_diff = mlc.next_tick, util.shallow_copy(mlc_env._out)
	local dbg = mlc.vars.debug and function(fmt, ...)
		log((' -- moon-logic [%s]: %s'):format(mlc_env._uid, fmt:format(...))) end
	mlc.vars.delay, mlc.vars.var, mlc.vars.debug, mlc.vars.irq, mlc.irq = 1, mlc.vars.var or {}

	if mlc.e.energy < constants.ENERGY_FAIL_LEVEL then
		mlc.state = 'no-power'
		update.mlc_update_led(mlc, mlc_env)
		mlc.next_tick = game.tick + constants.ENERGY_FAIL_DELAY
		return
	end

	if dbg then -- debug
		dbg('--- debug-run start [tick=%s] ---', tick)
		mlc_env.debug_wires_set({})
		dbg('env-before :: %s', serpent.line(mlc.vars))
		dbg('out-before :: %s', serpent.line(mlc_env._out)) end
	mlc_env._out['mlc-error'] = nil -- for internal use

	do
    -- Clear out output table before running code
    for k, _ in pairs(mlc_env._out) do
      mlc_env._out[k] = nil
    end
		local st, err = pcall(mlc_env._func)
		if not st then mlc.err_run = err or '[unspecified lua error]'
		else
			mlc.state, mlc.err_run = 'run'
			if mlc_env._out['mlc-error'] ~= 0 then -- can be used to stop combinator
				mlc.err_run = 'Internal mlc-error signal set'
				mlc_env._out['mlc-error'] = nil -- signal will be emitted via mlc.state
			end
		end
	end

	if dbg then -- debug
		dbg('used-inputs :: %s', serpent.line(mlc_env.debug_wires_set()))
		dbg('env-after :: %s', serpent.line(mlc.vars))
		dbg('out-after :: %s', serpent.line(mlc_env._out)) end

	local delay = tonumber(mlc.vars.delay) or 1
	if delay > constants.LED_SLEEP_MIN then mlc.state = 'sleep' end
	mlc.next_tick = tick + delay

	local sig = mlc.vars.irq
	if sig then
		sig = circuit_network.cn_sig(sig)
		if sig then mlc.irq, mlc.irq_delay = sig, tonumber(mlc.vars.irq_min_interval) else
			mlc.err_run = ('Unknown/ambiguous "irq" signal: %s'):format(serpent.line(mlc.vars.irq)) end
	end

	for sig, v in pairs(mlc_env._out) do
		if out_diff[sig] ~= v then out_diff[sig] = v
		else out_diff[sig] = nil end
	end
	local out_sync = next(out_diff) or out_tick == 0 -- force sync after reset

	if dbg then -- debug
		for sig, v in pairs(out_diff) do
			if not mlc_env._out[sig] then out_diff[sig] = '-'
		end end
		dbg('out-sync=%s out-diff :: %s', out_sync and true, serpent.line(out_diff)) end

	if out_sync then update.mlc_update_output(mlc, mlc_env._out) end

	local err_msg = format_mlc_err_msg(mlc)
	if err_msg then
		mlc.state = 'error'
		if dbg then dbg('error :: %s', err_msg) end -- debug
		alert_about_mlc_error(mlc_env, err_msg)
	end

	if dbg then dbg('--- debug-run end [tick=%s] ---', tick) end -- debug
	update.mlc_update_led(mlc, mlc_env)

	if mlc.vars.ota_update_from_uid then
		local mlc_src = mlc.vars.ota_update_from_uid
		mlc_src = mlc_src ~= mlc_env._uid and
			storage.combinators[mlc.vars.ota_update_from_uid]
		if mlc_src and mlc_src.code ~= mlc.code
			then guis.save_code(mlc_env._uid, mlc_src.code) end
		mlc.vars.ota_update_from_uid = nil
	end
end

local function on_tick(ev)
  -- Receive UDP packets and trigger processing
  helpers.recv_udp()


	local tick = ev.tick

	for uid, mlc in pairs(storage.combinators) do
		local mlc_env = memory.combinators[uid]
		if not mlc_env then
      mlc_env = init.mlc_init(mlc.e)
    end
    if mlc.removed_by_player then -- if it was removed by the user, keep it so it can be restored from undo
      goto skip
    end
		if not (mlc_env and mlc.e.valid and mlc.out_red.valid and mlc.out_green.valid) then
        init.mlc_remove(uid)
        goto skip
    end

		local err_msg = format_mlc_err_msg(mlc)
		if err_msg then
			if tick % constants.LOGIC_ALERT_INTERVAL == 0
				then alert_about_mlc_error(mlc_env, err_msg) end
			goto skip -- suspend combinator logic until errors are addressed
		elseif mlc_env._alert then alert_clear(mlc_env) end

		if mlc.irq and (mlc.irq_tick or 0) < tick - (mlc.irq_delay or 0)
				and mlc.e.get_signal(mlc.irq, defines.wire_connector_id.combinator_input_green, defines.wire_connector_id.combinator_input_red) ~= 0 then
      mlc.irq_tick = tick
      mlc.next_tick = nil
    end
		if tick >= (mlc.next_tick or 0) and mlc_env._func then
			run_moon_logic_tick(mlc, mlc_env, tick)
			for _, p in ipairs(game.connected_players) do
        local player, vars_uid = game.players[p.index], storage.guis_player['vars.'..p.index]
        if not player or vars_uid ~= uid then
          goto skip_vars
        end
        vars_dialog.update(player, uid)
        ::skip_vars::
      end
		end
	::skip:: end

	if next(storage.guis) then 
        update_signals_in_guis() 
    end
end

event_handler.add_handler(defines.events.on_tick, on_tick)

event_handler.add_handler(constants.events.on_task_request_completed, function(event)
  -- Complete the AI operation using the new manager
  ai_operation_manager.complete_operation(event.uid)
  
  -- Check if response starts with ERROR:
  if event.response and event.response:sub(1, 6) == "ERROR:" then
    local mlc = storage.combinators[event.uid]
    local mlc_env = memory.combinators[event.uid]
    if mlc and mlc_env then
      -- Extract the error message after "ERROR: "
      local error_message = event.response:sub(8) -- Skip "ERROR: "
      mlc.state = "error"
      mlc.err_parse = "AI Error: " .. error_message
      
      -- Update the LED to show error state
      update.mlc_update_led(mlc, mlc_env)
      
      game.print("[color=red]AI Error: " .. error_message .. "[/color]")
    end
  else
    guis.save_code(event.uid, event.response, "ai_generation")
  end
end)

event_handler.add_handler(constants.events.on_test_generation_completed, function(event)
  -- Complete the AI operation using the new manager
  ai_operation_manager.complete_operation(event.uid)
end)


-- ----- GUI events and entity interactions -----

script.on_event(defines.events.on_gui_opened, function(ev)
	if not ev.entity then return end
	local player = game.players[ev.player_index]
	local e = player.opened
	if not (e and e.name == 'mlc') then return end
	if not storage.combinators[e.unit_number] then
		player.opened = nil
		return util.console_warn(player, 'BUG: Combinator #'..e.unit_number..' is not registered with mod code')
	end
	local gui_t = storage.guis[e.unit_number]
	if not gui_t then guis.open(player, e)
	else
		e = game.players[gui_t.mlc_gui.player_index or 0]
		e = e and e.name or 'Another player'
		player.print(e..' already opened this combinator', {1,1,0})
	end
end)


-- ----- Remote Interface for /measured-command benchmarking -----
-- Usage: /measured-command remote.call('mlc', 'run', 1234, 100)

local remote_err = function(msg, ...) for n, p in pairs(game.players)
	do p.print(('Moon-Logic remote-call error: '..msg):format(...), {1,1,0}) end end
remote.add_interface('mlc', {run = function(uid_raw, count)
	local uid = tonumber(uid_raw)
	local mlc, mlc_env = storage.combinators[uid], memory.combinators[uid]
	if not mlc or not mlc_env then
		return remote_err('cannot find combinator with uid=%s', uid_raw) end
	local err_n, st, err, err_last = 0
	for n = 1, tonumber(count) or 1 do
		st, err = pcall(mlc_env._func)
		if not st then err_n, err_last = err_n + 1, err or '[unspecified lua error]' end
	end
	if err_n > 0 then remote_err( '%d/%d run(s)'..
		' raised error(s), last one: %s', err_n, count, err ) end
end})


-- ----- Init -----

local strict_mode = false
local function strict_mode_enable()
	if strict_mode then return end
	setmetatable(_ENV, {
		__newindex = function(self, key, value)
			error('\n\n[ENV Error] Forbidden global _ENV *write*:\n'
				..serpent.line{key=key or '<nil>', value=value or '<nil>'}..'\n', 2) end,
		__index = function(self, key)
			if key == 'game' then return end -- used in utils.log check
			error('\n\n[ENV Error] Forbidden global _ENV *read*:\n'
				..serpent.line{key=key or '<nil>'}..'\n', 2) end })
	strict_mode = true
end

local function update_signal_types_table()
	storage.signals, storage.signals_short = {}, {} -- short=false for ambiguous ones
	local sig_str, sig
	for k, sig in pairs(prototypes.virtual_signal) do
		if sig.special then goto skip end -- anything/everything/each
		sig_str, sig = circuit_network.cn_sig_str('virtual', k), {type='virtual', name=k, quality="normal"}
		storage.signals_short[k], storage.signals[sig_str] = sig_str, sig
	::skip:: end
	for t, protos in pairs{ fluid=prototypes.fluid,
			item=prototypes.get_item_filtered{{filter='hidden', invert=true}} } do
		for k, _ in pairs(protos) do
			sig_str, sig = circuit_network.cn_sig_str(t, k), {type=t, name=k, quality="normal"}
			storage.signals_short[k] = storage.signals_short[k] == nil and sig_str or false
			storage.signals[sig_str] = sig
	end end
	for t, k in pairs(prototypes.recipe) do
		sig_str, sig = circuit_network.cn_sig_str('recipe', t), {type='recipe', name=t, quality="normal"}
		if storage.signals_short[t] == nil then
			storage.signals_short[t] = sig_str
		end
		storage.signals[sig_str] = sig
	end
end

local function update_signal_quality_table()
	storage.quality = {}
	for t,_ in pairs(prototypes.quality) do
		table.insert(storage.quality, t)
	end
end

local function update_recipes()
	for _, force in pairs(game.forces) do
		if force.technologies['mlc'].researched then
			force.recipes['mlc'].enabled = true
	end end
end

script.on_init(function()
	--strict_mode_enable()
	update_signal_quality_table()
	update_signal_types_table()
	for k, _ in pairs(util.tt('combinators presets guis guis_player')) do storage[k] = {} end
end)

script.on_load(function()
	-- Check if AI bridge is available when mod is loaded
	bridge.check_bridge_availability()
end)

script.on_configuration_changed(function(data) -- migration
	--strict_mode_enable()
	update_signal_quality_table()
	update_signal_types_table()

	local update = data.mod_changes and data.mod_changes[script.mod_name]
	if update and update.old_version then

	end

	update_recipes()
	
	-- Check if AI bridge is available after configuration changes
	bridge.check_bridge_availability()
end)

-- Add console command to test AI bridge ping
commands.add_command("ai-ping", "Send a ping request to the AI bridge", function(command)
  local uid = tonumber(command.parameter) or 0
  bridge.send_ping_request(uid)
  game.print("Ping request sent to AI bridge (uid: " .. uid .. ")")
end)

-- Add event handler for ping responses
event_handler.add_handler(constants.events.on_ping_response, function(payload)
  -- Only print message for manual console commands, not automatic bridge checks
  if (payload.uid or 0) ~= constants.BRIDGE_CHECK_UID then
    game.print("Received ping response (uid: " .. (payload.uid or 0) .. ", status: " .. (payload.status or "unknown") .. ")")
  end
end)


event_handler.add_handler(constants.events.on_bridge_check_completed, function(payload)
  if not payload.available then
    -- Show warning window to all players
    for _, player in pairs(game.players) do
      if player.valid then
        ai_bridge_warning_dialog.show(player.index, true)
      end
    end
  end
end)

-- Check bridge availability when players join
event_handler.add_handler(defines.events.on_player_joined_game, function(event)
  bridge.check_bridge_availability()
end)

-- Clean up dialog stacks when players are removed
event_handler.add_handler(defines.events.on_player_removed, function(event)
  dialog_manager.cleanup_player(event.player_index)
end)

-- Activate Global (Storage) Variable Viewer (gvv) mod, if installed/enabled - https://mods.factorio.com/mod/gvv
if script.active_mods['gvv'] then require('__gvv__.gvv')() end

