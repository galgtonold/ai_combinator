local utils = require("src/core/utils")
local event_handler = require("src/events/event_handler")

local set_quantity_dialog = require("src/gui/dialogs/set_quantity_dialog")

local component = {}

function component.show(parent, style, signal_with_count, editable, button_tags, edit_button_tags)
    local flow = parent.add({
        type = "flow",
    })

    local button = flow.add({
        type = "choose-elem-button",
        elem_type = "signal",
        signal = signal_with_count.signal,
        style = style,
        tags = button_tags,
    })

    if signal_with_count.count then
        local count_label = flow.add({
            type = "label",
            caption = tostring(utils.format_number(signal_with_count.count)),
            style = "count_label",
            ignored_by_interaction = true,
        })
        count_label.style.top_margin = 20
        count_label.style.left_margin = -40
        count_label.style.right_margin = -40
        count_label.style.horizontal_align = "right"
        count_label.style.maximal_width = 33
        count_label.style.minimal_width = 33
    end
    button.locked = not editable

    if editable and signal_with_count.count then
        edit_button_tags = edit_button_tags or {}
        local tooltip = "[font=default-bold]Edit quantity[/font]\nCurrent: [color=yellow]" .. signal_with_count.count .. "[/color]"
        local edit_button = flow.add({
            type = "sprite-button",
            sprite = "utility/rename_icon",
            style = "mini_button",
            tooltip = tooltip,
            tags = utils.merge(edit_button_tags, { edit_signal_quantity = true, edit_signal_quantity_count = signal_with_count.count }),
        })
        edit_button.style.width = 16
        edit_button.style.height = 16
        edit_button.style.top_margin = 1
        edit_button.style.left_margin = 21
    end
end

local function on_gui_click(event)
    local element = event.element

    if not element.valid or not element.tags then
        return
    end

    local uid = element.tags.uid
    gui = storage.guis[uid]

    if element.tags.edit_signal_quantity then
        set_quantity_dialog.show(
            event.player_index,
            uid,
            element.tags.edit_signal_quantity_count,
            utils.exclude(element.tags, "edit_signal_quantity", "edit_signal_quantity_count")
        )
    end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)

return component
