import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/volunteer_model.dart';

class ProfileScreen extends StatefulWidget {
  final Volunteer? currentUser;
  final List<String> allRoles;
  final Function(String) onAddRole;
  final Function(String) onDeleteRole;

  const ProfileScreen({
    super.key,
    required this.currentUser,
    required this.allRoles,
    required this.onAddRole,
    required this.onDeleteRole,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;

  void _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      // No need to handle navigation, authStateChanges listener in HomeScreen will do it.
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '認證失敗')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('發生未知錯誤')),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showManageRolesDialog(BuildContext context) {
    final roleController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('管理職位'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: roleController,
                    decoration: const InputDecoration(hintText: '輸入新職位名稱'),
                    onSubmitted: (value) {
                      widget.onAddRole(value);
                      Navigator.of(context).pop();
                      _showManageRolesDialog(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.allRoles.length,
                      itemBuilder: (context, index) {
                        final role = widget.allRoles[index];
                        return ListTile(
                          title: Text(role),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              widget.onDeleteRole(role);
                              Navigator.of(context).pop();
                              _showManageRolesDialog(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  child: const Text('完成'), onPressed: () => Navigator.of(context).pop()),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return _buildAuthForm();
    } else {
      return _buildUserProfile();
    }
  }

  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('歡迎, ${widget.currentUser!.name}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Email: ${widget.currentUser!.email}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('角色: ${widget.currentUser!.isAdmin ? '管理員' : '義工'}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          if (widget.currentUser!.isAdmin)
            ElevatedButton.icon(
              icon: const Icon(Icons.work_history),
              onPressed: () => _showManageRolesDialog(context),
              label: const Text('管理職位'),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            child: const Text('登出'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value?.isEmpty ?? true) || !value!.contains('@') ? '請輸入有效的 Email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '密碼'),
                obscureText: true,
                validator: (value) => (value?.isEmpty ?? true) || value!.length < 6 ? '密碼長度不能少於 6 位' : null,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(_isLoginMode ? '登入' : '註冊'),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginMode = !_isLoginMode;
                  });
                },
                child: Text(_isLoginMode ? '還沒有帳號嗎？點此註冊' : '已經有帳號了？點此登入'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
