local tbar = {}

function tbar.show(gui, caption, close_button_tags, extra_tags, extra_buttons)
  extra_tags = extra_tags or {}

  local titlebar = gui.add{type = "flow", style = "frame_header_flow", tags = extra_tags}
  titlebar.drag_target = gui
  local title_label = titlebar.add{
    type = "label",
    style = "frame_title",
    caption = caption,
    ignored_by_interaction = true,
    tags = extra_tags,
  }
  title_label.style.bottom_padding = 3
  title_label.style.top_margin = -3
  local filler = titlebar.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
    tags = extra_tags,
  }
  filler.style.height = 24
  filler.style.horizontally_stretchable = true
  filler.style.right_margin = 5

  if extra_buttons then
    for _, button in ipairs(extra_buttons) do
      titlebar.add(button)
    end
  end  

  local close_button_tags = close_button_tags or {}
  for k, v in pairs(extra_tags) do
    close_button_tags[k] = v
  end

  titlebar.add{
    type = "sprite-button",
    style = "frame_action_button",
    sprite = "utility/close",
    tooltip = {"gui.close-instruction"},
    tags = close_button_tags,
  }
  return titlebar
end

return tbar