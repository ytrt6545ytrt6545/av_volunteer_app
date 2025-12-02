import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String? id; // Can be null when creating a new event locally
  final String title;
  final DateTime date;
  final List<String> roles;

  Event({
    this.id,
    required this.title,
    required this.date,
    required this.roles,
  });

  // Factory constructor to create an Event from a Firestore document
  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return Event(
      id: snapshot.id,
      title: data['title'],
      date: (data['date'] as Timestamp).toDate(),
      roles: List<String>.from(data['roles']),
    );
  }

  // Method to convert an Event instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'roles': roles,
    };
  }
}
