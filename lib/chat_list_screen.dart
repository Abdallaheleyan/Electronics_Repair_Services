import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'user_list_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
  }

  Future<void> _fetchCurrentUserRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      currentUserRole = doc['role'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: currentUserRole.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: currentUserId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.purple));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No chats yet.'));
                      }

                      final chats = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final data = chat.data() as Map<String, dynamic>;
                          final participants = List<String>.from(data['participants'] ?? []);
                          final otherUserId =
                              participants.firstWhere((id) => id != currentUserId, orElse: () => '');

                          if (otherUserId.isEmpty) return const SizedBox.shrink();

                          final unreadCount = data['unread']?[currentUserId] ?? 0;
                          final lastMessage = data['lastMessage'] ?? '';
                          final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate();
                          final formattedTime =
                              lastUpdated != null ? DateFormat('hh:mm a').format(lastUpdated) : '';

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const ListTile(title: Text('Loading...'));

                              final userDoc = snapshot.data;
                              if (userDoc == null || userDoc.data() == null) {
                                return const ListTile(title: Text(''));
                              }

                              final userData = userDoc.data() as Map<String, dynamic>;
                              final name = userData['fullName'] ?? 'User';
                              final image = userData['profileImage'];
                              final role = userData['role'] ?? '';

                              // 🔐 Filtering logic
                              if (role == 'admin') return const SizedBox.shrink();
                              if ((currentUserRole == 'customer' && role == 'customer') ||
                                  (currentUserRole == 'shop' && role == 'shop')) {
                                return const SizedBox.shrink();
                              }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        chatId: chat.id,
                                        otherUserId: otherUserId,
                                        otherUserName: name,
                                        otherUserImage: image,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F6FB),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage: image != null ? NetworkImage(image) : null,
                                        backgroundColor: Colors.grey[300],
                                        child: image == null
                                            ? const Icon(Icons.person, size: 28, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontSize: 16, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text(
                                              getMessagePreview(lastMessage),
                                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            formattedTime,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 6),
                                          if (unreadCount > 0)
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.red,
                                              ),
                                              child: Text(
                                                '$unreadCount',
                                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserListScreen()),
          );
        },
        backgroundColor: const Color(0xFF39ef64),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
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
          const Icon(Icons.message, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          const Text(
            'Messages',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

String getMessagePreview(String text) {
  if (text.contains('.jpg') || text.contains('.png') || text.contains('.jpeg')) return '📷 Image';
  if (text.contains('.mp4') || text.contains('.mov') || text.contains('.mkv')) return '🎥 Video';
  if (text.contains('https://www.google.com/maps')) return '📍 Location';
  return text;
}
