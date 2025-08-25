local event_handler = require("src/events/event_handler")
local config = require('src/core/config')


local dialog = {}

function dialog.show(pn, uid, paused, toggle_on)
	-- Switches variables-window to specified combinator or toggles it on/off
	local player, gui_k = game.players[pn], 'vars.'..pn
	local gui_exists = player.gui.screen['mlc-vars']
	if gui_exists then
		if toggle_on or (toggle_on == nil and storage.guis_player[gui_k] ~= uid) then
			storage.guis_player[gui_k] = uid
			return vars_window_update(player, uid, paused)
		elseif not toggle_on then return gui_exists.destroy() end
	elseif toggle_on == false then return end -- force off toggle

	local dw, dh, dsf = player.display_resolution.width,
		player.display_resolution.height, 1 / player.display_scale
	storage.guis_player[gui_k] = uid
	local gui = player.gui.screen.add{ type='frame',
		name='mlc-vars', caption='', direction='vertical' }
	gui.location = {math.max(50, (dw - 800) * dsf), 45 * dsf}
	local scroll = gui.add{type='scroll-pane',  name='mlc-vars-scroll', direction='vertical'}
	scroll.style.maximal_height = (dh - 300) * dsf
	local tb = scroll.add{type='text-box', name='mlc-vars-box', text=''}
	tb.style.width = conf.gui_vars_line_px
	tb.read_only, tb.selectable, tb.word_wrap = true, false, true
	local btns = gui.add{type='flow', name='mlc-vars-btns', direction='horizontal'}
	btns.add{type='button', name='mlc-vars-close', caption='Close'}
	btns.add{ type='button', name='mlc-vars-pause', caption='Pause',
		tooltip='Pausing updates also makes text editable,'..
			' so that Ctrl-A/Ctrl-C can be used there, but editing it will not change the environment.' }
	dialog.update(player, uid, paused)
end

function dialog.update(player, uid, pause_update)
	local gui = player.gui.screen['mlc-vars']
	if not gui then return end
	local gui_paused = gui.caption:match(' %-%- .+$')
	if pause_update ~= nil then gui_paused = pause_update end -- explicit pause/unpause
	if gui_paused and pause_update == nil then return end -- ignore calls from mlc updates
	local gui_st_old, gui_st = gui.caption,
		('Moon Logic Environment Variables [%s]%s'):format(uid, gui_paused and ' -- PAUSED' or '')
	if gui_st ~= gui_st_old then
		gui.caption, gui_st = gui_st, gui.children[2].children[2]
		gui_st.style = gui_paused and 'green_button' or 'button'
		gui_st.caption = gui_paused and 'Unpause' or 'Pause'
	end
	local mlc, vars_box = storage.combinators[uid], gui['mlc-vars-scroll']['mlc-vars-box']
	if gui_paused and vars_box.read_only then
		vars_box.selectable, vars_box.read_only = true, false
		vars_box.tooltip =
			'Text is editable for selection/copying while paused,\n'..
			'but changing it will not update the environment.'
	elseif not gui_paused and not vars_box.read_only then
		vars_box.selectable, vars_box.read_only, vars_box.tooltip = false, true, ''
	end

	if not mlc then vars_box.text = '--- [color=#911818]Moon Logic Combinator is Offline[/color] ---'
	else
		local text, esc, vs, c = '', function(s) return tostring(s):gsub('%[', '[ ') end
		for k, v in pairs(mlc.vars) do
			if k:match('^__') then goto skip end
			if text ~= '' then text = text..'\n' end
			vs = serpent.line(v, conf.gui_vars_serpent_opts)
			if vs:len() > conf.gui_vars_line_len_max
			then vs = serpent.block(v, conf.gui_vars_serpent_opts)
			elseif vs:len() > conf.gui_vars_line_len_max * 0.6 then vs = '\n  '..vs end
			text = text..('[color=#520007][font=default-bold]%s[/font][/color] = %s'):format(esc(k), esc(vs))
		::skip:: end
		vars_box.text = text
	end
end

return dialog