/// Shared helpers for oFocus backend API requests.
abstract final class ApiClient {
  static Map<String, String> authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
}
