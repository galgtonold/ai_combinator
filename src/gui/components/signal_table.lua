local signal_element = require("src/gui/components/signal_element")

local component = {}

function component.show(parent, signals_with_count, slot_style)
    local button_table = parent.add({ type = "table", column_count = 10, style = "filter_slot_table" })
    local row_count = math.ceil(#signals_with_count / 10)
    button_table.style.height = 40 * row_count

    for _, signal in pairs(signals_with_count) do
        signal_element.show(button_table, slot_style, signal)
    end
    return row_count
end

return component
