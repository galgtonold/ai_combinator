-- src/events/hotkey_events.lua
-- Handles keyboard hotkey events for the AI Combinator mod
--
-- Keybindings:
--   ai-combinator-code-save: Save code in active combinator
--   ai-combinator-code-commit: Save and close combinator GUI
--   ai-combinator-code-close: Close all dialogs and combinator GUI
--   ai-combinator-code-vars: Toggle variables window
--   ai-combinator-open-gui: Open combinator GUI when hovering over one

local hotkey_events = {}

local guis = require('src/gui/gui')
local help_dialog = require('src/gui/dialogs/help_dialog')
local vars_dialog = require('src/gui/dialogs/vars_dialog')

-- Get the single active GUI (if only one is open)
local function get_active_gui()
  local uid, gui_t
  for uid_chk, gui_t_chk in pairs(storage.guis) do
    if not uid then
      uid, gui_t = uid_chk, gui_t_chk
    else
      uid, gui_t = nil, nil
      break
    end
  end
  return uid, gui_t
end

-- Save code in active combinator
local function on_code_save(ev)
  local uid, gui_t = get_active_gui()
  if uid then guis.save_code(uid) end
end

-- Save and close combinator GUI
local function on_code_commit(ev)
  local uid, gui_t = next(storage.guis)
  if not uid then return end
  guis.save_code(uid)
  guis.close(uid)
end

-- Close all dialogs and combinator GUI
local function on_code_close(ev)
  guis.vars_window_toggle(ev.player_index, false)
  help_dialog.show(ev.player_index, false)
  local uid, gui_t = next(storage.guis)
  if not uid then return end
  guis.close(uid)
end

-- Toggle variables window
local function on_code_vars(ev)
  guis.vars_window_toggle(ev.player_index)
end

-- Open combinator GUI when hovering over one
local function on_open_gui(ev)
  local player = game.players[ev.player_index]
  local e = player.selected
  if e and e.name == 'ai-combinator' then player.opened = e end
end

function hotkey_events.register()
  script.on_event('ai-combinator-code-save', on_code_save)
  script.on_event('ai-combinator-code-commit', on_code_commit)
  script.on_event('ai-combinator-code-close', on_code_close)
  script.on_event('ai-combinator-code-vars', on_code_vars)
  script.on_event('ai-combinator-open-gui', on_open_gui)
end

return hotkey_events
