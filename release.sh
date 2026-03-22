#!/usr/bin/env bash
#
# release.sh — Build the macOS app, finalize the GitHub Release, and commit appcast.xml.
#
# This is step 2 of the two-step release process.  Step 1 (release.ps1) must have
# already run on Windows: it bumps the version in pubspec.yaml, builds the MSIX,
# and creates a draft GitHub Release.
#
# This script:
#   Phase 1 — Build macOS:
#     1.  git pull origin main
#     2.  Verify pubspec.yaml version matches the expected version
#     3.  flutter build macos --release
#     4.  Create staging directory and copy DhikrAtWork.app + README.txt
#     5.  Zip staging into DhikrAtWork-v{version}-macos-arm64.zip
#     6.  Sign the zip with Sparkle's sign_update → capture edSignature + length
#     7.  Generate SHA256 checksum of the zip
#
#   Phase 2 — Finalize GitHub Release:
#     8.  Download the Windows zip checksum from the draft release
#     9.  Generate DhikrAtWork.appinstaller XML
#     10. Update appcast.xml (remove placeholder item if present; prepend new item)
#     11. Upload macOS zip, macOS checksum, and .appinstaller to the draft release
#     12. Read changelog from draft release body
#     13. Generate full release notes and update the release body
#     14. Publish the release: gh release edit --draft=false
#     15. Commit updated appcast.xml to main and push
#
# Usage:
#   ./release.sh <version> [--sparkle-tools-dir <path>]
#
# Arguments:
#   version             Release version in X.Y.Z semver format (e.g. 0.2.0)
#   --sparkle-tools-dir Path to the extracted Sparkle tools directory containing sign_update.
#                       If omitted, the script expects sign_update on PATH or in ./bin/sign_update.
#
# Prerequisites:
#   - release.ps1 must have already run: pubspec.yaml bumped, draft release created with
#     Windows artifacts uploaded (zip + checksum + bare DhikrAtWork.msix)
#   - Sparkle sign_update tool accessible (--sparkle-tools-dir, PATH, or ./bin/sign_update)
#     IMPORTANT: must be the SAME Sparkle version bundled by the auto_updater pub package.
#     Check auto_updater's podspec or macos/Pods/Sparkle/ to determine the exact version.
#     Mismatched Sparkle versions cause SILENT signature verification failures.
#   - gh CLI installed and authenticated (gh auth status)
#   - flutter on PATH

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths and constants
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

PUBSPEC="$PROJECT_ROOT/pubspec.yaml"
APPCAST="$PROJECT_ROOT/appcast.xml"
README_TEMPLATE="$PROJECT_ROOT/dist/README-macos.txt"
APP_BUNDLE_SRC="$PROJECT_ROOT/build/macos/Build/Products/Release/dhikratwork.app"
STAGING_PARENT="$PROJECT_ROOT/build/_release_staging"

GITHUB_REPO="thecodeartificerX/dhikratwork"
APPINSTALLER_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/DhikrAtWork.appinstaller"

# ---------------------------------------------------------------------------
# Colour helpers (matching build.sh style)
# ---------------------------------------------------------------------------
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
NC='\033[0m'

step_header() {
  echo ""
  echo -e "${CYAN}[$1] $2${NC}"
  printf '%0.s-' {1..60}; echo ""
}

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; }
info() { echo -e "  ${DIM}INFO${NC}  $1"; }

die() {
  echo ""
  echo -e "  ${RED}ERROR${NC}  $1" >&2
  echo ""
  exit 1
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
VERSION=""
SPARKLE_TOOLS_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sparkle-tools-dir)
      [[ $# -lt 2 ]] && die "--sparkle-tools-dir requires a path argument"
      SPARKLE_TOOLS_DIR="$2"
      shift 2
      ;;
    --sparkle-tools-dir=*)
      SPARKLE_TOOLS_DIR="${1#*=}"
      shift
      ;;
    -*)
      die "Unknown flag: $1"
      ;;
    *)
      if [[ -z "$VERSION" ]]; then
        VERSION="$1"
      else
        die "Unexpected positional argument: $1"
      fi
      shift
      ;;
  esac
done

[[ -z "$VERSION" ]] && die "Usage: ./release.sh <version> [--sparkle-tools-dir <path>]
  Example: ./release.sh 0.2.0
  Example: ./release.sh 0.2.0 --sparkle-tools-dir ~/sparkle-2.x/bin"

