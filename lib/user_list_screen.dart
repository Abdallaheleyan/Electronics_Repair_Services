import 'chat_screen.dart';
import 'firebase_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String searchQuery = '';
  String currentUserId = '';
  String currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      setState(() {
        currentUserRole = doc['role'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(      
      body: Column(
        children: [
          Container(
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
      const SizedBox(width: 10),
      const Icon(Icons.person_search, color: Colors.white, size: 26),
      const SizedBox(width: 10),
      const Text(
        'Select User',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ],
  ),
),
const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              decoration: const InputDecoration(
                labelText: 'Search by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || currentUserRole.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['fullName']?.toLowerCase() ?? '';
                  final role = data['role'] ?? '';

                  // Prevent self and admin from appearing
                  if (doc.id == currentUserId || role == 'admin') return false;

                  // Customers see only shops, shops see only customers
                  if (currentUserRole == 'customer' && role != 'shop') return false;
                  if (currentUserRole == 'shop' && role != 'customer') return false;

                  return name.contains(searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    final name = data['fullName'] ?? 'Unnamed';
                    final image = data['profileImage'];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: image != null ? NetworkImage(image) : null,
                        child: image == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(name),
                      onTap: () async {
                        final chatService = FirebaseChatService();
                        final chatId = await chatService.createOrGetChatId(userId);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chatId,
                              otherUserId: userId,
                              otherUserName: name,
                              otherUserImage: image,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
