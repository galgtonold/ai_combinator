-- src/mlc/init.lua
local util = require('src/core/utils')
local cn = require('src/core/circuit_network')
local conf = require('src/core/config')
local sandbox = require('src/sandbox/base')
local update = require('src/ai_combinator/update')
local memory = require('src/ai_combinator/memory')
local guis = require('src/gui/gui')

local init = {}

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
function init.out_wire_clear_mlc(mlc)
	for _, e in ipairs{'core', 'out_red', 'out_green'} do
		e, mlc[e] = mlc[e]
		if e and e.valid then e.destroy() end
	end
	return mlc
end
function init.out_wire_connect_mlc(mlc)
	init.out_wire_clear_mlc(mlc)
	mlc.out_red, mlc.out_green = out_wire_connect_both(mlc.e)
	return mlc
end

local function mlc_log(...) log(...) end -- to avoid logging func code

function init.mlc_init(e)
	-- Inits *local* mlc_env state for combinator - builds env, evals lua code, etc
	-- *storage* (previously `global`) state will be used for init values if it exists, otherwise empty defaults
	-- Lua env for code is composed from: sandbox.env_base + local mlc_env proxies + global (storage) mlc.vars
	if not e.valid then return end
	local uid = e.unit_number
	if memory.combinators[uid] then error('Double-init for existing combinator unit_number') end
	memory.combinators[uid] = {} -- some state (e.g. loaded func) has to be local
	if not storage.combinators[uid] then storage.combinators[uid] = {e=e} end
	local mlc_env, mlc = memory.combinators[uid], storage.combinators[uid]

	mlc.output, mlc.vars = mlc.output or {}, mlc.vars or {}
	mlc_env._e, mlc_env._uid, mlc_env._out = e, uid, mlc.output

	local env_wire_red = {
		_e=mlc_env._e, _wire='red', _debug=false, _out=mlc_env._out,
		_iter=cn.cn_input_signal_iter, _cache={}, _cache_tick=-1 }
	local env_wire_green = util.shallow_copy(env_wire_red)
	env_wire_green._wire = 'green'

	local env_ro = { -- sandbox.env_base + mlc_env proxies
		uid = mlc_env._uid,
		out = setmetatable( mlc_env._out,
			{__index=cn.cn_output_table_value, __len=cn.cn_output_table_len} ),
		red = setmetatable(env_wire_red, {
			__serialize=cn.cn_input_signal_table_serialize, __len=cn.cn_input_signal_len,
			__index=cn.cn_input_signal_get, __newindex=cn.cn_input_signal_set }),
		green = setmetatable(env_wire_green, {
			__serialize=cn.cn_input_signal_table_serialize, __len=cn.cn_input_signal_len,
			__index=cn.cn_input_signal_get, __newindex=cn.cn_input_signal_set }) }
	env_ro[conf.red_wire_name] = env_ro.red
	env_ro[conf.green_wire_name] = env_ro.green
	setmetatable(env_ro, {__index=sandbox.env_base})

	if not mlc.vars.var then mlc.vars.var = {} end
	local env = setmetatable(mlc.vars, { -- env_ro + mlc.vars
		__index=env_ro, __newindex=function(vars, k, v)
			if k == 'out' then
				cn.cn_output_table_replace(env_ro.out, v)
				rawset(env_wire_red, '_debug', v)
				rawset(env_wire_green, '_debug', v)
			else rawset(vars, k, v) end end })

	mlc_env.debug_wires_set = function(v)
		local v_prev = rawget(env_wire_red, '_debug')
		rawset(env_wire_red, '_debug', v or false)
		rawset(env_wire_green, '_debug', v or false)
		return v_prev end

	-- Migration from pre-0.0.52 to separate wire outputs
	if mlc.core then init.out_wire_connect_mlc(mlc) end

	memory.combinator_env[uid] = env
	update.mlc_update_code(mlc, mlc_env, env)
	return mlc_env
end

function init.mlc_remove(uid, keep_entities, to_be_mined)
	guis.close(uid)
	if not keep_entities then
		local mlc = init.out_wire_clear_mlc(storage.combinators[uid] or {})
		if not to_be_mined and mlc.e and mlc.e.valid then mlc.e.destroy() end
	end
	memory.combinators[uid], memory.combinator_env[uid], storage.combinators[uid], storage.guis[uid] = nil, nil, nil, nil
end

return init
