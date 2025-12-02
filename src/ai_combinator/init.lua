-- src/ai_combinator/init.lua
local util = require('src/core/utils')
local cn = require('src/core/circuit_network')
local constants = require('src/core/constants')
local sandbox = require('src/sandbox/base')
local update = require('src/ai_combinator/update')
local memory = require('src/ai_combinator/memory')

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
		name='ai-combinator-core', position=e.position,
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

-- Export for use in control.lua
init.out_wire_connect_both = out_wire_connect_both

function init.out_wire_clear_combinator(combinator)
	for _, e in ipairs{'core', 'out_red', 'out_green'} do
		e, combinator[e] = combinator[e]
		if e and e.valid then e.destroy() end
	end
	return combinator
end
function init.out_wire_connect_combinator(combinator)
	init.out_wire_clear_combinator(combinator)
	combinator.out_red, combinator.out_green = out_wire_connect_both(combinator.e)
	return combinator
end

local function combinator_log(...) log(...) end -- to avoid logging func code

function init.combinator_init(e)
	-- Inits *local* combinator_env state for combinator - builds env, evals lua code, etc
	-- *storage* (previously `global`) state will be used for init values if it exists, otherwise empty defaults
	-- Lua env for code is composed from: sandbox.env_base + local combinator_env proxies + global (storage) combinator.vars
	if not e.valid then return end
	local uid = e.unit_number
	if memory.combinators[uid] then error('Double-init for existing combinator unit_number') end
	memory.combinators[uid] = {} -- some state (e.g. loaded func) has to be local
	if not storage.combinators[uid] then storage.combinators[uid] = {e=e} end
	local combinator_env, combinator = memory.combinators[uid], storage.combinators[uid]

	combinator.output, combinator.vars = combinator.output or {}, combinator.vars or {}
	combinator_env._e, combinator_env._uid, combinator_env._out = e, uid, combinator.output

	local env_wire_red = {
		_e=combinator_env._e, _wire='red', _debug=false, _out=combinator_env._out,
		_iter=cn.cn_input_signal_iter, _cache={}, _cache_tick=-1 }
	local env_wire_green = util.shallow_copy(env_wire_red)
	env_wire_green._wire = 'green'

	local env_ro = { -- sandbox.env_base + combinator_env proxies
		uid = combinator_env._uid,
		out = setmetatable( combinator_env._out,
			{__index=cn.cn_output_table_value, __len=cn.cn_output_table_len} ),
		red = setmetatable(env_wire_red, {
			__serialize=cn.cn_input_signal_table_serialize, __len=cn.cn_input_signal_len,
			__index=cn.cn_input_signal_get, __newindex=cn.cn_input_signal_set }),
		green = setmetatable(env_wire_green, {
			__serialize=cn.cn_input_signal_table_serialize, __len=cn.cn_input_signal_len,
			__index=cn.cn_input_signal_get, __newindex=cn.cn_input_signal_set }) }
	env_ro[constants.RED_WIRE_NAME] = env_ro.red
	env_ro[constants.GREEN_WIRE_NAME] = env_ro.green
	setmetatable(env_ro, {__index=sandbox.env_base})

	if not combinator.vars.var then combinator.vars.var = {} end
	local env = setmetatable(combinator.vars, { -- env_ro + combinator.vars
		__index=env_ro, __newindex=function(vars, k, v)
			if k == 'out' then
				cn.cn_output_table_replace(env_ro.out, v)
				rawset(env_wire_red, '_debug', v)
				rawset(env_wire_green, '_debug', v)
			else rawset(vars, k, v) end end })

	combinator_env.debug_wires_set = function(v)
		local v_prev = rawget(env_wire_red, '_debug')
		rawset(env_wire_red, '_debug', v or false)
		rawset(env_wire_green, '_debug', v or false)
		return v_prev end

	-- Migration from pre-0.0.52 to separate wire outputs
	if combinator.core then init.out_wire_connect_combinator(combinator) end

	memory.combinator_env[uid] = env
	update.update_code(combinator, combinator_env, env)
	return combinator_env
end

function init.combinator_remove(uid, keep_entities, to_be_mined)
	-- Close any open GUI for this combinator directly (avoiding circular dependency with gui.lua)
	local gui_t = storage.guis[uid]
	local gui = gui_t and gui_t.gui
	if gui then gui.destroy() end
	storage.guis[uid] = nil
	
	if not keep_entities then
		local combinator = init.out_wire_clear_combinator(storage.combinators[uid] or {})
		if not to_be_mined and combinator.e and combinator.e.valid then combinator.e.destroy() end
	end
	memory.combinators[uid], memory.combinator_env[uid] = nil, nil

  if not storage.combinators[uid].removed_by_player then -- Keep combinator data for possible restore on redo
    storage.combinators[uid] = nil
  end
end

return init
