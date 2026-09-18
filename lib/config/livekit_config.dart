/// LiveKit server URL (WebSocket).
///
/// Cấu hình qua `--dart-define=LIVEKIT_URL=wss://...` hoặc sửa [defaultUrl].
abstract final class LiveKitConfig {
  static const _url = String.fromEnvironment('LIVEKIT_URL');

  /// Ví dụ: `wss://myproject.livekit.cloud`
  static const defaultUrl = 'wss://api.ofocus.vn/livekit';

  static String get url => _url.isNotEmpty ? _url : defaultUrl;

  static bool get isConfigured => url.isNotEmpty;
}