# Validate semver format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  die "Version must be in X.Y.Z semver format (e.g. 0.2.0). Got: $VERSION"
fi

# Derived names
TAG="v${VERSION}"
APPINSTALLER_VERSION="${VERSION}.0"
ZIP_NAME="DhikrAtWork-${TAG}-macos-arm64"
ZIP_FILE="${ZIP_NAME}.zip"
CHECKSUM_FILE="${ZIP_FILE}.sha256"
STAGING_DIR="${STAGING_PARENT}/${ZIP_NAME}"
ZIP_PATH="${STAGING_PARENT}/${ZIP_FILE}"
CHECKSUM_PATH="${STAGING_PARENT}/${CHECKSUM_FILE}"
APPINSTALLER_PATH="${STAGING_PARENT}/DhikrAtWork.appinstaller"
WIN_ZIP_NAME="DhikrAtWork-${TAG}-windows-x64.zip"
WIN_CHECKSUM_FILE="${WIN_ZIP_NAME}.sha256"

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  DhikrAtWork Release Pipeline (macOS)${NC}"
echo -e "${YELLOW}  Version: ${TAG}${NC}"
echo -e "${YELLOW}========================================${NC}"

TIMER_START=$(date +%s)

# ---------------------------------------------------------------------------
# Step 1/9 — Validate prerequisites
# ---------------------------------------------------------------------------
step_header "1/9" "Validating prerequisites"

# Locate sign_update
SIGN_UPDATE=""
if [[ -n "$SPARKLE_TOOLS_DIR" ]]; then
  SIGN_UPDATE="${SPARKLE_TOOLS_DIR}/sign_update"
  [[ -x "$SIGN_UPDATE" ]] || die "sign_update not found or not executable at: $SIGN_UPDATE"
elif command -v sign_update &>/dev/null; then
  SIGN_UPDATE="sign_update"
elif [[ -x "$PROJECT_ROOT/bin/sign_update" ]]; then
  SIGN_UPDATE="$PROJECT_ROOT/bin/sign_update"
else
  die "Sparkle sign_update tool not found.
  Options:
    a) Pass --sparkle-tools-dir <path> pointing to the extracted Sparkle bin/ directory
    b) Add sign_update to your PATH
    c) Place sign_update at $PROJECT_ROOT/bin/sign_update
  IMPORTANT: Use the SAME Sparkle version as bundled by the auto_updater pub package.
  Check: macos/Pods/Sparkle/ (after pod install) or inspect auto_updater's podspec."
fi
pass "sign_update found: $SIGN_UPDATE"

# flutter
command -v flutter &>/dev/null || die "flutter not found on PATH. Install Flutter SDK."
pass "flutter found: $(flutter --version --machine 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("frameworkVersion","?"))' 2>/dev/null || flutter --version 2>&1 | head -1)"

# gh CLI
command -v gh &>/dev/null || die "gh CLI not found. Install from https://cli.github.com/"
pass "gh CLI found: $(gh --version 2>&1 | head -1)"

# gh authentication
gh auth status &>/dev/null || die "gh CLI is not authenticated. Run: gh auth login"
pass "gh CLI authenticated"

# README template
[[ -f "$README_TEMPLATE" ]] || die "README template not found: $README_TEMPLATE"
pass "dist/README-macos.txt found"

# Draft release must exist
gh release view "$TAG" --repo "$GITHUB_REPO" &>/dev/null \
  || die "Draft release $TAG not found on GitHub.
  Run release.ps1 on Windows first to create the draft release."
pass "Draft release $TAG exists on GitHub"

# ---------------------------------------------------------------------------
# Step 2/9 — git pull and version verification
# ---------------------------------------------------------------------------
step_header "2/9" "Syncing with remote and verifying version"

git -C "$PROJECT_ROOT" pull origin main \
  || die "git pull failed. Resolve conflicts and retry."
pass "Pulled latest main"

# flutter pub get (triggered by git pull or IDE) changes LF→CRLF in generated config files.
# These are false diffs with no real changes — restore them so the dirty-tree check passes.
GENERATED_FALSE_DIFFS=(
  "ios/Flutter/Debug.xcconfig"
  "ios/Flutter/Release.xcconfig"
  "macos/Flutter/Flutter-Debug.xcconfig"
  "macos/Flutter/Flutter-Release.xcconfig"
)
for f in "${GENERATED_FALSE_DIFFS[@]}"; do
  if git -C "$PROJECT_ROOT" diff --quiet -- "$f" 2>/dev/null; then
    :
  else
    git -C "$PROJECT_ROOT" checkout -- "$f" 2>/dev/null && \
      info "Restored false-diff generated file: $f"
  fi
