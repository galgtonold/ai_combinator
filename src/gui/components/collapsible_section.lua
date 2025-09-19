local event_handler = require("src/events/event_handler")

local collapsible_section = {}

-- Text formatting utilities
local function format_variable(name)
    return '[color=#ffe6c0]' .. name .. '[/color]'
end

local function format_code(code)
    return '[font=default-listbox][color=#e6e6e6]' .. code .. '[/color][/font]'
end

local function format_header(text)
    return '[font=default-semibold]' .. text .. '[/font]'
end

local function format_subheader(text)
    return '[font=default-semibold][color=#ffcc80]' .. text .. '[/color][/font]'
end

local function format_warning()
    return '[color=#ffaa55]⚠[/color] '
end

local function format_check()
    return '[color=#90EE90]✓[/color] '
end

-- Content builder functions
function collapsible_section.add_text(parent, text)
    parent.add{type='label', caption=text}
end

function collapsible_section.add_variable_desc(parent, var_name, description, indent)
    local indent_str = indent and '    ' or ''
    parent.add{type='label', caption=indent_str .. format_variable(var_name) .. ' ' .. description}
end

function collapsible_section.add_code_example(parent, code, description)
    if description then
        parent.add{type='label', caption=format_header(description)}
    end
    if code then
        parent.add{type='label', caption=format_code(code)}
    end
end

function collapsible_section.add_tip(parent, text)
    parent.add{type='label', caption=format_check() .. text}
end

function collapsible_section.add_warning_section(parent, title, items)
    parent.add{type='label', caption=format_warning() .. format_header(title)}
    for _, item in ipairs(items) do
        parent.add{type='label', caption='  • ' .. item}
    end
end

function collapsible_section.add_subheader(parent, text, top_margin)
    local label = parent.add{type='label', caption=format_subheader(text)}
    if top_margin then
        label.style.top_margin = top_margin
    end
    return label
end

function collapsible_section.add_indented_section(parent, items, left_margin)
    local section = parent.add{type='flow', direction='vertical'}
    section.style.left_margin = left_margin or 12
    section.style.top_margin = 2
    
    for _, item in ipairs(items) do
        if type(item) == "string" then
            section.add{type='label', caption=item}
        elseif type(item) == "table" then
            if item.type == "variable" then
                collapsible_section.add_variable_desc(section, item.name, item.desc, item.indent)
            elseif item.type == "text" then
                collapsible_section.add_text(section, item.text)
            elseif item.name and item.desc then
                -- Handle items with name and desc directly (like API entries)
                collapsible_section.add_variable_desc(section, item.name, item.desc, item.indent)
            end
        end
    end
    
    return section
end

function collapsible_section.add_spacer(parent)
    parent.add{type='label', caption=' '}
end

-- Render content based on content structure
function collapsible_section.render_content(parent, content_items)
    for _, item in ipairs(content_items) do
        if type(item) == "string" then
            collapsible_section.add_text(parent, item)
        elseif type(item) == "table" then
            if item.type == "subheader" then
                collapsible_section.add_subheader(parent, item.text, item.margin)
            elseif item.type == "variables" then
                collapsible_section.add_indented_section(parent, item.items)
            elseif item.type == "code_example" then
                if type(item.code) == "table" then
                    collapsible_section.add_code_example(parent, nil, item.title)
                    for _, code_line in ipairs(item.code) do
                        collapsible_section.add_code_example(parent, code_line)
                    end
                else
                    collapsible_section.add_code_example(parent, item.code, item.title)
                end
            elseif item.type == "code_pattern" then
                collapsible_section.add_text(parent, format_header(item.title))
                for _, code_line in ipairs(item.code) do
                    collapsible_section.add_code_example(parent, code_line)
                end
            elseif item.type == "tips" then
                for _, tip in ipairs(item.items) do
                    collapsible_section.add_tip(parent, tip)
                end
            elseif item.type == "warning_section" then
                collapsible_section.add_warning_section(parent, item.title, item.items)
            elseif item.type == "spacer" then
                collapsible_section.add_spacer(parent)
            end
        end
    end
end

-- Create a collapsible section with its own event handling
function collapsible_section.show(parent, section_id, title, is_expanded)
    local section = parent.add{type='flow', direction='vertical'}
    section.style.top_margin = 8
    
    -- Create a frame for more Factorio-like appearance
    local section_frame = section.add{type='frame', direction='vertical', style='deep_frame_in_shallow_frame'}
    section_frame.style.padding = 4
    section_frame.style.horizontally_stretchable = true
    
    -- Clickable header with expand/collapse indicator
    local header_flow = section_frame.add{type='flow', direction='horizontal'}
    header_flow.style.vertical_align = "center"
    header_flow.style.horizontally_stretchable = true
    
    local expand_icon = is_expanded and "▼" or "▶"
    local header_btn = header_flow.add{
        type='button',
        caption='[color=#87CEEB]' .. expand_icon .. '[/color] [font=default-bold][color=#ffffff]' .. title .. '[/color][/font]',
        style='transparent_button',
        tags={collapsible_section_toggle=section_id}
    }
    header_btn.style.font = "default-bold"
    header_btn.style.height = 32
    header_btn.style.horizontally_stretchable = true
    header_btn.style.horizontal_align = "left"
    header_btn.style.padding = {4, 8}
    
    -- Content container (visible/hidden based on expanded state)
    local content = section_frame.add{type='flow', direction='vertical', name='content_' .. section_id}
    content.style.left_margin = 12
    content.style.top_margin = 4
    content.style.bottom_margin = 4
    content.visible = is_expanded
    
    return section, content
end

-- Handle collapsible section toggle events
local function on_gui_click(event)
    local el = event.element
    
    if not el.valid or not el.tags then return end
    
    -- Handle section toggle
    if el.tags.collapsible_section_toggle then
        local section_id = el.tags.collapsible_section_toggle
        local content = el.parent.parent["content_" .. section_id]
        
        if content then
            -- Toggle visibility
            content.visible = not content.visible
            
            -- Update button caption with new arrow
            local expand_icon = content.visible and "▼" or "▶"
            local title = el.caption:match("%[font=default%-bold%]%[color=#ffffff%](.+)%[/color%]%[/font%]")
            if title then
                el.caption = '[color=#87CEEB]' .. expand_icon .. '[/color] [font=default-bold][color=#ffffff]' .. title .. '[/color][/font]'
            end
        end
    end
end

-- Register the event handler
event_handler.add_handler(defines.events.on_gui_click, on_gui_click)

return collapsible_section
