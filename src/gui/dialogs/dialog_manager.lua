--[[
Stack-based Dialog Manager

This module manages a stack of dialogs for each player, allowing proper handling of nested dialogs.
When a dialog opens another dialog, the new dialog is pushed onto the stack. When a dialog is closed,
it's popped from the stack along with all subordinate dialogs, revealing the parent dialog underneath.

Key features:
- Stack-based dialog management per player
- Proper ESC key handling for nested dialogs
- Automatic cleanup when players are removed
- Backward compatibility with existing dialog code
- Support for clicking outside dialogs to close them
- Closes all subordinate dialogs when a parent dialog is closed

Usage:
  dialog_manager.push_dialog(player_index, dialog_element)     -- Open a new dialog
  dialog_manager.pop_dialog(player_index)                     -- Close current dialog
  dialog_manager.get_current_dialog(player_index)             -- Get topmost dialog
  dialog_manager.close_all_dialogs(player_index)              -- Close all dialogs
  dialog_manager.close_dialog_and_children(player_index, dialog) -- Close specific dialog and its children
--]]

local dialog_manager = {
    dialog_stacks = {},
}

-- Initialize dialog stack for a player if it doesn't exist
local function ensure_dialog_stack(player_index)
    if not dialog_manager.dialog_stacks[player_index] then
        dialog_manager.dialog_stacks[player_index] = {}
    end
end

-- Prune invalid dialogs from the stack
local function prune_invalid_dialogs(player_index)
    ensure_dialog_stack(player_index)
    local stack = dialog_manager.dialog_stacks[player_index]
    for i = #stack, 1, -1 do
        if not (stack[i] and stack[i].valid) then
            table.remove(stack, i)
        end
    end
end

