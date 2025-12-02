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
local runtime = require('src/ai_combinator/runtime')
local gui_updater = require('src/gui/gui_updater')


-- ----- AI Combinator update processing -----

local error_signal = {type='virtual', name='ai-combinator-error'}

-- ----- Register entity and blueprint event handlers -----

blueprint_events.register()
entity_events.register()
hotkey_events.register()


-- ----- on_tick handling - lua code, gui updates -----

local function on_tick(ev)
  -- Receive UDP packets and trigger processing
  helpers.recv_udp()


	local tick = ev.tick

	for uid, combinator in pairs(storage.combinators) do
		local combinator_env = memory.combinators[uid]
		if not combinator_env then
      combinator_env = init.combinator_init(combinator.e)
    end
    if combinator.removed_by_player then -- if it was removed by the user, keep it so it can be restored from undo
      goto skip
    end
		if not (combinator_env and combinator.e.valid and combinator.out_red.valid and combinator.out_green.valid) then
        init.combinator_remove(uid)
        goto skip
    end

		local err_msg = runtime.format_error_message(combinator)
		if err_msg then
			if tick % constants.LOGIC_ALERT_INTERVAL == 0
				then runtime.alert_about_error(combinator_env, err_msg) end
			goto skip -- suspend combinator logic until errors are addressed
		elseif combinator_env._alert then runtime.alert_clear(combinator_env) end

		if combinator.irq and (combinator.irq_tick or 0) < tick - (combinator.irq_delay or 0)
				and combinator.e.get_signal(combinator.irq, defines.wire_connector_id.combinator_input_green, defines.wire_connector_id.combinator_input_red) ~= 0 then
      combinator.irq_tick = tick
      combinator.next_tick = nil
    end
		if tick >= (combinator.next_tick or 0) and combinator_env._func then
			runtime.run_combinator_tick(combinator, combinator_env, tick)
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
        gui_updater.update_signals_in_guis(runtime.format_error_message) 
    end
end

event_handler.add_handler(defines.events.on_tick, on_tick)

event_handler.add_handler(constants.events.on_task_request_completed, function(event)
  -- Complete the AI operation using the new manager
  ai_operation_manager.complete_operation(event.uid)
  
  -- Check if response starts with ERROR:
  if event.response and event.response:sub(1, 6) == "ERROR:" then
    local combinator = storage.combinators[event.uid]
    local combinator_env = memory.combinators[event.uid]
    if combinator and combinator_env then
      -- Extract the error message after "ERROR: "
      local error_message = event.response:sub(8) -- Skip "ERROR: "
      combinator.state = "error"
      combinator.err_parse = "AI Error: " .. error_message
      
      -- Update the LED to show error state
      update.update_led(combinator, combinator_env)
      
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
	if not (e and e.name == 'ai-combinator') then return end
	if not storage.combinators[e.unit_number] then
		player.opened = nil
		return util.console_warn(player, 'BUG: Combinator #'..e.unit_number..' is not registered with mod code')
	end
	local gui_t = storage.guis[e.unit_number]
	if not gui_t then guis.open(player, e)
	else
		e = game.players[gui_t.gui.player_index or 0]
		e = e and e.name or 'Another player'
		player.print(e..' already opened this combinator', {1,1,0})
	end
end)


-- ----- Remote Interface for /measured-command benchmarking -----
-- Usage: /measured-command remote.call('ai-combinator', 'run', 1234, 100)

local remote_err = function(msg, ...) for n, p in pairs(game.players)
	do p.print(('AI Combinator remote-call error: '..msg):format(...), {1,1,0}) end end
remote.add_interface('ai-combinator', {run = function(uid_raw, count)
	local uid = tonumber(uid_raw)
	local combinator, combinator_env = storage.combinators[uid], memory.combinators[uid]
	if not combinator or not combinator_env then
		return remote_err('cannot find combinator with uid=%s', uid_raw) end
	local err_n, st, err, err_last = 0
	for n = 1, tonumber(count) or 1 do
		st, err = pcall(combinator_env._func)
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
		if force.technologies['ai-combinator'].researched then
			force.recipes['ai-combinator'].enabled = true
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

