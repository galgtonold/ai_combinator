local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")
local testing = require("src/testing/testing")

local component = {}

function component.show(parent, uid)
  local test_cases_container = parent.add{
    type='flow', name='mlc_test_cases_container', direction='vertical'
  }
  local gui_t = storage.guis[uid]
  gui_t.mlc_test_cases_container = test_cases_container
  component.update(uid)
end

function component.update(uid)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  if not mlc or not gui_t or not gui_t.mlc_test_cases_container then
    return
  end
  
  local container = gui_t.mlc_test_cases_container
  container.clear()
  
  -- Helper function to add elements to the el_map
  local function add_to_map(element)
    if element.name then
      gui_t.el_map[element.index] = element
    end
    return element
  end
  
  -- Initialize test cases if not present
  if not mlc.test_cases then
    mlc.test_cases = {}
  end
  
  -- Header with summary and buttons
  local header_flow = container.add{
    type = "flow",
    direction = "horizontal",
    name = "mlc-test-cases-header"
  }
  
  local title_flow = header_flow.add{
    type = "flow",
    direction = "horizontal"
  }
  
  title_flow.add{
    type = "label",
    caption = "Test Cases",
    style = "semibold_label"
  }
  
  local add_test_btn = title_flow.add{
    type = "sprite-button",
    name = "mlc-add-test-case",
    sprite = "utility/add",
    tooltip = "Add test case",
    style = "mini_button_aligned_to_text_vertically",
    tags = {uid = uid, add_test_case = true}
  }
  add_test_btn.style.left_margin = 8
  add_to_map(add_test_btn)
  
  -- Calculate test case summary
  local total_tests = #mlc.test_cases
  local passed_tests = 0
  for _, test_case in ipairs(mlc.test_cases) do
    local signals_match = test_case.success or false
        
    if signals_match then
      passed_tests = passed_tests + 1
    end
  end
  
  if total_tests > 0 then
    local summary_label = title_flow.add{
      type = "label",
      caption = string.format("(%d/%d passing)", passed_tests, total_tests),
      style = "label"
    }
    summary_label.style.left_margin = 8
    summary_label.style.font_color = passed_tests == total_tests and {0.3, 0.8, 0.3} or {0.8, 0.8, 0.3}
  end
  
  local spacer = header_flow.add{type = "empty-widget"}
  spacer.style.horizontally_stretchable = true
  
  local auto_generate_btn = header_flow.add{
    type = "button",
    name = "mlc-auto-generate-tests",
    caption = "Auto Generate",
    tooltip = "Automatically generate test cases based on current inputs",
    style = "button",
    tags = {uid = uid, auto_generate_tests = true}
  }
  add_to_map(auto_generate_btn)

  local auto_generate_btn = header_flow.add{
    type = "button",
    name = "mlc-fix-tests",
    caption = "Fix with AI",
    tooltip = "Automatically fix implementation to make all tests pass",
    style = "green_button",
    tags = {uid = uid, fix_tests = true}
  }
  add_to_map(auto_generate_btn)

  
  -- Condensed test cases list
  if #mlc.test_cases > 0 then
    local test_scroll = container.add{
      type = "scroll-pane",
      name = "mlc-test-cases-scroll",
      direction = "vertical"
    }
    test_scroll.style.maximal_height = 200
    test_scroll.style.horizontally_stretchable = true
    add_to_map(test_scroll)
    
    for i, test_case in ipairs(mlc.test_cases) do
      local test_frame = test_scroll.add{
        type = "frame",
        direction = "horizontal",
        style = "subheader_frame",
        name = "test-case-frame-" .. i,
        tags = {uid = uid, edit_test_case = i}
      }
      test_frame.style.horizontally_stretchable = true
      test_frame.style.padding = 4
      
      -- Status indicator
      local status_sprite = test_frame.add{
        type = "sprite",
        sprite = "utility/status_working",
        tags = {uid = uid, edit_test_case = i}
      }

      if test_case.success then
        status_sprite.sprite = "utility/status_working"
        status_sprite.tooltip = "Test passes"
      else
        status_sprite.sprite = "utility/status_not_working"
        status_sprite.tooltip = "Test fails"
      end
      
      -- Test name
      local name_label = test_frame.add{
        type = "label",
        caption = test_case.name or ("Test Case " .. i),
        style = "label",
        tags = {uid = uid, edit_test_case = i}
      }
      name_label.style.left_margin = 8
      
      local spacer = test_frame.add{
        type = "empty-widget",
        tags = {uid = uid, edit_test_case = i}
      }
      spacer.style.horizontally_stretchable = true
      
      -- Only delete button - edit is handled by clicking anywhere on the frame
      local delete_btn = test_frame.add{
        type = "sprite-button",
        name = "mlc-delete-test-case-" .. i,
        sprite = "utility/trash",
        tooltip = "Delete test case",
        style = "tool_button_red",
        tags = {uid = uid, delete_test_case = i}
      }
      delete_btn.style.left_margin = 2
      add_to_map(delete_btn)
    end
  else
    local empty_label = container.add{
      type = "label",
      caption = "No test cases defined. Click + to add one or use Auto Generate.",
      style = "label"
    }
    empty_label.style.font_color = {0.6, 0.6, 0.6}
    empty_label.style.top_margin = 8
  end
end

local function on_test_case_evaluated(event)
  component.update(event.uid)
end

local function delete_test_case(uid, test_index)
  local mlc = storage.combinators[uid]
  if not mlc or not mlc.test_cases then return end

  table.remove(mlc.test_cases, test_index)
end

local function add_test_case(uid)
  local mlc = storage.combinators[uid]
  if not mlc then return end
  
  if not mlc.test_cases then
    mlc.test_cases = {}
  end
  
  local new_test_index = #mlc.test_cases + 1
  table.insert(mlc.test_cases, {
    name = "Test Case " .. new_test_index,
    red_input = {},
    green_input = {},
    expected_output = {},
    actual_output = {},
    success = false
  })
end

local function auto_generate_test_cases(uid)
  -- Placeholder for auto-generation logic
  local mlc = storage.combinators[uid]
  if not mlc then return end
  
  -- TODO: Implement auto-generation based on current inputs/outputs
end

local function on_gui_click(event)
  if not event.element or not event.element.valid or not event.element.tags then return end

  if event.element.tags.delete_test_case ~= nil then
    delete_test_case(event.element.tags.uid, event.element.tags.delete_test_case)
    component.update(event.element.tags.uid)
  elseif event.element.tags.add_test_case then
    add_test_case(event.element.tags.uid)
    component.update(event.element.tags.uid)
  elseif event.element.tags.auto_generate_tests then
    auto_generate_test_cases(event.element.tags.uid)
  end
end

event_handler.add_handler(constants.events.on_test_case_evaluated, on_test_case_evaluated)
event_handler.add_handler(constants.events.on_test_case_name_updated, on_test_case_evaluated)
event_handler.add_handler(defines.events.on_gui_click, on_gui_click)


return component