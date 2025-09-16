local conf = require('src/core/config')
conf.update_from_settings()

local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")
local bridge = require('src/services/bridge')
local init = require('src/ai_combinator/init')
local update = require('src/ai_combinator/update')
local circuit_network = require('src/core/circuit_network')
local memory = require('src/ai_combinator/memory')
local sandbox = require('src/sandbox/base')
local ai_operation_manager = require('src/core/ai_operation_manager')


local guis = require('src/gui/gui')
local dialog_manager = require('src/gui/dialogs/dialog_manager')

local ai_bridge_warning_dialog = require('src/gui/dialogs/ai_bridge_warning_dialog')
local help_dialog = require('src/gui/dialogs/help_dialog')
local vars_dialog = require('src/gui/dialogs/vars_dialog')


local util = require('src/core/utils')


-- ----- MLC update processing -----

local mlc_err_sig = {type='virtual', name='mlc-error'}

-- ----- MLC (+ sandbox) init / remove -----

local Terminals = {
	red = {
		output = defines.wire_connector_id.combinator_output_red,
		input = defines.wire_connector_id.combinator_input_red
	},
	green = {
		output = defines.wire_connector_id.combinator_output_green,
		input = defines.wire_connector_id.combinator_input_green
	}
}

-- Create/connect/remove invisible constant-combinator entities for wire outputs
local function out_wire_connect(e, color)
	local core = e.surface.create_entity{
		name='mlc-core', position=e.position,
		force=e.force, create_build_effect_smoke=false }

	local terminals = Terminals[color]
	local connectors = {
		transmitter = e.get_wire_connector( terminals.output ),
		receiver = core.get_wire_connector( terminals.input )
	}

	local success = connectors.transmitter.connect_to( connectors.receiver, false, defines.wire_origin.script )

	if not success then
		error(('Failed to connect %s wire outputs to core'):format(color))
	end

	core.destructible = false
	return core
end
local function out_wire_connect_both(e)
	return
		out_wire_connect(e, "red"),
		out_wire_connect(e, "green")
end
local function out_wire_clear_mlc(mlc)
	for _, e in ipairs{'core', 'out_red', 'out_green'} do
		e, mlc[e] = mlc[e]
		if e and e.valid then e.destroy() end
	end
	return mlc
end
local function out_wire_connect_mlc(mlc)
	out_wire_clear_mlc(mlc)
	mlc.out_red, mlc.out_green = out_wire_connect_both(mlc.e)
	return mlc
end

-- ----- Misc events -----

local mlc_filter = { { filter = 'name', name = 'mlc' },
-- { filter = "ghost", ghost_name = "mlc" } 
}

local function blueprint_match_positions(bp_es, map_es)
	-- Hack to work around invalidated ev.mapping - match entities by x/y position
	-- Same idea as in https://forums.factorio.com/viewtopic.php?p=466734
	--  but x/y in blueprints seem to be absolute in current factorio, not offset from center
	local bp_mlcs, bp_mlc_uids, be, k = {}, {}, nil, nil
	for _, e in ipairs(bp_es) do if e.name == 'mlc'
		then bp_mlcs[e.position.x..'_'..e.position.y] = e end end
	if not next(bp_mlcs) then return bp_mlc_uids end -- no mlcs in blueprint
	for _, e in ipairs(map_es) do
		if not (e.valid and ( e.name == 'mlc'
				or (e.name == 'entity-ghost' and e.ghost_name == 'mlc') ))
			then goto skip end
		k = e.position.x..'_'..e.position.y
		be, bp_mlcs[k] = bp_mlcs[k]
		if not be or e.name == 'entity-ghost' then goto skip end -- ghosts have tags already
		bp_mlc_uids[be.entity_number] = e.unit_number
	::skip:: end
	if next(bp_mlcs) then return end -- blueprint entities left unmapped
	return bp_mlc_uids
end

