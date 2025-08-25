local utils = require("src/core/utils")

local compact_signal_panel = {}

function compact_signal_panel.show(parent, signals, uid, test_index, signal_type)
  -- Create a compact 6-column grid of signal slots
  local signal_table = parent.add{
    type = "table",
    column_count = 6,
    style = "filter_slot_table",
    name = "signal-table-" .. signal_type,
    tags = {uid = uid, test_index = test_index, signal_type = signal_type}
  }
  
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
  
  -- Create slots
  for i = 1, total_slots do
    local signal_data = signal_lookup[i] or {}
    local slot_flow = signal_table.add{
      type = "flow",
      direction = "vertical",
      name = "slot-" .. i,
      tags = {uid = uid, test_index = test_index, signal_type = signal_type, slot_index = i}
    }
    
    -- Signal chooser button
    local signal_button = slot_flow.add{
      type = "choose-elem-button",
      elem_type = "signal",
      signal = signal_data.signal,
      name = "signal-button-" .. i,
      tags = {
        uid = uid,
        test_index = test_index,
        signal_type = signal_type,
        slot_index = i,
        test_signal_elem = true
      }
    }
    signal_button.style.width = 40
    signal_button.style.height = 40
    
    -- Overlay count label (positioned like in the base game)
    if signal_data.count and signal_data.count ~= 0 then
      local count_label = slot_flow.add{
        type = "label",
        caption = utils.format_number(signal_data.count),
        style = "count_label",
        name = "count-label-" .. i,
        ignored_by_interaction = true,
        tags = {uid = uid, test_index = test_index, signal_type = signal_type, slot_index = i}
      }
      count_label.style.top_margin = -40
      count_label.style.left_margin = 0
      count_label.style.right_margin = 0
      count_label.style.horizontal_align = "right"
      count_label.style.maximal_width = 38
      count_label.style.minimal_width = 38
    end
    
    -- Overlay edit button (small button in corner for editing quantity)
    if signal_data.signal then
      local edit_button = slot_flow.add{
        type = "sprite-button",
        sprite = "utility/rename_icon",
        name = "edit-button-" .. i,
        style = "mini_button",
        tooltip = "Edit quantity",
        tags = {
          uid = uid,
          test_index = test_index,
          signal_type = signal_type,
          slot_index = i,
          edit_signal_quantity = true
        }
      }
      edit_button.style.width = 16
      edit_button.style.height = 16
      edit_button.style.top_margin = -20
      edit_button.style.left_margin = 22
    end
  end
  
  signal_table.style.height = 40 * rows_needed
end

return compact_signal_panel
