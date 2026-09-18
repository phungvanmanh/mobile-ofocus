#!/usr/bin/env bash
set -euo pipefail

# Fix CI images that install "android-37.0" but Gradle expects "android-37".
SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-${ANDROID_HOME:-/usr/local/share/android-sdk}}}"
PLATFORMS_DIR="$SDK_ROOT/platforms"

echo "Using Android SDK: $SDK_ROOT"

if [ ! -d "$SDK_ROOT" ]; then
  echo "Android SDK not found."
  exit 1
fi

if [ -d "$PLATFORMS_DIR/android-37" ]; then
  echo "Platform android-37 is ready."
  exit 0
fi

if [ -d "$PLATFORMS_DIR/android-37.0" ]; then
  echo "Linking android-37 -> android-37.0"
  ln -sfn android-37.0 "$PLATFORMS_DIR/android-37"
  exit 0
fi

SDKMANAGER=""
for candidate in \
  "$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" \
  "$SDK_ROOT/cmdline-tools/bin/sdkmanager" \
  "$(command -v sdkmanager || true)"
do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then
    SDKMANAGER="$candidate"
    break
  fi
done

if [ -n "$SDKMANAGER" ]; then
  echo "Installing Android platform 37..."
  yes | "$SDKMANAGER" "platforms;android-37" >/dev/null
  exit 0
fi

echo "Could not provision android-37 in $PLATFORMS_DIR"
ls -la "$PLATFORMS_DIR" || true
exit 1
