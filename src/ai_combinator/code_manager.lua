-- src/ai_combinator/code_manager.lua
-- Handles code loading, saving, and history management for AI combinators

local constants = require('src/core/constants')
local circuit_network = require('src/core/circuit_network')
local update = require('src/ai_combinator/update')
local memory = require('src/ai_combinator/memory')

local code_manager = {}

--- Load code into a combinator and update history
--- Returns nil on success, "remove" if combinator should be removed, "init" if needs initialization
---@param code string|nil The code to load
---@param uid number The combinator unit number
---@param source_type string|nil The source of the code change ("manual", "ai_generation", etc.)
---@return string|nil action Action needed: nil=success, "remove"=remove combinator, "init"=needs init
function code_manager.load_code(code, uid, source_type)
	local mlc, mlc_env = storage.combinators[uid], memory.combinators[uid]
	if not ( mlc and mlc.e.valid
			and mlc.out_red.valid and mlc.out_green.valid )
		then return "remove" end
	
	-- Initialize code history if not present
	if not mlc.code_history then
		mlc.code_history = {}
	end
	
	-- Only add to history if code is different from current and non-empty
	local new_code = code or ''
	if new_code ~= '' and new_code ~= (mlc.code or '') then
		-- Track the source of this code change
		mlc.last_code_source = source_type or "manual"

		-- Add the new code to history
		table.insert(mlc.code_history, {
			code = new_code,
			timestamp = game.tick,
			source = mlc.last_code_source or "manual"
		})
		
		-- Limit history size
		if #mlc.code_history > constants.MAX_CODE_HISTORY_SIZE then
			table.remove(mlc.code_history, 1)
		end
		
		-- Set history index to the latest entry
		mlc.code_history_index = #mlc.code_history
	end
	
	mlc.code = new_code
	if not mlc_env then return "init" end
	update.mlc_update_code(mlc, mlc_env, memory.combinator_env[mlc_env._uid])
	if not mlc.err_parse then
		for _, player in pairs(game.players)
			do player.remove_alert{entity=mlc_env._e}
		end
	end
	return nil
end

--- Clear all output signals from a combinator
---@param uid number The combinator unit number
function code_manager.clear_outputs(uid)
	local mlc, mlc_env = storage.combinators[uid], memory.combinators[uid]
	if not (mlc and mlc_env) then return end
	circuit_network.cn_output_table_replace(mlc_env._out)
	update.mlc_update_output(mlc, mlc_env._out)
end

return code_manager
