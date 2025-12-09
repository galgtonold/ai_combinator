local event_handler = require("src/events/event_handler")
local titlebar = require("src/gui/components/titlebar")
local constants = require("src/core/constants")
local utils = require("src/core/utils")
local dialog_manager = require("src/gui/dialogs/dialog_manager")

local dialog = {}

function dialog.show(player_index, uid, default_value, tags)
    -- Simple quantity input dialog
    local player = game.players[player_index]
    local combinator = storage.combinators[uid]
    -- Prevent multiple instances - close existing dialog and its children if it exists
    local gui_t = storage.guis[uid]
    if gui_t and gui_t.quantity_dialog and gui_t.quantity_dialog.valid then
        dialog_manager.close_dialog_and_children(player_index, gui_t.quantity_dialog)
    end

    tags.uid = uid

    -- Create simple input dialog
    local quantity_frame = player.gui.screen.add({
        type = "frame",
        direction = "vertical",
        name = "set_quantity_frame",
        tags = utils.merge(tags, { quantity_dialog = true }),
    })
    quantity_frame.location = { player.display_resolution.width / 2 - 100, player.display_resolution.height / 2 - 50 }
    dialog_manager.set_current_dialog(player_index, quantity_frame)

    titlebar.show(quantity_frame, "Set Quantity", { quantity_dialog_close = true }, utils.merge(tags, { quantity_dialog = true }))

    local content = quantity_frame.add({
        type = "flow",
        direction = "vertical",
    })

    local input_flow = content.add({
        type = "flow",
        direction = "horizontal",
    })

    input_flow.add({ type = "label", caption = "Quantity:" })

    local quantity_input = input_flow.add({
        type = "textfield",
        text = tostring(default_value),
        numeric = true,
        allow_negative = true,
        name = "quantity-input",
        tags = utils.merge(tags, { quantity_input = true }),
    })
    quantity_input.style.width = 100
    quantity_input.style.left_margin = 8
    quantity_input.focus()
    quantity_input.select_all()
    gui_t.quantity_input = quantity_input

    local button_flow = content.add({
        type = "flow",
        direction = "horizontal",
    })

    local cancel_btn = button_flow.add({
        type = "button",
        caption = "Cancel",
        style = "back_button",
        tags = { quantity_cancel = true },
    })

    local ok_btn = button_flow.add({
        type = "button",
        caption = "OK",
        style = "confirm_button",
        tags = utils.merge(tags, { quantity_ok = true }),
    })
    ok_btn.style.left_margin = 8

    -- Store references for later access
    gui_t.quantity_dialog = quantity_frame
    gui_t.quantity_input = quantity_input
end

local function confirm_dialog(player_index, quantity_input)
    local quantity = tonumber(quantity_input.text)
    if quantity then
        event_handler.raise_event(
            constants.events.on_quantity_set,
            utils.merge(quantity_input.tags, { player_index = player_index, quantity = quantity })
        )
        dialog_manager.close_dialog(player_index)
    end
end

local function on_gui_click(event)
    local el = event.element

    if not el.valid or not el.tags then
        return
    end

    if event.element.tags.quantity_ok then
        local gui_t = storage.guis[event.element.tags.uid]
        confirm_dialog(event.player_index, gui_t.quantity_input)
    elseif event.element.tags.quantity_cancel then
        dialog_manager.close_dialog(event.player_index)
    end
end

local function on_gui_confirm(event)
    if event.element and event.element.valid and event.element.name == "quantity-input" then
        confirm_dialog(event.player_index, event.element)
    end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)
event_handler.add_handler(defines.events.on_gui_confirmed, on_gui_confirm)

return dialog
