local component = {}

function component.show(parent, red_network, green_network)
  local has_network = red_network ~= nil or green_network ~= nil

  if not has_network then
    parent.add{
      type = "label",
      caption = "Not connected",
      style = "label"
    }
    return
  end
  
  parent.add{
    type = "label",
    caption = "Connected to: ",
    style = "label"
  }
  
  if red_network then
    parent.add{
      type = "label",
      caption = "[color=red]" .. red_network.network_id .. "[/color] [img=info]",
      style = "label",
      tooltip = "Red circuit network with ID " .. red_network.network_id
    }
  end

  if green_network then
    parent.add{
      type = "label",
      caption = "[color=green]" .. green_network.network_id .. "[/color] [img=info]",
      style = "label",
      tooltip = "Green circuit network with ID " .. green_network.network_id
    }
  end
end

return component