# AI Combinator - Development Guide

Welcome to the AI Combinator development documentation! This guide covers the technical architecture, development setup, and contribution guidelines for the project.

## 🏗️ Project Architecture

The AI Combinator consists of two main components:

### 1. Factorio Mod (`/`)
The core mod that runs inside Factorio, handling the combinator entity, UI, circuit networks, and AI code execution.

**Directory Structure:**
```
/
├── control.lua          # Main entry point, tick handling, event registration
├── data.lua             # Entity, item, recipe, and graphics definitions
├── info.json            # Mod metadata
├── src/
│   ├── ai_combinator/   # Core combinator logic
│   │   ├── init.lua           # Combinator initialization
│   │   ├── runtime.lua        # Tick-by-tick code execution
│   │   ├── update.lua         # State updates, LED indicators
│   │   ├── code_manager.lua   # Code loading, history management
│   │   ├── combinator_service.lua  # Business logic layer
│   │   └── memory.lua         # Runtime memory management
│   ├── core/            # Shared utilities
│   │   ├── constants.lua      # Configuration, custom events
│   │   ├── circuit_network.lua    # Signal I/O handling
│   │   ├── ai_operation_manager.lua  # AI request state tracking
│   │   ├── utils.lua          # Helper functions
│   │   └── blueprint_serialization.lua  # Blueprint data handling
│   ├── events/          # Event handlers
│   │   ├── event_handler.lua  # Custom event system
│   │   ├── entity_events.lua  # Build/destroy handlers
│   │   ├── blueprint_events.lua   # Blueprint copy/paste
│   │   └── hotkey_events.lua  # Keyboard shortcuts
│   ├── gui/             # User interface
│   │   ├── gui.lua            # Main GUI controller
│   │   ├── gui_updater.lua    # Reactive UI updates
│   │   ├── gui_utils.lua      # UI helper functions
│   │   ├── components/        # Reusable UI components
│   │   └── dialogs/           # Modal dialogs
│   ├── sandbox/         # Lua sandbox environment
│   │   └── base.lua           # Safe function whitelist
│   ├── services/        # External communication
│   │   └── bridge.lua         # UDP communication with launcher
│   └── testing/         # Test framework
│       └── testing.lua        # Test case execution
└── locale/              # Translations
```

### 2. Launcher (`/launcher`)
Electron application that configures Factorio, manages the AI Bridge, and handles AI provider integration.

**Structure:**
```
launcher/
├── electron/            # Main Electron process
│   ├── app.ts                 # Application entry point
│   ├── preload.ts             # Context bridge for renderer
│   ├── managers/              # Feature managers
│   │   ├── ai-bridge-manager.ts   # AI Bridge lifecycle
│   │   ├── config-manager.ts      # Settings persistence
│   │   └── factorio-manager.ts    # Factorio detection/launch
│   └── services/              # Business logic
│       ├── ai-bridge.ts           # AI provider integration
│       └── ipc-handlers.ts        # IPC message handlers
├── renderer/            # Frontend UI (Svelte)
│   └── src/
│       ├── App.svelte             # Root component
│       ├── components/            # UI components
│       ├── stores/                # Svelte stores
│       └── styles/                # CSS/theming
├── shared/              # Shared types and utilities
│   ├── types.ts               # TypeScript interfaces
│   ├── constants.ts           # Shared constants
│   └── logger.ts              # Logging utility
└── build/               # Distribution builds
```

## 🔄 Data Flow

```
[Factorio Mod] ──UDP:8889──► [Launcher AI Bridge] ◄──HTTPS──► [AI Provider API]
       ▲                              │
       └────────UDP:9001──────────────┘
```

### Request Flow (Factorio → AI)
1. **User Input**: Player enters task description in combinator UI
2. **Mod → Bridge**: `bridge.lua` sends JSON request via UDP (port 8889)
3. **Bridge → AI**: Launcher processes with configured AI provider (OpenAI, Anthropic, etc.)
4. **Code Generation**: AI generates Lua code following sandbox constraints

### Response Flow (AI → Factorio)
5. **Bridge → Mod**: Launcher sends response via UDP (port 9001)
6. **Execution**: `runtime.lua` executes code in sandboxed environment

### Request Types
- **`task_request`**: Generate code from natural language description
- **`test_generation_request`**: Auto-generate test cases for existing code
- **`fix_request`**: Fix code to pass failing tests (includes error context)
- **`ping_request`**: Check AI Bridge availability

## 🧩 Key Components Deep Dive

### Lua Sandbox Environment

AI-generated code runs in a restricted environment defined in `src/sandbox/base.lua`:

