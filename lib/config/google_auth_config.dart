/// Google OAuth client IDs.
///
/// **Web (server):** client_type 3 — gửi id token lên BE (`auth/google-login`).
/// **iOS:** client_type iOS — bắt buộc cho Google Sign-In native trên iPhone.
///
/// Build:
/// ```bash
/// flutter run \
///   --dart-define=GOOGLE_SERVER_CLIENT_ID=....apps.googleusercontent.com \
///   --dart-define=GOOGLE_IOS_CLIENT_ID=....apps.googleusercontent.com
/// ```
///
/// iOS cũng cần `GIDClientID` + URL scheme trong `ios/Runner/Info.plist`
/// (chạy `scripts/configure_google_signin_ios.ps1` sau khi tạo OAuth client iOS).
class GoogleAuthConfig {
  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '651542608792-8gsabseh3l3p6n7jakk76vnuorfl01lt.apps.googleusercontent.com',
  );

  /// OAuth client ID loại **iOS** (Bundle ID: `com.example.ofocus`).
  static const iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '651542608792-v2dv7k8n0dk99oehf44krpir8tbkjbgm.apps.googleusercontent.com',
  );

  static String reversedClientId(String clientId) {
    const suffix = '.apps.googleusercontent.com';
    if (!clientId.endsWith(suffix)) return '';
    final core = clientId.substring(0, clientId.length - suffix.length);
    return 'com.googleusercontent.apps.$core';
  }
}