done

# Abort if the working tree has uncommitted changes — the script commits appcast.xml later
# and a dirty tree would pollute that commit or cause the push to fail.
DIRTY=$(git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null)
if [[ -n "$DIRTY" ]]; then
  die "Working tree has uncommitted changes. Commit or stash them before running release.sh.
  Dirty files:
$(git -C "$PROJECT_ROOT" status --short 2>/dev/null | sed 's/^/    /')"
fi
pass "Working tree is clean"

# Verify pubspec.yaml version matches
PUBSPEC_VERSION=$(grep -m1 '^version:' "$PUBSPEC" | sed 's/version:[[:space:]]*//' | sed 's/+.*//' | tr -d '[:space:]')
if [[ "$PUBSPEC_VERSION" != "$VERSION" ]]; then
  die "Version mismatch: pubspec.yaml has '$PUBSPEC_VERSION' but expected '$VERSION'.
  release.ps1 should have bumped the version and pushed it to main.
  After git pull, the version should match. Check that release.ps1 completed successfully."
fi
pass "pubspec.yaml version verified: $VERSION"

# ---------------------------------------------------------------------------
# Step 3/9 — flutter build macos --release
# ---------------------------------------------------------------------------
step_header "3/9" "flutter build macos --release"

flutter build macos --release \
  || die "flutter build macos --release failed. Check the output above."

[[ -d "$APP_BUNDLE_SRC" ]] \
  || die "Build output not found at expected path: $APP_BUNDLE_SRC"

APP_SIZE=$(du -sh "$APP_BUNDLE_SRC" | cut -f1)
pass "dhikratwork.app built ($APP_SIZE)"

# ---------------------------------------------------------------------------
# Step 4/9 — Create staging directory
# ---------------------------------------------------------------------------
step_header "4/9" "Creating staging directory"

# Clean previous staging for this version
rm -rf "$STAGING_DIR" "$ZIP_PATH" "$CHECKSUM_PATH" "$APPINSTALLER_PATH"
mkdir -p "$STAGING_DIR"

# Copy app bundle, renaming to DhikrAtWork.app for user-facing distribution
cp -R "$APP_BUNDLE_SRC" "$STAGING_DIR/DhikrAtWork.app"
pass "DhikrAtWork.app copied to staging"

# Copy README template with {{VERSION}} replaced (no SHA256 in README)
README_CONTENT=$(cat "$README_TEMPLATE")
README_CONTENT="${README_CONTENT//\{\{VERSION\}\}/$VERSION}"
echo "$README_CONTENT" > "$STAGING_DIR/README.txt"
pass "README.txt written to staging"

info "Staging contents:"
ls -lh "$STAGING_DIR" | tail -n +2 | while IFS= read -r line; do info "  $line"; done

# ---------------------------------------------------------------------------
# Step 5/9 — Create distribution zip
# ---------------------------------------------------------------------------
step_header "5/9" "Creating distribution zip: $ZIP_FILE"

# Zip from staging parent so the archive contains the DhikrAtWork-v{ver}-macos-arm64/ subfolder
(cd "$STAGING_PARENT" && zip -r --symlinks "$ZIP_FILE" "$(basename "$STAGING_DIR")")
pass "Distribution zip created: $ZIP_FILE"

# ---------------------------------------------------------------------------
# Step 6/9 — Sign with Sparkle sign_update
# ---------------------------------------------------------------------------
step_header "6/9" "Signing zip with Sparkle sign_update"

# sign_update outputs a line like:
#   sparkle:edSignature="BASE64_STRING" length="12345"
SIGN_OUTPUT=$("$SIGN_UPDATE" "$ZIP_PATH" 2>&1) \
  || die "sign_update failed. Output: $SIGN_OUTPUT"

info "sign_update output: $SIGN_OUTPUT"

# Parse edSignature and length (sed -E used instead of grep -oP for macOS BSD compatibility)
ED_SIGNATURE=$(echo "$SIGN_OUTPUT" | sed -nE 's/.*sparkle:edSignature="([^"]+)".*/\1/p')
# Parse length
SPARKLE_LENGTH=$(echo "$SIGN_OUTPUT" | sed -nE 's/.*length="([^"]+)".*/\1/p')

