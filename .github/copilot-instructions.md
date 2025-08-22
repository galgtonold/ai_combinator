# AI Combinator for Factorio: Development Guide

## Project Overview
The AI Combinator project adds a special circuit combinator to Factorio that uses AI to generate Lua code. It consists of:

1. **Factorio Mod** (`/`): Core mod files implementing the AI combinator entity and UI
2. **AI Bridge** (`/ai_bridge`): Python bridge for OpenAI API integration
3. **Launcher** (`/launcher`): Electron app to configure and launch Factorio with the mod

## Architecture & Data Flow

### Mod → AI Bridge Communication
- Mod sends requests via UDP (port 8889) to AI Bridge
- Bridge processes with OpenAI, returns Lua code responses
- `bridge.lua` manages communication from the Factorio side
- Data is transferred as JSON using the format in `bridge.send_task_request()`

### Launcher → Mod Integration
- Launcher detects Factorio installation, manages mod configuration
- Can run built-in AI Bridge using TypeScript implementation
- Configures OpenAI API keys, model selection, and port settings

## Key Components

### Factorio Mod
- **`control.lua`**: Main mod logic for combinator behavior
- **`gui.lua`**: UI for the combinator configuration window
- **`event_handler.lua`**: Custom event system for mod components
- **`data.lua`**: Defines entities, items, and graphics

### AI Bridge
- **`bridge.py`**: Python-based OpenAI integration
- Contains prompt template for generating valid Lua code

### Launcher
- **`electron/`**: Main process with Factorio detection and AI Bridge integration
- **`renderer/`**: Svelte-based UI with Factorio-inspired styling
- **`renderer/src/components/`**: Reusable UI components

## Development Workflow

### Running the Project
1. For mod development:
   ```
   # Test in Factorio with --mod-directory pointing to parent of this repo
   ```

2. For launcher development:
   ```
   cd launcher
   npm run dev
   ```

3. For debugging AI Bridge:
   ```
   cd ai_bridge
   # Either run via launcher or directly with Python
   python bridge.py
   ```

### UI Components Convention
- Launcher UI uses custom Factorio-styled components in `renderer/src/components/`
- Components use `:global()` CSS to override Bulma defaults where needed
- Prefer explicit styling to prevent Bulma inheritance issues

## Project Patterns

### Lua Environment
- Combinator code runs in a sandboxed Lua environment
- Available variables: `red`, `green`, `out`, `var`, `delay`, `game.tick`
- See prompt in `ai_bridge/bridge.py` for detailed constraints

### Event System
- Custom event handler for decoupled communication
- Register events with `event_handler.add_handler(event_name, handler_function)`
- Create custom events with `script.generate_event_name()`

### Configuration
- Mod settings in `settings.lua` and `config.lua`
- Launcher config stored in electron's `app.getPath("userData")`

## Code Examples

### Registering an Event Handler
```lua
local event_handler = require("event_handler")
event_handler.add_handler(defines.events.on_built_entity, function(event)
  -- Handler code
end)
```

### Launcher Component Pattern
```svelte
<script lang="ts">
  // Props with defaults
  export let width = "100%";
</script>

<div class="factorio-component" style="width: {width};">
  <slot />
</div>

<style>
  /* Use :global() to override Bulma */
  :global(.factorio-component) {
    /* Component styling */
  }
</style>
```


For terminal commands always use powershell syntax. Especially use ; instead of &&.
When trying to run npm always navigate to the launcher directory.
Especially if you want to launch the electron app, this is what you should do:
cd "c:\Users\...\AppData\Roaming\Factorio\mods\ai_combinator\launcher"; npm run dev