import 'package:google_sign_in/google_sign_in.dart';
import 'package:ofocus/config/google_auth_config.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    final serverClientId = GoogleAuthConfig.serverClientId;
    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _initialized = true;
  }

  Future<void> signOut() async {
    try {
      await ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  Future<GoogleSignInResult> signIn() async {
    await ensureInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final credential = account.authentication.idToken;

      if (credential == null || credential.isEmpty) {
        return GoogleSignInResult.failure(
          'Không lấy được token từ Google. Kiểm tra cấu hình OAuth (serverClientId).',
        );
      }

      return GoogleSignInResult.success(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleSignInResult.cancelled();
      }

      return GoogleSignInResult.failure(
        e.description ?? 'Đăng nhập Google thất bại',
      );
    } catch (_) {
      return GoogleSignInResult.failure(
        'Không thể đăng nhập bằng Google. Vui lòng thử lại.',
      );
    }
  }
}

class GoogleSignInResult {
  const GoogleSignInResult._({
    required this.isSuccess,
    this.isCancelled = false,
    this.credential,
    this.errorMessage,
  });

  factory GoogleSignInResult.success(String credential) {
    return GoogleSignInResult._(
      isSuccess: true,
      credential: credential,
    );
  }

  factory GoogleSignInResult.cancelled() {
    return const GoogleSignInResult._(
      isSuccess: false,
      isCancelled: true,
    );
  }

  factory GoogleSignInResult.failure(String message) {
    return GoogleSignInResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  final bool isSuccess;
  final bool isCancelled;
  final String? credential;
  final String? errorMessage;
}
