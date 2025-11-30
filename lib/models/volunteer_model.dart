class Volunteer {
  final String id;
  final String name;
  final String email;
  final List<String> skills;
  final bool isAdmin;

  Volunteer({
    required this.id,
    required this.name,
    required this.email,
    this.skills = const [],
    this.isAdmin = false,
  });
}