local function blueprint_map_validate(bp_es, bp_map)
	-- Blueprint ev.mapping can be invalidated by other mods acting on this event, so checked first
	-- See https://forums.factorio.com/viewtopic.php?p=457054#p457054 for more details
	local bp_check, bp_mlc_uids = {}, {}
	for _, e in ipairs(bp_es) do bp_check[e.entity_number] = e.name end
	for bp_idx, e in pairs(bp_map) do
		if not e.valid or bp_check[bp_idx] ~= e.name then return end -- abort on mismatch
		if e.name == 'mlc' then bp_mlc_uids[bp_idx] = e.unit_number end
		bp_check[bp_idx] = nil
	end
	if next(bp_check) then return end -- not all bp entities are in the mapping
	return bp_mlc_uids
end

local function on_setup_blueprint(ev)
	local p = game.players[ev.player_index]
	if not (p and p.valid) then return end

	local bp = p.blueprint_to_setup
	if not (bp and bp.valid_for_read) then bp = p.cursor_stack end
	if not (bp and bp.valid_for_read and bp.is_blueprint)
		then return console_warn( p, 'BUG: Failed to detect blueprint'..
			' item/info, Moon Logic Combinator code (if any) WILL NOT be stored there' ) end

	local bp_es = bp.get_blueprint_entities()
	if not bp_es then return end -- tiles-only blueprint, no mlcs
	local bp_map = ev.mapping.valid and ev.mapping.get() or {}
	local bp_mlc_uids = blueprint_map_validate(bp_es, bp_map) -- try using ev.mapping first
	if not bp_mlc_uids then -- fallback - map entities via blueprint_match_position
		-- Entity name filters are not used because both ghost/real entities must be matched
		local map_es = p.surface.find_entities(ev.area)
		bp_mlc_uids = blueprint_match_positions(bp_es, map_es)
	end
	if not bp_mlc_uids then return console_warn( p, 'BUG: Failed to match blueprint'..
		' entities to ones on the map, combinator settings WILL NOT be stored in this blueprint!' ) end

	for bp_idx, uid in pairs(bp_mlc_uids) do
		bp.set_blueprint_entity_tag(bp_idx, 'mlc_code', storage.combinators[uid].code)
    bp.set_blueprint_entity_tag(bp_idx, 'task', storage.combinators[uid].task)
    bp.set_blueprint_entity_tag(bp_idx, 'description', storage.combinators[uid].description)
  end
end

script.on_event(defines.events.on_player_setup_blueprint, on_setup_blueprint)

local function on_built(ev)
	local e = ev.created_entity or ev.entity -- latter for revive event
	if not e.valid then return end
	local mlc = out_wire_connect_mlc{e=e}
	storage.combinators[e.unit_number] = mlc

	-- Blueprints - try to restore settings from tags stored there on setup,
	--  or fallback to old method with uid stored in a constant for simple copy-paste if tags fail
	if ev.tags and ev.tags.mlc_code then
    mlc.code = ev.tags.mlc_code
    mlc.task = ev.tags.task
    mlc.description = ev.tags.description
	else
		local ecc_params = e.get_or_create_control_behavior().parameters
		local uid_src = ecc_params.first_constant or 0
		if uid_src < 0 then uid_src = uid_src + 0x100000000 end -- int -> uint conversion
		if uid_src ~= 0 then
			local mlc_src = storage.combinators[uid_src]
			if mlc_src then 
				mlc.code = mlc_src.code
				mlc.task = mlc_src.task
				mlc.description = mlc_src.description
			else
				mlc.code = ('-- No code was stored in blueprint and'..
					' Moon Logic [%s] is unavailable for OTA code update'):format(uid_src) end
	end end
end

script.on_event(defines.events.on_built_entity, on_built, mlc_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, mlc_filter)
script.on_event(defines.events.on_space_platform_built_entity, on_built, mlc_filter)
script.on_event(defines.events.script_raised_built, on_built, mlc_filter)
script.on_event(defines.events.script_raised_revive, on_built, mlc_filter)

