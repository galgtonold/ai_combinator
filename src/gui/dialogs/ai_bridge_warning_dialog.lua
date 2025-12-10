local event_handler = require("src/events/event_handler")

local dialog = {}

function dialog.show(pn, toggle_on)
    local player = game.players[pn]
    local gui_exists = player.gui.screen["ai-combinator-ai-warning"]
    if gui_exists and not toggle_on then
        return gui_exists.destroy()
    elseif toggle_on == false then
        return
    end
    local dw, dh, dsf = player.display_resolution.width, player.display_resolution.height, 1 / player.display_scale

    local gui = player.gui.screen.add({
        type = "frame",
        name = "ai-combinator-ai-warning",
        caption = "AI Combinator - Launcher Required",
        direction = "vertical",
    })
    gui.location = { math.max(50, (dw - 600) * dsf / 2), math.max(50, (dh - 400) * dsf / 2) }

    -- Main content area with light gray background (similar to AI combinator)
    local main_flow = gui.add({ type = "flow", direction = "vertical" })

    local content_frame = main_flow.add({ type = "frame", direction = "vertical", style = "inside_shallow_frame" })
    content_frame.style.padding = 8
    content_frame.style.minimal_width = 450

    local scroll = content_frame.add({ type = "scroll-pane", name = "ai-combinator-ai-warning-scroll", direction = "vertical" })
    scroll.style.maximal_height = (dh - 250) * dsf

    -- Status with red light (similar to status bar)
    local status_flow = scroll.add({ type = "flow", direction = "horizontal" })
    status_flow.add({ type = "label", caption = "[img=utility/status_not_working]" })
    status_flow.add({ type = "label", caption = "[font=default-bold][color=red]AI Combinator Launcher Not Available[/color][/font]" })

    -- Description section
    local desc_flow = scroll.add({ type = "flow", direction = "vertical" })
    desc_flow.style.top_margin = 8
    desc_flow.add({ type = "label", caption = "The AI Combinator mod requires the AI Combinator Launcher to be running" })
    desc_flow.add({ type = "label", caption = "to generate new code from text prompts." })

    -- Impact section
    local impact_flow = scroll.add({ type = "flow", direction = "vertical" })
    impact_flow.style.top_margin = 12
    impact_flow.add({ type = "label", caption = "The AI Combinator Launcher was not detected on your system. This means:" })
    impact_flow.style.top_margin = 4

    local impact_list = scroll.add({ type = "flow", direction = "vertical" })
    impact_list.style.top_margin = 4
    impact_list.style.left_margin = 12
    impact_list.add({ type = "label", caption = "• New AI prompts will not be processed" })
    impact_list.add({ type = "label", caption = "• Existing AI-generated combinators will continue to work normally" })
    impact_list.add({ type = "label", caption = "• You can still edit code manually in combinators" })

    -- Solutions section
    local solutions_header = scroll.add({ type = "label", caption = "[font=default-semibold][color=yellow]To resolve this issue:[/color][/font]" })
    solutions_header.style.top_margin = 12

    local solutions_list = scroll.add({ type = "flow", direction = "vertical" })
    solutions_list.style.top_margin = 4
    solutions_list.style.left_margin = 12
    solutions_list.add({ type = "label", caption = "1. Download and install the AI Combinator Launcher application" })
    solutions_list.add({ type = "label", caption = "2. Configure the launcher with a valid LLM API key" })
    solutions_list.add({ type = "label", caption = "3. Launch Factorio using the AI Combinator Launcher" })
    solutions_list.add({ type = "label", caption = "4. Ensure no firewall is blocking UDP port 8889" })

    -- Download section
    local download_header = scroll.add({
        type = "label",
        caption = "[font=default-semibold][color=yellow]Download AI Combinator Launcher (select and copy):[/color][/font]",
    })
    download_header.style.top_margin = 12

    -- Add selectable download link with wider width
    local link_textfield =
        scroll.add({ type = "text-box", name = "ai-combinator-ai-warning-link", text = "https://github.com/galgtonold/ai_combinator" })
    link_textfield.read_only = true
    link_textfield.style.width = 450
    link_textfield.style.top_margin = 4

    -- Single button spanning full width with green style - inside the content frame
    local button = content_frame.add({ type = "button", name = "ai-combinator-ai-warning-close", caption = "I Understand", style = "green_button" })
    button.style.horizontally_stretchable = true
    button.style.top_margin = 16
    button.style.height = 35
end

local function on_gui_click(event)
    local el = event.element

    if not el.valid then
        return
    end

    if el.name == "ai-combinator-ai-warning-close" then
        -- Find and destroy the warning window by name
        local player = game.players[event.player_index]
        local warning_window = player.gui.screen["ai-combinator-ai-warning"]
        if warning_window then
            return warning_window.destroy()
        end
    end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)

return dialog
