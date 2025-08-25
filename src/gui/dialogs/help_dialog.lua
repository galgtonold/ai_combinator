local event_handler = require("src/events/event_handler")
local config = require('src/core/config')


local dialog = {}

function dialog.show(pn, toggle_on)
	local player = game.players[pn]
	local gui_exists = player.gui.screen['mlc-help']
	if gui_exists and not toggle_on then return gui_exists.destroy()
	elseif toggle_on == false then return end
	local dw, dh, dsf = player.display_resolution.width,
		player.display_resolution.height, 1 / player.display_scale

	local gui = player.gui.screen.add{ type='frame',
		name='mlc-help', caption='Moon Logic Combinator Info', direction='vertical' }
	gui.location = {math.max(50, (dw - 800) * dsf), 20 * dsf}
	local scroll = gui.add{type='scroll-pane',  name='mlc-help-scroll', direction='vertical'}
	scroll.style.maximal_height = (dh - 200) * dsf
	local lines = {
		'Combinator has separate input and output leads, but note that you can connect them.',
		' ',
		'Special variables available/handled in Lua environment:',
		'  [color=#ffe6c0]uid[/color] (uint) -- globally-unique number of this combinator.',
		('  [color=#ffe6c0]%s[/color] {signal-name=value, ...} -- signals on the %s input wire (read-only).')
			:format(config.red_wire_name, config.red_wire_name),
		'    Any keys queried there are always numbers, returns 0 for missing signal.',
		('  [color=#ffe6c0]%s[/color] {signal-name=value, ...} -- same as above for %s input network.')
			:format(config.green_wire_name, config.green_wire_name),
		'  [color=#ffe6c0]out[/color] {signal-name=value, ...} -- table with all signals sent to networks.',
		'    They are persistent, so to remove a signal you need to set its entry',
		'      to nil or 0, or flush all signals by entering "[color=#ffe6c0]out = {}[/color]" (creates a fresh table).',
		('    Signal name can be prefixed by "%s/" or "%s/" to only output it on that specific wire,')
			:format(config.red_wire_name, config.green_wire_name),
		'      and will override non-prefixed signal value there, if that is used as well, until unset.',
		'  [color=#ffe6c0]var[/color] {} -- table to easily store values between code runs (per-mlc globals work too).',
		'  [color=#ffe6c0]delay[/color] (number) -- delay in ticks until next run - use for intervals or performance.',
		'    Defaults to 1 (run again on next tick), and gets reset to it before each run,',
		'      so must be set on every individual run if you want to delay the next one.',
		'  [color=#ffe6c0]irq[/color] (signal-name) -- input signal name to interrupt any delay on.',
		'    If any [color=#ffe6c0]delay[/color] value is set and this signal is non-zero on any input wire, delay gets interrupted.',
		'    Same as [color=#ffe6c0]delay[/color], gets reset before each code run, and must be set if still needed.',
		'  [color=#ffe6c0]irq_min_interval[/color] (number) -- min ticks between triggering code runs on any [color=#ffe6c0]irq[/color] signal.',
		'    To avoid complicated logic when that signal is not a pulse. Use nil or <=1 to disable (default).',
		'  [color=#ffe6c0]debug[/color] (bool) -- set to true to print debug info about next code run to factorio log.',
		'  [color=#ffe6c0]ota_update_from_uid[/color] (uint) -- copy code from another combinator with this uid.',
		'    Reset after code runs, ignored if MLC with that uid (number in a window header) does not exist.',
		'    Note that only code is updated, while persistent lua environment and outputs stay the same.',
		'  any vars with "__" prefix, e.g. __big_data -- work as normal, but won\'t clutter variables window.',
		' ',
		'Factorio APIs available, aside from general Lua stuff:',
		'  [color=#ffe6c0]game.tick[/color] -- read-only int for factorio game tick, to measure time intervals.',
		'  [color=#ffe6c0]game.log(...)[/color] -- prints passed value(s) to factorio log.',
		'  [color=#ffe6c0]game.print(...)[/color] -- prints values to an in-game console output.',
		'  [color=#ffe6c0]game.print_color(msg, c)[/color] -- for a more [color=#08c2ca]co[/color]'..
				'[color=#ed7a7e]lor[/color][color=#5cd568]ful[/color] console output, c={r[0-1],g,b}.',
		'  [color=#ffe6c0]serpent.line(...)[/color] and [color=#ffe6c0]serpent.block(...)[/color] -- dump tables to strings.',
		' ',
		'Presets - buttons with numbers on top of the UI:',
		'  Save and Load - [color=#ffe6c0]left-click[/color], Delete - [color=#ffe6c0]right-click[/color],'..
				' Overwrite - [color=#ffe6c0]right[/color] then [color=#ffe6c0]left[/color].',
		'  These are shared between all combinators, and can be used to copy code snippets.',
		'  Another way to copy code is the usual [color=#ffe6c0]shift+right-click[/color]'..
				' - [color=#ffe6c0]shift+left-click[/color] on the combinators.',
		' ',
		'Default UI hotkeys (rebindable, do not work when editing text-box is focused):',
		'  [color=#ffe6c0]Esc[/color] - unfocus/close code textbox (makes all other hotkeys work again),',
		'  [color=#ffe6c0]Ctrl-S[/color] - save/apply code changes,'..
				' [color=#ffe6c0]Ctrl-Left/Right[/color] - undo/redo last change,',
		'  [color=#ffe6c0]Ctrl-Q[/color] - close all UIs,'..
				' [color=#ffe6c0]Ctrl-Enter[/color] - save/apply and close,'..
				' [color=#ffe6c0]Ctrl-F[/color] - toggle env window.',
		'Some buttons at the top of the window also have multiple actions, see tooltips there.',
		' ',
		'To learn signal names, connect anything with signals to this combinator,',
		'  and their names will be printed as colored inputs on the right of the code window.',
		'If signal names are ambiguous (with some mods), signal type prefix can be used',
		'  ([color=#46a7f7]#[/color] - item, [color=#46a7f7]=[/color] - fluid, [color=#46a7f7]@[/color] - virtual signal)'
			..' for names that are same between multiple types.',
		' ' }
	for n, line in ipairs(lines) do scroll.add{
		type='label', name='line_'..n, direction='horizontal', caption=line } end
	gui.add{type='button', name='mlc-help-close', caption='Got it'}
end

function on_gui_click(event)
	local el = event.element

  if not el.valid then return end

	if el.name == 'mlc-help-close' then
    return el.parent.destroy()
  end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)


return dialog