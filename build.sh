#!/usr/bin/env bash
#
# build.sh — Build, test, and validate the DhikrAtWork Flutter macOS app.
#
# Automates the full build pipeline: clean, pub get, analyze, test, build.
# Each step's errors are captured and displayed in a copy-friendly block.
#
# Usage:
#   ./build.sh                     # full clean build with all checks
#   ./build.sh --skip-clean        # keep cached build artifacts
#   ./build.sh --skip-tests        # skip the test suite for faster iteration
#   ./build.sh --skip-clean --skip-tests  # quick rebuild

set -euo pipefail

# --- Configuration ---
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_MODE="release"
APP_BUNDLE="$PROJECT_ROOT/build/macos/Build/Products/Release/dhikratwork.app"

SKIP_CLEAN=false
SKIP_TESTS=false

for arg in "$@"; do
  case "$arg" in
    --skip-clean) SKIP_CLEAN=true ;;
    --skip-tests) SKIP_TESTS=true ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

# --- Helpers ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
NC='\033[0m'

FAILED_STEPS=()
TIMER_START=$(date +%s)

step_header() {
  echo ""
  echo -e "${CYAN}[$1] $2${NC}"
  printf '%0.s-' {1..60}; echo ""
}

pass() {
  echo -e "  ${GREEN}PASS${NC}  $1"
}

fail() {
  echo -e "  ${RED}FAIL${NC}  $1"
}

run_step() {
  local step_name="$1"
  local description="$2"
  shift 2
  local timeout="${TIMEOUT:-600}"

  step_header "$step_name" "$description"

  local output
  if output=$(timeout "${timeout}" "$@" 2>&1); then
    pass "$description"
    return 0
  else
    local exit_code=$?
    fail "$description (exit code $exit_code)"
    FAILED_STEPS+=("$description|$output")
    return 1
  fi
}

# --- Main Pipeline ---
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  DhikrAtWork macOS Build Pipeline${NC}"
echo -e "${YELLOW}  Mode: $BUILD_MODE${NC}"
echo -e "${YELLOW}========================================${NC}"

# Step 1: Clean
if [ "$SKIP_CLEAN" = false ]; then
  run_step "1/5" "flutter clean" flutter clean || true
else
  step_header "1/5" "flutter clean (SKIPPED)"
fi

# Step 2: Pub Get
if ! run_step "2/5" "flutter pub get" flutter pub get; then
  fail "pub get failed — skipping remaining steps."
else
  # Step 3: Analyze
  run_step "3/5" "flutter analyze" flutter analyze || true

  # Step 4: Test
  if [ "$SKIP_TESTS" = false ]; then
    TIMEOUT=300 run_step "4/5" "flutter test" flutter test || true
  else
    step_header "4/5" "flutter test (SKIPPED)"
  fi

  # Step 5: Build
  run_step "5/5" "flutter build macos --$BUILD_MODE" flutter build macos "--$BUILD_MODE" || true
fi

# --- Validate Output ---
TIMER_END=$(date +%s)
DURATION=$((TIMER_END - TIMER_START))

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Validation${NC}"
echo -e "${YELLOW}========================================${NC}"

if [ -d "$APP_BUNDLE" ]; then
  SIZE=$(du -sh "$APP_BUNDLE" | cut -f1)
  pass "dhikratwork.app exists ($SIZE)"
  echo -e "  ${DIM}Path: $APP_BUNDLE${NC}"

  # Check for expected frameworks
  FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
  for fw in FlutterMacOS.framework App.framework; do
    if [ -d "$FRAMEWORKS_DIR/$fw" ]; then
      pass "$fw present"
    else
      fail "$fw MISSING from build output"
    fi
  done
else
  fail "dhikratwork.app NOT FOUND at expected path"
  echo -e "  ${DIM}Expected: $APP_BUNDLE${NC}"
fi

# --- Summary ---
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Summary${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "  ${DIM}Duration: ${DURATION}s${NC}"

if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
  echo ""
  echo -e "  ${GREEN}ALL STEPS PASSED${NC}"
  echo ""
  exit 0
fi

# --- Error Report (copy-friendly) ---
echo ""
echo -e "  ${RED}${#FAILED_STEPS[@]} STEP(S) FAILED${NC}"
echo ""
echo -e "${YELLOW}Copy everything between the markers and send to Claude:${NC}"
echo ""
echo -e "${MAGENTA}===== BUILD ERRORS START =====${NC}"

for entry in "${FAILED_STEPS[@]}"; do
  IFS='|' read -r step_desc step_output <<< "$entry"
  echo ""
  echo "--- [$step_desc] ---"
  echo "$step_output"
done

echo ""
echo -e "${MAGENTA}===== BUILD ERRORS END =====${NC}"
echo ""

exit 1
