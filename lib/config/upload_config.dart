/// File upload CDN used for avatars and media.
abstract final class UploadConfig {
  static const uploadUrl = 'https://upload.hoclaptrinhiz.com/api/upload';
  static const viewBaseUrl = 'https://upload.hoclaptrinhiz.com/api/view?path=';

  static String avatarViewUrl(String relativePath) {
    return '$viewBaseUrl${Uri.encodeComponent(relativePath)}';
  }
}
