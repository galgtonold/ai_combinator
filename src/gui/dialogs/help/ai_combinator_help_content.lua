-- AI Combinator main dialog help content
local ai_combinator_help_content = {}

ai_combinator_help_content.sections = {
    {
        id = "overview",
        title = "AI Combinator Overview", 
        expanded = true,
        content = {
            "The AI Combinator is an intelligent circuit combinator that uses AI to generate",
            "Lua code based on your task description. It processes input signals and produces",
            "output signals according to the logic you describe in natural language."
        }
    },
    
    {
        id = "getting_started",
        title = "Getting Started",
        expanded = true,
        content = {
            {type = "tips", items = {
                'Click [color=#ffe6c0]Set Task[/color] to describe what you want the combinator to do',
                'The AI will automatically generate Lua code based on your description',
                'Connect circuit wires to provide input signals and read output signals',
                'Monitor the status indicator to see if the combinator is working correctly'
            }}
        }
    },
    
    {
        id = "interface",
        title = "Interface Components",
        expanded = false,
        content = {
            {type = "subheader", text = "Status & Controls:", margin = 4},
            {type = "variables", items = {
                {name = "Status Indicator", desc = "Shows working state, errors, or AI operation progress"},
                {name = "Progress Bar", desc = "Displays AI generation progress when active"},
                {name = "Cancel Button", desc = "Stops any running AI operation"},
                {type = "text", text = "    Button is only enabled when AI operation is in progress"}
            }},
            
            {type = "subheader", text = "Task Management:", margin = 8},
            {type = "variables", items = {
                {name = "Task Description", desc = "Shows your current task description"},
                {name = "Set Task Button", desc = "Opens dialog to set or modify your task"},
                {name = "Edit Source Code", desc = "Manually edit the generated Lua code"},
                {type = "text", text = "    Disabled during AI operations to prevent conflicts"}
            }},
            
            {type = "subheader", text = "Signal Monitoring:", margin = 8},
            {type = "variables", items = {
                {name = "Input Signals", desc = "Real-time view of red and green wire inputs"},
                {name = "Output Signals", desc = "Current signals being output by the combinator"},
                {type = "text", text = "    Updates automatically every few ticks"},
                {type = "text", text = "    Red wire inputs shown with red background"},
                {type = "text", text = "    Green wire inputs shown with green background"}
            }},
            
            {type = "subheader", text = "Test Cases:", margin = 8},
            {type = "variables", items = {
                {name = "Test Case Summary", desc = "Shows (passed/total) test count with status color"},
                {name = "Add Test Case (+)", desc = "Create new test with specific inputs and expected outputs"},
                {name = "Auto Generate", desc = "AI automatically creates test cases based on your task"},
                {name = "Fix with AI", desc = "AI analyzes failing tests and fixes the code automatically"},
                {type = "text", text = "    Test cases verify your combinator works correctly"},
                {type = "text", text = "    Click any test case to edit inputs, outputs, and conditions"},
                {type = "text", text = "    Green checkmark = passing, red X = failing"}
            }}
        }
    },
    
    {
        id = "task_examples",
        title = "Task Examples",
        expanded = false,
        content = {
            {type = "code_example", title = "Basic Signal Processing:", code = "Output the sum of iron plates and copper plates"},
            {type = "spacer"},
            {type = "code_example", title = "Conditional Logic:", code = "Turn on green signal when steam is above 1000, red signal when below 500"},
            {type = "spacer"},
            {type = "code_example", title = "Resource Management:", code = "Output assembling-machine-1 signal when iron plates > 100 and copper plates > 50"},
            {type = "spacer"},
            {type = "code_example", title = "Timer/Counter:", code = "Count the number of times a signal pulse occurs and output the count"},
            {type = "spacer"},
            {type = "code_example", title = "Smart Logistics:", code = "Calculate inserter enable signal based on buffer levels and production rate"},
            {type = "spacer"},
            {type = "code_example", title = "Complex Processing:", code = "Balance multiple assembly lines by adjusting priority signals based on inventory levels"}
        }
    },
    
    {
        id = "status_meanings",
        title = "Status Indicators",
        expanded = false,
        content = {
            {type = "subheader", text = "Normal Operation:", margin = 4},
            {type = "variables", items = {
                {name = "Working", desc = "Combinator is running normally"},
                {name = "AI Generating Code", desc = "AI is currently creating or fixing code"},
                {name = "AI Operation Complete", desc = "AI has finished generating code"}
            }},
            
            {type = "subheader", text = "Power Issues:", margin = 8},
            {type = "variables", items = {
                {name = "No Power", desc = "Combinator needs electrical connection"},
                {name = "Low Power", desc = "Insufficient power supply"},
                {name = "Disabled", desc = "Combinator manually disabled or by circuit"}
            }},
            
            {type = "subheader", text = "Errors:", margin = 8},
            {type = "variables", items = {
                {name = "Error: [message]", desc = "Lua code error with specific details"},
                {type = "text", text = "    Check the Edit Source Code dialog for error highlighting"},
                {type = "text", text = "    Use Set Task to ask AI to fix the error"}
            }}
        }
    },
    
    {
        id = "workflow",
        title = "Typical Workflow",
        expanded = false,
        content = {
            {type = "code_pattern", title = "1. Setup Task:", code = {
                "• Click 'Set Task' button",
                "• Describe what you want in natural language",
                "• Be specific about inputs, outputs, and conditions",
                "• Click 'Generate Code' to let AI create the logic"
            }},
            {type = "spacer"},
            {type = "code_pattern", title = "2. Connect Circuits:", code = {
                "• Connect red/green wires for input signals",
                "• Connect output wires to other combinators or devices",
                "• Check Input Signals section to verify connections"
            }},
            {type = "spacer"},
            {type = "code_pattern", title = "3. Create Tests:", code = {
                "• Use 'Auto Generate' to create comprehensive test cases",
                "• Or manually add test cases with + button",
                "• Verify tests cover your expected use cases",
                "• All tests should show green checkmarks when passing"
            }},
            {type = "spacer"},
            {type = "code_pattern", title = "4. Connect & Deploy:", code = {
                "• Connect red/green wires for input signals", 
                "• Connect output wires to other combinators or devices",
                "• Monitor real-time signals match test expectations"
            }},
            {type = "spacer"},
            {type = "code_pattern", title = "5. Debug & Maintain:", code = {
                "• If errors occur, check failing test cases first",
                "• Use 'Fix with AI' for automatic corrections",
                "• Or manually edit code and re-run tests",
                "• Add new tests when requirements change"
            }}
        }
    },
    
    {
        id = "testing",
        title = "Testing & Validation",
        expanded = false,
        content = {
            {type = "subheader", text = "Test Case Basics:", margin = 4},
            "Test cases are automated tests that verify your combinator produces the correct",
            "outputs for specific inputs. They help ensure your logic works correctly.",
            "",
            {type = "subheader", text = "Creating Test Cases:", margin = 8},
            {type = "variables", items = {
                {name = "Manual Creation", desc = "Click + button to add a new test case"},
                {name = "Auto Generate", desc = "AI creates comprehensive test cases automatically"},
                {type = "text", text = "    Auto Generate analyzes your task and creates relevant tests"},
                {type = "text", text = "    Generated tests cover common scenarios and edge cases"}
            }},
            
            {type = "subheader", text = "Test Case Components:", margin = 8},
            {type = "variables", items = {
                {name = "Red/Green Inputs", desc = "Specific signal values to feed into the combinator"},
                {name = "Expected Output", desc = "What signals the combinator should output"},
                {name = "Variables", desc = "Starting values for any persistent variables"},
                {name = "Game Tick", desc = "Simulation tick when test should be evaluated"},
                {name = "Expected Print", desc = "Any debug output the code should produce"}
            }},
            
            {type = "subheader", text = "Test Execution:", margin = 8},
            "Tests run automatically whenever code changes. Each test shows:",
            {type = "variables", items = {
                {name = "Status Icon", desc = "Green checkmark (pass) or red X (fail)"},
                {name = "Test Name", desc = "Descriptive name for the test scenario"},
                {type = "text", text = "    Click any test to edit its parameters"},
                {type = "text", text = "    Use trash icon to delete unwanted tests"}
            }},
            
            {type = "subheader", text = "AI-Powered Testing:", margin = 8},
            {type = "code_pattern", title = "Auto Generate Tests:", code = {
                "• Analyzes your task description and current code",
                "• Creates comprehensive test cases automatically",
                "• Covers normal operation and edge cases",
                "• Includes realistic signal names and values"
            }},
            {type = "spacer"},
            {type = "code_pattern", title = "Fix with AI:", code = {
                "• Analyzes which tests are failing and why",
                "• Automatically modifies code to make tests pass",
                "• Limited to 3 attempts to prevent infinite loops",
                "• Maintains original task intent while fixing issues"
            }},
            {type = "spacer"},
            {type = "warning_section", title = "Testing Best Practices:", items = {
                'Create tests before or immediately after generating code',
                'Use realistic signal values that match your factory',
                'Test both normal operation and edge cases (zero values, large numbers)',
                'Give tests descriptive names that explain what they verify',
                'Review generated tests to ensure they match your expectations'
            }}
        }
    },
    
    {
        id = "tips",
        title = "Tips & Best Practices",
        expanded = false,
        content = {
            {type = "tips", items = {
                'Be specific in task descriptions - mention exact signal names and conditions',
                'For better UPS, specify that checks should only run every X seconds (e.g., "check every 5 seconds")',
                'Use "Auto Generate" for comprehensive test coverage, then customize as needed',
                'Create tests early - they help catch issues before deploying to your factory',
                'Monitor the test summary (X/Y passing) to quickly assess combinator health',
                'Use descriptive test names that explain the scenario being tested',
                'Test edge cases like zero values, negative numbers, and maximum limits',
                'The "Fix with AI" feature can resolve most test failures automatically',
                'Start with simple tasks and gradually build complexity',
                'Check both input and output signal displays to debug issues',
                'Save complex combinators as blueprints after testing is complete'
            }}
        }
    },
    
    {
        id = "troubleshooting",
        title = "Troubleshooting",
        expanded = false,
        content = {
            {type = "warning_section", title = "Combinator not working?", items = {
                'Check status indicator for power or error messages',
                'Verify input signals are connected and showing values',
                'Ensure task description was specific enough for AI',
                'Try regenerating code with a clearer task description'
            }},
            {type = "spacer"},
            {type = "warning_section", title = "AI generation failed?", items = {
                'Check network connection and API configuration',
                'Simplify your task description and try again',
                'Look for error messages in the progress area',
                'Manually edit code if AI generation is unavailable'
            }},
            {type = "spacer"},
            {type = "warning_section", title = "Output signals wrong?", items = {
                'Create test cases to identify specific issues',
                'Review generated code in Edit Source Code dialog',
                'Update task with more specific requirements',
                'Check input signal names match your expectations'
            }},
            {type = "spacer"},
            {type = "warning_section", title = "Tests failing?", items = {
                'Click failing test to review expected vs actual outputs',
                'Use "Fix with AI" to automatically correct the code',
                'Verify test case inputs and expectations are correct',
                'Check if test timing (game tick) affects results'
            }},
            {type = "spacer"}
        }
    }
}

return ai_combinator_help_content
