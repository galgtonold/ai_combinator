-- src/events/entity_events.lua
-- Handles entity build, destroy, copy, and clone events for AI combinators

local constants = require("src/core/constants")
local init = require("src/ai_combinator/init")
local util = require("src/core/utils")
local blueprint_serialization = require("src/core/blueprint_serialization")

local entity_events = {}

-- Entity filter for AI combinators
local COMBINATOR_FILTER = { { filter = "name", name = "ai-combinator" } }
local COMBINATOR_CORE_FILTER = { { filter = "name", name = "ai-combinator" }, { filter = "name", name = "ai-combinator-core" } }

--- Handle entity built event - initialize new combinator
---@param ev EventData Event data
function entity_events.on_built(ev)
    ---@diagnostic disable-next-line: undefined-field
    local e = ev.created_entity or ev.entity -- latter for revive event
    if not e.valid then
        return
    end
    local combinator = init.out_wire_connect_combinator({ e = e })

    -- Merge with default combinator structure while preserving existing fields
    local default_combinator = blueprint_serialization.create_default_combinator(e)
    combinator = blueprint_serialization.merge_combinator_data(combinator, default_combinator)

    storage.combinators[e.unit_number] = combinator

    -- Blueprints - try to restore settings from tags stored there on setup,
    -- or fallback to old method with uid stored in a constant for simple copy-paste if tags fail
    ---@diagnostic disable-next-line: undefined-field
    if ev.tags then
        ---@diagnostic disable-next-line: undefined-field
        local deserialized_data = blueprint_serialization.deserialize_combinator(ev.tags)
        combinator = blueprint_serialization.merge_combinator_data(combinator, deserialized_data)
        storage.combinators[e.unit_number] = combinator

        -- Refresh imported test cases to ensure they're properly evaluated
        if deserialized_data.test_cases and #deserialized_data.test_cases > 0 then
            blueprint_serialization.refresh_imported_test_cases(combinator)
        end
    else
        local ecc_params = e.get_or_create_control_behavior().parameters
        local uid_src = ecc_params.first_constant or 0
        if uid_src < 0 then
            uid_src = uid_src + constants.INT32_TO_UINT32_OFFSET
        end -- int -> uint conversion
        if uid_src ~= 0 then
            local combinator_src = storage.combinators[uid_src]
            if combinator_src then
                local copied_data = {
                    code = combinator_src.code,
                    task = combinator_src.task,
                    description = combinator_src.description,
                    test_cases = combinator_src.test_cases,
                    code_history = combinator_src.code_history,
                    code_history_index = combinator_src.code_history_index,
                    vars = combinator_src.vars,
                }
                combinator = blueprint_serialization.merge_combinator_data(combinator, copied_data)
                storage.combinators[e.unit_number] = combinator

                -- Also refresh test cases when copying from another combinator
                if copied_data.test_cases and #copied_data.test_cases > 0 then
                    blueprint_serialization.refresh_imported_test_cases(combinator)
                end
            else
                combinator.code = ("-- No code was stored in blueprint and" .. " AI Combinator [%s] is unavailable for OTA code update"):format(
                    uid_src
                )
            end
        end
    end
end

--- Handle entity copy/clone event
---@param ev EventData Event data
function entity_events.on_entity_copy(ev)
    ---@diagnostic disable-next-line: undefined-field
    local destination = ev.destination
    ---@diagnostic disable-next-line: undefined-field
    local source = ev.source

    if destination.name == "ai-combinator-core" then
        return destination.destroy()
    end -- for clone event
    if not (source.name == "ai-combinator" and destination.name == "ai-combinator") then
        return
    end
    local uid_src, uid_dst = source.unit_number, destination.unit_number
    local combinator_old_outs = storage.combinators[uid_dst]
    init.combinator_remove(uid_dst, true)
    if combinator_old_outs then
        combinator_old_outs = { combinator_old_outs.out_red, combinator_old_outs.out_green }
        -- For cloned entities, ai-combinator-core's might not yet exist - create/register them here, remove clones above
        -- It'd give zero-outputs for one tick, but probably not an issue, easier to handle it like this
    else
        combinator_old_outs = { init.out_wire_connect_both(destination) }
    end
    storage.combinators[uid_dst] = util.deep_copy(storage.combinators[uid_src])
    local combinator_dst = storage.combinators[uid_dst]
    combinator_dst.e, combinator_dst.next_tick, combinator_dst.core = destination, 0, nil
    combinator_dst.out_red, combinator_dst.out_green = table.unpack(combinator_old_outs)
end

--- Handle entity destroyed event
---@param ev EventData Event data
function entity_events.on_destroyed(ev)
    ---@diagnostic disable-next-line: undefined-field
    local entity = ev.entity
    init.combinator_remove(entity.unit_number)
end

--- Handle entity mined event
---@param ev EventData Event data
function entity_events.on_mined(ev)
    ---@diagnostic disable-next-line: undefined-field
    local entity = ev.entity
    storage.combinators[entity.unit_number].removed_by_player = true
    init.combinator_remove(entity.unit_number, nil, true)
end

--- Register all entity-related event handlers
function entity_events.register()
    -- Build events
    script.on_event(defines.events.on_built_entity, entity_events.on_built, COMBINATOR_FILTER)
    script.on_event(defines.events.on_robot_built_entity, entity_events.on_built, COMBINATOR_FILTER)
    script.on_event(defines.events.on_space_platform_built_entity, entity_events.on_built, COMBINATOR_FILTER)
    script.on_event(defines.events.script_raised_built, entity_events.on_built, COMBINATOR_FILTER)
    script.on_event(defines.events.script_raised_revive, entity_events.on_built, COMBINATOR_FILTER)

    -- Copy/clone events
    script.on_event(defines.events.on_entity_cloned, entity_events.on_entity_copy, COMBINATOR_CORE_FILTER)
    script.on_event(defines.events.on_entity_settings_pasted, entity_events.on_entity_copy)

    -- Destroy events
    script.on_event(defines.events.on_pre_player_mined_item, entity_events.on_mined, COMBINATOR_FILTER)
    script.on_event(defines.events.on_robot_pre_mined, entity_events.on_mined, COMBINATOR_FILTER)
    script.on_event(defines.events.on_entity_died, entity_events.on_destroyed, COMBINATOR_FILTER)
    script.on_event(defines.events.script_raised_destroy, entity_events.on_destroyed, COMBINATOR_FILTER)
end

return entity_events
