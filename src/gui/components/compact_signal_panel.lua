local utils = require("src/core/utils")
local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")

local signal_element = require("src/gui/components/signal_element")

local compact_signal_panel = {}

function compact_signal_panel.show(parent, signals, uid, test_index, signal_type)
  local gui_t = storage.guis[uid]
  -- Create a compact 6-column grid of signal slots
  local signal_frame = parent.add{
    type="frame", direction="vertical", style="ugg_deep_frame", name = "signal-table-" .. signal_type, 
    tags = {uid = uid, test_index = test_index, signal_type = signal_type}
  }
  gui_t["compact_" .. signal_type .. "_signal_panel"] = signal_frame
  compact_signal_panel.update(signal_frame, signals, uid, test_index, signal_type)
end

function compact_signal_panel.update(signal_frame, signals, uid, test_index, signal_type)
  signal_frame.clear()
  local signal_table = signal_frame.add{type="table", column_count=6, style="filter_slot_table"}


  -- Convert signal array to lookup table for easier access
  local signal_lookup = {}
  for i, signal_data in ipairs(signals) do
    if signal_data.signal then
      signal_lookup[i] = signal_data
    end
  end
  
  -- Calculate how many rows we need (minimum 1, expand when last slot of a row is filled)
  local max_filled_slot = 0
  for i = 1, 60 do
    if signal_lookup[i] and signal_lookup[i].signal then
      max_filled_slot = i
    end
  end
  
  -- Always show at least one empty row, and add a new row if the last slot of the current row is filled
  local rows_needed = math.max(1, math.ceil(max_filled_slot / 6))
  if max_filled_slot > 0 and max_filled_slot % 6 == 0 then
    rows_needed = rows_needed + 1 -- Add one more row if last slot of current row is filled
  end
  local total_slots = rows_needed * 6
  signal_table.style.height = 40 * rows_needed

  -- Create slots
  for i = 1, total_slots do
    local signal_data = signal_lookup[i] or {}
    local button_tags = {
      uid = uid,
      test_index = test_index,
      signal_type = signal_type,
      slot_index = i
    }
    local edit_button_tags = {
        edit_test_signal_quantity = true,
        uid = uid,
        test_index = test_index,
        signal_type = signal_type,
        slot_index = i,
    }
    signal_element.show(signal_table, nil, signal_data, true, button_tags, edit_button_tags)
  end
end


local function get_signal_array(uid, test_index, signal_type)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases or not mlc.test_cases[test_index] then return {} end
  local test_case = mlc.test_cases[test_index]
  if signal_type == "red" then
    return test_case.red_input
  elseif signal_type == "green" then
    return test_case.green_input
  elseif signal_type == "expected" then
    return test_case.expected_output
  else
    return {}
  end

end


function compact_signal_panel.on_gui_elem_changed(event)
  local element = event.element
  if not element.tags then return end
  
  local uid = element.tags.uid
  local test_index = element.tags.test_index
  local signal_type = element.tags.signal_type
  local slot_index = element.tags.slot_index
      
  local signal_array = get_signal_array(uid, test_index, signal_type)

  -- Ensure the array is large enough
  while #signal_array < slot_index do
    table.insert(signal_array, {})
  end
  
  -- Update the signal
  if not signal_array[slot_index] then
    signal_array[slot_index] = {}
  end
  
  signal_array[slot_index].signal = element.elem_value
  
  -- If signal was cleared, also clear the count
  if not element.elem_value then
    signal_array[slot_index].count = nil
  elseif not signal_array[slot_index].count then
    signal_array[slot_index].count = 1 -- Default count
  end
  
  -- Clean up empty entries
  for i = #signal_array, 1, -1 do
    local entry = signal_array[i]
    if not entry.signal or not entry.count or entry.count == 0 then
      table.remove(signal_array, i)
    else
      break
    end
  end
  
  -- Refresh the dialog to show/hide edit buttons properly and expand rows if needed
  local gui_t = storage.guis[uid]
  if gui_t and gui_t.test_case_dialog and gui_t.test_case_dialog.valid then
    local panel_name = "compact_" .. signal_type .. "_signal_panel"
    local panel = gui_t[panel_name]
    if panel then
      compact_signal_panel.update(panel, signal_array, uid, test_index, signal_type)
    end
  end
  
  -- Auto-run the test after signal changes
  if signal_type == "red" or signal_type == "green" then
    event_handler.raise_event(constants.events.on_test_case_updated, {uid = uid, test_index = test_index})
  end
end

function compact_signal_panel.on_quantity_set(event)
  if not event.edit_test_signal_quantity then return end

  local signal_array = get_signal_array(event.uid, event.test_index, event.signal_type)
  if not signal_array then return end

  signal_array[event.slot_index] = signal_array[event.slot_index] or {}
  signal_array[event.slot_index].count = event.quantity

  local gui_t = storage.guis[event.uid]
  local panel_name = "compact_" .. event.signal_type .. "_signal_panel"
  local panel = gui_t[panel_name]
  compact_signal_panel.update(panel, signal_array, event.uid, event.test_index, event.signal_type)
end

event_handler.add_handler(defines.events.on_gui_elem_changed, compact_signal_panel.on_gui_elem_changed)
event_handler.add_handler(constants.events.on_quantity_set, compact_signal_panel.on_quantity_set)

return compact_signal_panel
