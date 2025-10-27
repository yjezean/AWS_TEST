class AppUser {
  final String id;
  final String username;
  final String? email;

  const AppUser({
    required this.id,
    required this.username,
    this.email,
  });
}
