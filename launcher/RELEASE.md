# Launcher Release Process

This document describes how to create releases for the AI Combinator Launcher using GitHub Actions.

## Overview

The GitHub Actions workflow automatically builds Windows executables for the launcher whenever you create a version tag. The workflow:

1. Builds the Svelte renderer
2. Compiles TypeScript for Electron
3. Packages the app using electron-builder
4. Creates a GitHub release with the installer

## Creating a Release

### Step 1: Update Version

Update the version number in `launcher/package.json`:

```json
{
  "name": "ai-combinator-launcher",
  "version": "0.2.0",  // Update this
  ...
}
```

### Step 2: Commit Changes

```powershell
cd "c:\Users\Philipp\AppData\Roaming\Factorio\mods\ai_combinator"
git add launcher/package.json
git commit -m "Bump launcher version to 0.2.0"
git push origin main
```

### Step 3: Create and Push Tag

```powershell
# Create the tag (must start with 'v')
git tag v0.2.0

# Push the tag to GitHub
git push origin v0.2.0
```

### Step 4: Monitor the Build

1. Go to https://github.com/galgtonold/ai_combinator/actions
2. Watch the "Build and Release Launcher" workflow
3. Once complete, check the Releases page

## What Gets Created

The workflow creates:
- **AI Combinator Launcher Setup X.Y.Z.exe** - Windows installer
- **latest.yml** - Auto-updater metadata
- GitHub Release with automatic release notes

## Manual Build (Alternative)

If you want to build locally without creating a release:

```powershell
cd "c:\Users\Philipp\AppData\Roaming\Factorio\mods\ai_combinator\launcher"

# Install dependencies (if needed)
npm install
cd renderer; npm install; cd ..

# Build
npm run build:renderer
npm run build:electron
npm run package
```

The installer will be in `launcher/build/`.

## Troubleshooting

### Build Fails
- Check that Node.js version in workflow matches your local version
- Verify all dependencies in package.json are correct
- Check the Actions logs for specific errors

### Version Mismatch
- Make sure the tag version (e.g., v0.2.0) matches package.json version (0.2.0)
- Tags must start with 'v'

### No Release Created
- Verify you pushed the tag: `git push origin v0.2.0`
- Check that workflow has `contents: write` permission (should be automatic)

## Testing Before Release

Before creating a release tag, test the build locally:

```powershell
cd "c:\Users\Philipp\AppData\Roaming\Factorio\mods\ai_combinator\launcher"
npm run package
```

Then test the installer in `build/` directory.
