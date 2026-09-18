#!/usr/bin/env bash
# Cai certificate + provisioning profiles cho GitHub Actions (macOS runner).
# Can secrets:
#   IOS_P12_BASE64, IOS_P12_PASSWORD
#   IOS_PROVISION_PROFILE_MAIN_BASE64      (com.example.ofocus)
#   IOS_PROVISION_PROFILE_EXTENSION_BASE64 (com.example.ofocus.LiveKit-Broadcast-Extension)
#   IOS_KEYCHAIN_PASSWORD (optional, mac dinh: github-actions)

set -euo pipefail

require_var() {
  if [[ -z "${!1:-}" ]]; then
    echo "Missing secret/env: $1" >&2
    exit 1
  fi
}

require_var IOS_P12_BASE64
require_var IOS_P12_PASSWORD
require_var IOS_PROVISION_PROFILE_MAIN_BASE64
require_var IOS_PROVISION_PROFILE_EXTENSION_BASE64

KEYCHAIN_PASSWORD="${IOS_KEYCHAIN_PASSWORD:-github-actions}"
CERTIFICATE_PATH="${RUNNER_TEMP}/ios_build.p12"
KEYCHAIN_PATH="${RUNNER_TEMP}/ios-signing.keychain-db"
MAIN_PROFILE_PATH="${RUNNER_TEMP}/main.mobileprovision"
EXT_PROFILE_PATH="${RUNNER_TEMP}/extension.mobileprovision"

install_profile() {
  local profile_path="$1"
  local uuid
  uuid="$(/usr/libexec/PlistBuddy -c 'Print UUID' /dev/stdin <<< "$(security cms -D -i "${profile_path}")")"
  mkdir -p "${HOME}/Library/MobileDevice/Provisioning Profiles"
  cp "${profile_path}" "${HOME}/Library/MobileDevice/Provisioning Profiles/${uuid}.mobileprovision"
  echo "Installed provisioning profile ${uuid}"
}

echo -n "${IOS_P12_BASE64}" | base64 --decode -o "${CERTIFICATE_PATH}"
echo -n "${IOS_PROVISION_PROFILE_MAIN_BASE64}" | base64 --decode -o "${MAIN_PROFILE_PATH}"
echo -n "${IOS_PROVISION_PROFILE_EXTENSION_BASE64}" | base64 --decode -o "${EXT_PROFILE_PATH}"

security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security set-keychain-settings -lut 21600 "${KEYCHAIN_PATH}"
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security import "${CERTIFICATE_PATH}" \
  -P "${IOS_P12_PASSWORD}" \
  -A \
  -t cert \
  -f pkcs12 \
  -k "${KEYCHAIN_PATH}"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security list-keychain -d user -s "${KEYCHAIN_PATH}"

install_profile "${MAIN_PROFILE_PATH}"
install_profile "${EXT_PROFILE_PATH}"

if [[ -n "${IOS_TEAM_ID:-}" ]]; then
  python3 <<PY
import re
from pathlib import Path

team_id = "${IOS_TEAM_ID}"
path = Path("ios/Runner.xcodeproj/project.pbxproj")
text = path.read_text()
if "DEVELOPMENT_TEAM" in text:
    text = re.sub(r"DEVELOPMENT_TEAM = [^;]+;", f"DEVELOPMENT_TEAM = {team_id};", text)
else:
    text = text.replace(
        "CODE_SIGN_STYLE = Automatic;",
        f"DEVELOPMENT_TEAM = {team_id};\\n\\t\\t\\t\\tCODE_SIGN_STYLE = Automatic;",
    )
path.write_text(text)
print(f"Set DEVELOPMENT_TEAM={team_id}")
PY
fi

echo "iOS code signing ready."
