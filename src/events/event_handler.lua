local event_handler = {}

-- Stores lists of handlers, keyed by event name (string or event_id)
local handlers = {}

-- Stores the multiplexer functions assigned to root script events
local root_multiplexers = {}

-- Set of KNOWN standard root-level script events that are registered via script[key](handler)
local known_root_level_events = {
  on_init = true,
  on_load = true, -- Handle with care!
  on_configuration_changed = true,
  on_game_save = true,
  on_player_created = true,
  on_player_removed = true,
  on_pre_player_removed = true,
  on_player_respawned = true,
  -- Add others *if they follow the script[key](handler) registration pattern*
  -- Consult Factorio API docs for the specific event if unsure.
  -- Do NOT add custom event names here.
}

-- Map "on_tick" string to the defines.events ID for consistency
local function normalize_event_name(event_name_or_id)
    if event_name_or_id == "on_tick" then
        return defines.events.on_tick
    end
    return event_name_or_id
end

-- Creates the multiplexer function for a specific root-level event
local function create_root_multiplexer(event_name)
    return function(event_data)
        local handler_list = handlers[event_name]
        if not handler_list then return end
        for _, handler_func in pairs(handler_list) do
            local success, err = pcall(handler_func, event_data)
            if not success then
                log(string.format("ERROR in %s handler: %s", event_name, tostring(err)))
            end
        end
    end
end

-- Ensures the appropriate global handler (script.on_event or script[name]) is registered
local function ensure_event_registered(event_name_or_id)
    local event_key = normalize_event_name(event_name_or_id)
    if handlers[event_key] then return end -- Already registered

    handlers[event_key] = {} -- Initialize handler list optimistically

    local normal_event = false
    if type(event_key) == "string" then
        -- Check if it's one of the *known* root-level events
        if known_root_level_events[event_key] then
            -- It's a known root-level event, register using script[key](handler)
            if not root_multiplexers[event_key] then
                 root_multiplexers[event_key] = create_root_multiplexer(event_key)
                 -- Safely check if script[event_key] is actually a function before calling it
                 if type(script[event_key]) == "function" then
                     script[event_key](root_multiplexers[event_key])
                     return
                 else
                     log(string.format("ERROR [EventHandler]: Script key '%s' is in known_root_level_events but script[%s] is not a function!", event_key, event_key))
                     -- Registration failed, clean up
                     handlers[event_key] = nil
                     root_multiplexers[event_key] = nil
                     return -- Stop processing this event key
                 end
            end
        else
            -- It's a string but NOT a known root-level event -> Treat as CUSTOM event
            normal_event = true
        end
    end
    if type(event_key) == "number" or normal_event then
         -- Standard defines.events ID, register with script.on_event
         script.on_event(event_key, function(event)
             -- Validity checks
             if event then
                 if event.element and not event.element.valid then return end
                 if event.entity and not event.entity.valid then return end
                 if event.player_index and game.players[event.player_index] and not game.players[event.player_index].connected then return end
             end
             local handler_list = handlers[event_key]
             if not handler_list then return end

            local function error_handler(err)
              local traceback = debug.traceback("", 2)
              local event_name = event_key
              if type(event_key) == "number" then
                event_name = defines.events[event_key] or 'Unknown'
              end
              log(string.format("ERROR in event handler ID %s: %s", event_name, err) .. "\n" .. traceback)
              game.print(string.format("ERROR in event handler ID %s: %s", event_name, err) .. "\n" .. traceback)
              return err
            end

            for _, handler_func in pairs(handler_list) do
                local success, err = xpcall(handler_func, error_handler, event)
                -- Error already logged by error_handler
            end
         end)
    else
        log(string.format("ERROR [EventHandler]: Cannot register unknown event type/name: %s", tostring(event_key)))
        handlers[event_key] = nil -- Clean up invalid entry
    end
end

-- Checks if a specific handler function is already in the list for an event
local function is_handler_already_registered(event_name_or_id, handler)
    local event_key = normalize_event_name(event_name_or_id)
    if handlers[event_key] then
        for _, registered_handler in ipairs(handlers[event_key]) do
            if registered_handler == handler then return true end
        end
    end
    return false
end

--- Adds a handler function for one or more events.
-- Handles standard events (defines.events), known root-level events (on_init, etc.), and custom events.
-- WARNING: Review Factorio docs for limitations on specific events like "on_load".
-- @param events string|number|table The event name, ID, or a table of these.
-- @param handler function The function to call when the event occurs.
function event_handler.add_handler(events, handler)
    if type(handler) ~= "function" then
        log("ERROR [EventHandler]: add_handler requires a function handler.")
        return
    end

    if type(events) == "table" then
        for _, event_name_or_id in pairs(events) do
            local event_key = normalize_event_name(event_name_or_id)
            ensure_event_registered(event_key)
            -- Check handlers[event_key] exists because ensure_event_registered might have failed
            if handlers[event_key] and not is_handler_already_registered(event_key, handler) then
                table.insert(handlers[event_key], handler)
            end
        end
    else -- Single event
        local event_key = normalize_event_name(events)
        ensure_event_registered(event_key)
        if handlers[event_key] and not is_handler_already_registered(event_key, handler) then
            table.insert(handlers[event_key], handler)
        end
    end
end

--- Removes a handler function from one or more events.
-- @param events string|number|table The event name, ID, or table of these.
-- @param handler function The handler function to remove.
function event_handler.remove_handler(events, handler)
  local function remove_from_event(event_name_or_id)
      local event_key = normalize_event_name(event_name_or_id)
      local handler_list = handlers[event_key]

      if handler_list then
          local handler_removed = false
          for i = #handler_list, 1, -1 do
              if handler_list[i] == handler then
                  table.remove(handler_list, i)
                  handler_removed = true
                  break
              end
          end

          if #handler_list == 0 and handler_removed then
              handlers[event_key] = nil -- Remove the list entry

              if type(event_key) == "string" then
                  -- If it's a KNOWN root event (we would have stored a multiplexer)
                  if known_root_level_events[event_key] and root_multiplexers[event_key] then
                      -- Check if script[event_key] exists and is our multiplexer before unregistering
                      if type(script[event_key]) == "function" and script[event_key] == root_multiplexers[event_key] then
                          script[event_key](nil) -- Call the unregister function
                          -- log(string.format("DEBUG [EventHandler]: Unregistered root handler '%s'", event_key))
                      end
                      root_multiplexers[event_key] = nil -- Clean up our stored multiplexer ref
                  -- else: It was a custom event, no script unregistration needed.
                  end
              elseif type(event_key) == "number" then
                  script.on_event(event_key, nil) -- Unregister standard event
                  -- log(string.format("DEBUG [EventHandler]: Unregistered script.on_event for ID %d", event_key))
              end
          end
      end
  end

  if type(events) == "table" then
      for _, event_name_or_id in pairs(events) do
          remove_from_event(event_name_or_id)
      end
  else
      remove_from_event(events)
  end
end

--- Raises a custom event.
-- @param event_name string | number The name or ID of the custom event.
-- @param event_data any Data to pass to the handlers.
function event_handler.raise_event(event_name, event_data)
    local event_key = event_name

    if handlers[event_key] then
        for _, handler_func in pairs(handlers[event_key]) do
             local success, err = xpcall(handler_func, debug.traceback, event_data)
             if not success then
                 game.print("ERROR in custom event handler '" .. tostring(event_key) .. "': " .. tostring(err))
                 log(string.format("ERROR in custom event handler '%s': %s", event_key, tostring(err)))
             end
        end
    -- else: No handlers registered for this custom event name
    end
end

return event_handler