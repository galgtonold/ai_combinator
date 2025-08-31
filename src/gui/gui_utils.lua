local gui_utils = {}

-- Helper function to get padding/margin
local function get_spacing(elem)
    local style = elem.style
    if not style then
        return {
            top = 0, right = 0, bottom = 0, left = 0,
            margin_top = 0, margin_right = 0, margin_bottom = 0, margin_left = 0
        }
    end
    
    return {
        top = style.top_padding or 0,
        right = style.right_padding or 0,
        bottom = style.bottom_padding or 0,
        left = style.left_padding or 0,
        margin_top = style.top_margin or 0,
        margin_right = style.right_margin or 0,
        margin_bottom = style.bottom_margin or 0,
        margin_left = style.left_margin or 0
    }
end

-- Recursively calculate the actual size of an element
local function get_actual_size(elem, parent_constraints)
    parent_constraints = parent_constraints or {}
    
    local element_width = 0
    local element_height = 0
    -- Base case: element with explicit size
    if elem.style and (elem.style.minimal_width or elem.style.minimal_height) then
        element_width= elem.style.minimal_width or 0
        element_height = elem.style.minimal_height or 0
        element_width = math.max(element_width, elem.style.minimal_width or 0)
        element_height = math.max(element_height, elem.style.minimal_height or 0)

        if elem.style.maximal_width and elem.style.maximal_width > 0 then
            element_width = math.min(element_width, elem.style.maximal_width)
        end
        if elem.style.maximal_height and elem.style.maximal_height > 0 then
            element_height = math.min(element_height, elem.style.maximal_height)
        end

        if element_width == 0 and elem.style.horizontally_stretchable and parent_constraints.width then
            element_width = parent_constraints.width or 0
        end
        if element_height == 0 and elem.style.vertically_stretchable and parent_constraints.height then
            element_height = parent_constraints.height or 0
        end
        if element_width ~= 0 and element_height ~= 0 then
            return {width = element_width, height = element_height}
        end
    end
    
    -- For containers without explicit size, calculate from children
    if elem.children and next(elem.children) then
        local total_width = 0
        local total_height = 0
        local spacing = get_spacing(elem)
        
        -- Determine flow direction
        local flow_direction = "none"
        if elem.type == "flow" then
            flow_direction = elem.direction or "horizontal"
        elseif elem.type == "frame" or elem.type == "scroll-pane" then
            flow_direction = "vertical"  -- Most frames layout vertically by default
        end
        
        -- Calculate size based on children
        local visible_children = {}
        for _, child in pairs(elem.children) do
            if child.visible ~= false then
                table.insert(visible_children, child)
            end
        end
        
        if #visible_children > 0 then
            if flow_direction == "horizontal" then
                -- Horizontal flow: sum widths, max height
                local max_height = 0
                for _, child in ipairs(visible_children) do
                    local child_size = get_actual_size(child)
                    local child_spacing = get_spacing(child)
                    total_width = total_width + child_size.width + 
                                  child_spacing.margin_left + child_spacing.margin_right
                    max_height = math.max(max_height, child_size.height + 
                                         child_spacing.margin_top + child_spacing.margin_bottom)
                end
                total_height = max_height
                
            elseif flow_direction == "vertical" then
                -- Vertical flow: max width, sum heights
                local max_width = 0
                for _, child in ipairs(visible_children) do
                    local child_size = get_actual_size(child)
                    local child_spacing = get_spacing(child)
                    total_height = total_height + child_size.height + 
                                   child_spacing.margin_top + child_spacing.margin_bottom
                    max_width = math.max(max_width, child_size.width + 
                                        child_spacing.margin_left + child_spacing.margin_right)
                end
                total_width = max_width
                
            else
                -- No specific flow (absolute positioning or table)
                -- Take the maximum extents
                for _, child in ipairs(visible_children) do
                    local child_size = get_actual_size(child)
                    local child_spacing = get_spacing(child)
                    total_width = math.max(total_width, child_size.width + 
                                          child_spacing.margin_left + child_spacing.margin_right)
                    total_height = math.max(total_height, child_size.height + 
                                           child_spacing.margin_top + child_spacing.margin_bottom)
                end
            end
        end
        
        -- Add container's own padding
        total_width = total_width + spacing.left + spacing.right
        total_height = total_height + spacing.top + spacing.bottom
        
        -- Apply style constraints
        if elem.style then
            total_width = math.max(total_width, elem.style.minimal_width or 0)
            total_height = math.max(total_height, elem.style.minimal_height or 0)
            
            if elem.style.maximal_width and elem.style.maximal_width > 0 then
                total_width = math.min(total_width, elem.style.maximal_width)
            end
            if elem.style.maximal_height and elem.style.maximal_height > 0 then
                total_height = math.min(total_height, elem.style.maximal_height)
            end
        end
        
        -- Handle stretchable properties
        if elem.style then
            if elem.style.horizontally_stretchable and parent_constraints.width then
                total_width = parent_constraints.width
            end
            if elem.style.vertically_stretchable and parent_constraints.height then
                total_height = parent_constraints.height
            end
        end
        
        return {width = total_width, height = total_height}
    end
    
    -- Fallback for elements without size or children
    local min_width = elem.style and elem.style.minimal_width or 0
    local min_height = elem.style and elem.style.minimal_height or 0
    return {width = min_width, height = min_height}
