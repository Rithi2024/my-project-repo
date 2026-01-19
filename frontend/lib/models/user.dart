class User {
  User({required this.id, required this.email, this.username});

  final int id;
  final String email;
  final String? username;

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: (j['id'] ?? 0) as int,
    email: (j['email'] ?? '') as String,
    username: j['username'] as String?,
  );
}
