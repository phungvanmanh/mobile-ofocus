#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"
flutter pub get

# Remove stale CocoaPods artifacts if a Podfile existed previously.
if [[ -d "${ROOT_DIR}/ios/Pods" || -f "${ROOT_DIR}/ios/Podfile.lock" ]]; then
  rm -rf "${ROOT_DIR}/ios/Pods" "${ROOT_DIR}/ios/Podfile.lock" "${ROOT_DIR}/ios/.symlinks"
fi

echo "iOS build prepare complete."
