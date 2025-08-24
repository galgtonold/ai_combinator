local utils = {}

function utils.tt(s, value)
	-- Helper to make padded table from other table keys or a string of keys
	local t = {}
	if not value then value = true end
	if type(s) == 'table' then for k,_ in pairs(s) do t[k] = value end
	else s:gsub('(%S+)', function(k) t[k] = value end) end
	return t
end

function utils.tc(src)
	-- Shallow-copy a table with keys
	local t = {}
	for k, v in pairs(src) do t[k] = v end
	return t
end

function utils.tdc(object)
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

return utils
