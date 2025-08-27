local sandbox = require('src/sandbox/base')
local utils = require('src/core/utils')

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


function testing.evaluate_test_case(uid, red, green, options)
  local ai_combinator = storage.combinators[uid]

	local env_ro = {
		uid = 123,
		out = {},
		red = {["signal-A"] = 70, x = 1},
		green = {},
    vars = options.vars or {}
  }
  testing.env.game.tick = options and options.game_tick or 1
	setmetatable(env_ro, {__index=testing.env})
  func, err = load(ai_combinator.code, ai_combinator.code, 't', env_ro)
  func()
  return env_ro.out
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

return testing
