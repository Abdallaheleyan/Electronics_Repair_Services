import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class SubmitRequestScreen extends StatefulWidget {
  const SubmitRequestScreen({Key? key}) : super(key: key);

  @override
  State<SubmitRequestScreen> createState() => _SubmitRequestScreenState();
}

class _SubmitRequestScreenState extends State<SubmitRequestScreen> {
  List<Map<String, dynamic>> _shops = [];
  String? _selectedShopId;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  XFile? _selectedVideo;

  final _deviceNameController = TextEditingController();
  final _issueController = TextEditingController();
  String _selectedDeviceType = 'Phone';

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'shop')
        .get();

    setState(() {
      _shops = querySnapshot.docs.map((doc) {
        return {'id': doc.id, 'name': doc['fullName'] ?? 'Unnamed Shop'};
      }).toList();

      if (_shops.isNotEmpty) {
        _selectedShopId = _shops[0]['id'];
      }
    });
  }

  Future<String?> _uploadFile(XFile file, String folder, String uid) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('repair_uploads/$uid/$folder/$fileName');

      print('⏫ Uploading to: ${ref.fullPath}');
      final uploadTask = await ref.putFile(File(file.path));
      final url = await uploadTask.ref.getDownloadURL();
      print('✅ Uploaded: $url');
      return url;
    } catch (e) {
      print('❌ Upload failed: $e');
      return null;
    }
  }

  Future<void> _submitRequest() async {
  if (_deviceNameController.text.isEmpty ||
      _issueController.text.isEmpty ||
      _selectedShopId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all required fields')),
    );
    return;
  }

  final uid = FirebaseAuth.instance.currentUser!.uid;
  String? imageUrl;
  String? videoUrl;

  try {
    if (_selectedImage != null) {
      imageUrl = await _uploadFile(_selectedImage!, 'images', uid);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed.')),
        );
        return;
      }
    }

    if (_selectedVideo != null) {
      videoUrl = await _uploadFile(_selectedVideo!, 'videos', uid);
      if (videoUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video upload failed.')),
        );
        return;
      }
    }

    await FirebaseFirestore.instance.collection('repair_requests').add({
      'deviceName': _deviceNameController.text.trim(),
      'deviceType': _selectedDeviceType,
      'issue': _issueController.text.trim(),
      'userId': uid,
      'customerId': uid, //  ADDED THIS LINE
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'shopId': _selectedShopId,
      'status': 'Pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Repair request submitted!')),
    );
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF39ef64),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                const Text(
                  'Submit Repair Request',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _deviceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Device Name (e.g., iPhone 14)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.devices_other),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedDeviceType,
                    decoration: const InputDecoration(
                      labelText: 'Select Device Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.laptop),
                    ),
                    items: ['Phone', 'Laptop', 'Tablet'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDeviceType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedShopId,
                    decoration: const InputDecoration(
                      labelText: 'Select Shop',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                    items: _shops.map<DropdownMenuItem<String>>((shop) {
                      return DropdownMenuItem<String>(
                        value: shop['id'],
                        child: Text(shop['name']),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedShopId = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _issueController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Describe the issue in detail',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF8F5FF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final status = await Permission.photos.request();
                      if (status.isGranted) {
                        final picked = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 50,
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedImage = picked;
                          });
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Permission denied.")),
                        );
                      }
                    },
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: Text(
                      _selectedImage != null ? 'Image Selected' : 'Upload Image',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39ef64),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await _picker.pickVideo(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedVideo = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.videocam, color: Colors.white),
                    label: Text(
                      _selectedVideo != null ? 'Video Selected' : 'Upload Video',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39ef64),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _submitRequest,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text('Submit', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39ef64),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
