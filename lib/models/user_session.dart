class UserSession {
  const UserSession({
    required this.token,
    required this.expiresAt,
    this.userData,
  });

  final String token;
  final DateTime expiresAt;
  final Map<String, dynamic>? userData;

  bool get isValid => DateTime.now().isBefore(expiresAt);

  Duration get remaining => expiresAt.difference(DateTime.now());
}
