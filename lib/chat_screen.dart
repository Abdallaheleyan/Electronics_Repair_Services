import 'dart:io';
import 'package:intl/intl.dart';
import 'image_view_screen.dart';
import 'firebase_chat_service.dart';
import 'FullscreenVideoScreen.dart';
import 'location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({'unread.${_currentUserId}': 0});
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    await FirebaseChatService().sendMessage(
      widget.chatId,
      widget.otherUserId,
      text.trim(),
    );
    _messageController.clear();
  }

  Future<void> _sendLocation() async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LocationPickerScreen(
              onLocationPicked: (picked) {
                Navigator.pop(context, picked);
              },
            ),
      ),
    );

    if (selectedLocation != null) {
      final url =
          'https://www.google.com/maps?q=${selectedLocation.latitude},${selectedLocation.longitude}';
      await _sendMessage(url);
    }
  }

  Future<void> _sendMedia(ImageSource source, String type) async {
    final picked =
        await (type == 'image'
            ? _picker.pickImage(source: source)
            : _picker.pickVideo(source: source));
    if (picked == null) return;

    final file = File(picked.path);
    final ref = FirebaseStorage.instance.ref(
      'chat_uploads/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}',
    );

    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _sendMessage(url);
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text("Send Image"),
                  onTap: () {
                    Navigator.pop(context);
                    _sendMedia(ImageSource.gallery, 'image');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text("Send Video"),
                  onTap: () {
                    Navigator.pop(context);
                    _sendMedia(ImageSource.gallery, 'video');
                  },
                ),
              ],
            ),
          ),
    );
  }

  bool _isImage(String url) =>
      url.contains('.jpg') || url.contains('.png') || url.contains('.jpeg');
  bool _isVideo(String url) =>
      url.contains('.mp4') || url.contains('.mov') || url.contains('.mkv');
  bool _isLocation(String text) => text.contains('https://www.google.com/maps');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF39ef64),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  widget.otherUserImage != null
                      ? NetworkImage(widget.otherUserImage!)
                      : null,
              child:
                  widget.otherUserImage == null
                      ? const Icon(Icons.person)
                      : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.otherUserName,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _currentUserId;
                    final time = (msg['timestamp'] as Timestamp?)?.toDate();
                    final text = msg['text'];

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        padding:
                            _isImage(text) || _isVideo(text)
                                ? const EdgeInsets.all(6)
                                : const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isMe ? const Color(0xFF39ef64) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IntrinsicWidth(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLocation(text))
                                GestureDetector(
                                  onTap: () => launchUrl(Uri.parse(text)),
                                  child: Text(
                                    '📍 Location Shared',
                                    style: TextStyle(
                                      color:
                                          isMe
                                              ? Colors.white
                                              : Colors
                                                  .blueAccent, // 👈 Looks nice on light/green
                                      fontWeight:
                                          FontWeight
                                              .bold, // 👈 Feels interactive
                                      fontSize: 15,
                                      decoration:
                                          TextDecoration
                                              .none, // 👈 No underline
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                )
                              else if (_isImage(text))
                                GestureDetector(
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ImageViewScreen(
                                                imageUrl: text,
                                              ),
                                        ),
                                      ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(text, width: 200),
                                  ),
                                )
                              else if (_isVideo(text))
                                GestureDetector(
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => FullscreenVideoScreen(
                                                videoUrl: text,
                                              ),
                                        ),
                                      ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.videocam,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Video File',
                                          style: TextStyle(
                                            color:
                                                isMe
                                                    ? Colors.white
                                                    : Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                              if (time != null)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      DateFormat('hh:mm a').format(time),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            isMe
                                                ? Colors.white70
                                                : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.purple),
                  onPressed: _showMediaPicker,
                ),
                IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.redAccent),
                  onPressed: _sendLocation,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF39ef64)),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
