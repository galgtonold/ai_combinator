-- src/events/blueprint_events.lua
-- Handles blueprint setup and entity tag serialization for AI combinators

local util = require('src/core/utils')
local blueprint_serialization = require('src/core/blueprint_serialization')

local blueprint_events = {}

--- Match blueprint entities to map entities by position
-- Hack to work around invalidated ev.mapping - match entities by x/y position
-- Same idea as in https://forums.factorio.com/viewtopic.php?p=466734
-- but x/y in blueprints seem to be absolute in current factorio, not offset from center
---@param bp_es table Blueprint entities
---@param map_es table Map entities
---@return table|nil bp_combinator_uids Mapping of blueprint entity number to combinator unit number
local function blueprint_match_positions(bp_es, map_es)
	local bp_combinators, bp_combinator_uids, be, k = {}, {}, nil, nil
	for _, e in ipairs(bp_es) do 
		if e.name == 'ai-combinator' then 
			bp_combinators[e.position.x..'_'..e.position.y] = e 
		end 
	end
	if not next(bp_combinators) then return bp_combinator_uids end -- no combinators in blueprint
	for _, e in ipairs(map_es) do
		if not (e.valid and ( e.name == 'ai-combinator'
				or (e.name == 'entity-ghost' and e.ghost_name == 'ai-combinator') ))
			then goto skip end
		k = e.position.x..'_'..e.position.y
		be, bp_combinators[k] = bp_combinators[k]
		if not be or e.name == 'entity-ghost' then goto skip end -- ghosts have tags already
		bp_combinator_uids[be.entity_number] = e.unit_number
	::skip:: end
	if next(bp_combinators) then return end -- blueprint entities left unmapped
	return bp_combinator_uids
end

--- Validate blueprint entity mapping
-- Blueprint ev.mapping can be invalidated by other mods acting on this event, so checked first
-- See https://forums.factorio.com/viewtopic.php?p=457054#p457054 for more details
---@param bp_es table Blueprint entities
---@param bp_map table Blueprint mapping from event
---@return table|nil bp_combinator_uids Mapping of blueprint entity number to combinator unit number
local function blueprint_map_validate(bp_es, bp_map)
	local bp_check, bp_combinator_uids = {}, {}
	for _, e in ipairs(bp_es) do bp_check[e.entity_number] = e.name end
	for bp_idx, e in pairs(bp_map) do
		if not e.valid or bp_check[bp_idx] ~= e.name then return end -- abort on mismatch
		if e.name == 'ai-combinator' then bp_combinator_uids[bp_idx] = e.unit_number end
		bp_check[bp_idx] = nil
	end
	if next(bp_check) then return end -- not all bp entities are in the mapping
	return bp_combinator_uids
end

--- Handle blueprint setup event - store combinator settings in blueprint tags
---@param ev EventData Event data from on_player_setup_blueprint
function blueprint_events.on_setup_blueprint(ev)
	---@diagnostic disable-next-line: undefined-field
	local p = game.players[ev.player_index]
	if not (p and p.valid) then return end

	local bp = p.blueprint_to_setup
	if not (bp and bp.valid_for_read) then bp = p.cursor_stack end
	if not (bp and bp.valid_for_read and bp.is_blueprint)
		then return util.console_warn( p, 'BUG: Failed to detect blueprint'..
			' item/info, AI Combinator code (if any) WILL NOT be stored there' ) end

	local bp_es = bp.get_blueprint_entities()
	if not bp_es then return end -- tiles-only blueprint, no combinators
	---@diagnostic disable-next-line: undefined-field
	local bp_map = ev.mapping.valid and ev.mapping.get() or {}
	local bp_combinator_uids = blueprint_map_validate(bp_es, bp_map) -- try using ev.mapping first
	if not bp_combinator_uids then -- fallback - map entities via blueprint_match_position
		-- Entity name filters are not used because both ghost/real entities must be matched
		---@diagnostic disable-next-line: undefined-field
		local map_es = p.surface.find_entities(ev.area)
		bp_combinator_uids = blueprint_match_positions(bp_es, map_es)
	end
	if not bp_combinator_uids then return util.console_warn( p, 'BUG: Failed to match blueprint'..
		' entities to ones on the map, combinator settings WILL NOT be stored in this blueprint!' ) end

	for bp_idx, uid in pairs(bp_combinator_uids) do
		local combinator = storage.combinators[uid]
		if combinator then
			local tags = blueprint_serialization.serialize_combinator(combinator)
			for tag_name, tag_value in pairs(tags) do
				bp.set_blueprint_entity_tag(bp_idx, tag_name, tag_value)
			end
		end
	end
end

--- Register all blueprint-related event handlers
function blueprint_events.register()
	script.on_event(defines.events.on_player_setup_blueprint, blueprint_events.on_setup_blueprint)
end

return blueprint_events
