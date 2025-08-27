local utils = {}

function utils.tt(s, value)
	-- Helper to make padded table from other table keys or a string of keys
	local t = {}
	if not value then value = true end
	if type(s) == 'table' then for k,_ in pairs(s) do t[k] = value end
	else s:gsub('(%S+)', function(k) t[k] = value end) end
	return t
end

function utils.shallow_copy(src)
	-- Shallow-copy a table with keys
	local t = {}
	for k, v in pairs(src) do t[k] = v end
	return t
end

function utils.deep_copy(object)
	-- Deep-copy of lua table, from factorio util.lua
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= 'table' then return object
			elseif object.__self then return object
			elseif lookup_table[object] then return lookup_table[object] end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object)
			do new_table[_copy(index)] = _copy(value) end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

function utils.console_warn(p, text)
	p.print(('[Moon Logic mod] %s'):format(text), {0.957, 0.710, 0.659})
end

function utils.format_number(num)
  if num < 0 then
    return "-" .. utils.format_number(-num)
  end
  
  if num < 1000 then
    return tostring(num)
  elseif num < 10000 then
    return string.format("%.1fk", num / 1000):gsub("%.0+k$", "k")
  elseif num < 100000 then
    return string.format("%dk", math.floor(num / 1000))
  elseif num < 1000000 then
    return string.format("%dk", math.floor(num / 1000))
  elseif num < 10000000 then
    return string.format("%.1fM", num / 1000000):gsub("%.0+M$", "M")
  elseif num < 100000000 then
    return string.format("%dM", math.floor(num / 1000000))
  elseif num < 1000000000 then
    return string.format("%dM", math.floor(num / 1000000))
  elseif num < 10000000000 then
    return string.format("%.1fG", num / 1000000000):gsub("%.0+G$", "G")
  else
    return string.format("%dG", math.floor(num / 1000000000))
  end
end

function utils.merge(...)
    local result = {}
    for i = 1, select('#', ...) do
        local t = select(i, ...)
        for k, v in pairs(t) do
            result[k] = v
        end
    end
    return result
end

function utils.exclude(t, ...)
    local excluded = {}
    for i = 1, select('#', ...) do
        excluded[select(i, ...)] = true
    end
    
    local result = {}
    for k, v in pairs(t) do
        if not excluded[k] then
            result[k] = v
        end
    end
    return result
end

return utils