[[ -n "$ED_SIGNATURE" ]] \
  || die "Failed to parse edSignature from sign_update output.
  Expected output like: sparkle:edSignature=\"BASE64\" length=\"12345\"
  Got: $SIGN_OUTPUT"

[[ -n "$SPARKLE_LENGTH" ]] \
  || die "Failed to parse length from sign_update output.
  Expected output like: sparkle:edSignature=\"BASE64\" length=\"12345\"
  Got: $SIGN_OUTPUT"

pass "EdDSA signature captured"
pass "Zip length captured: $SPARKLE_LENGTH bytes"
info "edSignature: ${ED_SIGNATURE:0:32}..."

# ---------------------------------------------------------------------------
# Step 7/9 — SHA256 checksum
# ---------------------------------------------------------------------------
step_header "7/9" "Computing SHA256 checksum"

# shasum -a 256 outputs: "HASH  FILENAME" — strip the path from the filename
MACOS_SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
echo "${MACOS_SHA256}  ${ZIP_FILE}" > "$CHECKSUM_PATH"
pass "Checksum file created: $CHECKSUM_FILE"
info "SHA256: $MACOS_SHA256"

# ---------------------------------------------------------------------------
# Step 8/9a — Download Windows checksum from draft release
# ---------------------------------------------------------------------------
step_header "8/9" "Downloading Windows checksum from draft release"

WIN_CHECKSUM_DOWNLOAD_DIR=$(mktemp -d)
# Clean up on exit
trap 'rm -rf "$WIN_CHECKSUM_DOWNLOAD_DIR"' EXIT

