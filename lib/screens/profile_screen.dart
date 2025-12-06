import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/volunteer_model.dart';
import 'manage_users_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Volunteer? currentUser;
  final List<String> allRoles;
  final Function(String) onAddRole;
  final Function(String) onDeleteRole;
  final Function(String, String, List<String>) onUpdateProfile;

  const ProfileScreen({
    super.key,
    required this.currentUser,
    required this.allRoles,
    required this.onAddRole,
    required this.onDeleteRole,
    required this.onUpdateProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;

  void _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'isAdmin': _emailController.text.trim().contains('admin'),
          'skills': [],
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? '認證失敗')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('發生未知錯誤')));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showPasswordResetDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      useSafeArea: false, // Prevent keyboard from resizing the dialog
      builder: (context) {
        return AlertDialog(
          title: const Text('重設密碼'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: '請輸入您的 Email'),
          ),
          actions: [
            TextButton(child: const Text('取消'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('發送'),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密碼重設信件已寄出，請檢查您的信箱。')));
                  }
                } on FirebaseAuthException catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? '發送失敗')));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showManageRolesDialog(BuildContext context) {
    final roleController = TextEditingController();
    showDialog(
      context: context,
      useSafeArea: false, // Prevent keyboard from resizing the dialog
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) { 
            return AlertDialog(
              title: const Text('管理職位'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: roleController,
                        decoration: const InputDecoration(hintText: '輸入新職位名稱'),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            widget.onAddRole(value);
                            roleController.clear();
                            setDialogState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: widget.allRoles.map((role) {
                          return ListTile(
                            title: Text(role),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                widget.onDeleteRole(role);
                                setDialogState(() {});
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(child: const Text('完成'), onPressed: () => Navigator.of(context).pop()),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.currentUser?.name ?? '');
    final Set<String> selectedSkills = widget.currentUser?.skills.toSet() ?? {};

    showDialog(
      context: context,
      useSafeArea: false, // Prevent keyboard from resizing the dialog
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('編輯個人資料'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '姓名'),
                    ),
                    const SizedBox(height: 16),
                    const Text('我的技能:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...widget.allRoles.map((role) {
                      return CheckboxListTile(
                        title: Text(role),
                        value: selectedSkills.contains(role),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) { selectedSkills.add(role); } 
                            else { selectedSkills.remove(role); }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(child: const Text('取消'), onPressed: () => Navigator.of(context).pop()),
                TextButton(
                  child: const Text('儲存'),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      await widget.onUpdateProfile(widget.currentUser!.id, nameController.text, selectedSkills.toList());
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('個人資料已更新！')));
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.currentUser == null ? _buildAuthForm() : _buildUserProfile();
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
          if (widget.currentUser!.skills.isNotEmpty)
            Text('我的技能: ${widget.currentUser!.skills.join(', ')}'),
          const SizedBox(height: 8),
          Text('角色: ${widget.currentUser!.isAdmin ? '管理員' : '義工'}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
           Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                if (widget.currentUser!.isAdmin)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.work_history),
                    onPressed: () => _showManageRolesDialog(context),
                    label: const Text('管理職位'),
                  ),
                if (widget.currentUser!.isAdmin)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.manage_accounts),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageUsersScreen()));
                    },
                    label: const Text('管理義工'),
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditProfileDialog(context),
                  label: const Text('編輯個人資料'),
                ),
              ],
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
              if (!_isLoginMode)
                TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '姓名'),
                    validator: (value) => (value?.isEmpty ?? true) ? '請輸入您的姓名' : null),
              if (!_isLoginMode) const SizedBox(height: 12),
              TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value?.isEmpty ?? true) || !value!.contains('@') ? '請輸入有效的 Email' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: '密碼'),
                  obscureText: true,
                  validator: (value) => (value?.isEmpty ?? true) || value!.length < 6 ? '密碼長度不能少於 6 位' : null),
              if (_isLoginMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showPasswordResetDialog,
                    child: const Text('忘記密碼？'),
                  ),
                ),
              const SizedBox(height: 8),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(_isLoginMode ? '登入' : '註冊'),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(_isLoginMode ? '還沒有帳號嗎？點此註冊' : '已經有帳號了？點此登入'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