-- Get the topmost (current) dialog for a player
function dialog_manager.get_current_dialog(player_index)
    prune_invalid_dialogs(player_index)
    local stack = dialog_manager.dialog_stacks[player_index]
    return stack[#stack]
end

-- Push a new dialog onto the stack (opens a new dialog)
function dialog_manager.push_dialog(player_index, dialog)
    ensure_dialog_stack(player_index)
    table.insert(dialog_manager.dialog_stacks[player_index], dialog)
end

-- Find the index of a dialog in the stack
local function find_dialog_index(player_index, dialog)
    ensure_dialog_stack(player_index)
    local stack = dialog_manager.dialog_stacks[player_index]
    for i, d in ipairs(stack) do
        if d == dialog then
            return i
        end
    end
    return nil
end

-- Clear gui_t references for a destroyed dialog based on its tags
local function clear_dialog_references(dialog)
    if not dialog or not dialog.valid then
        return
    end

    local tags = dialog.tags
    if not tags or not tags.uid then
        return
    end

    local gui_t = storage.guis[tags.uid]
    if not gui_t then
        return
    end

    -- Clear references based on dialog type tags
    if tags.edit_code_dialog then
        gui_t.edit_code_dialog = nil
        gui_t.edit_code_textbox = nil
        gui_t.edit_code_prev_button = nil
        gui_t.edit_code_next_button = nil
        gui_t.edit_code_history_info = nil
        gui_t.edit_code_version_info = nil
    end
    if tags.test_case_dialog then
        gui_t.test_case_dialog = nil
        gui_t.test_case_status_flow = nil
    end
    if tags.task_dialog then
        gui_t.task_dialog = nil
        gui_t.task_textbox = nil
    end
    if tags.description_dialog then
        gui_t.description_dialog = nil
        gui_t.description_textbox = nil
    end
    if tags.quantity_dialog then
        gui_t.quantity_dialog = nil
        gui_t.quantity_input = nil
    end
    if tags.test_name_dialog then
        gui_t.test_name_dialog = nil
        gui_t.test_name_input = nil
    end
end

-- Close a specific dialog and all dialogs above it in the stack (its children)
function dialog_manager.close_dialog_and_children(player_index, dialog)
    ensure_dialog_stack(player_index)
    local stack = dialog_manager.dialog_stacks[player_index]
    local dialog_index = find_dialog_index(player_index, dialog)

    if not dialog_index then
        -- Dialog not in stack, just destroy it if valid
        clear_dialog_references(dialog)
        if dialog and dialog.valid then
            dialog.destroy()
        end
        return
    end

    -- Close all dialogs from the top of the stack down to (and including) the target dialog
    for i = #stack, dialog_index, -1 do
        local d = table.remove(stack, i)
        clear_dialog_references(d)
        if d and d.valid then
            d.destroy()
        end
    end
end

-- Pop the topmost dialog from the stack (closes current dialog)
function dialog_manager.pop_dialog(player_index)
    ensure_dialog_stack(player_index)
    local stack = dialog_manager.dialog_stacks[player_index]
    if #stack > 0 then
        local dialog = table.remove(stack)
        clear_dialog_references(dialog)
        if dialog and dialog.valid then
            dialog.destroy()
        end
        return dialog
    end
    return nil
end

-- Get the number of open dialogs for a player
function dialog_manager.get_dialog_count(player_index)
    prune_invalid_dialogs(player_index)
    return #dialog_manager.dialog_stacks[player_index]
end

-- Close all dialogs for a player
function dialog_manager.close_all_dialogs(player_index)
    ensure_dialog_stack(player_index)
    local stack = dialog_manager.dialog_stacks[player_index]
    for i = #stack, 1, -1 do
        local dialog = stack[i]
        clear_dialog_references(dialog)
        if dialog and dialog.valid then
            dialog.destroy()
        end
    end
    dialog_manager.dialog_stacks[player_index] = {}
end

-- Clean up dialog stack when player is removed
function dialog_manager.cleanup_player(player_index)
    if dialog_manager.dialog_stacks[player_index] then
        dialog_manager.close_all_dialogs(player_index)
        dialog_manager.dialog_stacks[player_index] = nil
    end
end

-- Legacy compatibility functions
function dialog_manager.set_current_dialog(player_index, dialog)
    -- For backward compatibility, this will push the dialog onto the stack
    dialog_manager.push_dialog(player_index, dialog)
end

function dialog_manager.close_dialog(player_index)
    -- For backward compatibility, this will pop the topmost dialog
    dialog_manager.pop_dialog(player_index)
end

function dialog_manager.close_background_dialogs(event)
    -- Close dialogs when the user clicks outside of them
    local player_index = event.player_index
    local element = event.element

    -- Do not close dialog when clicked inside current dialog
    while element and element.valid do
        local current_dialog = dialog_manager.get_current_dialog(player_index)
        if current_dialog and element == current_dialog then
            return
        end
        element = element.parent
    end

    -- Close the topmost dialog if clicking outside
    local current_dialog = dialog_manager.get_current_dialog(player_index)
    if current_dialog and current_dialog.valid then
        dialog_manager.pop_dialog(player_index)
    end
end

function dialog_manager.handle_dialog_closed(player_index)
    -- Also fired for original auto-closed combinator GUI, which is ignored due to uid=gui_t=nil
    -- How unfocus/close sequence works:
    --  - click on code -  sets "code_focused = true", and game suppresses hotkeys except for esc
    --  - esc - with code_focused set, it is cleared, unfocus(), player.opened re-set to this gui again
    --  - esc again - as gui_t.code_focused is unset now, gui is simply closed here

    -- Check if there's a dialog open and close the topmost one
    local current_dialog = dialog_manager.get_current_dialog(player_index)
    if current_dialog and current_dialog.valid then
        -- Get the uid from the dialog tags to find the main combinator window
        local dialog_uid = current_dialog.tags and current_dialog.tags.uid
        dialog_manager.pop_dialog(player_index)

        -- If there are no more dialogs in the stack, refocus the main combinator window
        if dialog_manager.get_dialog_count(player_index) == 0 and dialog_uid then
            local gui_t = storage.guis[dialog_uid]
            if gui_t and gui_t.ai_combinator_gui and gui_t.ai_combinator_gui.valid then
                local p = game.players[player_index]
                p.opened = gui_t.ai_combinator_gui
            end
        end
        return true
    end
    return false
end

return dialog_manager