local function on_entity_copy(ev)
	if ev.destination.name == 'mlc-core' then return ev.destination.destroy() end -- for clone event
	if not (ev.source.name == 'mlc' and ev.destination.name == 'mlc') then return end
	local uid_src, uid_dst = ev.source.unit_number, ev.destination.unit_number
	local mlc_old_outs = storage.combinators[uid_dst]
	init.mlc_remove(uid_dst, true)
	if mlc_old_outs
		then mlc_old_outs = {mlc_old_outs.out_red, mlc_old_outs.out_green}
		-- For cloned entities, mlc-core's might not yet exist - create/register them here, remove clones above
		-- It'd give zero-outputs for one tick, but probably not an issue, easier to handle it like this
		else mlc_old_outs = {out_wire_connect_both(ev.destination)} end
	storage.combinators[uid_dst] = util.deep_copy(storage.combinators[uid_src])
	local mlc_dst, mlc_src = storage.combinators[uid_dst], storage.combinators[uid_src]
	mlc_dst.e, mlc_dst.next_tick, mlc_dst.core = ev.destination, 0, nil
	mlc_dst.out_red, mlc_dst.out_green = table.unpack(mlc_old_outs)
end

script.on_event(
	defines.events.on_entity_cloned, on_entity_copy, -- can be tested via clone in /editor
	{{filter='name', name='mlc'}, {filter='name', name='mlc-core'}} )
script.on_event(defines.events.on_entity_settings_pasted, on_entity_copy)

local function on_destroyed(ev) init.mlc_remove(ev.entity.unit_number) end
local function on_mined(ev) init.mlc_remove(ev.entity.unit_number, nil, true) end

script.on_event(defines.events.on_pre_player_mined_item, on_mined, mlc_filter)
script.on_event(defines.events.on_robot_pre_mined, on_mined, mlc_filter)
script.on_event(defines.events.on_entity_died, on_destroyed, mlc_filter)
script.on_event(defines.events.script_raised_destroy, on_destroyed, mlc_filter)


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
						conf.get_wire_label(k), icon, sig, v ) }
				label.style.font_color = color
				label.tags = {signal=sig}
		::skip:: end end

		-- Outputs
		mlc_out, mlc_out_idx, mlc_out_err = {}, {}, util.shallow_copy((memory.combinators[uid] or {})._out or {})
		for k, cb in pairs{red=mlc.out_red, green=mlc.out_green} do
			cb = cb.get_control_behavior()
			for _, cbs in pairs(cb.sections[1].filters or {}) do
				sig, label = cbs.value.name, conf.get_wire_label(k)
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
					caption=('[out/%s] %s%s = %s'):format(conf.get_wire_label(k), label, sig, val[k] or 0) }
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

	if mlc.e.energy < conf.energy_fail_level then
		mlc.state = 'no-power'
		update.mlc_update_led(mlc, mlc_env)
		mlc.next_tick = game.tick + conf.energy_fail_delay
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
	if delay > conf.led_sleep_min then mlc.state = 'sleep' end
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
		if not mlc_env then mlc_env = init.mlc_init(mlc.e) end
		if not ( mlc_env and mlc.e.valid
				and mlc.out_red.valid and mlc.out_green.valid )
			then init.mlc_remove(uid); goto skip end

		local err_msg = format_mlc_err_msg(mlc)
		if err_msg then
			if tick % conf.logic_alert_interval == 0
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

	if next(storage.guis)
			and game.tick % conf.gui_signals_update_interval == 0
		then update_signals_in_guis() end
end

event_handler.add_handler(defines.events.on_tick, on_tick)

event_handler.add_handler(constants.events.on_task_request_completed, function(event)
  -- check if response starts with error
  --if event.response:sub(1, 5) == "ERROR" then
--    game.print("Error in task response: " .. event.response)
    --return
  --end
  
  -- Complete the AI operation using the new manager
  ai_operation_manager.complete_operation(event.uid)
  
  guis.save_code(event.uid, event.response)
end)

event_handler.add_handler(constants.events.on_test_generation_completed, function(event)
  -- Complete the AI operation using the new manager
  ai_operation_manager.complete_operation(event.uid)
end)


-- ----- GUI events and entity interactions -----

