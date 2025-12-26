#!/bin/bash

# Manual update script for Plezy Homebrew cask
# Usage: ./scripts/update.sh [version]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CASK_FILE="$PROJECT_ROOT/Casks/plezy.rb"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

print_info "Plezy Homebrew Cask Update Script"
echo

# Check if cask file exists
if [ ! -f "$CASK_FILE" ]; then
    print_error "Cask file not found at $CASK_FILE"
    exit 1
fi

# Get version from argument or fetch latest
if [ -n "$1" ]; then
    VERSION="$1"
    print_info "Using provided version: $VERSION"
else
    print_info "Fetching latest version from GitHub..."
    VERSION=$(curl -s https://api.github.com/repos/edde746/plezy/releases/latest | jq -r '.tag_name')

    if [ "$VERSION" = "null" ] || [ -z "$VERSION" ]; then
        print_error "Failed to fetch latest version from GitHub"
        exit 1
    fi

    print_success "Found latest version: $VERSION"
fi

# Get current version from cask
CURRENT_VERSION=$(grep 'version "' "$CASK_FILE" | sed 's/.*version "\(.*\)".*/\1/')
print_info "Current cask version: $CURRENT_VERSION"

# Check if update is needed
if [ "$CURRENT_VERSION" = "$VERSION" ]; then
    print_warning "Cask is already at version $VERSION"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aborting update"
        exit 0
    fi
fi

# Download the release
DOWNLOAD_URL="https://github.com/edde746/plezy/releases/download/$VERSION/plezy-macos.dmg"
print_info "Downloading $DOWNLOAD_URL"

curl -L -f -o "/tmp/plezy-macos.dmg" "$DOWNLOAD_URL"

if [ ! -f "/tmp/plezy-macos.dmg" ]; then
    print_error "Failed to download release asset"
    exit 1
fi

print_success "Downloaded release asset"

# Calculate SHA256
print_info "Calculating SHA256 checksum..."
SHA256=$(shasum -a 256 "/tmp/plezy-macos.dmg" | cut -d' ' -f1)
print_success "SHA256: $SHA256"

# Verify DMG contents
print_info "Verifying DMG contents..."
hdiutil attach "/tmp/plezy-macos.dmg" -nobrowse -quiet

# Find the mount point
MOUNT_POINT=$(hdiutil info | grep -A1 "plezy-macos.dmg" | grep "/Volumes" | awk '{print $1}')
if [ -z "$MOUNT_POINT" ]; then
    MOUNT_POINT="/Volumes/Plezy"
fi

echo "DMG contents:"
ls -la "$MOUNT_POINT"

if [ ! -d "$MOUNT_POINT/Plezy.app" ]; then
    print_warning "Plezy.app not found in expected location"
    print_info "DMG contents above - please verify manually"
    hdiutil detach "$MOUNT_POINT" -quiet
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Aborting due to unexpected DMG structure"
        exit 1
    fi
else
    hdiutil detach "$MOUNT_POINT" -quiet
fi

# Create backup of current cask
BACKUP_FILE="$CASK_FILE.backup.$(date +%s)"
cp "$CASK_FILE" "$BACKUP_FILE"
print_info "Created backup: $BACKUP_FILE"

# Update cask file
print_info "Updating cask file..."

cat > "$CASK_FILE" << EOF
cask "plezy" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/edde746/plezy/releases/download/#{version}/plezy-macos.dmg"
  name "Plezy"
  desc "Modern Plex client for desktop and mobile"
  homepage "https://github.com/edde746/plezy"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  app "Plezy.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Plezy.app"],
                   sudo: false
  end

  uninstall quit: "com.edde746.plezy"

  zap trash: [
    "~/Library/Application Support/com.edde746.plezy",
    "~/Library/Caches/com.edde746.plezy",
    "~/Library/HTTPStorages/com.edde746.plezy",
    "~/Library/Preferences/com.edde746.plezy.plist",
    "~/Library/Saved Application State/com.edde746.plezy.savedState",
    "~/Library/WebKit/com.edde746.plezy",
  ]
end
EOF

print_success "Updated cask file"

# Validate cask if Homebrew is available
if command -v brew &> /dev/null; then
    print_info "Validating cask syntax..."
    if brew audit --strict --cask plezy 2>/dev/null; then
        print_success "Cask validation passed"
    else
        print_warning "Cask validation failed, but file was still updated"
    fi

    print_info "Checking cask style..."
    if brew style plezy 2>/dev/null; then
        print_success "Style check passed"
    else
        print_warning "Style check failed, but file was still updated"
    fi
else
    print_warning "Homebrew not found - skipping validation"
fi

# Clean up
rm -f "/tmp/plezy-macos.dmg"

print_success "Update completed!"
echo
print_info "Updated from $CURRENT_VERSION to $VERSION"
print_info "SHA256: $SHA256"
print_info "Backup saved as: $BACKUP_FILE"
echo
print_info "Next steps:"
echo "  1. Test the cask: brew install --cask plezy"
echo "  2. Validate: brew audit --strict --cask plezy"
echo "  3. Commit changes: git add Casks/plezy.rb && git commit -m 'chore: update plezy to $VERSION'"
echo "  4. Push changes: git push"
echo
print_info "To restore backup if needed:"
echo "  mv $BACKUP_FILE $CASK_FILE"
