local constants = require('src/core/constants')

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

function circuit_network.cn_sig(k, err_level)
	local signame, qname = circuit_network.cn_sig_quality(k)
	local sig = storage.signals_short[signame or k]
	if type(sig) ~= false then sig = storage.signals[sig or signame] end
	if sig and qname ~="" then
		sig.quality = qname
		return sig
	elseif sig then
		return sig
	end
	if not err_level then return end
	if sig == false then
		local m = {}
		for _,t in ipairs{'virtual', 'item', 'fluid'} do
			sig = circuit_network.cn_sig_str(t, k)
			if storage.signals[sig] then table.insert(m, sig) end
		end
		error(( 'Ambiguous short signal name "%s",'..
			' matching: %s' ):format(k, table.concat(m, ' ')), err_level)
	end
	error('Unknown signal: '..k, err_level)
end


local function cn_sig_quality(sig_str)
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

local cn_sig_str_prefix = {item='#', fluid='=', virtual='@', recipe='~'}
local function cn_sig_str(t, name)
	-- Translates name or type/name or signal to its type-prefixed string-id
	if not name then
		if type(t) == 'string' then
			name = storage.signals_short[t]
			if name == false then return end -- ambiguous name
			return name or t
		else
			if t.type == nil then
        t.type = 'item'
      end
			name = t.name

		end
	end
	if not t then
		return storage.signals_short[name]
	end
	if t.quality ~= "normal" and t.quality ~= nil then
		return t.quality.."/"..cn_sig_str_prefix[t.type]..name
	end
	return cn_sig_str_prefix[t.type or t]..name
end

local function cn_wire_signals(e, wire_type, canon)
	-- Returns signal=count table, with signal names abbreviated where possible
	local ccid
	if wire_type == defines.wire_type.green then
		ccid = defines.wire_connector_id.combinator_input_green
	elseif wire_type == defines.wire_type.red then
		ccid = defines.wire_connector_id.combinator_input_red
	end
	local res, cn, k = {}, e.get_or_create_control_behavior()
		.get_circuit_network(ccid)
	for _, sig in pairs(cn and cn.signals or {}) do
		-- Check for name=nil SignalIDs (dunno what these are), and items w/ flag=hidden
		if storage.signals_short[sig.signal.name] == nil then goto skip end
		if canon then k = cn_sig_str(sig.signal)
		elseif sig.signal.quality ~= nil and sig.signal.type == 'recipe' then
			k = sig.signal.quality.."/~"..storage.signals_short[sig.signal.name] and sig.signal.quality.."/~"..sig.signal.name or "~"..cn_sig_str(sig.signal)
		elseif sig.signal.type == 'recipe' then
			k = "~"..storage.signals_short[sig.signal.name] and "~"..sig.signal.name or "~"..cn_sig_str(sig.signal)
		elseif sig.signal.quality ~= nil then
			k = sig.signal.quality.."/"..storage.signals_short[sig.signal.name] and sig.signal.quality.."/"..sig.signal.name or cn_sig_str(sig.signal)
		else k = storage.signals_short[sig.signal.name]
			and sig.signal.name or cn_sig_str(sig.signal) end
		res[k] = sig.count
	::skip:: end
	return res
end

function circuit_network.cn_input_signal(wenv, wire_type, k)
	local signals = wenv._cache
	if wenv._cache_tick ~= game.tick then
		signals = cn_wire_signals(wenv._e, wire_type, true)
		wenv._cache, wenv._cache_tick = signals, game.tick
	end
	if k and #storage.quality ~= 0 then
		local signame, q_name = cn_sig_quality(k)
		if q_name == nil or q_name == "normal" then
			signals = signals[cn_sig_str(circuit_network.cn_sig(signame, 4))]
			return signals
		end
		signals = signals[q_name.."/"..cn_sig_str(circuit_network.cn_sig(signame, 4))]
		return signals
	end
	if k then signals = signals[cn_sig_str(circuit_network.cn_sig(k, 4))] end
	return signals
end

function circuit_network.cn_input_signal_get(wenv, k)
	local v = circuit_network.cn_input_signal(wenv, defines.wire_type[wenv._wire], k) or 0
	if wenv._debug then wenv._debug[constants.get_wire_label(wenv._wire)..'['..k..']'] = v end
	return v
end
function circuit_network.cn_input_signal_set(wenv, k, v)
	error(( 'Attempt to set value on input wire:'..
		' %s[%s] = %s' ):format(constants.get_wire_label(wenv._wire), k, v), 2)
end

function circuit_network.cn_input_signal_len(wenv)
	local n, sigs = 0, circuit_network.cn_input_signal(wenv, defines.wire_type[wenv._wire])
	for sig, c in pairs(sigs) do if c ~= 0 then n = n + 1 end end
	return n
end
function circuit_network.cn_input_signal_iter(wenv)
	-- This returns shortened signal names for simplicity and compatibility
	local signals, sig_cache = {}, circuit_network.cn_input_signal(wenv, defines.wire_type[wenv._wire])
	for k, v in pairs(sig_cache) do signals[circuit_network.cn_sig_name(k)] = sig_cache[k] end
	if wenv._debug then
		local sig_fmt = constants.get_wire_label(wenv._wire)..'[%s]'
		for sig, v in pairs(signals) do wenv._debug[sig_fmt:format(sig)] = v or 0 end
	end
	return signals
end

function circuit_network.cn_input_signal_table_serialize(wenv)
	return {__wire_inputs=constants.get_wire_label(wenv._wire)}
end

function circuit_network.cn_output_table_len(out) -- rawlen won't skip 0 and doesn't work anyway
	local n = 0
	for k, v in pairs(out) do if v ~= 0 then n = n + 1 end end
	return n
end

function circuit_network.cn_output_table_value(out, k)
	if k == '__self' then return end -- for table.deepcopy to tell this apart from factorio object
	return rawget(out, k) or rawget(out, storage.signals_short[k]) or 0
end

function circuit_network.cn_output_table_replace(out, new_tbl)
	-- Note: validation for sig_names/values is done when output table is used later
	for sig, v in pairs(out) do out[sig] = nil end
	for sig, v in pairs(new_tbl or {}) do out[sig] = v end
end

return circuit_network