function load_code_from_gui(code, uid, source_type) -- note: in global _ENV, used from gui.lua
	local mlc, mlc_env = storage.combinators[uid], memory.combinators[uid]
	if not ( mlc and mlc.e.valid
			and mlc.out_red.valid and mlc.out_green.valid )
		then return init.mlc_remove(uid) end
	
	-- Initialize code history if not present
	if not mlc.code_history then
		mlc.code_history = {}
		mlc.code_history_index = 0
	end
	
	-- Only add to history if code is different from current
	local new_code = code or ''
	if new_code ~= (mlc.code or '') then
		-- Add current code to history before changing it
		if mlc.code and mlc.code ~= '' then
			table.insert(mlc.code_history, {
				code = mlc.code,
				timestamp = game.tick,
				source = mlc.last_code_source or "manual",
				previous_source = mlc.last_code_source
			})
		end
		
		-- Limit history size to last 20 versions
		if #mlc.code_history > 20 then
			table.remove(mlc.code_history, 1)
		end
		
		-- Reset history index to current (latest) position
		mlc.code_history_index = #mlc.code_history + 1
		
		-- Track the source of this code change
		mlc.last_code_source = source_type or "manual"
	end
	
	mlc.code = new_code
	if not mlc_env then return init.mlc_init(mlc.e) end
	update.mlc_update_code(mlc, mlc_env, memory.combinator_env[mlc_env._uid])
	if not mlc.err_parse then
		for _, player in pairs(game.players)
			do player.remove_alert{entity=mlc_env._e}
    end
	end
end

function clear_outputs_from_gui(uid) -- note: in global _ENV, used from gui.lua
	local mlc, mlc_env = storage.combinators[uid], memory.combinators[uid]
	if not (mlc and mlc_env) then return end
	circuit_network.cn_output_table_replace(mlc_env._out)
	update.mlc_update_output(mlc, mlc_env._out)
end

script.on_event(defines.events.on_gui_opened, function(ev)
	if not ev.entity then return end
	local player = game.players[ev.player_index]
	local e = player.opened
	if not (e and e.name == 'mlc') then return end
	if not storage.combinators[e.unit_number] then
		player.opened = nil
		return console_warn(player, 'BUG: Combinator #'..e.unit_number..' is not registered with mod code')
	end
	local gui_t = storage.guis[e.unit_number]
	if not gui_t then guis.open(player, e)
	else
		e = game.players[gui_t.mlc_gui.player_index or 0]
		e = e and e.name or 'Another player'
		player.print(e..' already opened this combinator', {1,1,0})
	end
end)

-- ----- Keyboard editing hotkeys -----
-- Most editing hotkeys only work if one window is opened,
--  as I don't know how to check which one is focused otherwise.
-- Keybindings don't work in general when text-box element is focused.

local function get_active_gui()
	local uid, gui_t
	for uid_chk, gui_t_chk in pairs(storage.guis) do
		if not uid
			then uid, gui_t = uid_chk, gui_t_chk
			else uid, gui_t = nil; break end
	end
	return uid, gui_t
end

script.on_event('mlc-code-save', function(ev)
	local uid, gui_t = get_active_gui()
	if uid then guis.save_code(uid) end
end)

script.on_event('mlc-code-commit', function(ev)
	local uid, gui_t = next(storage.guis)
	if not uid then return end
	guis.save_code(uid)
	guis.close(uid)
end)

script.on_event('mlc-code-close', function(ev)
	guis.vars_window_toggle(ev.player_index, false)
	help_dialog.show(ev.player_index, false)
	local uid, gui_t = next(storage.guis)
	if not uid then return end
	guis.close(uid)
end)

script.on_event('mlc-code-vars', function(ev)
	guis.vars_window_toggle(ev.player_index)
end)

script.on_event('mlc-open-gui', function(ev)
	local player = game.players[ev.player_index]
	local e = player.selected
	if e and e.name == 'mlc' then player.opened = e end
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

script.on_load(function()
	-- Check if AI bridge is available when mod is loaded
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
  if (payload.uid or 0) ~= 999999 then
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

