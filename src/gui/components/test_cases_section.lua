local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")
local circuit_network = require('src/core/circuit_network')
local test_case_dialog = require('src/gui/dialogs/test_case_dialog')
local bridge = require("src/services/bridge")
local ai_operation_manager = require('src/core/ai_operation_manager')


local component = {}

-- Forward declaration
local update_ai_buttons

function update_ai_buttons(uid)
  local mlc = storage.combinators[uid]
  local gui_t = storage.guis[uid]
  
  if not mlc or not gui_t then return end
  
  -- Update Fix with AI button state
  local fix_button = gui_t.mlc_fix_tests
  if fix_button and fix_button.valid then
    local total_tests = #(mlc.test_cases or {})
    local passed_tests = 0
    
    for _, test_case in ipairs(mlc.test_cases or {}) do
      if test_case.success then
        passed_tests = passed_tests + 1
      end
    end
    
    local all_tests_pass = total_tests > 0 and passed_tests == total_tests
    local ai_operation_running = ai_operation_manager.is_operation_active(uid)
    local max_attempts_reached = mlc.fix_attempt_count and mlc.fix_attempt_count >= 3
    
    -- Disable button if all tests pass, AI is running, or max attempts reached
    fix_button.enabled = not (all_tests_pass or ai_operation_running or max_attempts_reached)
    
    -- Update tooltip based on state
    if all_tests_pass then
      fix_button.tooltip = "All tests are passing - no fixes needed"
    elseif ai_operation_running then
      fix_button.tooltip = "AI operation in progress..."
    elseif max_attempts_reached then
      fix_button.tooltip = "Maximum fix attempts (3) reached"
    else
      fix_button.tooltip = "Automatically fix implementation to make all tests pass"
    end
  end
  
  -- Update Auto Generate button state
  local auto_gen_button = gui_t.mlc_auto_generate_tests
  if auto_gen_button and auto_gen_button.valid then
    local ai_operation_running = ai_operation_manager.is_operation_active(uid)
    auto_gen_button.enabled = not ai_operation_running
    
    if ai_operation_running then
      auto_gen_button.tooltip = "AI operation in progress..."
    else
      auto_gen_button.tooltip = "Automatically generate test cases based on current inputs"
    end
  end
end

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
      -- Also store by name for easy access
      gui_t[element.name:gsub('%-', '_')] = element
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

  local fix_tests_btn = header_flow.add{
    type = "button",
    name = "mlc-fix-tests",
    caption = "Fix with AI",
    tooltip = "Automatically fix implementation to make all tests pass",
    style = "green_button",
    tags = {uid = uid, fix_tests = true}
  }
  add_to_map(fix_tests_btn)

  
  -- Condensed test cases list
  if #mlc.test_cases > 0 then
    local test_scroll = container.add{
      type = "scroll-pane",
      name = "mlc-test-cases-scroll",
      direction = "vertical",
      horizontal_scroll_policy = "never",
      style = "shallow_scroll_pane"
    }
    test_scroll.style.maximal_height = 350
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
      name_label.style.left_margin = 4
      
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
      delete_btn.style.top_margin = 2
      delete_btn.style.right_margin = 1
      add_to_map(delete_btn)
    end
  else
    local empty_label = container.add{
      type = "label",
      caption = "No test cases defined. Click + to add one or use Auto Generate.",
      style = "label"
    }
    empty_label.style.font_color = {0.5, 0.5, 0.5}
    empty_label.style.top_margin = 8
  end
  
  -- Update AI buttons state after creating them
  update_ai_buttons(uid)
end

update_ai_buttons = function(uid)
  local gui_t = storage.guis[uid]
  
  if not gui_t then
    return
  end
  
  -- Check if any AI operation is in progress
  local ai_operation_in_progress = ai_operation_manager.is_operation_active(uid)
  
  -- Update Auto Generate Tests button if it exists
  if gui_t.mlc_auto_generate_tests then
    gui_t.mlc_auto_generate_tests.enabled = not ai_operation_in_progress
  end
  
  -- Update Fix Tests button if it exists
  if gui_t.mlc_fix_tests then
    gui_t.mlc_fix_tests.enabled = not ai_operation_in_progress
  end
