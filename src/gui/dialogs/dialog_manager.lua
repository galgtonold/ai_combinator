--[[
Stack-based Dialog Manager

This module manages a stack of dialogs for each player, allowing proper handling of nested dialogs.
When a dialog opens another dialog, the new dialog is pushed onto the stack. When a dialog is closed,
it's popped from the stack, revealing the previous dialog underneath.

Key features:
- Stack-based dialog management per player
- Proper ESC key handling for nested dialogs
- Automatic cleanup when players are removed
- Backward compatibility with existing dialog code
- Support for clicking outside dialogs to close them

Usage:
  dialog_manager.push_dialog(player_index, dialog_element)     -- Open a new dialog
  dialog_manager.pop_dialog(player_index)                     -- Close current dialog
  dialog_manager.get_current_dialog(player_index)             -- Get topmost dialog
  dialog_manager.close_all_dialogs(player_index)              -- Close all dialogs
--]]

local dialog_manager = {
  dialog_stacks = {}
}

-- Initialize dialog stack for a player if it doesn't exist
local function ensure_dialog_stack(player_index)
  if not dialog_manager.dialog_stacks[player_index] then
    dialog_manager.dialog_stacks[player_index] = {}
  end
end

-- Get the topmost (current) dialog for a player
function dialog_manager.get_current_dialog(player_index)
  ensure_dialog_stack(player_index)
  local stack = dialog_manager.dialog_stacks[player_index]
  return stack[#stack]
end

-- Push a new dialog onto the stack (opens a new dialog)
function dialog_manager.push_dialog(player_index, dialog)
  ensure_dialog_stack(player_index)
  table.insert(dialog_manager.dialog_stacks[player_index], dialog)
end

-- Pop the topmost dialog from the stack (closes current dialog)
function dialog_manager.pop_dialog(player_index)
  ensure_dialog_stack(player_index)
  local stack = dialog_manager.dialog_stacks[player_index]
  if #stack > 0 then
    local dialog = table.remove(stack)
    if dialog and dialog.valid then
      dialog.destroy()
    end
    return dialog
  end
  return nil
end

-- Get the number of open dialogs for a player
function dialog_manager.get_dialog_count(player_index)
  ensure_dialog_stack(player_index)
  return #dialog_manager.dialog_stacks[player_index]
end

-- Close all dialogs for a player
function dialog_manager.close_all_dialogs(player_index)
  ensure_dialog_stack(player_index)
  local stack = dialog_manager.dialog_stacks[player_index]
  for i = #stack, 1, -1 do
    local dialog = stack[i]
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