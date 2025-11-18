# GitHub Actions Workflows

## Release Launcher

The `release-launcher.yml` workflow builds and releases the AI Combinator Launcher for Windows.

### How to Create a Release

#### Method 1: Using Git Tags (Recommended)

1. Update the version in `launcher/package.json`
2. Commit the changes:
   ```powershell
   git add launcher/package.json
   git commit -m "Bump version to X.Y.Z"
   ```
3. Create and push a version tag:
   ```powershell
   git tag v0.1.0
   git push origin v0.1.0
   ```
4. The workflow will automatically build and create a GitHub release

#### Method 2: Manual Trigger

1. Go to the [Actions tab](../../actions/workflows/release-launcher.yml) on GitHub
2. Click "Run workflow"
3. Enter the version number
4. Click "Run workflow"

This method will build the application but won't create a release automatically.

### What Gets Built

- **AI Combinator Launcher Setup X.Y.Z.exe** - Windows installer (NSIS format)
- **latest.yml** - Update metadata for electron auto-updater
- Build artifacts are stored for 7 days

### Release Notes

Release notes are automatically generated from commit messages between tags.

### Requirements

- Node.js 20
- The workflow runs on Windows to ensure proper Windows executable generation
- Requires `GITHUB_TOKEN` (automatically provided by GitHub Actions)
