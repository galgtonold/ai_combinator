# Changelog

All notable changes to the AI Combinator project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.1.0] - 2024-12-14

### Added
- **Ollama support**: Added support for Ollama as an AI provider, enabling local AI model usage
- Free-form model input for Ollama provider allowing any compatible model
- Ollama provider logo and UI integration

### Changed
- Enhanced AI provider configuration to support multiple provider types
- Updated model selection to persist separately for each provider
- Improved provider switching UX in launcher

## [1.0.0] - 2024-12-13

### 🎉 First Stable Release!

AI Combinator is now production-ready for Factorio 2.0.

### Added
- Added video demos to mod portal documentation
- Added new GPT-5.2 and GPT-5.2 Pro model options

### Changed
- Updated mod description to better explain test case features
- Refined AI model selection options

## [0.1.8] - 2024-12-10

### Fixed
- Fixed launcher version not updating in release pipeline (package.json was outdated)

## [0.1.7] - 2024-12-10

### Fixed
- Internal Github pipeline problems

## [0.1.6] - 2024-12-10

### Added
- Added MIT license
- Added demo video to README
- Added mod portal description (MOD_PORTAL.md)
- Added thumbnail for mod portal

### Fixed
- Fix API key binding and bridge restart on provider/key changes
- Fix duplicate open warning in AI combinator GUI
- Center dialog properly in AI combinator GUI
- Fix "Fix with AI" button now works when code has errors even if tests pass
- Include syntax and runtime errors in AI fix requests
- Improve Lua error message formatting for better readability
- Clear internal 'var' variables when code changes

### Changed
- Refactor code to remove unused variables and improve readability
- Unify Lua code style with StyLua
- Update DEVELOPMENT.md with current project structure
- Update README with better examples and fix image links

## [0.1.5] - 2024-12-07

### Changed
- Improved README with clearer examples and security note for Windows SmartScreen

## [0.1.4] - 2024-12-07

### Fixed
- Fixed release pipeline not uploading installer files

## [0.1.3] - 2024-12-07

### Fixed
- Fixed launcher crash on startup (missing runtime dependencies)

## [0.1.2] - 2024-12-07

### Added
- Version number now displayed in launcher title bar
- Auto-update support for the launcher (Windows)

## [0.1.1] - 2024-12-07

### Fixed
- Fixed crashes when closing dialogs in certain order
- Fixed crashes related to GUI element validity
- Fixed test case evaluation issues
- Fixed help button not working in some dialogs
- Fixed launcher status message when Factorio closes

### Added
- Added UPS optimization tips to help dialogs
- Added newer AI model options (GPT-4o, Claude 3.5 Sonnet, etc.)
- Improved AI "Fix with AI" prompt for better results

### Changed
- Improved dialog management - dialogs now properly single-instance
- Improved live updates in the combinator GUI

## [0.1.0] - 2024-11-XX

### Added
- Initial release with launcher application
- AI-powered Lua code generation for circuit combinators
- Test case system with auto-generation feature
- "Fix with AI" feature to automatically fix failing tests
- Blueprint support with undo compatibility
- Help dialogs explaining all features
- Cancellation support for AI operations
- Fun progress messages during AI processing
- Variable persistence across game saves

### Fixed
- Various UI and stability fixes

### Changed
- Improved test case UI layout
- Better AI operation status feedback
- Major layout improvements to test case UI
- Main AI combinator dialog UI improvements
