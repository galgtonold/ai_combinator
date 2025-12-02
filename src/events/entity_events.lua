-- src/events/entity_events.lua
-- Handles entity build, destroy, copy, and clone events for AI combinators

local constants = require('src/core/constants')
local init = require('src/ai_combinator/init')
local util = require('src/core/utils')
local blueprint_serialization = require('src/core/blueprint_serialization')

local entity_events = {}

-- Entity filter for MLC combinators
local MLC_FILTER = { { filter = 'name', name = 'mlc' } }
local MLC_CORE_FILTER = {{filter='name', name='mlc'}, {filter='name', name='mlc-core'}}

--- Handle entity built event - initialize new combinator
---@param ev EventData Event data
function entity_events.on_built(ev)
	local e = ev.created_entity or ev.entity -- latter for revive event
	if not e.valid then return end
	local mlc = init.out_wire_connect_mlc{e=e}
	
	-- Merge with default combinator structure while preserving existing fields
	local default_mlc = blueprint_serialization.create_default_combinator(e)
	mlc = blueprint_serialization.merge_combinator_data(mlc, default_mlc)
	
	storage.combinators[e.unit_number] = mlc

	-- Blueprints - try to restore settings from tags stored there on setup,
	-- or fallback to old method with uid stored in a constant for simple copy-paste if tags fail
	if ev.tags then
		local deserialized_data = blueprint_serialization.deserialize_combinator(ev.tags)
		mlc = blueprint_serialization.merge_combinator_data(mlc, deserialized_data)
		storage.combinators[e.unit_number] = mlc
		
		-- Refresh imported test cases to ensure they're properly evaluated
		if deserialized_data.test_cases and #deserialized_data.test_cases > 0 then
			blueprint_serialization.refresh_imported_test_cases(mlc)
		end
	else
		local ecc_params = e.get_or_create_control_behavior().parameters
		local uid_src = ecc_params.first_constant or 0
		if uid_src < 0 then uid_src = uid_src + constants.INT32_TO_UINT32_OFFSET end -- int -> uint conversion
		if uid_src ~= 0 then
			local mlc_src = storage.combinators[uid_src]
			if mlc_src then 
				local copied_data = {
					code = mlc_src.code,
					task = mlc_src.task,
					description = mlc_src.description,
					test_cases = mlc_src.test_cases,
					code_history = mlc_src.code_history,
					code_history_index = mlc_src.code_history_index,
					vars = mlc_src.vars
				}
				mlc = blueprint_serialization.merge_combinator_data(mlc, copied_data)
				storage.combinators[e.unit_number] = mlc
				
				-- Also refresh test cases when copying from another combinator
				if copied_data.test_cases and #copied_data.test_cases > 0 then
					blueprint_serialization.refresh_imported_test_cases(mlc)
				end
			else
				mlc.code = ('-- No code was stored in blueprint and'..
					' Moon Logic [%s] is unavailable for OTA code update'):format(uid_src) 
			end
		end
	end
end

--- Handle entity copy/clone event
---@param ev EventData Event data
function entity_events.on_entity_copy(ev)
	if ev.destination.name == 'mlc-core' then return ev.destination.destroy() end -- for clone event
	if not (ev.source.name == 'mlc' and ev.destination.name == 'mlc') then return end
	local uid_src, uid_dst = ev.source.unit_number, ev.destination.unit_number
	local mlc_old_outs = storage.combinators[uid_dst]
	init.mlc_remove(uid_dst, true)
	if mlc_old_outs
		then mlc_old_outs = {mlc_old_outs.out_red, mlc_old_outs.out_green}
		-- For cloned entities, mlc-core's might not yet exist - create/register them here, remove clones above
		-- It'd give zero-outputs for one tick, but probably not an issue, easier to handle it like this
		else mlc_old_outs = {init.out_wire_connect_both(ev.destination)} end
	storage.combinators[uid_dst] = util.deep_copy(storage.combinators[uid_src])
	local mlc_dst = storage.combinators[uid_dst]
	mlc_dst.e, mlc_dst.next_tick, mlc_dst.core = ev.destination, 0, nil
	mlc_dst.out_red, mlc_dst.out_green = table.unpack(mlc_old_outs)
end

--- Handle entity destroyed event
---@param ev EventData Event data
function entity_events.on_destroyed(ev)
	init.mlc_remove(ev.entity.unit_number)
end

--- Handle entity mined event
---@param ev EventData Event data
function entity_events.on_mined(ev)
	storage.combinators[ev.entity.unit_number].removed_by_player = true
	init.mlc_remove(ev.entity.unit_number, nil, true)
end

--- Register all entity-related event handlers
function entity_events.register()
	-- Build events
	script.on_event(defines.events.on_built_entity, entity_events.on_built, MLC_FILTER)
	script.on_event(defines.events.on_robot_built_entity, entity_events.on_built, MLC_FILTER)
	script.on_event(defines.events.on_space_platform_built_entity, entity_events.on_built, MLC_FILTER)
	script.on_event(defines.events.script_raised_built, entity_events.on_built, MLC_FILTER)
	script.on_event(defines.events.script_raised_revive, entity_events.on_built, MLC_FILTER)
	
	-- Copy/clone events
	script.on_event(defines.events.on_entity_cloned, entity_events.on_entity_copy, MLC_CORE_FILTER)
	script.on_event(defines.events.on_entity_settings_pasted, entity_events.on_entity_copy)
	
	-- Destroy events
	script.on_event(defines.events.on_pre_player_mined_item, entity_events.on_mined, MLC_FILTER)
	script.on_event(defines.events.on_robot_pre_mined, entity_events.on_mined, MLC_FILTER)
	script.on_event(defines.events.on_entity_died, entity_events.on_destroyed, MLC_FILTER)
	script.on_event(defines.events.script_raised_destroy, entity_events.on_destroyed, MLC_FILTER)
end

return entity_events
