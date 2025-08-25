local utils = require('src/core/utils')

local component = {}

function component.show(parent, style, signal_with_count, count)
  local flow = parent.add{type="flow"}

  local button = flow.add{
      type="choose-elem-button",
      elem_type="signal",
      signal = signal_with_count.signal,
      style=style
  }

  local count_label = flow.add{
    type="label", 
    caption=tostring(utils.format_number(signal_with_count.count)),
    style="count_label",
    ignored_by_interaction=true
  }
  count_label.style.top_margin = 20
  count_label.style.left_margin = -40
  count_label.style.right_margin = -40
  count_label.style.horizontal_align = "right"
  count_label.style.maximal_width = 33
  count_label.style.minimal_width = 33
  button.locked = true
end

return component