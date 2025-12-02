import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Factory constructor to create a Volunteer from a Firestore document
  factory Volunteer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return Volunteer(
      id: snapshot.id,
      name: data['name'] ?? '匿名使用者',
      email: data['email'] ?? 'no-email@example.com',
      skills: List<String>.from(data['skills'] ?? []),
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  // Method to convert a Volunteer instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'skills': skills,
      'isAdmin': isAdmin,
    };
  }
}
