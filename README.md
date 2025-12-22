# Homebrew Tap for Plezy

A Homebrew tap for [Plezy](https://github.com/edde746/plezy) - A modern Plex client for desktop and mobile.

## Quick Start

```bash
# Add the tap and install Plezy
brew tap Tazi0/plezy
brew install --cask plezy

# That's it! Plezy is now installed in your Applications folder.
```

## Installation

### Add the tap and install Plezy

```bash
brew tap Tazi0/plezy
brew install --cask plezy
```

### Install directly (without adding tap)

```bash
brew install --cask Tazi0/plezy/plezy
```

## What is Plezy?

Plezy is a modern Plex client built with Flutter that provides:

- 🔐 **Authentication**: Sign in with Plex and automatic server discovery
- 📚 **Media Browsing**: Browse libraries with rich metadata and advanced search
- 🎬 **Playback**: Wide codec support including HEVC, AV1, VP9, HDR, and Dolby Vision
- 📥 **Downloads**: Download media for offline viewing with background queue management
- 👥 **Watch Together**: Synchronized playback with friends

## Supported Platforms

This tap provides:

- **macOS**: Universal app bundle (Intel and Apple Silicon)

## Usage

### Install Plezy

```bash
brew tap Tazi0/plezy
brew install --cask plezy
```

### Update Plezy

```bash
brew upgrade --cask plezy
```

### Uninstall Plezy

```bash
brew uninstall --cask plezy
```

### Remove this tap

```bash
brew untap Tazi0/plezy
```

## Automatic Updates

This tap automatically monitors the [official Plezy releases](https://github.com/edde746/plezy/releases) and updates the cask when new versions are available. The automation runs every 30 minutes.

## Manual Updates

If you want to force an update or contribute:

1. Fork this repository
2. Update the version and SHA256 in `Casks/plezy.rb`
3. Test locally: `brew install --cask Casks/plezy.rb`
4. Submit a pull request

## Verification

Each release is verified with:

- SHA256 checksum validation
- App bundle structure verification
- Download URL accessibility testing
- Code syntax validation

## Troubleshooting

### Installation Issues

**Permission denied**

```bash
sudo chown -R $(whoami) /opt/homebrew/Caskroom/
```

**App won't open (macOS Gatekeeper)**

```bash
xattr -cr /Applications/plezy.app
```

**Cask conflicts**

```bash
brew uninstall --cask plezy
brew install --cask plezy
```

### Getting Help

- **App Issues**: [Report on main repository](https://github.com/edde746/plezy/issues)
- **Tap Issues**: [Create issue here](../../issues)
- **Homebrew Issues**: [Homebrew Documentation](https://docs.brew.sh/)

## Development

### Testing the Cask

```bash
# Validate syntax
brew audit --strict --cask Casks/plezy.rb

# Test installation
brew install --cask Casks/plezy.rb --dry-run

# Check style
brew style Casks/plezy.rb
```

### Local Development

```bash
git clone https://github.com/Tazi0/homebrew-plezy.git
cd homebrew-plezy

# Test cask
brew install --cask Casks/plezy.rb

# Make changes and test
brew uninstall --cask plezy
brew install --cask Casks/plezy.rb
```

## Repository Structure

```
homebrew-plezy/
├── Casks/
│   └── plezy.rb              # Main cask definition
├── .github/
│   └── workflows/
│       ├── update-cask.yml   # Auto-update workflow
│       └── test-cask.yml     # Testing workflow
├── scripts/
│   └── update.sh             # Manual update script
└── README.md                 # This file
```

## Links

- **Plezy Homepage**: https://github.com/edde746/plezy
- **Plezy Releases**: https://github.com/edde746/plezy/releases
- **Homebrew Documentation**: https://docs.brew.sh/
- **Homebrew Cask Cookbook**: https://github.com/Homebrew/homebrew-cask/blob/master/CONTRIBUTING.md

## License

This tap is provided as-is. Plezy is licensed under its own terms - see the [main repository](https://github.com/edde746/plezy) for details.
