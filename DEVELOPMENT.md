# AI Combinator - Development Guide

Welcome to the AI Combinator development documentation! This guide covers the technical architecture, development setup, and contribution guidelines for the project.

## 🏗️ Project Architecture

The AI Combinator consists of three main components:

### 1. Factorio Mod (`/`)
The core mod that runs inside Factorio, handling the combinator entity, UI, and game logic.

**Key Files:**
- `control.lua` - Main mod logic, combinator behavior, and game event handling
- `gui.lua` - User interface for the AI combinator configuration window
- `bridge.lua` - UDP communication with the AI Bridge
- `data.lua` - Entity definitions, items, recipes, and graphics
- `event_handler.lua` - Custom event system for decoupled component communication


### 3. Launcher (`/launcher`)
Electron application that configures and launches Factorio with the mod enabled.

**Structure:**
- `electron/` - Main Electron process (Node.js/TypeScript)
- `renderer/` - Frontend UI (Svelte/TypeScript)
- `build/` - Distribution builds

## 🔄 Data Flow

```
[Factorio Mod] --UDP:8889--> [AI Bridge] <--HTTPS--> [OpenAI API]
       ↑              |            ↑
       |              └─UDP:9001───┘
       └────── [Launcher] ──────────┘
```

The communication uses two separate UDP channels:

### Request Flow (Factorio → Launcher)
1. **User Input**: Player enters natural language prompt in combinator UI
2. **Mod → Bridge**: Mod sends request via UDP to AI Bridge (port 8889)
3. **Bridge → OpenAI**: Launcher's AI Bridge processes request with OpenAI API
4. **Code Generation**: AI generates Lua code following safety constraints

### Response Flow (Launcher → Factorio)
5. **Bridge → Mod**: AI Bridge sends response via UDP to Factorio (port 9001, configurable)
6. **Execution**: Mod executes generated code in sandboxed Lua environment

**UDP Ports:**
- **8889**: Launcher listens for incoming requests from Factorio mod
- **9001**: Factorio listens for responses from launcher (configured via `--enable-lua-udp` argument)

## 🛠️ Development Setup

### Prerequisites

- **Factorio 2.0+** with mod development enabled
- **Node.js 18+** and npm for launcher development
- **OpenAI API key** for testing AI functionality

### Environment Setup

1. **Clone the repository** to your Factorio mods directory:
   ```powershell
   cd "C:\Users\[USER]\AppData\Roaming\Factorio\mods"
   git clone https://github.com/galgtonold/ai_combinator.git
   ```

2. **Set up the launcher development environment**:
   ```powershell
   cd ai_combinator\launcher
   npm install
   ```

3. **Set up the AI Bridge**:
   ```powershell
   cd ..\ai_bridge
   pip install -r requirements.txt
   ```

### Development Workflow

#### Mod Development

Use FMTK for easy development and debugging.

#### Launcher Development
```powershell
cd launcher
npm run dev  # Starts Electron with hot reload
```

## 🧩 Key Components Deep Dive

### Lua Sandbox Environment

The AI-generated code runs in a carefully controlled environment with these available variables:

- **`red`** - Red wire circuit signals (read-only table)
- **`green`** - Green wire circuit signals (read-only table)  
- **`out`** - Output signals table (write-only)
- **`var`** - Persistent variables across ticks
- **`delay`** - Signal delay configuration
- **`game.tick`** - Current game tick (read-only)

**Safety Constraints:**
- No file system access
- No network operations
- No dangerous Lua functions (`loadstring`, `dofile`, etc.)
- Memory and execution time limits
- Restricted global namespace

### Event System

Custom event handler provides decoupled communication:

```lua
local event_handler = require("event_handler")

-- Register event handler
event_handler.add_handler(defines.events.on_built_entity, function(event)
    -- Handle entity built
end)

-- Create custom events
local custom_event = script.generate_event_name()
event_handler.add_handler(custom_event, handler_function)
```

### UDP Communication Protocol

**Request Format:**
```json
{
    "type": "generate_code",
    "prompt": "user description",
    "context": {
        "signals": {...},
        "tick": 12345
    }
}
```

**Response Format:**
```json
{
    "status": "success|error",
    "code": "-- Generated Lua code",
    "error": "error message if failed"
}
```

### Launcher Architecture

**Main Process (`electron/`):**
- Factorio detection via registry and Steam library parsing
- Configuration management (stored in userData)
- AI Bridge process management
- IPC handlers for renderer communication

**Renderer Process (`renderer/`):**
- Svelte-based UI with Factorio-inspired styling
- Real-time configuration and status updates
- Custom components in `src/components/`

## 🧪 Testing

### Manual Testing Checklist

**Mod Functionality:**
- [ ] Combinator places and connects to circuits correctly
- [ ] UI opens and responds to user input
- [ ] Generated code executes without errors
- [ ] Signals flow correctly through circuit networks
- [ ] Error handling displays appropriate messages

**Launcher Functionality:**
- [ ] Factorio detection works on clean system
- [ ] OpenAI API key configuration persists
- [ ] Factorio launches with mod enabled
- [ ] AI Bridge starts and connects successfully

**AI Bridge:**
- [ ] UDP server starts on correct port
- [ ] OpenAI API calls succeed with valid key
- [ ] Generated code follows safety constraints
- [ ] Error handling for API failures

## 📦 Building and Distribution

### Development Builds
```powershell
cd launcher
npm run dev  # Development with hot reload
```

### Production Builds
```powershell
cd launcher
npm run build     # Build renderer
npm run package   # Package Electron app
```

**Output:** Distributable installer in `launcher/build/`

### Mod Packaging
Factorio automatically packages the mod from the mods directory. For manual distribution:

1. Create zip archive of mod directory
2. Rename to `ai_combinator_[version].zip`
3. Upload to mod portal or distribute directly

## 🤝 Contributing

### Code Style

**Lua (Factorio Mod):**
- Use snake_case for variables and functions
- Prefer local variables over global
- Comment complex logic blocks
- Follow Factorio modding best practices

**TypeScript (Launcher):**
- Use camelCase for variables and functions
- Prefer interfaces over types for object shapes
- Use async/await over promises
- Document public APIs with JSDoc

### Pull Request Process

1. **Fork** the repository and create a feature branch
2. **Test** your changes thoroughly using the manual checklist
3. **Document** any new features or API changes
4. **Submit** PR with clear description of changes
5. **Respond** to code review feedback promptly

### Issue Reporting

When reporting issues, please include:
- Factorio version and mod version
- Launcher version (if applicable)
- Steps to reproduce the issue
- Error messages or logs
- Operating system and relevant system info

## 📚 Additional Resources

- **Factorio Modding API**: [lua-api.factorio.com](https://lua-api.factorio.com)
- **Electron Documentation**: [electronjs.org/docs](https://electronjs.org/docs)
- **Svelte Guide**: [svelte.dev/tutorial](https://svelte.dev/tutorial)
- **OpenAI API Reference**: [platform.openai.com/docs](https://platform.openai.com/docs)

## 🏷️ Project History

Based on the Moon Logic 2 mod with significant enhancements:
- AI integration for code generation
- Modern Electron launcher
- Enhanced UI and user experience
---

Happy coding! 🚀 Feel free to reach out in the GitHub issues if you need help getting started with development.
