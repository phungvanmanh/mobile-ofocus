#!/usr/bin/env bash
# Cai certificate + provisioning profiles cho GitHub Actions (macOS runner).

set -euo pipefail

log() { echo "[ios-signing] $*"; }
fail() { echo "[ios-signing] ERROR: $*" >&2; exit 1; }

require_var() {
  local name="$1"
  local value="${!name:-}"
  if [[ -z "${value// /}" ]]; then
    fail "Thieu GitHub Secret: ${name}. Vao repo Settings -> Secrets and variables -> Actions."
  fi
}

decode_base64_secret() {
  local name="$1"
  local out_path="$2"
  local raw="${!name}"
  # Loai bo xuong dong / khoang trang (thuong gap khi copy base64 tu Windows)
  local cleaned
  cleaned="$(printf '%s' "${raw}" | tr -d '[:space:]')"
  if [[ -z "${cleaned}" ]]; then
    fail "${name} rong sau khi trim."
  fi
  if ! printf '%s' "${cleaned}" | base64 --decode > "${out_path}" 2>/dev/null; then
    fail "${name} khong decode duoc base64. Tao lai base64 tu file goc (xem huong dan duoi)."
  fi
  if [[ ! -s "${out_path}" ]]; then
    fail "${name} decode ra file rong."
  fi
  log "Decoded ${name} -> ${out_path} ($(wc -c < "${out_path}") bytes)"
}

profile_summary() {
  local profile_path="$1"
  local label="$2"
  local plist_xml
  if ! plist_xml="$(security cms -D -i "${profile_path}" 2>/dev/null)"; then
    fail "${label}: khong doc duoc provisioning profile (file hu hoac base64 sai)."
  fi
  local name uuid app_id
  name="$(/usr/libexec/PlistBuddy -c 'Print Name' /dev/stdin <<< "${plist_xml}")"
  uuid="$(/usr/libexec/PlistBuddy -c 'Print UUID' /dev/stdin <<< "${plist_xml}")"
  app_id="$(/usr/libexec/PlistBuddy -c 'Print Entitlements:application-identifier' /dev/stdin <<< "${plist_xml}")"
  log "${label}: Name=${name}"
  log "${label}: UUID=${uuid}"
  log "${label}: AppID=${app_id}"
  if ! /usr/libexec/PlistBuddy -c 'Print Entitlements:com.apple.security.application-groups' /dev/stdin <<< "${plist_xml}" >/dev/null 2>&1; then
    log "WARNING ${label}: profile KHONG co App Groups — screen share se loi tren iPhone."
  else
    log "${label}: App Groups OK"
  fi
  printf '%s' "${uuid}"
}

install_profile() {
  local profile_path="$1"
  local label="$2"
  local uuid
  uuid="$(profile_summary "${profile_path}" "${label}")"
  mkdir -p "${HOME}/Library/MobileDevice/Provisioning Profiles"
  cp "${profile_path}" "${HOME}/Library/MobileDevice/Provisioning Profiles/${uuid}.mobileprovision"
  log "Installed ${label} profile"
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

decode_base64_secret IOS_P12_BASE64 "${CERTIFICATE_PATH}"
decode_base64_secret IOS_PROVISION_PROFILE_MAIN_BASE64 "${MAIN_PROFILE_PATH}"
decode_base64_secret IOS_PROVISION_PROFILE_EXTENSION_BASE64 "${EXT_PROFILE_PATH}"

# Kiem tra nhanh dinh dang p12
if ! openssl pkcs12 -in "${CERTIFICATE_PATH}" -noout -passin "pass:${IOS_P12_PASSWORD}" 2>/dev/null; then
  fail "IOS_P12_PASSWORD sai hoac file IOS_P12_BASE64 khong phai .p12 hop le."
fi

security delete-keychain "${KEYCHAIN_PATH}" >/dev/null 2>&1 || true
security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security set-keychain-settings -lut 21600 "${KEYCHAIN_PATH}"
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"

if ! security import "${CERTIFICATE_PATH}" \
  -P "${IOS_P12_PASSWORD}" \
  -A \
  -T /usr/bin/codesign \
  -T /usr/bin/security \
  -t cert \
  -f pkcs12 \
  -k "${KEYCHAIN_PATH}"; then
  fail "Khong import duoc certificate vao keychain."
fi

security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}" || true
security list-keychain -d user -s "${KEYCHAIN_PATH}" login.keychain-db

install_profile "${MAIN_PROFILE_PATH}" "MAIN"
install_profile "${EXT_PROFILE_PATH}" "EXTENSION"

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
print(f"[ios-signing] Set DEVELOPMENT_TEAM={team_id}")
PY
else
  log "WARNING: chua dat IOS_TEAM_ID — co the build signed that bai."
fi

log "iOS code signing ready."
