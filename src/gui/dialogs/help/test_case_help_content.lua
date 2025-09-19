-- Test Case dialog help content
local test_case_help_content = {}

test_case_help_content.sections = {
    {
        id = "overview",
        title = "Test Case Overview",
        expanded = true,
        content = {
            "Test cases verify that your AI Combinator produces the correct output signals",
            "for specific input conditions. Each test case defines inputs, expected outputs,",
            "and validation conditions to ensure your combinator logic works correctly."
        }
    },
    
    {
        id = "test_structure",
        title = "Test Case Structure",
        expanded = true,
        content = {
            {type = "subheader", text = "Test Components:", margin = 4},
            {type = "variables", items = {
                {name = "Test Name", desc = "Descriptive name explaining what this test verifies"},
                {name = "Red/Green Inputs", desc = "Specific signal values fed into the combinator"},
                {name = "Expected Output", desc = "Signals the combinator should produce"},
                {name = "Actual Output", desc = "Live signals currently being produced (read-only)"},
                {name = "Status Indicator", desc = "Shows if test passes (green) or fails (red) with details"}
            }},
            
            {type = "subheader", text = "Test Execution:", margin = 8},
            "Tests run automatically when:",
            {type = "variables", items = {
                {name = "Code Changes", desc = "Combinator logic is updated or regenerated"},
                {name = "Test Modified", desc = "Input values or expected outputs are changed"},
                {name = "Manual Trigger", desc = "When you save changes in this dialog"},
                {type = "text", text = "    Results update in real-time during editing"}
            }}
        }
    },
    
    {
        id = "inputs_section",
        title = "Configuring Inputs",
        expanded = false,
        content = {
            {type = "subheader", text = "Red Wire Inputs:", margin = 4},
            "Configure signals that will be provided on the red circuit wire:",
            {type = "variables", items = {
                {name = "Add Signal", desc = "Click + to add a new input signal"},
                {name = "Signal Selection", desc = "Choose from items, fluids, or virtual signals"},
                {name = "Signal Value", desc = "Set the specific count/amount for this signal"},
                {type = "text", text = "    Use realistic values that match your factory conditions"}
            }},
            
            {type = "subheader", text = "Green Wire Inputs:", margin = 8},
            "Configure signals that will be provided on the green circuit wire:",
            {type = "variables", items = {
                {name = "Independent Setup", desc = "Green wire signals are separate from red wire"},
                {name = "Signal Selection", desc = "Choose signals using the UI selector"},
                {type = "text", text = "    Both red and green inputs are available to the combinator simultaneously"}
            }},
            
            {type = "subheader", text = "Input Best Practices:", margin = 8},
            {type = "tips", items = {
                'Test with zero values to verify edge case handling',
                'Include negative values if your logic should handle them',
                'Test with very large numbers to check overflow behavior',
                'Use realistic ranges that match your factory conditions'
            }}
        }
    },
    
    {
        id = "outputs_section", 
        title = "Expected vs Actual Outputs",
        expanded = false,
        content = {
            {type = "subheader", text = "Expected Output:", margin = 4},
            "Define what signals your combinator should produce:",
            {type = "variables", items = {
                {name = "Signal Configuration", desc = "Add expected output signals with specific values"},
                {name = "Exact Matching", desc = "Test passes only if actual output exactly matches expected"},
                {name = "Zero Handling", desc = "Signals not listed are expected to be zero or absent"},
                {type = "text", text = "    Be precise - even small value differences will fail the test"}
            }},
            
            {type = "subheader", text = "Actual Output (Live):", margin = 8},
            "Shows real-time signals from your combinator:",
            {type = "variables", items = {
                {name = "Live Updates", desc = "Refreshes automatically as combinator runs"},
                {name = "Read-Only Display", desc = "Cannot be edited - reflects actual combinator behavior"},
                {name = "Debugging Aid", desc = "Compare with expected to identify discrepancies"},
                {type = "text", text = "    Green checkmark = outputs match, red X = mismatch detected"}
            }},
            
            {type = "subheader", text = "Common Output Issues:", margin = 8},
            {type = "warning_section", title = "Troubleshooting:", items = {
                'Wrong signal values (check your calculation logic)', 
                'Missing signals (ensure your code outputs all expected signals)',
                'Extra signals (your code may be outputting unexpected signals)'
            }}
        }
    },
    
    {
        id = "advanced_features",
        title = "Advanced Test Features",
        expanded = false,
        content = {
            {type = "subheader", text = "Variable State:", margin = 4},
            "Set initial values for AI-managed internal variables:",
            {type = "variables", items = {
                {name = "AI Variables", desc = "Variables created and used internally by the AI-generated code"},
                {name = "Persistent State", desc = "Variables persist across ticks during combinator operation"},
                {name = "State Testing", desc = "Test different internal states by setting initial variable values"},
                {type = "text", text = "    Check the generated code to understand which variables are used"}
            }},
            
            {type = "subheader", text = "Game Tick Setting:", margin = 8},
            "Control the tick value seen by the combinator during testing:",
            {type = "variables", items = {
                {name = "Tick Value", desc = "Sets the game.tick value that the combinator code sees"},
                {name = "Time-based Logic", desc = "Test logic that depends on specific tick values"},
                {type = "text", text = "    Useful for testing time-dependent behavior and calculations"}
            }},
            
            {type = "subheader", text = "Print Output Validation:", margin = 8},
            "Verify text output from the combinator:",
            {type = "variables", items = {
                {name = "Expected Print", desc = "Text that should be contained in any print output"},
                {name = "Substring Matching", desc = "Test passes if expected text appears anywhere in output"},
                {name = "Empty String", desc = "Empty expected print always passes (no validation)"},
                {type = "text", text = "    Used to verify the combinator communicates correctly to users"}
            }}
        }
    },
    
    {
        id = "test_workflow", 
        title = "Test Creation Workflow",
        expanded = false,
        content = {
            {type = "code_pattern", title = "1. Define Test Scenario:", code = {
                "• Give your test a descriptive name",
                "• Identify what specific behavior you're testing",
                "• Consider edge cases and boundary conditions",
                "• Think about realistic factory conditions"
            }},
            {type = "spacer"},
            {type = "code_pattern", title = "2. Set Up Inputs:", code = {
                "• Add red wire input signals with specific values",
                "• Add green wire input signals if needed",
                "• Set initial variable values for stateful tests",
                "• Choose appropriate game tick timing"
            }},
            {type = "spacer"},
            {type = "code_pattern", title = "3. Define Expected Results:", code = {
                "• Add all expected output signals with exact values",
                "• Include expected print output if the combinator produces text",
                "• Consider zero/absent signals as part of expectations",
                "• Be precise with signal names and values"
            }},
            {type = "spacer"},
            {type = "code_pattern", title = "4. Validate & Debug:", code = {
                "• Save test and check if it passes immediately",
                "• Compare actual vs expected outputs for mismatches",
                "• Adjust test parameters or fix code as needed",
                "• Use multiple tests to cover different scenarios"
            }}
        }
    },
    
    {
        id = "tips",
        title = "Testing Best Practices",
        expanded = false,
        content = {
            {type = "tips", items = {
                'Create tests for normal operation, edge cases, and error conditions',
                'Use descriptive test names that explain the scenario being tested',
                'Test with zero values, negative numbers, and very large values',
                'For stateful combinators, test multiple sequential inputs',
                'Set appropriate game tick values for time-dependent logic',
                'Test expected print output if the combinator communicates to users',
                'Create separate tests for each major code path or condition',
                'Test both red and green wire inputs independently and together',
                'Verify that unused signals remain zero or absent',
                'Update tests when you change your task or requirements'
            }}
        }
    },
    
    {
        id = "troubleshooting",
        title = "Test Troubleshooting",
        expanded = false,
        content = {
            {type = "warning_section", title = "Test always fails?", items = {
                'Verify expected values match what your logic should produce',
                'Check if your code has runtime errors preventing execution',
                'Review actual output to see what signals are actually produced'
            }},
            {type = "spacer"},
            {type = "warning_section", title = "Actual output is empty?", items = {
                'Verify your combinator code is running without errors',
                'Check that input signals are properly configured',
                'Ensure combinator has power and is enabled',
                'Look for syntax errors in your Lua code'
            }}
        }
    }
}

return test_case_help_content
