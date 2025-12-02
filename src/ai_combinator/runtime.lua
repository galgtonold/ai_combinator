local constants = require('src/core/constants')
local update = require('src/ai_combinator/update')
local circuit_network = require('src/core/circuit_network')
local util = require('src/core/utils')

local runtime = {}

local error_signal = {type='virtual', name='ai-combinator-error'}

function runtime.format_error_message(combinator)
	if not (combinator.err_parse or combinator.err_run or combinator.err_out) then return end
	local err_msg = ''
	for prefix, err in pairs{ ParserError=combinator.err_parse,
			RuntimeError=combinator.err_run, OutputError=combinator.err_out } do
		if not err then goto skip end
		if err_msg ~= '' then err_msg = err_msg..' :: ' end
		err_msg = err_msg..('%s: %s'):format(prefix, err)
	::skip:: end
	return err_msg
end

function runtime.alert_about_error(combinator_env, err_msg)
	local p = combinator_env._e.last_user
	if p.valid and p.connected
		then p = {p} else p = p.force.connected_players end
	combinator_env._alert = p
	for _, p in ipairs(p) do
		p.add_custom_alert( combinator_env._e, error_signal,
			'AI Combinator Error ['..combinator_env._uid..']: '..err_msg, true )
	end
end

function runtime.alert_clear(combinator_env)
	local p = combinator_env._alert or {}
	for _, p in ipairs(p) do
		if p.valid and p.connected then p.remove_alert{icon=error_signal} end
	end
	combinator_env._alert = nil
end

function runtime.run_combinator_tick(combinator, combinator_env, tick, guis)
	-- Runs logic of the specified combinator, reading its input and setting outputs
	local out_tick, out_diff = combinator.next_tick, util.shallow_copy(combinator_env._out)
	local dbg = combinator.vars.debug and function(fmt, ...)
		log((' -- ai-combinator [%s]: %s'):format(combinator_env._uid, fmt:format(...))) end
	combinator.vars.delay, combinator.vars.var, combinator.vars.debug, combinator.vars.irq, combinator.irq = 1, combinator.vars.var or {}

	if combinator.e.energy < constants.ENERGY_FAIL_LEVEL then
		combinator.state = 'no-power'
		update.update_led(combinator, combinator_env)
		combinator.next_tick = game.tick + constants.ENERGY_FAIL_DELAY
		return
	end

	if dbg then -- debug
		dbg('--- debug-run start [tick=%s] ---', tick)
		combinator_env.debug_wires_set({})
		dbg('env-before :: %s', serpent.line(combinator.vars))
		dbg('out-before :: %s', serpent.line(combinator_env._out)) end
	combinator_env._out['ai-combinator-error'] = nil -- for internal use

	do
    -- Clear out output table before running code
    for k, _ in pairs(combinator_env._out) do
      combinator_env._out[k] = nil
    end
		local st, err = pcall(combinator_env._func)
		if not st then combinator.err_run = err or '[unspecified lua error]'
		else
			combinator.state, combinator.err_run = 'run'
			if combinator_env._out['ai-combinator-error'] ~= 0 then -- can be used to stop combinator
				combinator.err_run = 'Internal ai-combinator-error signal set'
				combinator_env._out['ai-combinator-error'] = nil -- signal will be emitted via combinator.state
			end
		end
	end

	if dbg then -- debug
		dbg('used-inputs :: %s', serpent.line(combinator_env.debug_wires_set()))
		dbg('env-after :: %s', serpent.line(combinator.vars))
		dbg('out-after :: %s', serpent.line(combinator_env._out)) end

	local delay = tonumber(combinator.vars.delay) or 1
	if delay > constants.LED_SLEEP_MIN then combinator.state = 'sleep' end
	combinator.next_tick = tick + delay

	local sig = combinator.vars.irq
	if sig then
		sig = circuit_network.cn_sig(sig)
		if sig then combinator.irq, combinator.irq_delay = sig, tonumber(combinator.vars.irq_min_interval) else
			combinator.err_run = ('Unknown/ambiguous "irq" signal: %s'):format(serpent.line(combinator.vars.irq)) end
	end

	for sig, v in pairs(combinator_env._out) do
		if out_diff[sig] ~= v then out_diff[sig] = v
		else out_diff[sig] = nil end
	end
	local out_sync = next(out_diff) or out_tick == 0 -- force sync after reset

	if dbg then -- debug
		for sig, v in pairs(out_diff) do
			if not combinator_env._out[sig] then out_diff[sig] = '-'
		end end
		dbg('out-sync=%s out-diff :: %s', out_sync and true, serpent.line(out_diff)) end

	if out_sync then update.update_output(combinator, combinator_env._out) end

	local err_msg = runtime.format_error_message(combinator)
	if err_msg then
		combinator.state = 'error'
		if dbg then dbg('error :: %s', err_msg) end -- debug
		runtime.alert_about_error(combinator_env, err_msg)
	end

	if dbg then dbg('--- debug-run end [tick=%s] ---', tick) end -- debug
	update.update_led(combinator, combinator_env)

	if combinator.vars.ota_update_from_uid then
		local combinator_src = combinator.vars.ota_update_from_uid
		combinator_src = combinator_src ~= combinator_env._uid and
			storage.combinators[combinator.vars.ota_update_from_uid]
		if combinator_src and combinator_src.code ~= combinator.code
			then guis.save_code(combinator_env._uid, combinator_src.code) end
		combinator.vars.ota_update_from_uid = nil
	end
end

return runtime