if gh release download "$TAG" \
    --repo "$GITHUB_REPO" \
    --pattern "*.sha256" \
    --dir "$WIN_CHECKSUM_DOWNLOAD_DIR" 2>/dev/null; then

  WIN_CHECKSUM_FILE_PATH="${WIN_CHECKSUM_DOWNLOAD_DIR}/${WIN_CHECKSUM_FILE}"
  if [[ -f "$WIN_CHECKSUM_FILE_PATH" ]]; then
    WIN_SHA256=$(awk '{print $1}' "$WIN_CHECKSUM_FILE_PATH")
    pass "Windows checksum downloaded: $WIN_SHA256"
  else
    # Try to find whatever .sha256 file was downloaded
    FOUND=$(ls "$WIN_CHECKSUM_DOWNLOAD_DIR"/*.sha256 2>/dev/null | head -1 || true)
    if [[ -n "$FOUND" ]]; then
      WIN_SHA256=$(awk '{print $1}' "$FOUND")
      WIN_CHECKSUM_FILE=$(basename "$FOUND")
      WIN_ZIP_NAME="${WIN_CHECKSUM_FILE%.sha256}"
      pass "Windows checksum found: $WIN_SHA256 (from $WIN_CHECKSUM_FILE)"
    else
      info "WARNING: Windows checksum file not found — release notes will show placeholder."
      WIN_SHA256="(not available)"
    fi
  fi
else
  info "WARNING: Could not download Windows checksum — release notes will show placeholder."
  WIN_SHA256="(not available)"
fi

# ---------------------------------------------------------------------------
# Step 8/9b — Generate .appinstaller XML
# ---------------------------------------------------------------------------
step_header "8b/9" "Generating DhikrAtWork.appinstaller"

MSIX_URL="https://github.com/${GITHUB_REPO}/releases/download/${TAG}/DhikrAtWork.msix"

# NOTE: The .appinstaller MainPackage Uri must point to a directly downloadable .msix file.
# release.ps1 must upload a bare DhikrAtWork.msix artifact alongside the distribution zip.
# If this artifact is missing, Windows auto-update will fail silently.

cat > "$APPINSTALLER_PATH" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<AppInstaller
    xmlns="http://schemas.microsoft.com/appx/appinstaller/2021"
    Version="${APPINSTALLER_VERSION}"
    Uri="${APPINSTALLER_URL}">

    <MainPackage
        Name="com.dhikratwork.app"
        Publisher="CN=DhikrAtWork Open Source"
        Version="${APPINSTALLER_VERSION}"
        ProcessorArchitecture="x64"
        Uri="${MSIX_URL}" />

    <UpdateSettings>
        <OnLaunch HoursBetweenUpdateChecks="12" />
        <AutomaticBackgroundTask />
        <ForceUpdateFromAnyVersion>false</ForceUpdateFromAnyVersion>
    </UpdateSettings>

</AppInstaller>
EOF

pass "DhikrAtWork.appinstaller generated"
info "MSIX URI: $MSIX_URL"
info "AppInstaller URI: $APPINSTALLER_URL"

# ---------------------------------------------------------------------------
# Step 8c/9 — Update appcast.xml
# ---------------------------------------------------------------------------
step_header "8c/9" "Updating appcast.xml"

MACOS_ZIP_URL="https://github.com/${GITHUB_REPO}/releases/download/${TAG}/${ZIP_FILE}"
PUB_DATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")

# Build the new <item> block (indented with 4 spaces to match existing appcast.xml style)
NEW_ITEM="    <item>
      <title>Version ${VERSION}</title>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:version>${VERSION}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>12.0</sparkle:minimumSystemVersion>
      <enclosure
        url=\"${MACOS_ZIP_URL}\"
        sparkle:version=\"${VERSION}\"
        sparkle:shortVersionString=\"${VERSION}\"
        type=\"application/octet-stream\"
        sparkle:edSignature=\"${ED_SIGNATURE}\"
        length=\"${SPARKLE_LENGTH}\" />
    </item>"

# Read the current appcast.xml
APPCAST_CONTENT=$(cat "$APPCAST")

# Remove the placeholder item (Version 1.0.0 with YOUR_ED25519_SIGNATURE) if present.
# Match the entire <item>...</item> block containing the placeholder.
if echo "$APPCAST_CONTENT" | grep -q 'YOUR_ED25519_SIGNATURE'; then
  info "Removing placeholder item (Version 1.0.0) from appcast.xml"
  # Use Python for reliable multi-line XML block removal
  APPCAST_CONTENT=$(python3 - "$APPCAST" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the placeholder <item> block (any <item>...</item> containing YOUR_ED25519_SIGNATURE)
content = re.sub(
    r'\n\s*<item>(?:(?!</item>)[\s\S])*?YOUR_ED25519_SIGNATURE[\s\S]*?</item>',
    '',
    content
)

print(content, end='')
PYEOF
)
  pass "Placeholder item removed from appcast.xml"
fi

# Insert new <item> right after <channel> opening tags (before the first existing <item> or </channel>).
# Strategy: insert after the last metadata line in <channel> (before first <item> or </channel>).
APPCAST_CONTENT=$(echo "$APPCAST_CONTENT" | python3 - "$NEW_ITEM" <<'PYEOF'
import sys

new_item = sys.argv[1]
lines = sys.stdin.read()

# Find the position to insert: right before the first <item> or before </channel>
import re
# Insert after <channel> header lines (title, link, description, language) and before first <item>
insert_pattern = re.compile(r'(<channel>(?:(?!<item>).)*?)(<item>|</channel>)', re.DOTALL)
match = insert_pattern.search(lines)
if match:
    insert_pos = match.start(2)
    lines = lines[:insert_pos] + '\n' + new_item + '\n\n' + lines[insert_pos:]
else:
    # Fallback: append before </channel>
    lines = lines.replace('</channel>', '\n' + new_item + '\n\n  </channel>')

print(lines, end='')
PYEOF
)

echo "$APPCAST_CONTENT" > "$APPCAST"
pass "appcast.xml updated with new item for v${VERSION}"
info "Download URL: $MACOS_ZIP_URL"

# ---------------------------------------------------------------------------
# Step 9/9a — Upload macOS artifacts to draft release
# ---------------------------------------------------------------------------
step_header "9/9" "Uploading macOS artifacts to draft release"

gh release upload "$TAG" \
    "$ZIP_PATH" \
    "$CHECKSUM_PATH" \
    "$APPINSTALLER_PATH" \
    --repo "$GITHUB_REPO" \
    --clobber \
  || die "gh release upload failed. Check that the draft release exists and gh is authenticated."

pass "Uploaded: $ZIP_FILE"
pass "Uploaded: $CHECKSUM_FILE"
pass "Uploaded: DhikrAtWork.appinstaller"

# ---------------------------------------------------------------------------
# Step 9/9b — Read changelog from draft release body and generate release notes
# ---------------------------------------------------------------------------
step_header "9b/9" "Generating release notes"

CHANGELOG=$(gh release view "$TAG" \
    --repo "$GITHUB_REPO" \
    --json body \
    --jq '.body' 2>/dev/null || echo "")

if [[ -z "$CHANGELOG" ]]; then
  info "WARNING: Could not read changelog from draft release body. Using placeholder."
  CHANGELOG="(see commits since last release)"
fi

pass "Changelog read from draft release"

# Build full release notes
RELEASE_NOTES=$(cat <<NOTES
## DhikrAtWork ${TAG}

### What's New
${CHANGELOG}

### Downloads
| Platform | File |
|----------|------|
| Windows  | [DhikrAtWork-${TAG}-windows-x64.zip](https://github.com/${GITHUB_REPO}/releases/download/${TAG}/DhikrAtWork-${TAG}-windows-x64.zip) |
| macOS    | [DhikrAtWork-${TAG}-macos-arm64.zip](https://github.com/${GITHUB_REPO}/releases/download/${TAG}/DhikrAtWork-${TAG}-macos-arm64.zip) |

### Verification
| File | SHA256 |
|------|--------|
| Windows zip | \`${WIN_SHA256}\` |
| macOS zip   | \`${MACOS_SHA256}\` |

### Security
This is open-source software distributed without paid code signing.
You can verify safety by:
- Checking the SHA256 checksums above match your download
- Scanning the downloads on [VirusTotal](https://www.virustotal.com)
- Reviewing the source code in this repository
NOTES
)

# Write notes to temp file for safe multi-line passing to gh
NOTES_TMPFILE=$(mktemp)
# Ensure cleanup even if script exits early (appended to existing trap)
trap 'rm -rf "$WIN_CHECKSUM_DOWNLOAD_DIR" "$NOTES_TMPFILE"' EXIT

echo "$RELEASE_NOTES" > "$NOTES_TMPFILE"

gh release edit "$TAG" \
    --repo "$GITHUB_REPO" \
    --notes-file "$NOTES_TMPFILE" \
  || die "Failed to update release notes on GitHub."

pass "Release notes updated on GitHub"

# ---------------------------------------------------------------------------
# Step 9/9c — Publish the release (draft=false)
# ---------------------------------------------------------------------------
step_header "9c/9" "Publishing GitHub Release ${TAG}"

# CRITICAL: Must publish as a FULL release (not pre-release).
# The .appinstaller Uri uses releases/latest/download/ which only resolves to
# non-prerelease releases. Publishing as pre-release silently breaks auto-updates
# for ALL existing Windows users.
gh release edit "$TAG" \
    --repo "$GITHUB_REPO" \
    --draft=false \
  || die "Failed to publish release. Check that the draft release exists and gh is authenticated."

pass "Release ${TAG} published as a full release (not pre-release)"
info "URL: https://github.com/${GITHUB_REPO}/releases/tag/${TAG}"

# ---------------------------------------------------------------------------
# Step 9/9d — Commit appcast.xml to main and push
# ---------------------------------------------------------------------------
step_header "9d/9" "Committing appcast.xml to main"

git -C "$PROJECT_ROOT" add "$APPCAST"
git -C "$PROJECT_ROOT" commit -m "chore: update appcast.xml for ${TAG}" \
  || die "git commit of appcast.xml failed."
git -C "$PROJECT_ROOT" push origin main \
  || die "git push of appcast.xml failed. Resolve and push manually: git push origin main"

pass "appcast.xml committed and pushed to main"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
TIMER_END=$(date +%s)
DURATION=$((TIMER_END - TIMER_START))

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Release pipeline complete!${NC}"
echo -e "${YELLOW}  Duration: ${DURATION}s${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "  ${GREEN}Release ${TAG} is now live.${NC}"
echo ""
echo "  Artifacts published:"
echo -e "    ${DIM}${ZIP_FILE}${NC}"
echo -e "    ${DIM}${CHECKSUM_FILE}${NC}"
echo -e "    ${DIM}DhikrAtWork.appinstaller${NC}"
echo ""
echo "  Post-release (manual steps):"
echo -e "    ${YELLOW}1. Drag the macOS zip to https://www.virustotal.com${NC}"
echo -e "    ${YELLOW}2. Drag the Windows zip to https://www.virustotal.com${NC}"
echo -e "    ${YELLOW}3. Edit the release notes to add the VirusTotal scan links.${NC}"
echo ""
echo "  Release URL:"
echo -e "    ${DIM}https://github.com/${GITHUB_REPO}/releases/tag/${TAG}${NC}"
echo ""
