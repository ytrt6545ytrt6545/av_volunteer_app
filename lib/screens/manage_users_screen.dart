import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/volunteer_model.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  Future<void> _updateUserAdminStatus(String uid, bool isAdmin) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'isAdmin': isAdmin});
  }

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .withConverter(fromFirestore: Volunteer.fromFirestore, toFirestore: (Volunteer v, _) => v.toFirestore())
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理義工'),
      ),
      body: StreamBuilder<QuerySnapshot<Volunteer>>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('讀取使用者資料時發生錯誤'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Switch(
                    value: user.isAdmin,
                    onChanged: (bool newValue) {
                      // We directly call the update function here
                      _updateUserAdminStatus(user.id, newValue);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
