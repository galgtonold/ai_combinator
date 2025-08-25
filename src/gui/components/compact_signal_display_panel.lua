local utils = require("src/core/utils")

local compact_signal_display_panel = {}

function compact_signal_display_panel.show(parent, signals)
  -- Create a 6-column grid for displaying actual output signals
  local signal_table = parent.add{
    type = "table",
    column_count = 6,
    style = "filter_slot_table",
    name = "actual-signal-table"
  }
  
  -- Convert signals to array for display
  local signal_array = {}
  for signal_name, count in pairs(signals or {}) do
    if count ~= 0 then
      table.insert(signal_array, {signal_name = signal_name, count = count})
    end
  end
  
  -- Show "No output" if empty
  if #signal_array == 0 then
    local empty_slot = signal_table.add{
      type = "flow",
      direction = "vertical",
      name = "empty-slot"
    }
    
    local empty_button = empty_slot.add{
      type = "choose-elem-button",
      elem_type = "signal",
      locked = true
    }
    empty_button.style.width = 40
    empty_button.style.height = 40
    
    -- Add a few more empty slots to fill the first row
    for i = 2, 6 do
      local empty_slot2 = signal_table.add{
        type = "flow",
        direction = "vertical"
      }
      local empty_button2 = empty_slot2.add{
        type = "choose-elem-button",
        elem_type = "signal",
        locked = true
      }
      empty_button2.style.width = 40
      empty_button2.style.height = 40
    end
  else
    -- Calculate rows needed
    local rows_needed = math.max(1, math.ceil(#signal_array / 6))
    local total_slots = rows_needed * 6
    
    -- Fill slots with signals and empty slots
    for i = 1, total_slots do
      local signal_data = signal_array[i]
      local slot_flow = signal_table.add{
        type = "flow",
        direction = "vertical",
        name = "actual-slot-" .. i
      }
      
      if signal_data then
        -- Try to parse the signal name back to a signal object
        local signal_obj = nil
        if storage.signals and storage.signals[signal_data.signal_name] then
          signal_obj = storage.signals[signal_data.signal_name]
        end
        
        local signal_button = slot_flow.add{
          type = "choose-elem-button",
          elem_type = "signal",
          signal = signal_obj,
          locked = true,
          name = "actual-signal-" .. i
        }
        signal_button.style.width = 40
        signal_button.style.height = 40
        
        -- Count label overlay
        local count_label = slot_flow.add{
          type = "label",
          caption = utils.format_number(signal_data.count),
          style = "count_label",
          ignored_by_interaction = true
        }
        count_label.style.top_margin = -40
        count_label.style.horizontal_align = "right"
        count_label.style.maximal_width = 38
      else
        -- Empty slot
        local empty_button = slot_flow.add{
          type = "choose-elem-button",
          elem_type = "signal",
          locked = true,
          name = "empty-actual-" .. i
        }
        empty_button.style.width = 40
        empty_button.style.height = 40
      end
    end
    
    signal_table.style.height = 40 * rows_needed
  end
end

return compact_signal_display_panel