**Available Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| `red` | table | Red wire signals (read-only) |
| `green` | table | Green wire signals (read-only) |
| `out` | table | Output signals (write) |
| `var` | table | Persistent variables across ticks |
| `delay` | number | Ticks until next execution (default: 1) |
| `game.tick` | number | Current game tick (read-only) |
| `game.print()` | function | Print to game console |
| `game.log()` | function | Write to log file |

**Available Libraries:**
- `string.*` - String manipulation
- `table.*` - Table operations  
- `math.*` - Mathematical functions
- `bit32.*` - Bitwise operations
- `serpent.line/block` - Table serialization
- `pairs`, `ipairs`, `next` - Iteration
- `tonumber`, `tostring`, `type` - Type conversion
- `pcall`, `assert`, `error` - Error handling

**Blocked Operations:**
- File system access
- Network operations
- `loadstring`, `dofile`, `loadfile`
- `os.*`, `io.*`, `debug.*`
- `rawget`, `rawset`, `setmetatable` (on protected tables)

### Event System

Custom event system for decoupled component communication:

```lua
local event_handler = require("src/events/event_handler")
local constants = require("src/core/constants")

-- Register for built-in Factorio events
event_handler.add_handler(defines.events.on_built_entity, function(event)
    -- Handle entity placement
end)

-- Register for custom events
event_handler.add_handler(constants.events.on_code_changed, function(event)
    -- event.uid, event.code, event.source_type
end)

-- Raise custom events
event_handler.raise_event(constants.events.on_code_changed, {
    uid = combinator_uid,
    code = new_code,
    source_type = "ai_generation"
})
```

### AI Operation Manager

Tracks async AI requests to prevent duplicate operations:

```lua
local ai_operation_manager = require("src/core/ai_operation_manager")

-- Start an operation (returns false if one is already running)
local success, correlation_id = ai_operation_manager.start_operation(
    uid, 
    ai_operation_manager.OPERATION_TYPES.CODE_GENERATION
)

-- Check operation state
if ai_operation_manager.is_operation_active(uid) then
    -- Show loading indicator
end

-- Complete operation (called when response received)
ai_operation_manager.complete_operation(uid)
```

### Test Framework

Built-in test case system for validating combinator code:

```lua
-- Test case structure
{
    name = "Test name",
    red_input = { {signal = {type="virtual", name="signal-A"}, count = 10} },
    green_input = { },
    expected_output = { {signal = {type="virtual", name="signal-B"}, count = 20} },
    variables = { {name = "counter", value = 5} },
    game_tick = 100,
    success = true/false,  -- Set after evaluation
    actual_output = { }    -- Set after evaluation
}
```

## 🛠️ Development Setup

### Prerequisites

- **Factorio 2.0+** with mod development enabled
- **Node.js 18+** and npm
- **API key** for your chosen AI provider (OpenAI, Anthropic, Google, xAI, or DeepSeek)

### Quick Start

1. **Clone to mods directory:**
   ```powershell
   cd "$env:APPDATA\Factorio\mods"
   git clone https://github.com/galgtonold/ai_combinator.git
   ```

2. **Install launcher dependencies:**
   ```powershell
   cd ai_combinator\launcher
   npm install
   ```

3. **Run launcher in development mode:**
   ```powershell
   npm run dev
   ```

### Development Workflow

#### Mod Development
- Edit Lua files directly - Factorio reloads on game restart
- Use `/c game.print(serpent.block(storage.combinators))` for debugging
- Check `factorio-current.log` for error messages

#### Launcher Development
```powershell
cd launcher
npm run dev      # Start with hot reload
npm run build    # Build for production
npm run package  # Create distributable
```

#### Code Style

**Lua:**
- Use `snake_case` for variables and functions
- Prefer `local` over global scope
- Use StyLua for formatting (config in `stylua.toml`)

**TypeScript:**
- Use `camelCase` for variables, `PascalCase` for types
- Prefer `async/await` over raw promises
- Document with JSDoc comments

## 📦 Building and Distribution

### Production Build
```powershell
cd launcher
npm run build     # Build renderer
npm run package   # Create installer
```

Output: `launcher/build/AI Combinator Launcher Setup X.X.X.exe`

### Mod Distribution
The mod is loaded directly from the Factorio mods directory. For portal distribution:
1. Zip the mod folder (excluding `launcher/`, `.git/`, etc.)
2. Rename to `ai_combinator_X.X.X.zip`
3. Upload to [mods.factorio.com](https://mods.factorio.com)

## 📚 Additional Resources

- **Factorio Lua API**: [lua-api.factorio.com](https://lua-api.factorio.com)
- **Electron Docs**: [electronjs.org/docs](https://electronjs.org/docs)
- **Svelte Tutorial**: [svelte.dev/tutorial](https://svelte.dev/tutorial)

---

Happy coding! 🚀