end

local function on_test_case_evaluated(event)
  component.update(event.uid)
end

local function on_test_generation_completed(event)
  local mlc = storage.combinators[event.uid]
  if not mlc then return end
  
  -- Complete AI operation using the new manager
  ai_operation_manager.complete_operation(event.uid)
  
  -- Parse the AI response
  local test_cases_json = event.test_cases
  
  -- Try to parse JSON
  local success, parsed_test_cases = pcall(helpers.json_to_table, test_cases_json)
  
  if not success or not parsed_test_cases or type(parsed_test_cases) ~= "table" then
    game.print("[color=red]Failed to generate test cases: Invalid AI response format[/color]")
    return
  end
  
  -- Initialize test cases if needed
  if not mlc.test_cases then
    mlc.test_cases = {}
  end
  
  -- Append generated test cases
  local added_count = 0
  for _, generated_test in ipairs(parsed_test_cases) do
    for _, signal in ipairs(generated_test.red_input or {}) do
      signal.signal = circuit_network.cn_sig(signal.signal)
    end
    for _, signal in ipairs(generated_test.green_input or {}) do
      signal.signal = circuit_network.cn_sig(signal.signal)
    end
    for _, signal in ipairs(generated_test.expected_output or {}) do
      signal.signal = circuit_network.cn_sig(signal.signal)
    end

    if type(generated_test) == "table" and generated_test.name then
      -- Check if advanced features are being used
      local uses_advanced = false
      if generated_test.variables and #generated_test.variables > 0 then
        uses_advanced = true
      elseif generated_test.game_tick and generated_test.game_tick ~= 1 then
        uses_advanced = true
      elseif generated_test.expected_print and generated_test.expected_print ~= "" then
        uses_advanced = true
      end
      
      table.insert(mlc.test_cases, {
        name = generated_test.name or ("Generated Test " .. (#mlc.test_cases + 1)),
        red_input = generated_test.red_input or {},
        green_input = generated_test.green_input or {},
        expected_output = generated_test.expected_output or {},
        actual_output = {},
        variables = generated_test.variables or {},
        game_tick = generated_test.game_tick or 1,
        expected_print = generated_test.expected_print or "",
        show_advanced = uses_advanced,
        success = false
      })
      added_count = added_count + 1
      
      -- Evaluate the new test case
      local test_index = #mlc.test_cases
      event_handler.raise_event(constants.events.on_test_case_updated, {
        uid = event.uid,
        test_index = test_index
      })
    end
  end
  
  if added_count > 0 then
    game.print(string.format("[color=green]Successfully generated and added %d test cases[/color]", added_count))
    component.update(event.uid)
  else
    game.print("[color=yellow]No valid test cases could be extracted from AI response[/color]")
  end
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
  event_handler.raise_event(constants.events.on_test_case_updated, {
    uid = uid,
    test_index = new_test_index
  })
end

local function auto_generate_test_cases(uid)
  local mlc = storage.combinators[uid]
  if not mlc then return end
  
  -- Get task description and source code
  local task_description = mlc.task or "No task description available"
  local source_code = mlc.code or "No source code available"
  
  -- Start AI operation using the new manager
  local success, correlation_id = ai_operation_manager.start_operation(uid, ai_operation_manager.OPERATION_TYPES.TEST_GENERATION)
  
  if success then
    -- Send test generation request via bridge
    bridge.send_test_generation_request(uid, task_description, source_code)
    
    -- Show feedback to user
    game.print("[color=yellow]Generating test cases with AI...[/color]")
  else
    game.print("[color=red]Failed to start test generation operation[/color]")
  end
end

local function fix_failing_tests(uid)
  local mlc = storage.combinators[uid]
  if not mlc then return end
  
  -- Check if any tests are failing
  local failed_tests = {}
  local passed_tests = 0
  
  for i, test_case in ipairs(mlc.test_cases or {}) do
    if test_case.success then
      passed_tests = passed_tests + 1
    else
      table.insert(failed_tests, {index = i, test_case = test_case})
    end
  end
  
  if #failed_tests == 0 then
    game.print("[color=green]All tests are already passing![/color]")
    return
  end
  
  -- Initialize fix attempt counter if not present
  if not mlc.fix_attempt_count then
    mlc.fix_attempt_count = 0
  end
  
  if mlc.fix_attempt_count >= 3 then
    game.print("[color=red]Maximum fix attempts (3) reached. Cannot fix tests automatically.[/color]")
    return
  end
  
  mlc.fix_attempt_count = mlc.fix_attempt_count + 1
  
  -- Start AI operation
  local success, correlation_id = ai_operation_manager.start_operation(uid, ai_operation_manager.OPERATION_TYPES.TEST_FIXING)
  
  if success then
    -- Get required data for fix request
    local task_description = mlc.task or "No task description available"
    local current_code = mlc.code or ""
    
    -- Send fix request via bridge
    bridge.send_fix_request(uid, task_description, current_code, failed_tests)
    
    -- Show feedback to user
    game.print(string.format("[color=yellow]Fixing failing tests with AI (attempt %d/3)...[/color]", mlc.fix_attempt_count))
  else
    mlc.fix_attempt_count = mlc.fix_attempt_count - 1  -- Rollback the attempt count
    game.print("[color=red]Failed to start test fixing operation[/color]")
  end
end

local function on_gui_click(event)
  if not event.element or not event.element.valid or not event.element.tags then return end

  if event.element.tags.delete_test_case ~= nil then
    delete_test_case(event.element.tags.uid, event.element.tags.delete_test_case)
    component.update(event.element.tags.uid)
  elseif event.element.tags.add_test_case then
    local uid = event.element.tags.uid
    add_test_case(uid)
    component.update(uid)
  elseif event.element.tags.auto_generate_tests then
    auto_generate_test_cases(event.element.tags.uid)
  elseif event.element.tags.fix_tests then
    fix_failing_tests(event.element.tags.uid)
  elseif event.element.tags.edit_test_case then
    test_case_dialog.show(event.player_index, event.element.tags.uid, event.element.tags.edit_test_case)
  end
end

local function on_ai_operation_state_changed(event)
  update_ai_buttons(event.uid)
end

local function on_fix_completion(event)
  local uid = event.uid
  local mlc = storage.combinators[uid]
  
  if not mlc then return end
  
  if event.success then
    game.print("[color=green]Tests fixed successfully![/color]")
    
    -- Update the combinator code with the fixed code and trigger proper re-evaluation
    if event.code then
      -- Trigger code update event to properly re-evaluate all test cases
      event_handler.raise_event(constants.events.on_code_updated, {
        uid = uid,
        code = event.code,
        source_type = "ai_fix"
      })
    end
  else
    -- Display the error message from the AI if available
    if event.error_message then
      local error_text = event.error_message:sub(1, 6) == "ERROR:" and event.error_message:sub(8) or event.error_message
      game.print("[color=red]AI Error: " .. error_text .. "[/color]")
    else
      game.print("[color=red]Unable to fix tests. Manual intervention required.[/color]")
    end
  end

  -- Update button states
  update_ai_buttons(uid)
  component.update(uid)
end

event_handler.add_handler(constants.events.on_test_case_evaluated, on_test_case_evaluated)
event_handler.add_handler(constants.events.on_test_case_name_updated, on_test_case_evaluated)
event_handler.add_handler(constants.events.on_test_generation_completed, on_test_generation_completed)
event_handler.add_handler(constants.events.on_ai_operation_state_changed, on_ai_operation_state_changed)
event_handler.add_handler(constants.events.on_fix_completed, on_fix_completion)
event_handler.add_handler(defines.events.on_gui_click, on_gui_click)


return component