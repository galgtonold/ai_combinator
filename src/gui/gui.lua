local event_handler = require("src/events/event_handler")
local bridge = require("src/services/bridge")
local constants = require("src/core/constants")
local ai_operation_manager = require("src/core/ai_operation_manager")

local code_manager = require("src/ai_combinator/code_manager")
local combinator_service = require("src/ai_combinator/combinator_service")

local dialog_manager = require("src/gui/dialogs/dialog_manager")

local vars_dialog = require("src/gui/dialogs/vars_dialog")
local set_task_dialog = require("src/gui/dialogs/set_task_dialog")
local set_description_dialog = require("src/gui/dialogs/set_description_dialog")
local edit_code_dialog = require("src/gui/dialogs/edit_code_dialog")
local ai_combinator_dialog = require("src/gui/dialogs/ai_combinator_dialog")

local guis = {}

local function vars_window_uid(gui)
    if not gui then
        return
    end
    while gui.name ~= "ai-combinator-vars" do
        gui = gui.parent
    end
    return tonumber(gui.caption:match("%[(%d+)%]"))
end

-- ----- Interface for control.lua -----

local function find_gui(ev)
    -- Finds uid and gui table for specified event-target element
    if ev.entity and ev.entity.valid then
        local uid = ev.entity.unit_number
        local gui_t = storage.guis[uid]
        if gui_t then
            return uid, gui_t
        end
    end
    local el = ev.element
    local el_chk
    if not el then
        return
    end
    for uid, gui_t in pairs(storage.guis) do
        el_chk = gui_t.el_map[el.index]
        if el_chk and el_chk == el then
            return uid, gui_t
        end
    end
end

function guis.open(player, e)
    local uid_old = storage.guis_player[player.index]
    if uid_old then
        player.opened = guis.close(uid_old, player.index)
    end
    local gui_t = ai_combinator_dialog.show(player, e)
    player.opened = gui_t.gui
    storage.guis_player[player.index] = e.unit_number

    -- Initialize the description UI now that gui_t is stored
    guis.update_description_ui(e.unit_number)

    return gui_t
end

function guis.close(uid, player_index)
    local gui_t = storage.guis[uid]
    local gui = gui_t and gui_t.gui

    -- Try to get player_index from the GUI if not provided
    if not player_index and gui and gui.valid then
        player_index = gui.player_index
    end

    if gui and gui.valid then
        gui.destroy()
    end

    -- Close all open dialogs in the stack for this player
    if player_index then
        dialog_manager.close_all_dialogs(player_index)
    end

    -- Also destroy any open dialogs that might have been tracked separately (fallback)
    if gui_t then
        if gui_t.edit_code_dialog and gui_t.edit_code_dialog.valid then
            gui_t.edit_code_dialog.destroy()
        end
        if gui_t.test_case_dialog and gui_t.test_case_dialog.valid then
            gui_t.test_case_dialog.destroy()
        end
        if gui_t.task_dialog and gui_t.task_dialog.valid then
            gui_t.task_dialog.destroy()
        end
        if gui_t.quantity_dialog and gui_t.quantity_dialog.valid then
            gui_t.quantity_dialog.destroy()
        end
        if gui_t.description_dialog and gui_t.description_dialog.valid then
            gui_t.description_dialog.destroy()
        end
        if gui_t.test_name_dialog and gui_t.test_name_dialog.valid then
            gui_t.test_name_dialog.destroy()
        end
    end

    storage.guis[uid] = nil
end

event_handler.add_handler(constants.events.on_description_updated, function(event)
    local uid = event.uid
    -- Only update UI, model is updated by service
    guis.update_description_ui(uid)
end)

event_handler.add_handler(constants.events.on_task_updated, function(event)
    local uid = event.uid
    local task = event.task
    local gui_t = storage.guis[uid]
    if gui_t and gui_t.task_label then
        gui_t.task_label.caption = task
    end
end)

