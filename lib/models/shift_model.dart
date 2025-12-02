import 'package:cloud_firestore/cloud_firestore.dart';

class Shift {
  final String? id;
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String role;
  final String volunteerId;
  final String volunteerName;
  final String? status; // New field for completion status
  final String? notes;  // New field for notes

  Shift({
    this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.role,
    required this.volunteerId,
    required this.volunteerName,
    this.status,
    this.notes,
  });

  factory Shift.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return Shift(
      id: snapshot.id,
      eventId: data['eventId'],
      eventTitle: data['eventTitle'],
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      role: data['role'],
      volunteerId: data['volunteerId'],
      volunteerName: data['volunteerName'],
      status: data['status'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDate': Timestamp.fromDate(eventDate),
      'role': role,
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'status': status,
      'notes': notes,
    };
  }
}
