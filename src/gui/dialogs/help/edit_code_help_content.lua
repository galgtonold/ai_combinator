-- Edit Code dialog help content
local edit_code_help_content = {}

edit_code_help_content.sections = {
    {
        id = "overview",
        title = "Overview",
        expanded = true,
        content = {
            "The AI Combinator executes Lua code in a sandboxed Lua environment",
            "with special variables and limited Factorio APIs.",
            "It runs its code once every tick and transforms the red and green",
            "input signals into output signals.",
        },
    },

    {
        id = "variables",
        title = "Special Variables",
        expanded = true,
        content = {
            { type = "subheader", text = "Input/Output:", margin = 4 },
            {
                type = "variables",
                items = {
                    { name = "uid", desc = "(uint) — Globally-unique number of this combinator" },
                    { name = "red", desc = "{signal=value, ...} — Signals on red input wire (read-only)" },
                    { type = "text", text = "    Returns 0 for missing signals, all values are numbers" },
                    { name = "green", desc = "{signal=value, ...} — Signals on green input wire (read-only)" },
                    { name = "out", desc = "{signal=value, ...} — Output signals sent to networks" },
                    { type = "text", text = "    Persistent: set to nil/0 to remove, or use [color=#ffe6c0]out = {}[/color] to clear all" },
                    { type = "text", text = '    Prefix with "red/" or "green/" for wire-specific output' },
                },
            },

            { type = "subheader", text = "Control & Timing:", margin = 8 },
            {
                type = "variables",
                items = {
                    { name = "delay", desc = "(number) — Ticks until next run (default: 1)" },
                    { type = "text", text = "    Reset before each run, must be set every time" },
                    { name = "irq", desc = "(signal-name) — Signal to interrupt any delay" },
                    { type = "text", text = "    Triggers when signal is non-zero on any input wire" },
                    { name = "irq_min_interval", desc = "(number) — Min ticks between IRQ triggers" },
                    { type = "text", text = "    Use nil or ≤1 to disable (default)" },
                },
            },

            { type = "subheader", text = "Storage & Debug:", margin = 8 },
            {
                type = "variables",
                items = {
                    { name = "var", desc = "{} — Persistent table for storing values between runs" },
                    { name = "debug", desc = "(bool) — Set to true to print debug info to factorio log" },
                },
            },
        },
    },

    {
        id = "apis",
        title = "Available APIs",
        expanded = false,
        content = {
            {
                type = "variables",
                items = {
                    { name = "game.tick", desc = "— Current game tick (read-only)" },
                    { name = "game.log(...)", desc = "— Print to factorio log file" },
                    { name = "game.print(...)", desc = "— Print to in-game console" },
                    { name = "game.print_color(msg, {r,g,b})", desc = "— Colored console output" },
                    { name = "serpent.line(...)", desc = "/ [color=#ffe6c0]serpent.block(...)[/color] — Serialize tables to strings" },
                },
            },
        },
    },

    {
        id = "examples",
        title = "Quick Examples",
        expanded = false,
        content = {
            { type = "code_example", title = "Basic signal output:", code = 'out["iron-plate"] = red["iron-ore"] * 2' },
            { type = "spacer" },
            { type = "code_example", title = "Conditional logic:", code = 'if red["steam"] > 1000 then out["signal-green"] = 1 end' },
            { type = "spacer" },
            { type = "code_example", title = "Delayed execution:", code = "delay = 60  -- Run again in 1 second" },
            { type = "spacer" },
            {
                type = "code_example",
                title = "Using persistent variables:",
                code = {
                    "var.counter = (var.counter or 0) + 1",
                    'out["count"] = var.counter',
                },
            },
        },
    },

    {
        id = "tips",
        title = "Tips & Best Practices",
        expanded = false,
        content = {
            {
                type = "tips",
                items = {
                    "Use [color=#ffe6c0]delay[/color] for performance: avoid running every tick when possible",
                    "For UPS-heavy tasks, run checks only every few seconds (e.g., [color=#ffe6c0]delay = 300[/color] for 5 seconds)",
                    "Use [color=#ffe6c0]var[/color] table for data that persists between runs",
                    "Check [color=#ffe6c0]game.tick[/color] for time-based logic and intervals",
                    "Use [color=#ffe6c0]debug = true[/color] to troubleshoot execution issues",
                },
            },
        },
    },

    {
        id = "patterns",
        title = "Common Patterns",
        expanded = false,
        content = {
            {
                type = "code_pattern",
                title = "Timer/Clock:",
                code = {
                    "var.timer = (var.timer or 0) + 1",
                    "if var.timer >= 60 then",
                    '  out["pulse"] = 1',
                    "  var.timer = 0",
                    "end",
                },
            },
            { type = "spacer" },
            {
                type = "code_pattern",
                title = "State Machine:",
                code = {
                    'var.state = var.state or "idle"',
                    'if var.state == "idle" and red["start"] > 0 then',
                    '  var.state = "running"',
                    'elseif var.state == "running" then',
                    '  out["active"] = 1',
                    "end",
                },
            },
            { type = "spacer" },
            {
                type = "code_pattern",
                title = "Edge Detection:",
                code = {
                    'local current = red["input"]',
                    "if current > 0 and (var.last or 0) == 0 then",
                    '  out["rising-edge"] = 1  -- Pulse on rising edge',
                    "end",
                    "var.last = current",
                },
            },
        },
    },

    {
        id = "troubleshooting",
        title = "Troubleshooting",
        expanded = false,
        content = {
            {
                type = "warning_section",
                title = "Code not running?",
                items = {
                    "Check for syntax errors (missing [color=#ffe6c0]end[/color], parentheses, etc.)",
                    "Enable [color=#ffe6c0]debug = true[/color] to see execution info in log",
                    "Verify combinator has power and proper connections",
                },
            },
            { type = "spacer" },
            {
                type = "warning_section",
                title = "Performance issues?",
                items = {
                    "Use [color=#ffe6c0]delay[/color] to reduce execution frequency",
                    "Avoid complex calculations every tick",
                    "Check for infinite loops or heavy operations",
                },
            },
        },
    },
}

return edit_code_help_content
