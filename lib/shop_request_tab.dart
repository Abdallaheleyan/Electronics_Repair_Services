import 'package:intl/intl.dart';
import 'image_view_screen.dart';
import 'FullscreenVideoScreen.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
// 🔁 YOUR EXISTING IMPORTS

class ShopRequestTab extends StatelessWidget {
  final String status;

  const ShopRequestTab({Key? key, required this.status}) : super(key: key);

  Future<Map<String, dynamic>?> _getFeedback(String requestId, String userId) async {
    final feedbackDoc = await FirebaseFirestore.instance
        .collection('repair_requests')
        .doc(requestId)
        .collection('feedback')
        .doc(userId)
        .get();

    if (feedbackDoc.exists) return feedbackDoc.data();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String shopId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('repair_requests')
          .where('shopId', isEqualTo: shopId)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No repair requests found.'));
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            final requestId = request.id;
            final deviceName = data['deviceName'] ?? 'Unknown Device';
            final issue = data['issue'] ?? 'Issue not specified';
            final deviceType = data['deviceType'] ?? 'Device';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final imageUrl = data['imageUrl'];
            final videoUrl = data['videoUrl'];
            final userId = data['userId'];
            final formattedDate = createdAt != null
                ? DateFormat('MMM d, yyyy  h:mm a').format(createdAt)
                : '';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final customerName = userData['fullName'] ?? 'Customer';

                return FutureBuilder<Map<String, dynamic>?>(
                  future: status == 'Completed' ? _getFeedback(requestId, userId) : Future.value(null),
                  builder: (context, feedbackSnapshot) {
                    final feedback = feedbackSnapshot.data;

                    return Card(
                      color: const Color(0xFFE8F9F1),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF39ef64).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.devices, size: 20, color: Colors.green),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(deviceName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text(deviceType, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                const Spacer(),
                                _buildStatusChip(status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(issue),
                            const SizedBox(height: 6),
                            Text("Customer: $customerName"),
                            if (formattedDate.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Submitted: $formattedDate',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            // 💾 Your image, video, feedback, reject button sections remain 100% unchanged here
                            if (imageUrl != null && imageUrl != '')
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Attached Image:', style: TextStyle(fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewScreen(imageUrl: imageUrl)));
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (videoUrl != null && videoUrl != '')
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Attached Video:', style: TextStyle(fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        height: 200,
                                        child: VideoPreview(videoUrl: videoUrl),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (status == 'Completed' && feedback != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    const Text('Customer Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: List.generate(5, (i) {
                                        return Icon(
                                          i < (feedback['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                          size: 20,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(feedback['comment'] ?? ''),
                                  ],
                                ),
                              ),
                            if (status == 'Pending')
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _showRejectDialog(context, requestId, userId),
                                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                    label: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                  ),
                                ),
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
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'In Progress':
        color = Colors.blueAccent;
        break;
      case 'Completed':
        color = Colors.green;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  void _showRejectDialog(BuildContext context, String requestId, String userId) {
    final TextEditingController _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Optional reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final reason = _reasonController.text.trim();
              final timestamp = FieldValue.serverTimestamp();

              await FirebaseFirestore.instance.collection('repair_requests').doc(requestId).update({
                'status': 'Rejected',
                'rejectedAt': timestamp,
                'rejectionReason': reason,
              });

              try {
                final callable = FirebaseFunctions.instance.httpsCallable('sendStatusUpdateNotification');
                await callable.call({'receiverId': userId, 'status': 'Rejected'});
              } catch (e) {
                print('❌ Failed to send reject notification: $e');
              }

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class VideoPreview extends StatefulWidget {
  final String videoUrl;
  const VideoPreview({required this.videoUrl, Key? key}) : super(key: key);

  @override
  _VideoPreviewState createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FullscreenVideoScreen(videoUrl: widget.videoUrl)));
            },
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  if (!_controller.value.isPlaying)
                    const Icon(Icons.play_circle_fill, size: 60, color: Colors.white),
                ],
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
