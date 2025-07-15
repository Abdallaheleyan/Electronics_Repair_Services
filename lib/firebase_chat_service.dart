import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instance;

  Future<String> createOrGetChatId(String otherUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    final chatId1 = '${currentUserId}_$otherUserId';
    final chatId2 = '${otherUserId}_$currentUserId';

    final doc1 = await _firestore.collection('chats').doc(chatId1).get();
    final doc2 = await _firestore.collection('chats').doc(chatId2).get();

    if (doc1.exists) {
      await _firestore.collection('chats').doc(chatId1).update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return chatId1;
    }
    if (doc2.exists) {
      await _firestore.collection('chats').doc(chatId2).update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return chatId2;
    }

    await _firestore.collection('chats').doc(chatId1).set({
      'participants': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastUpdated': FieldValue.serverTimestamp(),
      'unread': {currentUserId: 0, otherUserId: 0},
    });

    return chatId1;
  }

  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(
    String chatId,
    String otherUserId,
    String text,
  ) async {
    print(
      'Sending message to chatId: $chatId, otherUserId: $otherUserId, message: $text',
    );
    final currentUserId = _auth.currentUser!.uid;
    final message = {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message);
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
      'unread.$otherUserId': FieldValue.increment(1),
    });
    
    // ✅ Call Cloud Function to send push notification
    try {
      final callable = _functions.httpsCallable(
        'sendChatNotification',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call({
        'receiverId': otherUserId,
        'message': text,
      });
      print('✅ Chat notification sent: ${result.data}');
    } catch (e) {
      print('❌ Failed to call sendChatNotification: $e');
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final currentUserId = _auth.currentUser!.uid;
    await _firestore.collection('chats').doc(chatId).update({
      'unread.$currentUserId': 0,
    });
  }
}
