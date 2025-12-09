-- src/ai_combinator/update.lua
local util = require('src/core/utils')
local cn = require('src/core/circuit_network')
local constants = require('src/core/constants')

local update = {}

local error_signal = {type='virtual', name='ai-combinator-error'}

function update.update_output(combinator, output_raw)
	-- Sets signal outputs on invisible ai-combinator-core combinators to visible outputs
	local signals, errors, output = {red={}, green={}}, {}, {}
	for k, v in pairs(output_raw) do output[tostring(k)] = v end

	local sig_err, sig, st, err, pre, pre_label = util.shallow_copy(output)
	for _, k in ipairs{false, 'red', 'green'} do
		st = signals[k] and {signals[k]} or {signals.red, signals.green}
		if not k then pre, pre_label = '^.+$', '^.+$'
			else pre, pre_label = '^'..k..'/(.+)$', '^'..constants.get_wire_label(k)..'/(.+)$' end
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
		ps, ecc = {}, combinator['out_'..k].get_or_create_control_behavior()
		if not (ecc and ecc.valid) then goto skip end
		n = 1
		for sig, v in pairs(signals[k]) do
			local signal, quality = cn.cn_sig_quality(sig)
			ps[n] = {value={name = "", quality = "", type = ""}, min=v}
			ps[n].value.name = storage.signals[signal].name
			ps[n].value.type = storage.signals[signal].type
			ps[n].value.quality = quality or "normal"
			n = n + 1
		end
		ecc.enabled = true
		ecc.get_section(1).filters = ps
	::skip:: end

	if next(errors) then combinator.err_out = table.concat(errors, ', ') end
end

function update.update_led(combinator, combinator_env)
	-- This should set state in a way that doesn't actually produce any signals
	-- Combinator is not considered 'active', as it ends up with 0 value, unless it's ai-combinator-error
	-- It's possible to have it output value and cancel it out, but shows-up on ALT-display
	-- First constant on the combinator encodes its uid value, as a fallback to copy code in blueprints
	if combinator.state == combinator_env._state then return end
	local st, cb = combinator.state, combinator.e.get_or_create_control_behavior()
	if not (cb and cb.valid) then return end

	local op, a, b, out = '*', combinator_env._uid, 0, nil
	-- uid is uint, signal is int (signed), so must be negative if >=2^31
	if a >= constants.INT32_SIGN_BIT then a = a - constants.INT32_TO_UINT32_OFFSET end
	if not st then op = '*'
	elseif st == 'run' then op = '%'
	elseif st == 'sleep' then op = '-'
	elseif st == 'no-power' then op = '^'
	elseif st == 'error' then op, b, out = '+', 1 - a, error_signal end -- shown with ALT
	combinator_env._state, cb.parameters = st, {
		operation=op, first_signal=nil, second_signal=nil,
		first_constant=a, second_constant=b, output_signal=out }
end

-- Formats Lua error messages into more readable format
-- Transforms: '[string "@combinator"]:15: attempt to index field...' into 'Line 15: attempt to index field...'
function update.format_lua_error(err)
	if not err then return nil end
	-- Match patterns like: [string "@combinator"]:15: message  or  @combinator:15: message
	local line, msg = err:match('%]?:(%d+):%s*(.+)$')
	if line and msg then
		return ('Line %s: %s'):format(line, msg)
	end
	-- If no line number found, just clean up the chunk name prefix
	local cleaned = err:gsub('^%[string ".-"%]:%s*', ''):gsub('^@%S+:%s*', '')
	return cleaned ~= '' and cleaned or err
end

function update.update_code(combinator, combinator_env, lua_env)
	combinator.next_tick, combinator.state, combinator.err_parse, combinator.err_run, combinator.err_out = 0, nil, nil, nil, nil
	
	-- Clear internal 'var' variables to avoid inconsistent state with new code
	if combinator.vars and combinator.vars.var then
		for k in pairs(combinator.vars.var) do
			combinator.vars.var[k] = nil
		end
	end
	
	local code, err = (combinator.code or ''), nil
	if code:match('^%s*(.-)%s*$') ~= '' then -- Check if not just whitespace
		combinator_env._func, err = load(code, '@combinator', 't', lua_env)
		if not combinator_env._func then combinator.err_parse, combinator.state = update.format_lua_error(err), 'error' end
	else
		combinator_env._func = nil
		cn.cn_output_table_replace(combinator_env._out)
		update.update_output(combinator, combinator_env._out)
	end
	update.update_led(combinator, combinator_env)
end

return update
