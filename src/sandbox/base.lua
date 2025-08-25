local event_handler = require("src/events/event_handler")
local cn = require("src/core/circuit_network")

local sandbox = {}

sandbox.env_pairs_mt_iter = {}
function sandbox.env_pairs(tbl) -- allows to iterate over red/green ro-tables
	local mt = getmetatable(tbl)
	if mt and sandbox.env_pairs_mt_iter[mt.__index] then tbl = tbl._iter(tbl) end
	return pairs(tbl)
end

function sandbox.clean_table(tbl, apply_func)
	local tbl_clean = {}
	for k, v in sandbox.env_pairs(tbl) do tbl_clean[k] = v end
	if apply_func then return apply_func(tbl_clean) else return tbl_clean end
end

function sandbox.game_print(...)
	local args, msg = table.pack(...), ''
	for _, arg in ipairs(args) do
		if msg ~= '' then msg = msg..' ' end
		if type(arg) == 'table' then arg = sandbox.clean_table(arg, serpent.line) end
		msg = msg..(tostring(arg or 'nil') or '[value]')
	end
	game.print(msg)
end

-- This env gets modified on ticks, which might cause mp desyncs
sandbox.env_base = {
	_init = false,

	pairs = sandbox.env_pairs,
	ipairs = ipairs,
	next = next,
	pcall = pcall,
	tonumber = tonumber,
	tostring = tostring,
	type = type,
	assert = assert,
	error = error,
	select = select,

	serpent = {
		block = function(tbl) return sandbox.clean_table(tbl, serpent.block) end,
		line = function(tbl) return sandbox.clean_table(tbl, serpent.line) end },
	string = {
		byte = string.byte, char = string.char, find = string.find,
		format = string.format, gmatch = string.gmatch, gsub = string.gsub,
		len = string.len, lower = string.lower, match = string.match,
		rep = string.rep, reverse = string.reverse, sub = string.sub,
		upper = string.upper },
	table = {
		concat = table.concat, insert = table.insert, remove = table.remove,
		sort = table.sort, pack = table.pack, unpack = table.unpack },
	math = {
		abs = math.abs, acos = math.acos, asin = math.asin,
		atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos,
		cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor,
		fmod = math.fmod, frexp = math.frexp, huge = math.huge,
		ldexp = math.ldexp, log = math.log, max = math.max,
		min = math.min, modf = math.modf, pi = math.pi, pow = math.pow,
		rad = math.rad, random = math.random, sin = math.sin, sinh = math.sinh,
		sqrt = math.sqrt, tan = math.tan, tanh = math.tanh },
	bit32 = {
		arshift = bit32.arshift, band = bit32.band, bnot = bit32.bnot,
		bor = bit32.bor, btest = bit32.btest, bxor = bit32.bxor,
		extract = bit32.extract, replace = bit32.replace, lrotate = bit32.lrotate,
		lshift = bit32.lshift, rrotate = bit32.rrotate, rshift = bit32.rshift }
}

local function mlc_log(...) log(...) end -- to avoid logging func code

event_handler.add_handler(defines.events.on_tick, function(event)
	if not sandbox.env_base._init then
		-- This is likely to cause mp desyncs
		sandbox.env_base.game = {
			tick=game.tick, log=mlc_log,
			print=sandbox.game_print, print_color=game.print }
		sandbox.env_base._api = { game=game, script=script,
			remote=remote, commands=commands, settings=settings,
			rcon=rcon, rendering=rendering, global=storage, defines=defines, prototypes=prototypes }
		sandbox.env_pairs_mt_iter[cn.cn_input_signal_get] = true
		sandbox.env_base._init = true
	end

  if sandbox.env_base.game then
    sandbox.env_base.game.tick = event.tick
  end
end)

return sandbox
