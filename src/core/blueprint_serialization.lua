-- src/core/blueprint_serialization.lua
-- Handles serialization and deserialization of AI Combinator data for blueprints

local util = require('src/core/utils')
local event_handler = require('src/events/event_handler')
local constants = require('src/core/constants')

local serialization = {}

-- Version for serialization format
local SERIALIZATION_VERSION = 1

-- Maximum length for blueprint tags (Factorio limitation)
local MAX_TAG_LENGTH = 200000

--- Serializes a combinator's complete state for blueprint storage
function serialization.serialize_combinator(combinator)
  if not combinator then return {} end
  
  local tags = {}
  
  -- Basic data for backward compatibility
  tags.ai_combinator_code = combinator.code
  tags.task = combinator.task
  tags.description = combinator.description
  
  -- Extended data structure with cleaned test cases
  local extended_data = {
    version = SERIALIZATION_VERSION,
    code = combinator.code,
    task = combinator.task,
    description = combinator.description,
    test_cases = serialization._clean_test_cases_for_serialization(combinator.test_cases or {}),
    code_history = combinator.code_history or {},
    code_history_index = combinator.code_history_index,
    vars = combinator.vars or {},
    created_time = combinator.created_time or game.tick,
    last_modified = game.tick
  }
  
  -- Try to serialize extended data
  local success, serialized_data = pcall(serpent.line, extended_data, {sparse=false, nocode=true, nohuge=true})
  if success and serialized_data and #serialized_data <= MAX_TAG_LENGTH then
    tags.ai_combinator_extended = serialized_data
  else
    -- Fallback: try without code history
    extended_data.code_history = {}
    local success_fallback, serialized_fallback = pcall(serpent.line, extended_data, {sparse=false, nocode=true, nohuge=true})
    if success_fallback and serialized_fallback and #serialized_fallback <= MAX_TAG_LENGTH then
      tags.ai_combinator_extended = serialized_fallback
    end
  end
  
  return tags
end

--- Deserializes combinator data from blueprint tags
function serialization.deserialize_combinator(tags)
  if not tags then return {} end
  
  local combinator_data = {}
  
  -- Try extended format first (new format)
  if tags.ai_combinator_extended then
    local success, load_success, extended_data = pcall(serpent.load, tags.ai_combinator_extended)
    if success and load_success and extended_data then
      if extended_data and type(extended_data) == "table" and extended_data.version == SERIALIZATION_VERSION then
        combinator_data = extended_data
        combinator_data.version = nil
        
        -- Restore test_cases signal structures
        if combinator_data.test_cases then
          combinator_data.test_cases = serialization._restore_test_case_signals(combinator_data.test_cases)
        end
        
        return combinator_data
      end
    end
  end
  
  -- Fallback to basic format
  combinator_data.code = tags.ai_combinator_code
  combinator_data.task = tags.task
  combinator_data.description = tags.description
  
  return combinator_data
end

--- Cleans test cases for serialization by converting signals to simple structures
function serialization._clean_test_cases_for_serialization(test_cases)
  if not test_cases then return {} end
  
  local cleaned = {}
  for i, test_case in ipairs(test_cases) do
    local cleaned_test = {
      name = test_case.name,
      description = test_case.description,
      red_input = serialization._clean_signal_array(test_case.red_input),
      green_input = serialization._clean_signal_array(test_case.green_input),
      expected_output = serialization._clean_signal_array(test_case.expected_output),
      variables = test_case.variables or {},
      game_tick = test_case.game_tick or 1
    }
    
    cleaned[i] = cleaned_test
  end
  
  return cleaned
end

--- Cleans an array of signals for serpent serialization
function serialization._clean_signal_array(signals)
  if not signals or type(signals) ~= "table" then
    return {}
  end
  
  local cleaned = {}
  
  -- Handle both array format and key-value format
  if #signals > 0 then
    -- Array format: {signal = {type, name}, count}
    for _, signal_entry in ipairs(signals) do
      if signal_entry and signal_entry.signal and signal_entry.count then
        table.insert(cleaned, {
          signal = {
            type = signal_entry.signal.type,
            name = signal_entry.signal.name
          },
          count = signal_entry.count
        })
      end
    end
  else
    -- Key-value format: signal_name = count
    for signal_name, count in pairs(signals) do
      if type(signal_name) == "string" and type(count) == "number" then
        cleaned[signal_name] = count
      end
    end
  end
  
  return cleaned
end

