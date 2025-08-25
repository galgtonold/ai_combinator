local circuit_connection_header = require("src/gui/components/circuit_connection_header")

local component = {}

function component.add()

end

function component.update(frame, mlc)
    frame.clear()
    frame.add{
      type = "label",
      caption = "Input:",
      style = "subheader_caption_label"
    }
    red_network = mlc.e.get_or_create_control_behavior().get_circuit_network(defines.wire_connector_id.combinator_input_red)
    green_network = mlc.e.get_or_create_control_behavior().get_circuit_network(defines.wire_connector_id.combinator_input_green)
    circuit_connection_header.add(frame, red_network, green_network)

    local spacer = frame.add{
      type = "empty-widget",
    }
    spacer.style.horizontally_stretchable = true

    frame.add{
      type = "label",
      caption = "Output:",
      style = "subheader_caption_label"
    }

    red_network = mlc.out_red.get_control_behavior().get_circuit_network(defines.wire_connector_id.circuit_red)
    green_network = mlc.out_green.get_control_behavior().get_circuit_network(defines.wire_connector_id.circuit_green)
    if red_network and red_network.connected_circuit_count < 3 then
      red_network = nil
    end
    if green_network and green_network.connected_circuit_count < 3 then
      green_network = nil
    end
    circuit_connection_header.add(frame, red_network, green_network)
end

return component