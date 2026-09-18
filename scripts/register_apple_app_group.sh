#!/usr/bin/env bash
# Dang ky App Group tren Apple Developer Portal (chay tren Mac/Codemagic).
# Can mot trong:
#   - APP_STORE_CONNECT_KEY_IDENTIFIER + APP_STORE_CONNECT_ISSUER_ID + APP_STORE_CONNECT_PRIVATE_KEY
#   - FASTLANE_USER + FASTLANE_PASSWORD (hoac FASTLANE_SESSION)

set -euo pipefail

APP_GROUP_ID="${APP_GROUP_ID:-group.com.example.ofocus}"
APP_GROUP_NAME="${APP_GROUP_NAME:-Ofocus Shared}"
MAIN_BUNDLE_ID="${MAIN_BUNDLE_ID:-com.example.ofocus}"
EXTENSION_BUNDLE_ID="${EXTENSION_BUNDLE_ID:-com.example.ofocus.LiveKit-Broadcast-Extension}"

echo "Registering App Group: ${APP_GROUP_ID}"

if ! command -v fastlane >/dev/null 2>&1; then
  echo "Installing fastlane..."
  gem install fastlane --no-document
fi

export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_DISABLE_COLORS=1

ruby <<RUBY
require 'spaceship'

def login
  if ENV['APP_STORE_CONNECT_KEY_IDENTIFIER'] && ENV['APP_STORE_CONNECT_ISSUER_ID'] && ENV['APP_STORE_CONNECT_PRIVATE_KEY']
    key = ENV['APP_STORE_CONNECT_PRIVATE_KEY'].gsub('\\n', "\n")
    api_key = Spaceship::ConnectAPI::Token.create(
      key_id: ENV['APP_STORE_CONNECT_KEY_IDENTIFIER'],
      issuer_id: ENV['APP_STORE_CONNECT_ISSUER_ID'],
      key: key
    )
    Spaceship::Portal.login(api_key: api_key)
  elsif ENV['FASTLANE_USER']
    Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  else
    abort <<~MSG
      Thieu thong tin dang nhap Apple Developer.
      Dat bien moi truong tren Codemagic (group apple_credentials):
        APP_STORE_CONNECT_KEY_IDENTIFIER
        APP_STORE_CONNECT_ISSUER_ID
        APP_STORE_CONNECT_PRIVATE_KEY
      hoac FASTLANE_USER + FASTLANE_PASSWORD
    MSG
  end
end

login

group = Spaceship.app_group.find('${APP_GROUP_ID}')
unless group
  puts "Creating App Group ${APP_GROUP_ID}..."
  group = Spaceship.app_group.create!(
    group_id: '${APP_GROUP_ID}',
    name: '${APP_GROUP_NAME}'
  )
else
  puts "App Group ${APP_GROUP_ID} already exists."
end

['${MAIN_BUNDLE_ID}', '${EXTENSION_BUNDLE_ID}'].each do |bundle_id|
  app = Spaceship.app.find(bundle_id)
  unless app
    warn "WARNING: App ID #{bundle_id} chua ton tai. Tao thu cong tren developer.apple.com truoc."
    next
  end

  puts "Enabling App Groups for #{bundle_id}..."
  app.update_service(Spaceship::Portal.app_service.app_group.on)
  app.associate_groups([group])
  puts "OK: #{bundle_id} -> ${APP_GROUP_ID}"
end

puts "App Group registration complete."
RUBY
