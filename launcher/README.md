# AI Combinator Launcher

A desktop application for configuring and launching Factorio with the AI Combinator mod. This launcher manages AI provider configuration, automatically detects Factorio installations, and runs the AI Bridge for real-time code generation.

## Features

### 🎮 Factorio Integration
- **Automatic Detection**: Finds Factorio installations via Windows Registry and Steam library folders (VDF parsing)
- **Manual Selection**: Browse for `factorio.exe` if auto-detection fails
- **Launch Management**: Starts Factorio with proper UDP configuration for mod communication
- **Status Monitoring**: Real-time process monitoring with visual indicators

### 🤖 AI Provider Support
- **Multiple Providers**: OpenAI, Anthropic (Claude), Google (Gemini), xAI (Grok), DeepSeek
- **Model Selection**: Choose from provider-specific models with automatic validation
- **API Key Management**: Secure storage of provider credentials
- **Hot Swapping**: Change models without restarting

### 🌉 AI Bridge
- **Real-time Communication**: UDP-based bidirectional messaging with Factorio
- **Code Generation**: Translates natural language into Lua code for Moon Logic combinators
- **Test Generation**: AI-powered test case creation for combinator logic
- **Built-in Bridge**: No separate Python installation required

### 🎨 User Interface
- **Factorio Theme**: Custom UI matching the game's aesthetic
- **Frameless Window**: Native window controls with custom title bar
- **Responsive**: Clean layout optimized for quick configuration

## Quick Start

### Prerequisites
- **Node.js** 18+ and npm
- **Factorio** installed on your system
- **API Key** from at least one supported AI provider

### Installation

```powershell
cd launcher
npm install
```

### Development

```powershell
npm run dev
```

This starts:
1. Vite dev server for the renderer (port 5173)
2. TypeScript compilation in watch mode
3. Electron window with hot reloading

### Building

```powershell
npm run package
```

Creates distributable packages in `build/` directory using electron-builder.

## Project Structure

```
launcher/
├── electron/              # Main process (Node.js backend)
│   ├── app.ts            # Application entry point
│   ├── preload.ts        # Context bridge (IPC interface)
│   ├── managers/         # Business logic managers
│   │   ├── config-manager.ts
│   │   ├── factorio-manager.ts
│   │   └── ai-bridge-manager.ts
│   └── services/         # Core services
│       ├── ai-bridge.ts  # UDP AI Bridge implementation
│       └── ipc-handlers.ts
│
├── renderer/             # Frontend (Svelte UI)
│   └── src/
│       ├── App.svelte    # Main component
│       ├── components/   # Reusable UI components
│       ├── stores/       # State management
│       ├── composables/  # Reactive effects
│       ├── config/       # AI provider configuration
│       └── utils/        # Helper functions
│
├── shared/               # Shared types and utilities
│   ├── types.ts          # Type definitions
│   ├── constants.ts      # Application constants
│   └── logger.ts         # Logging utility
│
└── assets/               # Application assets
    └── icon.png/ico      # App icon
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development mode with hot reload |
| `npm run package` | Build production distributable |
| `npm run build:electron` | Compile TypeScript for main process |
| `npm run build:renderer` | Build renderer for production |
| `npm run lint` | Run ESLint on all files |
| `npm run lint:fix` | Auto-fix ESLint issues |
| `npm run format` | Format code with Prettier |
| `npm run typecheck` | Type-check without emitting files |

## Configuration

The launcher stores configuration in Electron's `userData` directory:
- **Windows**: `%APPDATA%\ai-combinator-launcher\config.json`

### Config Schema

```typescript
{
  factorioPath: string;           // Path to factorio.exe
  aiBridgeEnabled: boolean;       // Auto-start bridge
  aiProvider: AIProvider;         // Selected provider
  aiModel: string;                // Model identifier
  udpPort: number;                // UDP communication port (default: 9001)
  providerApiKeys: {              // API keys per provider
    [provider: string]: string;
  }
}
```

## Architecture

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed architecture documentation including:
- Application lifecycle and bootstrapping
- IPC communication patterns
- State management approach
- AI Bridge protocol
- Component hierarchy

## Development Guidelines

### Code Style
- **TypeScript**: Strict mode enabled
- **Formatting**: Prettier with project config
- **Linting**: ESLint with TypeScript and Svelte plugins
- **Naming**: 
  - Files: `kebab-case.ts`
  - Components: `PascalCase.svelte`
  - Functions: `camelCase`
  - Constants: `UPPER_SNAKE_CASE`

### Best Practices
- Use `createLogger('ModuleName')` for all logging
- Prefer TypeScript interfaces over types for objects
- Document public APIs with JSDoc comments
- Keep components focused and single-purpose
- Use Svelte stores for cross-component state

### Adding New AI Providers

1. Update `shared/types.ts`: Add provider to `AIProvider` type
2. Update `renderer/src/config/ai-config.ts`: Add provider and models
3. Update `electron/services/ai-bridge.ts`: Add SDK import and provider case
4. Install provider SDK: `npm install @ai-sdk/[provider]`

## Troubleshooting

### Factorio Not Detected
- Ensure Factorio is installed via Steam or standalone installer
- Try manual browse if auto-detection fails
- Check that `factorio.exe` exists at the selected path

### AI Bridge Won't Start
- Verify API key is entered correctly
- Check that UDP port 9001 is not in use
- Look for errors in the console

### Build Errors
- Delete `node_modules` and `dist` folders, then `npm install`
- Ensure Node.js version is 18+
- Check that all peer dependencies are installed

