-- src/events/hotkey_events.lua
-- Handles keyboard hotkey events for the AI Combinator mod
--
-- Keybindings:
--   mlc-code-save: Save code in active combinator
--   mlc-code-commit: Save and close combinator GUI
--   mlc-code-close: Close all dialogs and combinator GUI
--   mlc-code-vars: Toggle variables window
--   mlc-open-gui: Open combinator GUI when hovering over one

local hotkey_events = {}

local guis  -- Lazy loaded to avoid circular dependency
local help_dialog
local vars_dialog

local function get_guis()
  if not guis then
    guis = require('src/gui/gui')
  end
  return guis
end

local function get_help_dialog()
  if not help_dialog then
    help_dialog = require('src/gui/dialogs/help_dialog')
  end
  return help_dialog
end

local function get_vars_dialog()
  if not vars_dialog then
    vars_dialog = require('src/gui/dialogs/vars_dialog')
  end
  return vars_dialog
end

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
  if uid then get_guis().save_code(uid) end
end

-- Save and close combinator GUI
local function on_code_commit(ev)
  local uid, gui_t = next(storage.guis)
  if not uid then return end
  local g = get_guis()
  g.save_code(uid)
  g.close(uid)
end

-- Close all dialogs and combinator GUI
local function on_code_close(ev)
  get_guis().vars_window_toggle(ev.player_index, false)
  get_help_dialog().show(ev.player_index, false)
  local uid, gui_t = next(storage.guis)
  if not uid then return end
  get_guis().close(uid)
end

-- Toggle variables window
local function on_code_vars(ev)
  get_guis().vars_window_toggle(ev.player_index)
end

-- Open combinator GUI when hovering over one
local function on_open_gui(ev)
  local player = game.players[ev.player_index]
  local e = player.selected
  if e and e.name == 'mlc' then player.opened = e end
end

function hotkey_events.register()
  script.on_event('mlc-code-save', on_code_save)
  script.on_event('mlc-code-commit', on_code_commit)
  script.on_event('mlc-code-close', on_code_close)
  script.on_event('mlc-code-vars', on_code_vars)
  script.on_event('mlc-open-gui', on_open_gui)
end

return hotkey_events