--- Restores test case signals from serialized format
function serialization._restore_test_case_signals(test_cases)
  if not test_cases then return {} end
  
  -- Test cases should be restored to their proper format
  for i, test_case in ipairs(test_cases) do
    test_case.red_input = serialization._restore_signal_array(test_case.red_input)
    test_case.green_input = serialization._restore_signal_array(test_case.green_input)
    test_case.expected_output = serialization._restore_signal_array(test_case.expected_output)
    test_case.variables = test_case.variables or {}
    test_case.game_tick = test_case.game_tick or 1
  end
  
  return test_cases
end

--- Restores a signal array from cleaned format
function serialization._restore_signal_array(signals)
  if not signals or type(signals) ~= "table" then
    return {}
  end
  
  -- If it's already in the correct array format, return as-is
  if #signals > 0 and signals[1] and signals[1].signal then
    return signals
  end
  
  -- Convert from key-value format to array format
  local restored = {}
  for signal_name, count in pairs(signals) do
    if type(signal_name) == "string" and type(count) == "number" then
      -- Parse signal name to determine type
      local signal_type = "item" -- default
      if string.match(signal_name, "^signal%-") then
        signal_type = "virtual"
      elseif string.match(signal_name, "^fluid%-") then
        signal_type = "fluid"
      end
      
      table.insert(restored, {
        signal = {
          type = signal_type,
          name = signal_name
        },
        count = count
      })
    end
  end
  
  return restored
end

--- Validates that test cases contain proper signal data
function serialization._validate_test_cases(test_cases)
  if not test_cases or type(test_cases) ~= "table" then
    return {}
  end
  
  local validated = {}
  
  for i, test_case in ipairs(test_cases) do
    if type(test_case) == "table" then
      local normalized_case = {
        name = test_case.name or ("Test Case " .. i),
        red_input = serialization._validate_signals(test_case.red_input),
        green_input = serialization._validate_signals(test_case.green_input),
        expected_output = serialization._validate_signals(test_case.expected_output),
        actual_output = serialization._validate_signals(test_case.actual_output),
        variables = test_case.variables or {},
        game_tick = test_case.game_tick or 1,
        expected_print = test_case.expected_print or "",
        success = test_case.success or false,
        last_run_tick = test_case.last_run_tick,
        error_message = test_case.error_message
      }
      table.insert(validated, normalized_case)
    end
  end
  
  return validated
end

--- Validates signal data
function serialization._validate_signals(signals)
  if not signals or type(signals) ~= "table" then
    return {}
  end
  
  local validated = {}
  
  for _, signal in ipairs(signals) do
    if type(signal) == "table" and signal.signal and signal.count then
      local normalized_signal = {
        signal = {
          type = signal.signal.type,
          name = signal.signal.name
        },
        count = signal.count
      }
      
      if normalized_signal.signal.type and normalized_signal.signal.name then
        table.insert(validated, normalized_signal)
      end
    end
  end
  
  return validated
end

--- Creates a combinator data structure with defaults
function serialization.create_default_combinator(entity)
  return {
    e = entity,
    code = nil,
    task = nil,
    description = nil,
    test_cases = {},
    code_history = {},
    code_history_index = 0,
    vars = { var = {} },
    output = {},
    created_time = game.tick,
    last_modified = game.tick,
    next_tick = 0,
    core = nil,
    out_red = nil,
    out_green = nil
  }
end

--- Merges deserialized data into combinator structure
function serialization.merge_combinator_data(combinator, deserialized_data)
  if not combinator or not deserialized_data then return combinator end
  
  -- Preserve all existing fields from combinator, only override with non-nil values from deserialized_data
  for key, value in pairs(deserialized_data) do
    if value ~= nil then
      if key == "vars" then
        combinator.vars = util.deep_copy(value)
        if not combinator.vars.var then
          combinator.vars.var = {}
        end
      else
        combinator[key] = value
      end
    end
  end
  
  -- Ensure required fields exist with defaults if not already present
  combinator.code = combinator.code or nil
  combinator.task = combinator.task or nil
  combinator.description = combinator.description or nil
  combinator.test_cases = combinator.test_cases or {}
  combinator.code_history = combinator.code_history or {}
  combinator.code_history_index = combinator.code_history_index or 0
  combinator.vars = combinator.vars or { var = {} }
  combinator.output = combinator.output or {}
  combinator.created_time = combinator.created_time or game.tick
  combinator.last_modified = game.tick
  combinator.next_tick = combinator.next_tick or 0
  
  return combinator
end

--- Refreshes all imported test cases by triggering evaluation events
function serialization.refresh_imported_test_cases(combinator)
  if not combinator or not combinator.test_cases or not combinator.e or not combinator.e.valid then
    return
  end
  
  -- Trigger test case update events for all imported test cases
  for i = 1, #combinator.test_cases do
    event_handler.raise_event(constants.events.on_test_case_updated, {
      uid = combinator.e.unit_number,
      test_index = i
    })
  end
end

return serialization
