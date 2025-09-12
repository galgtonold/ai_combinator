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

local function expand_signal_short_names_and_remove_zeroes(signals)
  for signal, count in pairs(signals) do
    if count == 0 then
      signals[signal] = nil
    else
      local new_name = circuit_network.cn_sig_str(signal)
      signals[new_name] = count
      if new_name ~= signal then
        signals[signal] = nil
      end
    end
  end
  
  return signals
end

function testing.evaluate_test_case(uid, red, green, options)
  local ai_combinator = storage.combinators[uid]
  local captured_print = ""

	local env_ro = {
		uid = uid,
		out = {},
		red = red,
		green = green,
    var = {},
  }
  
  -- Set up variables from options
  if options and options.vars then
    for name, value in pairs(options.vars) do
      env_ro.var[name] = value
    end
  end
  
  testing.env.game = {}
  testing.env.game.tick = options and options.game_tick or 1
  testing.env.game.print = function(...)
    local args = {...}
    local str_args = {}
    for i, arg in ipairs(args) do
      str_args[i] = tostring(arg)
    end
    if #captured_print > 0 then
      captured_print = captured_print .. "\n"
    end
    captured_print = captured_print .. table.concat(str_args, "\t")
  end
	setmetatable(env_ro, {__index=testing.env})
  func, err = load(ai_combinator.code, ai_combinator.code, 't', env_ro)
  
  if func then
    local success, result = pcall(func)
    if not success then
      env_ro.out = {}
    end
  else
    env_ro.out = {}
  end

  return expand_signal_short_names_and_remove_zeroes(env_ro.out), captured_print
end

function testing.strip_factorio_markup(text)
  if not text then return "" end
  
  -- Remove Factorio markup tags like [color=red], [/color], [font=default-bold], etc.
  local stripped = text
  
  -- Remove opening tags like [color=red], [font=default-bold], [item=iron-plate], etc.
  stripped = stripped:gsub("%[%w+[=%w%-]*%]", "")
  
  -- Remove closing tags like [/color], [/font], etc.
  stripped = stripped:gsub("%[/%w+%]", "")
  
  -- Remove locale tags like __ENTITY__iron-chest__
  stripped = stripped:gsub("__%w+__[%w%-]*__", "")
  
  return stripped
end

function testing.print_output_matches(expected, actual)
  if not expected or expected == "" then
    return true -- No expected output means any output is acceptable
  end
  
  local stripped_expected = testing.strip_factorio_markup(expected)
  local stripped_actual = testing.strip_factorio_markup(actual)
  
  -- Check if actual contains expected (partial match)
  return stripped_actual:find(stripped_expected, 1, true) ~= nil
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

local function variables_to_associative(variables_array)
  local result = {}
  if variables_array then
    for i, var in ipairs(variables_array) do
      if var and var.name and var.name ~= "" then
        result[var.name] = var.value or 0
      end
    end
  end
  return result
end

function testing.on_test_case_updated(event)
  local mlc = storage.combinators[event.uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[event.test_index] then return end

  local test_case = mlc.test_cases[event.test_index]

  -- Prepare advanced options
  local options = {
    vars = variables_to_associative(test_case.variables),
    game_tick = test_case.game_tick or 1
  }

  local out, actual_print = testing.evaluate_test_case(
    event.uid,
    signals_to_associative(test_case.red_input),
    signals_to_associative(test_case.green_input),
    options
  )
  local expected = signals_to_associative(test_case.expected_output)

  test_case.actual_output = associative_to_signals(out)
  test_case.actual_print = actual_print

  local signals_equal, only_in_expected, only_in_actual = testing.compare_outputs(expected, out)
  local print_matches = testing.print_output_matches(test_case.expected_print, actual_print)
  
  -- Test passes if both signals and print output match
  local overall_success = signals_equal and print_matches

  test_case.success = overall_success
  test_case.only_in_expected = only_in_expected
  test_case.only_in_actual = only_in_actual
  test_case.print_matches = print_matches

  event_handler.raise_event(constants.events.on_test_case_evaluated, {
    uid = event.uid, 
    test_index = event.test_index,
    success = overall_success, 
    only_in_expected = only_in_expected,
    only_in_actual = only_in_actual,
    print_matches = print_matches
  })
end

event_handler.add_handler(constants.events.on_test_case_updated, testing.on_test_case_updated)

return testing
