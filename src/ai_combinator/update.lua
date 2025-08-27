-- src/mlc/update.lua
local util = require('src/core/utils')
local cn = require('src/core/circuit_network')
local conf = require('src/core/config')

local update = {}

local mlc_err_sig = {type='virtual', name='mlc-error'}

function update.mlc_update_output(mlc, output_raw)
	-- Sets signal outputs on invisible mlc-core combinators to visible outputs
	local signals, errors, output = {red={}, green={}}, {}, {}
	for k, v in pairs(output_raw) do output[tostring(k)] = v end

	local sig_err, sig, st, err, pre, pre_label = util.shallow_copy(output)
	for _, k in ipairs{false, 'red', 'green'} do
		st = signals[k] and {signals[k]} or {signals.red, signals.green}
		if not k then pre, pre_label = '^.+$', '^.+$'
			else pre, pre_label = '^'..k..'/(.+)$', '^'..conf.get_wire_label(k)..'/(.+)$' end
		for k, v in pairs(output) do
			sig, err = cn.cn_sig(k:match(pre) or k:match(pre_label))
			if not sig then goto skip end
			sig_err[k] = nil
			if type(v) == 'boolean' then v = v and 1 or 0
			elseif type(v) ~= 'number' then
				err = ('signal must be a number [%s=(%s) %s]'):format(sig.name, type(v), v)
			elseif not (v >= -2147483648 and v <= 2147483647) then
				err = ('signal value out of range [%s=%s]'):format(sig.name, v) end
			if err then table.insert(errors, err); goto skip end
			for _, sig_table in ipairs(st) do sig_table[cn.cn_sig_str(sig)] = v end
	::skip:: end end
	for sig, _ in pairs(sig_err)
		do table.insert(errors, ('unknown signal [%s]'):format(sig)) end

	local ps, ecc, n
	for _, k in ipairs{'red', 'green'} do
		ps, ecc = {}, mlc['out_'..k].get_or_create_control_behavior()
		if not (ecc and ecc.valid) then goto skip end
		n = 1
		for sig, v in pairs(signals[k]) do
			local qname = ""
			sig,qname = cn.cn_sig_quality(sig)
			ps[n] = {value={name = "", quality = "", type = ""}, min=v}
			ps[n].value.name = storage.signals[sig].name
			ps[n].value.type = storage.signals[sig].type
			ps[n].value.quality = qname or "normal"
			n = n + 1
		end
		ecc.enabled = true
		ecc.get_section(1).filters = ps
	::skip:: end

	if next(errors) then mlc.err_out = table.concat(errors, ', ') end
end

function update.mlc_update_led(mlc, mlc_env)
	-- This should set state in a way that doesn't actually produce any signals
	-- Combinator is not considered 'active', as it ends up with 0 value, unless it's mlc-error
	-- It's possible to have it output value and cancel it out, but shows-up on ALT-display
	-- First constant on the combinator encodes its uid value, as a fallback to copy code in blueprints
	if mlc.state == mlc_env._state then return end
	local st, cb = mlc.state, mlc.e.get_or_create_control_behavior()
	if not (cb and cb.valid) then return end

	local op, a, b, out = '*', mlc_env._uid, 0
	-- uid is uint, signal is int (signed), so must be negative if >=2^31
	if a >= 0x80000000 then a = a - 0x100000000 end
	if not st then op = '*'
	elseif st == 'run' then op = '%'
	elseif st == 'sleep' then op = '-'
	elseif st == 'no-power' then op = '^'
	elseif st == 'error' then op, b, out = '+', 1 - a, mlc_err_sig end -- shown with ALT
	mlc_env._state, cb.parameters = st, {
		operation=op, first_signal=nil, second_signal=nil,
		first_constant=a, second_constant=b, output_signal=out }
end

function update.mlc_update_code(mlc, mlc_env, lua_env)
	mlc.next_tick, mlc.state, mlc.err_parse, mlc.err_run, mlc.err_out = 0, nil, nil, nil, nil
	local code, err = (mlc.code or '')
	if code:match('^%s*(.-)%s*$') ~= '' then -- Check if not just whitespace
		mlc_env._func, err = load(code, code, 't', lua_env)
		if not mlc_env._func then mlc.err_parse, mlc.state = err, 'error' end
	else
		mlc_env._func = nil
		cn.cn_output_table_replace(mlc_env._out)
		update.mlc_update_output(mlc, mlc_env._out)
	end
	update.mlc_update_led(mlc, mlc_env)
end

return update
