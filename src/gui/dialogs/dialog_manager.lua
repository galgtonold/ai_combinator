local dialog_manager = {
  current_dialog = {}
}

function dialog_manager.get_current_dialog(player_index)
  return dialog_manager.current_dialog[player_index]
end

function dialog_manager.set_current_dialog(player_index, dialog)
  dialog_manager.current_dialog[player_index] = dialog
end

function dialog_manager.close_dialog(player_index)
  if dialog_manager.current_dialog[player_index] and dialog_manager.current_dialog[player_index].valid then
    dialog_manager.current_dialog[player_index].destroy()
    dialog_manager.current_dialog[player_index] = nil
  end
end

function dialog_manager.close_background_dialogs(event)
  -- Close dialogs when the user clicks outside of them
  local player_index = event.player_index
  local element = event.element
  -- Do not close dialog when clicked inside current dialog
  while element and element.valid do
    if dialog_manager.current_dialog[player_index] and element == dialog_manager.current_dialog[player_index] then
      return
    end
    element = element.parent
  end

  if dialog_manager.current_dialog[player_index] and dialog_manager.current_dialog[player_index].valid then
    dialog_manager.current_dialog[player_index].destroy()
    dialog_manager.current_dialog[player_index] = nil
  end
end


function dialog_manager.handle_dialog_closed(player_index)
	-- Also fired for original auto-closed combinator GUI, which is ignored due to uid=gui_t=nil
	-- How unfocus/close sequence works:
	--  - click on code -  sets "code_focused = true", and game suppresses hotkeys except for esc
	--  - esc - with code_focused set, it is cleared, unfocus(), player.opened re-set to this gui again
	--  - esc again - as gui_t.code_focused is unset now, gui is simply closed here
  
	-- Check if there's a set task dialog open and close it first
	if dialog_manager.current_dialog[player_index] and dialog_manager.current_dialog[player_index].valid then
		-- Get the uid from the dialog tags to find the main combinator window
		local dialog_uid = dialog_manager.current_dialog[player_index].tags and dialog_manager.current_dialog[player_index].tags.uid
		dialog_manager.close_dialog(player_index)
		-- Refocus the main combinator window so next escape will close it
		if dialog_uid then
			local gui_t = storage.guis[dialog_uid]
			if gui_t and gui_t.mlc_gui and gui_t.mlc_gui.valid then
				local p = game.players[player_index]
				p.opened = gui_t.mlc_gui
			end
		end
		return true
	end
  return false
end

return dialog_manager