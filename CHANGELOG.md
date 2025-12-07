# Changelog

All notable changes to the AI Combinator project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
