# AI Combinator Launcher

This is a launcher application for the Factorio AI Combinator mod. It helps users configure and launch Factorio with the AI Combinator mod properly set up.

## Features

- Automatic detection of Factorio executable using:
  - Windows Registry entries
  - Steam library folders parsing (VDF files)
- Manual selection of Factorio executable
- OpenAI API key configuration
- Factorio-inspired UI design resembling a combinator interface
- Easy launch of Factorio with mod configuration

## Folder structure

- **/**
  - README.md
  - package.json
  - **electron** - Contains all the Electron-specific code
    - app.ts - Main process code with Factorio detection logic
    - preload.ts - Sets up communication between renderer and main process
    - tsconfig.json
  - **renderer** - Contains all frontend code
    - **src**
      - App.svelte - Main Svelte component
      - factorio.css - Factorio-inspired UI styles
      - ipc.ts - IPC bridge definition
    - vite.config.ts
    - package.json

## Commands

- `npm run dev` - Start the application in development mode with hot reloading
- `npm run package` - Package the application into a distributable format using electron-builder

## Requirements

- Node.js and npm
- Factorio installed on the system
- OpenAI API key for AI features
