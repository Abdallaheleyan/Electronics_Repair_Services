import 'package:intl/intl.dart';
import 'feedback_screen..dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackRepairStatusScreen extends StatelessWidget {
  const TrackRepairStatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String customerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('repair_requests')
                  .where('userId', isEqualTo: customerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No repair requests yet.'));
                }

                final requests = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final data = request.data() as Map<String, dynamic>;
                    final deviceName = data['deviceName'] ?? 'Unknown Device';
                    final issue = data['issue'] ?? 'Issue details not entered';
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final status = data['status'] ?? 'Pending';
                    final deviceType = data['deviceType'] ?? 'Device';
                    final rejectionReason = data['rejectionReason'] ?? null;

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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        Text(
                                          deviceName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          deviceType,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                _buildStatusChip(status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(issue),
                            if (createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Submitted: ${DateFormat('MMM d, yyyy').format(createdAt)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            if (status == 'Rejected' && rejectionReason != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    const Text(
                                      'Rejection Reason:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(rejectionReason),
                                  ],
                                ),
                              ),
                            if (status == 'Completed')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FeedbackScreen(requestId: request.id),
                                      ),
                                    );
                                  },
                                    icon: const Icon(Icons.rate_review, color: Colors.green),
                                    label: const Text(
                                    'Leave Feedback',
                                    style: TextStyle(
                                        color: Colors.green,
                                      fontWeight: FontWeight.bold,
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
            ),
          ),
        ],
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
          const Icon(Icons.track_changes, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          const Text(
            'Track Repair Status',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
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
      case 'Rejected':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