end

-- Find the surrounding window of an element
function gui_utils.get_element_window(element)
    if not element or not element.valid then
        return nil, "Invalid element"
    end
    
    local current = element
    while current do
        -- Check if this element has a location property (typically windows)
        if current.location then
            return current
        end
        current = current.parent
    end
    error("No surrounding window found")
    return nil
end

function gui_utils.get_position_relative_to_window(element, offset_x, offset_y)
  -- Offsets the coordinate of the surrounding window with the values
  local window = gui_utils.get_element_window(element)
  if not window then
      return {x = 0, y = 0}
  end
  return {
    x = (window.location.x or 0) + offset_x,
    y = (window.location.y or 0) + offset_y
  }
end

-- Get the position of an element
-- TODO doesn't quite work at the moment, requires calculation of text width and some more
function gui_utils.get_element_position(element)
    if not element or not element.valid then
        return nil, "Invalid element"
    end
    
    -- Build path from element to root
    local path = {}
    local current = element
    while current do
        table.insert(path, 1, current)
        current = current.parent
    end
    
    -- Find the topmost element with a queryable location
    local base_element, err = gui_utils.get_element_window(element)
    if not base_element then
        return nil, err
    end
    
    local base_index = 0
    for i, elem in ipairs(path) do
        if elem == base_element then
            base_index = i
            break
        end
    end
    
    -- Start with base location
    local x = base_element.location.x or base_element.location[1] or 0
    local y = base_element.location.y or base_element.location[2] or 0
    
    -- Calculate layout for stretchable elements
    local function calculate_layout(container)
        if not container.children then
            return {}, 0, "none"
        end
        
        local children = {}
        for _, child in pairs(container.children) do
            if child.visible ~= false then
                table.insert(children, child)
            end
        end
        
        local flow_direction = "none"
        if container.type == "flow" then
            flow_direction = container.direction or "horizontal"
        elseif container.type == "frame" or container.type == "scroll-pane" then
            flow_direction = "vertical"
        end
        
        local container_size = get_actual_size(container)
        local container_spacing = get_spacing(container)
        
        -- First pass: calculate fixed sizes and count stretchables
        local fixed_size = 0
        local stretchable_count = 0
        local child_sizes = {}
        
        for _, child in ipairs(children) do
            local size = get_actual_size(child, container_size)
            local spacing = get_spacing(child)
            child_sizes[child.index] = size
            
            if flow_direction == "horizontal" then
                if not (child.style and child.style.horizontally_stretchable) then
                    fixed_size = fixed_size + size.width + spacing.margin_left + spacing.margin_right
                else
                    stretchable_count = stretchable_count + 1
                end
            elseif flow_direction == "vertical" then
                if not (child.style and child.style.vertically_stretchable) then
                    fixed_size = fixed_size + size.height + spacing.margin_top + spacing.margin_bottom
                else
                    stretchable_count = stretchable_count + 1
                end
            end
        end
        
        -- Calculate space for stretchable elements
        local available_space = 0
        if flow_direction == "horizontal" then
            available_space = container_size.width - container_spacing.left - container_spacing.right - fixed_size
        elseif flow_direction == "vertical" then
            available_space = container_size.height - container_spacing.top - container_spacing.bottom - fixed_size
        end
        
        local stretchable_size = stretchable_count > 0 and math.max(0, available_space / stretchable_count) or 0
        
        -- Update sizes for stretchable elements
        for _, child in ipairs(children) do
            if flow_direction == "horizontal" and child.style and child.style.horizontally_stretchable then
                child_sizes[child.index].width = stretchable_size
            elseif flow_direction == "vertical" and child.style and child.style.vertically_stretchable then
                child_sizes[child.index].height = stretchable_size
            end
        end
        
        return child_sizes, stretchable_size, flow_direction
    end
    
    -- Traverse from base element to target element
    for i = base_index + 1, #path do
        local parent = path[i - 1]
        local current_elem = path[i]
        
        if not parent.children then
            break
        end
        
        local spacing = get_spacing(parent)
        x = x + spacing.left
        y = y + spacing.top
        
        -- Calculate layout for parent's children
        local child_sizes, stretchable_size, flow_direction = calculate_layout(parent)
        
        -- Find position of current element among siblings
        local offset_x = 0
        local offset_y = 0
        
        for _, sibling in pairs(parent.children) do
            if sibling.visible ~= false then
                if sibling.index == current_elem.index then
                    break
                end
                
                local sibling_size = child_sizes[sibling.index] or get_actual_size(sibling)
                local sibling_spacing = get_spacing(sibling)
                
                if flow_direction == "horizontal" then
                    offset_x = offset_x + sibling_size.width + sibling_spacing.margin_left + sibling_spacing.margin_right
                elseif flow_direction == "vertical" then
                    offset_y = offset_y + sibling_size.height + sibling_spacing.margin_top + sibling_spacing.margin_bottom
                end
            end
        end
        
        -- Add sibling offset and current element's margin
        local current_spacing = get_spacing(current_elem)
        x = x + offset_x + current_spacing.margin_left
        y = y + offset_y + current_spacing.margin_top
    end
    
    return {x = x, y = y}