function guis.create_signal_inputs(parent, signals, uid, test_index, signal_type, gui_t)
    -- Create editable signal input fields
    for i = 1, math.max(3, #signals + 1) do
        local signal_data = signals[i] or {}

        local signal_flow = parent.add({ type = "flow", direction = "horizontal" })
        signal_flow.style.vertical_align = "center"

        -- Signal chooser
        local signal_chooser = signal_flow.add({
            type = "choose-elem-button",
            elem_type = "signal",
            signal = signal_data.signal,
            name = "ai-combinator-test-signal-" .. test_index .. "-" .. signal_type .. "-" .. i,
            tags = {
                uid = uid,
                test_case_signal = true,
                test_index = test_index,
                signal_type = signal_type,
                signal_index = i,
            },
        })
        signal_chooser.style.width = 40
        signal_chooser.style.height = 40

        -- Add to element map for GUI tracking
        if gui_t and gui_t.el_map then
            gui_t.el_map[signal_chooser.index] = signal_chooser
        end

        -- Value input
        local value_input = signal_flow.add({
            type = "textfield",
            name = "ai-combinator-test-value-" .. test_index .. "-" .. signal_type .. "-" .. i,
            text = signal_data.count and tostring(signal_data.count) or "",
            numeric = true,
            allow_negative = true,
            tags = {
                uid = uid,
                test_case_value = true,
                test_index = test_index,
                signal_type = signal_type,
                signal_index = i,
            },
        })
        value_input.style.width = 80
        value_input.style.left_margin = 4

        -- Add to element map for GUI tracking
        if gui_t and gui_t.el_map then
            gui_t.el_map[value_input.index] = value_input
        end
    end
end

function guis.update_description_ui(uid)
    local combinator = storage.combinators[uid]
    local gui_t = storage.guis[uid]

    if not combinator then
        return
    end

    if not gui_t then
        return
    end

    if not gui_t.description_container then
        return
    end

    local container = gui_t.description_container
    container.clear()

    -- Helper function to add elements to the el_map
    local function add_to_map(element)
        if element.name then
            gui_t.el_map[element.index] = element
        end
        return element
    end

    if combinator.description and combinator.description ~= "" then
        -- Show description with edit button
        local header_flow = container.add({
            type = "flow",
            direction = "horizontal",
            name = "ai-combinator-description-header",
        })
        add_to_map(header_flow)

        header_flow.add({
            type = "label",
            caption = "Description",
            style = "semibold_label",
        })

        local edit_btn = header_flow.add({
            type = "sprite-button",
            name = "ai-combinator-desc-btn-flow",
            sprite = "utility/rename_icon",
            tooltip = "Edit description",
            style = "mini_button_aligned_to_text_vertically",
            tags = { uid = uid, description_edit = true },
        })
        --edit_btn.style.left_margin = 8

        add_to_map(edit_btn)

        local desc_text = container.add({
            type = "label",
            caption = combinator.description,
            style = "label",
        })
        desc_text.style.single_line = false
        desc_text.style.maximal_width = 380
    else
        -- Show "Add Description" button
        local desc_btn = container.add({
            type = "button",
            name = "ai-combinator-desc-btn-flow",
            caption = "Add Description",
            tags = { uid = uid, description_add = true },
        })
        add_to_map(desc_btn)
    end
end

local function update_all_test_cases(uid)
    local combinator = storage.combinators[uid]
    if not combinator or not combinator.test_cases then
        return
    end
    for i, _ in ipairs(combinator.test_cases) do
        event_handler.raise_event(constants.events.on_test_case_updated, {
            uid = uid,
            test_index = i,
        })
    end
end

event_handler.add_handler(constants.events.on_code_updated, function(event)
    combinator_service.save_code(event.uid, event.code, event.source_type)
    -- Test case update is triggered by on_code_changed event raised by save_code
end)

-- When code changes (after being saved), re-evaluate all test cases
event_handler.add_handler(constants.events.on_code_changed, function(event)
    update_all_test_cases(event.uid)
end)

function guis.handle_task_dialog_click(event)
    local gui

    if not event.element.valid or not event.element.tags then
        return
    end
    local uid = event.element.tags.uid
    gui = storage.guis[uid]

    if event.element.tags.set_task_button then
        local task_input = gui.task_textbox
        combinator_service.set_task(uid, task_input.text)
        bridge.check_bridge_availability()

        local success, _ = ai_operation_manager.start_operation(uid, ai_operation_manager.OPERATION_TYPES.TASK_EVALUATION)
        if success then
            bridge.send_task_request(uid, task_input.text)
        end

        dialog_manager.close_dialog(event.player_index)
        return true
    elseif event.element.tags.set_description_button then
        local description_input = gui.description_textbox
        combinator_service.set_description(uid, description_input.text)
        dialog_manager.close_dialog(event.player_index)
        return true
    elseif event.element.tags.task_dialog_close then
    -- Don't do anything as close is default option for other clicks not in dialog
    elseif event.element.tags.description_dialog_close then
    -- Don't do anything as close is default option for other clicks not in dialog
    elseif event.element.tags.edit_code_dialog_close then
    -- Don't do anything as close is default option for other clicks not in dialog
    elseif event.element.tags.test_case_dialog_close then
    -- Don't do anything as close is default option for other clicks not in dialog
    elseif event.element.tags.dialog then
        return true -- Any clicks inside dialog should not close it
    end
end

function guis.on_gui_click(event)
    if guis.handle_task_dialog_click(event) then
        return
    end

    local element = event.element

    if not element.valid then
        return
    end

    -- Separate "help" and "vars" windows, not tracked in globals (storage), unlike main AI Combinator gui
    if element.name == "ai-combinator-help-close" then
        return element.parent.destroy()
    elseif element.name == "ai-combinator-vars-close" then
        return (element.parent.paent or element.parent).destroy()
    elseif element.name == "ai-combinator-vars-pause" then
        return vars_dialog.show(event.player_index, vars_window_uid(element), element.style.name ~= "green_button", true)
    end

    if element.tags and element.tags.close_combinator_ui then
        guis.close(element.tags.uid, event.player_index)
        return
    end

    -- Handle description buttons that have tags with uid
    if element.tags and element.tags.uid then
        if element.tags.description_add or element.tags.description_edit then
            set_description_dialog.show(event.player_index, element.tags.uid)
            return
        end
    end

    local uid, _ = find_gui(event)
    if not uid then
        return
    end

    local combinator = storage.combinators[uid]
    if not combinator then
        return guis.close(uid, event.player_index)
    end
    local el_id = element.name
    local rmb = defines.mouse_button_type.right

    if el_id == "ai-combinator-set-task" then
        set_task_dialog.show(event.player_index, uid)
    elseif el_id == "ai-combinator-cancel-ai" then
        ai_operation_manager.cancel_operation(uid)
    elseif el_id == "ai-combinator-desc-btn-flow" then
        set_description_dialog.show(event.player_index, uid)
    elseif el_id == "ai-combinator-edit-code" then
        edit_code_dialog.show(event.player_index, uid)
    elseif el_id == "ai-combinator-save" then
        combinator_service.save_code(uid)
    elseif el_id == "ai-combinator-commit" then
        combinator_service.save_code(uid)
        guis.close(uid, event.player_index)
    elseif el_id == "ai-combinator-close" then
        guis.close(uid, event.player_index)
    elseif el_id == "ai-combinator-vars" then
        if event.button == rmb then
            if event.shift then
                code_manager.clear_outputs(uid)
            else -- clear env
                for k, _ in pairs(combinator.vars) do
                    combinator.vars[k] = nil
                end
                vars_dialog.update(game.players[event.player_index], uid)
            end
        else
            vars_dialog.show(event.player_index, uid, event.shift, event.shift or nil)
        end
    end
end

function guis.on_gui_close(ev)
    if dialog_manager.handle_dialog_closed(ev.player_index) then
        return
    end

    local uid, _ = find_gui(ev)
    if not uid then
        return
    end
    guis.close(uid, ev.player_index)
end

function guis.vars_window_toggle(pn, toggle_on)
    local gui = game.players[pn].gui.screen["ai-combinator-gui"]
    local uid, _ = find_gui({ element = gui })
    if not uid then
        uid = storage.guis_player["vars." .. pn]
    end
    if not uid then
        return
    end
    vars_dialog.show(pn, uid, nil, toggle_on)
end

event_handler.add_handler(defines.events.on_gui_click, guis.on_gui_click)
event_handler.add_handler(defines.events.on_gui_closed, guis.on_gui_close)

return guis
