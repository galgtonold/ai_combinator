local event_handler = require("src/events/event_handler")
local titlebar = require("src/gui/components/titlebar")
local utils = require("src/core/utils")
local dialog_manager = require("src/gui/dialogs/dialog_manager")
local combinator_service = require("src/ai_combinator/combinator_service")

local dialog = {}

function dialog.show(player_index, uid, location, default_value, tags)
    -- Simple test name input dialog
    local player = game.players[player_index]
    -- Prevent multiple instances - close existing dialog and its children if it exists
    local gui_t = storage.guis[uid]
    if gui_t and gui_t.test_name_dialog and gui_t.test_name_dialog.valid then
        dialog_manager.close_dialog_and_children(player_index, gui_t.test_name_dialog)
    end

    tags.uid = uid

    -- Create simple input dialog
    local test_name_frame = player.gui.screen.add({
        type = "frame",
        direction = "vertical",
        name = "set_test_name_frame",
        tags = utils.merge(tags, { test_name_dialog = true }),
    })
    test_name_frame.location = location
    dialog_manager.set_current_dialog(player_index, test_name_frame)

    titlebar.show(test_name_frame, "Change test case name", { test_name_dialog_close = true }, utils.merge(tags, { test_name_dialog = true }))

    local input_flow = test_name_frame.add({
        type = "frame",
        direction = "horizontal",
        style = "inside_shallow_frame",
    })
    input_flow.style.horizontally_stretchable = true
    input_flow.style.horizontally_squashable = false
    input_flow.style.padding = 0

    local test_name_input = input_flow.add({
        type = "textfield",
        text = default_value,
        name = "test_name_input",
        tags = utils.merge(tags, { test_name_input = true }),
    })
    test_name_input.style.horizontally_stretchable = true
    test_name_input.focus()
    test_name_input.select_all()
    gui_t.test_name_input = test_name_input

    local ok_btn = input_flow.add({
        type = "sprite-button",
        sprite = "utility/enter",
        style = "item_and_count_select_confirm",
        tags = utils.merge(tags, { test_name_ok = true }),
    })
    ok_btn.style.left_margin = -3

    -- Store references for later access
    local gui_t = storage.guis[uid]
    gui_t.test_name_dialog = test_name_frame
    gui_t.test_name_input = test_name_input
end

local function confirm_dialog(player_index, test_name_input)
    local test_name = test_name_input.text
    if test_name then
        local uid = test_name_input.tags.uid
        local test_index = test_name_input.tags.test_index
        combinator_service.update_test_case(uid, test_index, { name = test_name })
        dialog_manager.close_dialog(player_index)
    end
end

local function on_gui_click(event)
    local el = event.element

    if not el.valid or not el.tags then
        return
    end

    if event.element.tags.test_name_ok then
        local gui_t = storage.guis[event.element.tags.uid]
        confirm_dialog(event.player_index, gui_t.test_name_input)
    end
end

local function on_gui_confirm(event)
    if event.element and event.element.valid and event.element.name == "test_name_input" then
        confirm_dialog(event.player_index, event.element)
    end
end

event_handler.add_handler(defines.events.on_gui_click, on_gui_click)
event_handler.add_handler(defines.events.on_gui_confirmed, on_gui_confirm)

return dialog
