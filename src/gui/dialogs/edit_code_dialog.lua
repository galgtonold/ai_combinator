local dialog_manager = require("src/gui/dialogs/dialog_manager")
local titlebar = require("src/gui/components/titlebar")
local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")
local utils = require("src/core/utils")

local help_dialog = require("src/gui/dialogs/help_dialog")

local dialog = {}

local err_icon_sub_add = "[color=#c02a2a]%1[/color]"
local err_icon_sub_clear = "%[color=#c02a2a%]([^\n]+)%[/color%]"
local function code_error_highlight(text, line_err)
    -- Add/strip rich error highlight tags
    if type(line_err) == "string" then
        line_err = line_err:match(":(%d+):")
    end
    text = text:gsub(err_icon_sub_clear, "%1")
    text = text:match("^(.-)%s*$") -- strip trailing newlines/spaces
    line_err = tonumber(line_err)
    if not line_err then
        return text
    end
    local _, line_count = text:gsub("([^\n]*)\n?", "")
    if string.sub(text, -1) == "\n" then
        line_count = line_count + 1
    end
    local n, result = 0, ""
    for line in text:gmatch("([^\n]*)\n?") do
        n = n + 1
        if n == line_err then
            line = line:gsub("^(.+)$", err_icon_sub_add)
        end
        if n < line_count or line ~= "" then
            result = result .. line .. "\n"
        end
    end
    return result
end

function dialog.show(player_index, uid)
    local player = game.players[player_index]
    local gui_t = storage.guis[uid]
    local combinator = storage.combinators[uid]
    local combinator_err = combinator.err_parse or combinator.err_run

    -- Close existing dialogs of this type or conflicting types (and their children)
    if gui_t.edit_code_dialog and gui_t.edit_code_dialog.valid then
        dialog_manager.close_dialog_and_children(player_index, gui_t.edit_code_dialog)
    end
    if gui_t.test_case_dialog and gui_t.test_case_dialog.valid then
        dialog_manager.close_dialog_and_children(player_index, gui_t.test_case_dialog)
    end

    local popup_frame = player.gui.screen.add({
        type = "frame",
        direction = "vertical",
        tags = { uid = uid, dialog = true, edit_code_dialog = true },
    })
    gui_t.edit_code_dialog = popup_frame
    dialog_manager.set_current_dialog(player_index, popup_frame)

    local extra_buttons = {
        {
            type = "sprite-button",
            style = "frame_action_button",
            sprite = "ai-combinator-help",
            tooltip = "Show help",
            tags = { show_help_button = true },
        },
    }
    titlebar.show(
        popup_frame,
        "Edit Source Code",
        { edit_code_dialog_close = true },
        { uid = uid, dialog = true, edit_code_dialog = true },
        extra_buttons
    )

    local content_flow = popup_frame.add({
        type = "flow",
        direction = "vertical",
        tags = { uid = uid, dialog = true, edit_code_dialog = true },
    })

    -- Get current code from the combinator
    local current_code = combinator.code or ""

    -- Reset history index to latest when opening dialog to ensure we see current state
    local history = combinator.code_history or {}
    combinator.code_history_index = #history

    local code_textbox = content_flow.add({
        type = "text-box",
        name = "ai-combinator-edit-code-input",
        text = current_code,
        style = "edit_blueprint_description_textbox",
        tags = { uid = uid, dialog = true, edit_code_dialog = true },
    })
    code_textbox.text = code_error_highlight(code_textbox.text, combinator_err)

    code_textbox.word_wrap = true
    code_textbox.style.width = 600
    code_textbox.style.height = 400
    code_textbox.style.bottom_margin = 8
    gui_t.edit_code_textbox = code_textbox

    -- Code history navigation section
    local history_flow = content_flow.add({
        type = "flow",
        direction = "horizontal",
        tags = { uid = uid, dialog = true, edit_code_dialog = true },
    })
    history_flow.style.bottom_margin = 8

    local history_label = history_flow.add({
        type = "label",
        caption = "Code History:",
        style = "semibold_label",
        tags = { uid = uid, dialog = true, edit_code_dialog = true },
    })
    history_label.style.right_margin = 8

    local prev_button = history_flow.add({
        type = "sprite-button",
        name = "ai-combinator-history-prev",
        sprite = "utility/left_arrow",
        tooltip = "Previous version",
        style = "tool_button",
        tags = { uid = uid, history_prev = true, dialog = true, edit_code_dialog = true },
    })
    prev_button.style.right_margin = 4
    gui_t.edit_code_prev_button = prev_button

    local history_info_label = history_flow.add({
        type = "label",
        name = "ai-combinator-history-info",
        caption = "1/1",
        style = "label",
        tags = { uid = uid, dialog = true, edit_code_dialog = true },
    })
    history_info_label.style.right_margin = 4
    gui_t.edit_code_history_info = history_info_label

    local next_button = history_flow.add({
        type = "sprite-button",
        name = "ai-combinator-history-next",
        sprite = "utility/right_arrow",
        tooltip = "Next version",
        style = "tool_button",
        tags = { uid = uid, history_next = true, dialog = true, edit_code_dialog = true },
    })
    next_button.style.right_margin = 8
    gui_t.edit_code_next_button = next_button

    -- Version info
    local version_info = history_flow.add({
        type = "label",
        name = "ai-combinator-version-info",
        caption = "",
        style = "label",
        tags = { uid = uid, dialog = true, edit_code_dialog = true },
    })
    version_info.style.font_color = { 0.7, 0.7, 0.7 }
    gui_t.edit_code_version_info = version_info

    -- Update history navigation state
    dialog.update_history_navigation(uid)

    local button_flow = content_flow.add({
        type = "flow",
        direction = "horizontal",
        tags = { uid = uid, dialog = true, edit_code_dialog = true },
    })

    local filler = button_flow.add({
        type = "empty-widget",
        style = "draggable_space",
        ignored_by_interaction = true,
        tags = { uid = uid, dialog = true, edit_code_dialog = true },
    })
    filler.style.horizontally_stretchable = true
    filler.style.vertically_stretchable = true

    local cancel_button = button_flow.add({
        type = "button",
        caption = "Cancel",
        style = "back_button",
        tags = { uid = uid, edit_code_cancel = true, dialog = true, edit_code_dialog = true },
    })
    cancel_button.style.left_margin = 8

    local apply_button = button_flow.add({
        type = "button",
        caption = "Apply Code",
        style = "confirm_button",
        tags = { uid = uid, edit_code_apply = true, dialog = true, edit_code_dialog = true },
    })
    apply_button.style.left_margin = 8

    code_textbox.focus()