end

-- Get both position and size of an element
function gui_utils.get_element_bounds(element)
    local position = gui_utils.get_element_position(element)
    if not position then
        return nil
    end
    
    local size = get_actual_size(element)
    return {
        x = position.x,
        y = position.y,
        width = size.width,
        height = size.height,
        right = position.x + size.width,
        bottom = position.y + size.height
    }
end

-- Debug function to print element hierarchy with sizes
function gui_utils.debug_element_tree(element, indent)
    indent = indent or 0
    local spacing = string.rep("  ", indent)
    
    if not element or not element.valid then
        return
    end
    
    local size = get_actual_size(element)
    local pos = gui_utils.get_element_position(element)
    
    local info = string.format("%s%s [%s]: size=%.0fx%.0f", 
        spacing, element.name or "unnamed", element.type, size.width, size.height)
    
    if pos then
        info = info .. string.format(" pos=%.0f,%.0f", pos.x, pos.y)
    end
    
    if element.style then
        if element.style.horizontally_stretchable then
            info = info .. " [H-stretch]"
        end
        if element.style.vertically_stretchable then
            info = info .. " [V-stretch]"
        end
    end
    
    game.print(info)
    
    if element.children then
        for _, child in pairs(element.children) do
            gui_utils.debug_element_tree(child, indent + 1)
        end
    end
end

return gui_utils