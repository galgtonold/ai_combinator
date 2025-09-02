local component = {
  status = {
    RED = "utility/status_not_working",
    GREEN = "utility/status_working",
    YELLOW = "utility/status_yellow"
  }
}

function component.show(parent, sprite, status_text)
  local status_flow = parent.add{type='flow', name='mlc-status-flow', direction='horizontal'}
  status_flow.style.vertical_align = 'center'
  component.update(status_flow, sprite, status_text)

  return status_flow
end

function component.update(parent, sprite, status_text)
  parent.clear()

  -- Add status elements
  local status_sprite = parent.add{type = 'sprite', style = 'status_image', sprite = sprite}
  status_sprite.style.stretch_image_to_widget_size = true
  parent.add{type = 'label', name='mlc-status-text', caption=status_text}
end

return component