end

function dialog.update_history_navigation(uid)
    local gui_t = storage.guis[uid]
    local combinator = storage.combinators[uid]

    if not gui_t or not combinator or not gui_t.edit_code_prev_button then
        return
    end

    local history = combinator.code_history or {}
    local current_index = combinator.code_history_index or #history

    -- Ensure current_index is valid
    if current_index < 1 then
        current_index = #history
    end
    if current_index > #history then
        current_index = #history
    end

    -- Update navigation buttons
    gui_t.edit_code_prev_button.enabled = current_index > 1
    gui_t.edit_code_next_button.enabled = current_index < #history

    -- Update history info
    if #history > 0 then
        gui_t.edit_code_history_info.caption = string.format("%d/%d", current_index, #history)

        -- Update version info
        local current_version = history[current_index]
        if current_version then
            local timestamp_text = ""
            if current_version.timestamp and type(current_version.timestamp) == "number" then
                timestamp_text = utils.time_ago(current_version.timestamp, game.tick)
            else
                timestamp_text = "unknown time"
            end

            local source_text = ""
            if current_version.source == "manual" then
                source_text = "Manual edit"
            elseif current_version.source == "ai_generation" then
                source_text = "AI generated"
            elseif current_version.source == "ai_fix" then
                source_text = "AI fix"
            else
                source_text = "Unknown source"
            end

            gui_t.edit_code_version_info.caption = string.format("%s - %s", source_text, timestamp_text)
        else
            gui_t.edit_code_version_info.caption = ""
        end
    else
        gui_t.edit_code_history_info.caption = "0/0"
        gui_t.edit_code_version_info.caption = "No history"
    end
end

function dialog.navigate_history(uid, direction)
    local combinator = storage.combinators[uid]
    local gui_t = storage.guis[uid]

    if not combinator or not gui_t or not gui_t.edit_code_textbox then
        return
    end

    local history = combinator.code_history or {}
    local current_index = combinator.code_history_index or #history

    if direction == "prev" and current_index > 1 then
        current_index = current_index - 1
    elseif direction == "next" and current_index < #history then
        current_index = current_index + 1
    else
        return -- No change
    end

    combinator.code_history_index = current_index

    -- Update textbox with the selected version
    local selected_version = history[current_index]
    if selected_version then
        gui_t.edit_code_textbox.text = selected_version.code or ""
    end

    -- Update navigation state
    dialog.update_history_navigation(uid)
end

function on_gui_click(event)
    local el = event.element

    if not el.valid or not el.tags then
        return
    end

    local uid = event.element.tags.uid
    gui = storage.guis[uid]

    if event.element.tags.edit_code_cancel then
        dialog_manager.close_dialog(event.player_index)
    elseif event.element.tags.edit_code_apply then
        local code_input = gui.edit_code_textbox
        local code_text = code_error_highlight(code_input.text)
        event_handler.raise_event(constants.events.on_code_updated, { player_index = event.player_index, uid = uid, code = code_text })
        dialog_manager.close_dialog(event.player_index)
    elseif event.element.tags.history_prev then
        dialog.navigate_history(uid, "prev")
    elseif event.element.tags.history_next then
        dialog.navigate_history(uid, "next")
    elseif event.element.tags.show_help_button then
        help_dialog.show(event.player_index, help_dialog.HELP_TYPES.EDIT_CODE)
    end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)

event_handler.add_handler(constants.events.on_code_changed, function(event)
    local uid = event.uid
    local gui_t = storage.guis[uid]

    -- If dialog is open for this combinator
    if gui_t and gui_t.edit_code_dialog and gui_t.edit_code_dialog.valid then
        local combinator = storage.combinators[uid]
        if not combinator then
            return
        end

        -- Update textbox with new code
        if gui_t.edit_code_textbox and gui_t.edit_code_textbox.valid then
            gui_t.edit_code_textbox.text = code_error_highlight(event.code or "")
        end

        -- Update history index to point to the new latest version
        local history = combinator.code_history or {}
        combinator.code_history_index = #history

        -- Update navigation buttons/info
        dialog.update_history_navigation(uid)
    end
end)

return dialog
