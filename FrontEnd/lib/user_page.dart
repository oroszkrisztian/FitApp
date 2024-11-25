import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_app/services/user_update.dart';
import 'package:http/http.dart' as http;



class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = true;

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;
  String _selectedGender = 'Male';
  int? userId;

  late TextEditingController _passwordController;
  bool _showPassword = false;

  bool _isEditingAccount = false;
  bool _isEditingPersonal = false;
  bool _isAccountExpanded = false;
  bool _isPersonalExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  void _initializeControllers() {
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _ageController = TextEditingController();
    _passwordController = TextEditingController();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('user_id');

      if (userId != null) {
        final response = await http.get(
          Uri.parse(
              'https://func-fitapp-backend.azurewebsites.net/users/$userId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print(response.body);

          setState(() {
            _usernameController.text = data['username'] ?? '';
            _emailController.text = data['user']['email'] ??
                ''; // Access email from nested user object
            _heightController.text = (data['height'] ?? '').toString();
            _weightController.text = (data['weight'] ?? '').toString();
            _ageController.text = (data['age'] ?? '').toString();
            _selectedGender = data['gender'] == 'male'
                ? 'Male'
                : data['gender'] == 'female'
                    ? 'Female'
                    : 'Other';
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load user data');
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabled: _isEditing,
    );
  }


  Future<void> _toggleAccountEdit() async {
    if (_isEditingAccount) {
      if (_formKey.currentState!.validate()) {
        try {
          await UserUpdate().updateUser(
            userId: userId!,
            email: _emailController.text,
            password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
          );

          await _loadUserData();
          _passwordController.clear();  // Clear password after successful update
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account information updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    setState(() {
      _isEditingAccount = !_isEditingAccount;
      if (_isEditingAccount) _isEditingPersonal = false;
    });
  }

  Future<void> _togglePersonalEdit() async {
    if (_isEditingPersonal) {
      if (_formKey.currentState!.validate()) {
        try {
          await UserUpdate().updateUser(
            userId: userId!,
            height: double.tryParse(_heightController.text),
            weight: double.tryParse(_weightController.text),
            age: int.tryParse(_ageController.text),
            gender: _selectedGender.toLowerCase(),
          );

          await _loadUserData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Personal information updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    setState(() {
      _isEditingPersonal = !_isEditingPersonal;
      if (_isEditingPersonal) _isEditingAccount = false;  // Close other section
    });
  }


  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACCOUNT INFORMATION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                icon: Icon(_isEditingAccount ? Icons.save : Icons.edit),
                onPressed: _toggleAccountEdit,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: _buildInputDecoration('Username', Icons.person),
            enabled: _isEditingAccount,
            validator: (value) => value?.isEmpty ?? true ? 'Username is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: _buildInputDecoration('Email', Icons.email),
            enabled: _isEditingAccount,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Email is required';
              if (!value!.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          if (_isEditingAccount) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: _buildInputDecoration('New Password', Icons.lock).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
              obscureText: !_showPassword,
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Leave password empty to keep current password',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Modify your build method's personal section:
  Widget _buildPersonalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PERSONAL INFORMATION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 1.2,
              ),
            ),
            IconButton(
              icon: Icon(_isEditingPersonal ? Icons.save : Icons.edit),
              onPressed: _togglePersonalEdit,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _heightController,
                decoration: _buildInputDecoration('Height (cm)', Icons.height),
                keyboardType: TextInputType.number,
                enabled: _isEditingPersonal,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                decoration: _buildInputDecoration('Weight (kg)', Icons.monitor_weight),
                keyboardType: TextInputType.number,
                enabled: _isEditingPersonal,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
                decoration: _buildInputDecoration('Age', Icons.calendar_today),
                keyboardType: TextInputType.number,
                enabled: _isEditingPersonal,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender.toLowerCase() == 'male' ? 'Male' :
                _selectedGender.toLowerCase() == 'female' ? 'Female' : 'Other',
                decoration: _buildInputDecoration('Gender', Icons.person_outline),
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                ))
                    .toList(),
                onChanged: _isEditingPersonal
                    ? (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                }
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required bool isExpanded,
    required Function() onToggle,
    required bool isEditing,
    required Function() onEdit,
    required Function() onCancel,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (isExpanded)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: onEdit,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Column(
                children: [
                  ...children,
                  if (isEditing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: onCancel,
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: Icon(
                            Icons.save,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            'Save',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  void _cancelAccountEdit() {
    _loadUserData(); // Reload original data
    setState(() {
      _isEditingAccount = false;
      _passwordController.clear(); // Clear any entered password
    });
  }

  void _cancelPersonalEdit() {
    _loadUserData(); // Reload original data
    setState(() {
      _isEditingPersonal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.inversePrimary.withOpacity(0.2),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _usernameController.text,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _emailController.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'Account Information',
                    isExpanded: _isAccountExpanded,
                    onToggle: () => setState(() {
                      _isAccountExpanded = !_isAccountExpanded;
                      if (_isAccountExpanded) _isPersonalExpanded = false;
                    }),
                    isEditing: _isEditingAccount,
                    onEdit: _toggleAccountEdit,
                    onCancel: _cancelAccountEdit,
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: _buildInputDecoration('Username', Icons.person),
                        enabled: _isEditingAccount,
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Username is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: _buildInputDecoration('Email', Icons.email),
                        enabled: _isEditingAccount,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Email is required';
                          if (!value!.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      if (_isEditingAccount) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: _buildInputDecoration('New Password', Icons.lock)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: !_showPassword,
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Leave password empty to keep current password',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Personal Information',
                    isExpanded: _isPersonalExpanded,
                    onToggle: () => setState(() {
                      _isPersonalExpanded = !_isPersonalExpanded;
                      if (_isPersonalExpanded) _isAccountExpanded = false;
                    }),
                    isEditing: _isEditingPersonal,
                    onEdit: _togglePersonalEdit,
                    onCancel: _cancelPersonalEdit,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              decoration: _buildInputDecoration(
                                  'Height (cm)', Icons.height),
                              keyboardType: TextInputType.number,
                              enabled: _isEditingPersonal,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (double.tryParse(value!) == null)
                                  return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              decoration: _buildInputDecoration(
                                  'Weight (kg)', Icons.monitor_weight),
                              keyboardType: TextInputType.number,
                              enabled: _isEditingPersonal,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (double.tryParse(value!) == null)
                                  return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              decoration: _buildInputDecoration(
                                  'Age', Icons.calendar_today),
                              keyboardType: TextInputType.number,
                              enabled: _isEditingPersonal,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (int.tryParse(value!) == null)
                                  return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender.toLowerCase() == 'male'
                                  ? 'Male'
                                  : _selectedGender.toLowerCase() == 'female'
                                  ? 'Female'
                                  : 'Other',
                              decoration: _buildInputDecoration(
                                  'Gender', Icons.person_outline),
                              items: ['Male', 'Female', 'Other']
                                  .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                                  .toList(),
                              onChanged: _isEditingPersonal
                                  ? (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
