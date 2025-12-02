local event_handler = require("src/events/event_handler")
local titlebar = require('src/gui/components/titlebar')
local dialog_manager = require('src/gui/dialogs/dialog_manager')
local collapsible_section = require('src/gui/components/collapsible_section')

local dialog = {}

-- Help dialog constants for external use
dialog.HELP_TYPES = {
	EDIT_CODE = 'edit_code',
	AI_COMBINATOR = 'ai_combinator',
	TEST_CASE = 'test_case',
	-- Add more types here as needed:
	-- VARIABLES = 'variables'
}

-- Predefined help configurations
local help_configs = {
	edit_code = {
		title = "Source Code Help",
		dialog_name = 'ai-combinator-help',
		width = 500,
		height = 900,
		content = require('src/gui/dialogs/help/edit_code_help_content')
	},
	ai_combinator = {
		title = "AI Combinator Help",
		dialog_name = 'ai-combinator-help',
		width = 550,
		height = 900,
		content = require('src/gui/dialogs/help/ai_combinator_help_content')
	},
	test_case = {
		title = "Test Case Help",
		dialog_name = 'test-case-help',
		width = 550,
		height = 900,
		content = require('src/gui/dialogs/help/test_case_help_content')
	}
}

function dialog.show(pn, config_name_or_table, toggle_on)
	-- Default to ai_combinator if no config specified
	config_name_or_table = config_name_or_table or 'ai_combinator'
	
	-- Get config from predefined configs or use provided table
	local config
	if type(config_name_or_table) == "string" then
		config = help_configs[config_name_or_table]
		if not config then
			error("Unknown help config: " .. config_name_or_table)
		end
	else
		config = config_name_or_table
	end
	
	local player = game.players[pn]
	local gui_exists = player.gui.screen[config.dialog_name]
	if gui_exists and not toggle_on then return gui_exists.destroy()
	elseif toggle_on == false then return end
	
	local dw, dh, dsf = player.display_resolution.width,
		player.display_resolution.height, 1 / player.display_scale

	local dialog_width = config.width or 500
	local dialog_height = math.min(config.height or 900, dh - 100)

	local gui = player.gui.screen.add{ type='frame',
		name=config.dialog_name, caption='', direction='vertical' }
	gui.location = {math.max(50, (dw - dialog_width) * dsf / 2), 20 * dsf}
	dialog_manager.set_current_dialog(pn, gui)

	titlebar.show(gui, config.title, {help_dialog_close = true}, {help_dialog = true})
	
	-- Content frame with shallow frame style
	local content_frame = gui.add{type='frame', direction='vertical', style='inside_shallow_frame'}
	content_frame.style.padding = 0
	
	local scroll = content_frame.add{type='scroll-pane', name='help-scroll', direction='vertical'}
	scroll.style.maximal_height = dialog_height * dsf
	scroll.style.minimal_height = dialog_height * dsf
	scroll.style.maximal_width = dialog_width
	scroll.style.minimal_width = dialog_width - 20
	scroll.style.padding = 8
  scroll.vertical_scroll_policy = 'always'
	
	-- Render all sections from content data
	if config.content and config.content.sections then
		for i, section_data in ipairs(config.content.sections) do
			local section, content = collapsible_section.show(scroll, section_data.id, section_data.title, section_data.expanded)
			
			-- First section gets less top margin
			if i == 1 then
				section.style.top_margin = 4
			end
			
			-- Render the content using the content structure
			collapsible_section.render_content(content, section_data.content)
		end
	end
end

function on_gui_click(event)
	local el = event.element

  if not el.valid or not el.tags then return end

	if el.tags.help_dialog_close then
    return dialog_manager.close_dialog(event.player_index)
  end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)


return dialog