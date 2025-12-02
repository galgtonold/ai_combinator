local constants = require('src/core/constants')
local update = require('src/ai_combinator/update')
local circuit_network = require('src/core/circuit_network')
local util = require('src/core/utils')

local runtime = {}

local mlc_err_sig = {type='virtual', name='mlc-error'}

function runtime.format_mlc_err_msg(mlc)
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

function runtime.alert_about_mlc_error(mlc_env, err_msg)
	local p = mlc_env._e.last_user
	if p.valid and p.connected
		then p = {p} else p = p.force.connected_players end
	mlc_env._alert = p
	for _, p in ipairs(p) do
		p.add_custom_alert( mlc_env._e, mlc_err_sig,
			'Moon Logic Error ['..mlc_env._uid..']: '..err_msg, true )
	end
end

function runtime.alert_clear(mlc_env)
	local p = mlc_env._alert or {}
	for _, p in ipairs(p) do
		if p.valid and p.connected then p.remove_alert{icon=mlc_err_sig} end
	end
	mlc_env._alert = nil
end

function runtime.run_moon_logic_tick(mlc, mlc_env, tick, guis)
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

	local err_msg = runtime.format_mlc_err_msg(mlc)
	if err_msg then
		mlc.state = 'error'
		if dbg then dbg('error :: %s', err_msg) end -- debug
		runtime.alert_about_mlc_error(mlc_env, err_msg)
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

return runtime
