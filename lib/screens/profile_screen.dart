import 'package:flutter/material.dart';
import '../models/volunteer_model.dart';

class ProfileScreen extends StatelessWidget {
  final Volunteer? currentUser;
  final Function(bool) onLogin;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.currentUser,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: currentUser == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => onLogin(false), // Login as volunteer
                  child: const Text('以義工身份登入'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => onLogin(true), // Login as admin
                  child: const Text('以管理員身份登入'),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('姓名: ${currentUser!.name}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Email: ${currentUser!.email}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('角色: ${currentUser!.isAdmin ? '管理員' : '義工'}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onLogout,
                    child: const Text('登出'),
                  ),
                ],
              ),
            ),
    );
  }
}
