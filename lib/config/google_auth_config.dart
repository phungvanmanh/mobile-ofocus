/// Google OAuth Web client ID (client_type: 3).
///
/// Required on Android/iOS to receive an ID token for backend verification.
/// Pass at build time:
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com`
///
/// Alternatively, add `google-services.json` with a web OAuth client entry.
class GoogleAuthConfig {
  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '651542608792-8gsabseh3l3p6n7jakk76vnuorfl01lt.apps.googleusercontent.com',
  );
}
