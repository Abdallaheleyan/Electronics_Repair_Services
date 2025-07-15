import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _birthDateController = TextEditingController();

  String _email = '';
  String _role = '';
  String? _profileImageUrl;
  File? _selectedImage;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _fullNameController.text = data['fullName'] ?? '';
        _phoneNumberController.text = data['phoneNumber'] ?? '';
        _birthDateController.text = data['birthDate'] ?? '';
        _email = data['email'] ?? '';
        _role = data['role'] ?? '';
        _profileImageUrl = data['profileImage'] ?? null;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _updateProfile() async {
    String? imageUrl = _profileImageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadProfileImage(_selectedImage!);
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fullName': _fullNameController.text.trim(),
      'phoneNumber': _phoneNumberController.text.trim(),
      'birthDate': _birthDateController.text.trim(),
      'profileImage': imageUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF39ef64),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'Profile',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null) as ImageProvider?,
                    ),
                    if (_selectedImage == null && _profileImageUrl == null)
                      const Icon(Icons.camera_alt, size: 28, color: Colors.grey),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInputField(label: 'Full Name', controller: _fullNameController),
            const SizedBox(height: 14),
            _buildInputField(label: 'Email', value: _email, readOnly: true),
            const SizedBox(height: 14),
            _buildInputField(label: 'Phone Number', controller: _phoneNumberController),
            const SizedBox(height: 14),
            _buildInputField(
              label: 'Birthdate',
              controller: _birthDateController,
              readOnly: true,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  _birthDateController.text = picked.toIso8601String().split('T').first;
                }
              },
            ),
            const SizedBox(height: 14),
            _buildInputField(label: 'Role', value: _role, readOnly: true),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39ef64),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    TextEditingController? controller,
    String? value,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller ?? TextEditingController(text: value),
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: readOnly ? TextInputType.none : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
