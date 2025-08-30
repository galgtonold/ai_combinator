local sandbox = require('src/sandbox/base')
local event_handler = require("src/events/event_handler")
local utils = require('src/core/utils')
local constants = require('src/core/constants')
local circuit_network = require('src/core/circuit_network')

local testing = {
  env = utils.deep_copy(sandbox.env_base)
}

function testing.test_case_matches(expected, actual)
  -- Check if expected output matches actual output
  if not expected or not actual then
    return false
  end
  
  -- Check all expected signals are present with correct values
  for signal, expected_count in pairs(expected) do
    if expected_count ~= 0 then
      local actual_count = actual[signal] or 0
      if actual_count ~= expected_count then
        return false
      end
    end
  end
  
  -- Check no unexpected signals are present
  for signal, actual_count in pairs(actual) do
    if actual_count ~= 0 then
      local expected_count = expected[signal] or 0
      if expected_count == 0 then
        return false
      end
    end
  end
  
  return true
end

local function expand_signal_short_names(signals)
  for signal, count in pairs(signals) do
    local new_name = circuit_network.cn_sig_str(signal)
    signals[new_name] = count
    if new_name ~= signal then
      signals[signal] = nil
    end
  end
  
  return signals
end

function testing.evaluate_test_case(uid, red, green, options)
  local ai_combinator = storage.combinators[uid]

	local env_ro = {
		uid = uid,
		out = {},
		red = red,
		green = green,
    vars = options.vars or {}
  }
  testing.env.game = {}
  testing.env.game.tick = options and options.game_tick or 1
	setmetatable(env_ro, {__index=testing.env})
  func, err = load(ai_combinator.code, ai_combinator.code, 't', env_ro)
  func()

  return expand_signal_short_names(env_ro.out)
end

function testing.compare_outputs(expected, actual)
  -- Returns true if tables are equal, plus lists of keys only in expected and only in actual
  if type(expected) ~= "table" or type(actual) ~= "table" then
    return false, {}, {}
  end

  local only_in_expected = {}
  local only_in_actual = {}
  local all_keys = {}

  for k in pairs(expected) do all_keys[k] = true end
  for k in pairs(actual) do all_keys[k] = true end

  local equal = true
  for k in pairs(all_keys) do
    local v1 = expected[k]
    local v2 = actual[k]
    if v1 ~= v2 then
      equal = false
      if v1 ~= nil and v2 == nil then
        table.insert(only_in_expected, k)
      elseif v2 ~= nil and v1 == nil then
        table.insert(only_in_actual, k)
      else
        table.insert(only_in_expected, k)
        table.insert(only_in_actual, k)
      end
    end
  end

  return equal, only_in_expected, only_in_actual
end

local function signals_to_associative(signal_array)
  local result = {}
  for i, signal in ipairs(signal_array) do
    if signal and signal.signal then
      result[circuit_network.cn_sig_str(signal.signal)] = signal.count or 0
    end
  end
  return result
end

local function associative_to_signals(associative_array)
  local result = {}
  for signal, count in pairs(associative_array) do
    table.insert(result, {signal = circuit_network.cn_sig(signal), count = count})
  end
  return result
end

function testing.on_test_case_updated(event)
  local mlc = storage.combinators[event.uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[event.test_index] then return end

  local test_case = mlc.test_cases[event.test_index]

  local out = testing.evaluate_test_case(event.uid, signals_to_associative(test_case.red_input), signals_to_associative(test_case.green_input), {vars = {}})
  local expected = signals_to_associative(test_case.expected_output)

  test_case.actual_output = associative_to_signals(out)

  local equal, only_in_expected, only_in_actual = testing.compare_outputs(expected, out)

  test_case.success = equal

  event_handler.raise_event(constants.events.on_test_case_evaluated, {uid = event.uid, test_index = event.test_index, success = equal, only_in_expected = only_in_expected, only_in_actual = only_in_actual})
end

event_handler.add_handler(constants.events.on_test_case_updated, testing.on_test_case_updated)

return testing
