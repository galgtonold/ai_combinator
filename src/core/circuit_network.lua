local circuit_network = {}

function circuit_network.cn_sig_quality(sig_str)
	-- removes quality prefix from signal string, returns signal name and quality
	if not sig_str then return end
	local q_name = ""
	for _, q in pairs(storage.quality) do
		if string.match(sig_str, "^"..q) then
			q_name = q
			break
		end
	end
	if q_name == "" then return sig_str end
	return string.gsub(sig_str, q_name.."/", ''), q_name
end

circuit_network.cn_sig_str_prefix = {item='#', fluid='=', virtual='@', recipe='~'}
function circuit_network.cn_sig_str(t, name)
	-- Translates name or type/name or signal to its type-prefixed string-id
	if not name then
		if type(t) == 'string' then
			name = storage.signals_short[t]
			if name == false then return end -- ambiguous name
			return name or t
		else 
			if t.type == nil then t.type = 'item' end
			name = t.name

		end
	end
	if not t then
		return storage.signals_short[name]
	end
	if t.quality ~= "normal" and t.quality ~= nil then
		return t.quality.."/"..circuit_network.cn_sig_str_prefix[t.type]..name
	end
	return circuit_network.cn_sig_str_prefix[t.type or t]..name
end

function circuit_network.cn_sig_name(sig_str)
	-- Returns abbreviated signal name without prefix
	local signame, qname = circuit_network.cn_sig_quality(sig_str)
	local k = signame:sub(2)
	local sig_str2 = storage.signals_short[k]
	if sig_str2 == false then return sig_str
	elseif sig_str2 == sig_str then return k
	elseif qname ~= nil and qname.."/"..sig_str2 == sig_str then return qname.."/"..k
	elseif not sig_str2 then error(('MOD BUG - abbreviation for invalid signal string: %s'):format(sig_str))
	else error(('MOD BUG - signal string/abbrev mismatch: %s != %s'):format(sig_str, sig_str2)) end
end

return circuit_network
