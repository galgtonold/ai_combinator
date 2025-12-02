# AI Combinator Launcher Architecture

This document describes the architecture, design decisions, and data flow of the AI Combinator Launcher application.

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Application Structure](#application-structure)
4. [Process Architecture](#process-architecture)
5. [Data Flow](#data-flow)
6. [Component Hierarchy](#component-hierarchy)
7. [State Management](#state-management)
8. [AI Bridge Protocol](#ai-bridge-protocol)
9. [Design Decisions](#design-decisions)

## Overview

The AI Combinator Launcher is an Electron application that serves as a configuration hub and runtime manager for the Factorio AI Combinator mod. It consists of three main parts:

1. **Main Process** (Node.js): Manages system integration, file operations, and AI Bridge
2. **Renderer Process** (Browser): Svelte-based UI for user interaction
3. **AI Bridge** (UDP Server): Real-time communication layer between Factorio and AI providers

## Technology Stack

### Core Technologies
- **Electron 28**: Desktop application framework
- **TypeScript 5**: Type-safe JavaScript
- **Svelte 5**: Reactive UI framework with runes API
- **Vite**: Fast build tool and dev server

### AI SDKs
- **Vercel AI SDK**: Unified interface for multiple AI providers
- Provider-specific SDKs: OpenAI, Anthropic, Google, xAI, DeepSeek

### Communication
- **IPC (Inter-Process Communication)**: Electron's built-in IPC for main ↔ renderer
- **UDP Sockets**: Node.js `dgram` for Factorio ↔ AI Bridge

### Development Tools
- **ESLint**: Code linting with TypeScript and Svelte plugins
- **Prettier**: Code formatting
- **electron-builder**: Application packaging

## Application Structure

```
┌─────────────────────────────────────────────────────────────┐
│                     Electron Main Process                   │
├─────────────────────────────────────────────────────────────┤
│  app.ts                                                     │
│  ├─ Window Management                                       │
│  ├─ Lifecycle Hooks                                         │
│  └─ Manager Initialization                                  │
├─────────────────────────────────────────────────────────────┤
│  Managers Layer                                             │
│  ├─ ConfigManager: User preferences persistence             │
│  ├─ FactorioManager: Process detection and launching        │
│  └─ AIBridgeManager: AI service lifecycle                   │
├─────────────────────────────────────────────────────────────┤
│  Services Layer                                             │
│  ├─ IPCHandlers: IPC endpoint definitions                   │
│  └─ AIBridge: UDP server and AI API integration             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Electron Renderer Process                 │
├─────────────────────────────────────────────────────────────┤
│  App.svelte                                                 │
│  └─ Root component with global effects                      │
├─────────────────────────────────────────────────────────────┤
│  Stores (State Management)                                  │
│  ├─ config-store: Application configuration                 │
│  ├─ status-store: UI status and messages                    │
│  ├─ ai-bridge-service: AI Bridge control                    │
│  └─ factorio-service: Factorio process control              │
├─────────────────────────────────────────────────────────────┤
│  Components                                                 │
│  ├─ sections/: High-level feature sections                  │
│  ├─ form/: Input components                                 │
│  ├─ buttons/: Styled buttons                                │
│  ├─ ui/: Display components                                 │
│  └─ layout/: Structural components                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        Shared Module                        │
├─────────────────────────────────────────────────────────────┤
│  types.ts: Type definitions (Config, ContextBridge, etc.)   │
│  constants.ts: Application-wide constants                   │
│  logger.ts: Structured logging utility                      │
└─────────────────────────────────────────────────────────────┘
```

## Process Architecture

### Main Process Responsibilities

1. **System Integration**
   - Factorio executable detection (Registry, Steam VDF parsing)
   - File system operations (config read/write)
   - Process monitoring (tasklist polling)
   - External URL opening

2. **AI Bridge Management**
   - UDP socket lifecycle
   - AI SDK client initialization
   - Request/response handling
   - Provider switching

3. **Configuration Management**
   - JSON config persistence
   - Migration handling
   - API key storage

### Renderer Process Responsibilities

1. **User Interface**
   - Factorio-themed components
   - Real-time status updates
   - Form validation
   - Window controls

2. **State Management**
   - Reactive stores with Svelte runes
   - IPC request orchestration
   - Status message timing

3. **User Interactions**
   - Provider/model selection
   - API key input
   - Path browsing
   - Launch controls

### Preload Script

The preload script (`electron/preload.ts`) acts as a secure bridge between processes:

```typescript
// Exposes limited, safe API to renderer
contextBridge.exposeInMainWorld('bridge', {
  getConfig: () => ipcRenderer.invoke('get-config'),
  saveConfig: (config) => ipcRenderer.invoke('save-config', config),
  // ... other methods
});
```

This ensures:
- No direct Node.js access from renderer (security)
- Type-safe IPC with `ContextBridge` interface
- Centralized IPC endpoint definitions

## Data Flow

### Configuration Loading

```
Application Start
       ↓
ConfigManager.loadConfig()
       ↓
Read config.json from userData
       ↓
Apply migrations (if needed)
       ↓
Initialize managers with config
       ↓
Renderer requests config via IPC
       ↓
UI displays current settings
```

### Factorio Launch Flow

```
User clicks "Launch"
       ↓
Renderer: factorioService.launchFactorio()
       ↓
IPC: launchFactorio()
       ↓
Main: FactorioManager.launchFactorio()
       ↓
exec("factorio.exe --enable-lua-udp 9001")
       ↓
Status monitoring begins
       ↓
IPC: factorio-status-update events
       ↓
Renderer: Update UI status
```

### AI Bridge Request Flow

```
Factorio Mod sends UDP request
       ↓
AIBridge receives on port 8889
       ↓
Parse JSON payload
       ↓
Determine request type (task/fix/test_generation)
       ↓
Build prompt with context
       ↓
Call AI Provider SDK (generateText)
       ↓
Receive AI response
       ↓
Format response JSON
       ↓
Send UDP response to port 9001
       ↓
Factorio Mod receives and executes
```

## Component Hierarchy

```
App.svelte
├─ TitleBar
│  ├─ Window controls (minimize, close)
│  └─ App title
├─ StatusIndicator
│  └─ Current status display
├─ StatusPreviewDisplay
│  └─ Visual status indicators
├─ FactorioPathSection
│  ├─ InputField (path display)
│  ├─ Button (Browse)
│  └─ Button (Auto-detect)
├─ AIConfigSection
│  ├─ Dropdown (Provider)
│  ├─ Dropdown (Model)
│  ├─ KeyToggleInput (API Key)
│  └─ Button (Get API Key)
└─ LaunchSection
   └─ GreenButton (Launch Factorio)
```

### Component Design Principles

1. **Single Responsibility**: Each component has one clear purpose
2. **Props Down, Events Up**: Data flows down, events bubble up
3. **Composability**: Small components combine to build features
4. **Styling Isolation**: Components use scoped styles with `:global()` for Factorio theme

## State Management

### Store Architecture

The application uses **Svelte stores** with **service classes** for business logic:

```typescript
// Store: Reactive data container
export const config = writable<Config>(initialConfig);

// Service: Business logic and IPC communication
export class ConfigService {
  async loadConfig(): Promise<void> {
    const loadedConfig = await ipc.getConfig();
    config.set(loadedConfig);
  }
  
  async saveConfig(configValue: Config): Promise<void> {
    await ipc.saveConfig(configValue);
    config.set(configValue);
  }
}

export const configService = new ConfigService();
```

### Store Categories

1. **config-store**: Application configuration
   - Provider/model selection
   - API keys
   - Factorio path
   - UDP port

2. **status-store**: UI status and messages
   - Factorio running state
   - Temporary status messages
   - Launching state
   - Status indicators

3. **ai-bridge-service**: AI Bridge control
   - Start/stop/restart operations
   - Model updates
   - Bridge status

4. **factorio-service**: Factorio process control
   - Status checking
   - Path detection
   - Launch operations

### Reactive Effects with Svelte 5 Runes

The application uses Svelte 5's `$effect` rune for reactive side effects:

```typescript
// Auto-save when provider changes
$effect(() => {
  if (previousProvider !== null && $config.aiProvider !== previousProvider) {
    aiBridgeService.restartAIBridge();
  }
  previousProvider = $config.aiProvider;
});
```

## AI Bridge Protocol

### Message Format

All UDP messages use JSON with a common structure:

#### Request Types

**Task Request** (Generate new code)
```json
{
  "type": "task_request",
  "uid": 123,
  "task_text": "Output 1 to signal-A when iron-ore > 100",
  "correlation_id": 456
}
```

**Fix Request** (Fix existing code)
```json
{
  "type": "fix_request",
  "uid": 123,
  "task_text": "Error: attempt to index nil value\n-- code snippet --",
  "correlation_id": 456
}
```

**Test Generation Request**
```json
{
  "type": "test_generation_request",
  "uid": 123,
  "task_description": "Output signal when threshold exceeded",
  "source_code": "if red['iron-ore'] > 100 then out['signal-A'] = 1 end",
  "correlation_id": 456
}
```

**Ping Request**
```json
{
  "type": "ping_request",
  "uid": 123,
  "timestamp": 1234567890
}
```

#### Response Format

```json
{
  "type": "task_request_completed",
  "uid": 123,
  "correlation_id": 456,
  "response": "if (red['iron-ore'] or 0) > 100 then\n  out['signal-A'] = 1\nend"
}
```

### Prompt Engineering

The AI Bridge uses a comprehensive system prompt that:
- Constrains output to valid Lua 5.2 syntax
- Defines the combinator sandbox environment
- Lists forbidden operations (function declarations, external libraries)
- Provides examples of valid code
- Handles ambiguity with ERROR responses

See `electron/services/ai-bridge.ts` for the full prompt.

## Design Decisions

### Why Electron?
- **Cross-platform**: Works on Windows, macOS, Linux
- **Unified stack**: TypeScript/JavaScript throughout
- **Rich APIs**: File system, process management, native dialogs
- **Auto-updates**: Built-in update mechanism

### Why Svelte 5?
- **Performance**: Compiles to vanilla JS, no virtual DOM
- **Reactivity**: Natural reactive programming with runes
- **Bundle size**: Smaller than React/Vue equivalents
- **Developer experience**: Less boilerplate, intuitive API

### Why UDP for AI Bridge?
- **Simplicity**: Connectionless, no handshake overhead
- **Speed**: Low latency for real-time interaction
- **Factorio compatibility**: Lua has built-in UDP socket support
- **Local only**: No network security concerns

### Why Vercel AI SDK?
- **Unified interface**: Same API for all providers
- **Type safety**: Full TypeScript support
- **Streaming support**: Ready for future streaming features
- **Provider flexibility**: Easy to add new providers

### Configuration Storage
- **JSON file**: Human-readable, easy to debug
- **Electron userData**: Standard location per platform
- **No database**: Overkill for simple key-value config

### Manager Pattern
- **Separation of concerns**: Each manager handles one domain
- **Testability**: Managers can be unit tested independently
- **Dependency injection**: Passed to IPCHandlers for flexible composition
- **Lifecycle management**: Clear initialization and cleanup

## Security Considerations

1. **Context Isolation**: Preload script prevents direct Node.js access
2. **API Key Storage**: Plain text in userData (OS-level protection)
3. **IPC Validation**: Type checking on all IPC calls
4. **No Remote Code**: No `eval()` or dynamic script loading
5. **Local Only**: UDP sockets only bind to localhost

## Performance Optimizations

1. **Lazy Loading**: Components loaded on demand
2. **Debouncing**: API key input changes debounced
3. **Efficient Polling**: 5-second interval for status checks
4. **Minimal Re-renders**: Svelte's fine-grained reactivity
5. **TypeScript Compilation**: Pre-compiled for production

## Future Considerations

### Potential Enhancements
- **Bridge as standalone service**: Separate from launcher
- **Multiple Factorio instances**: Support concurrent games
- **AI response caching**: Cache common patterns
- **Settings export/import**: Portable configuration
- **Dark/light themes**: User preference support
- **Logging to file**: Persistent logs for debugging

### Known Limitations
- **Windows-focused**: Auto-detection only works on Windows
- **Single provider**: Can't use multiple providers simultaneously
- **No streaming**: AI responses arrive all at once
- **English only**: No internationalization
