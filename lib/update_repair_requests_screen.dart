import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class UpdateRepairRequestsScreen extends StatelessWidget {
  final String shopId;
  const UpdateRepairRequestsScreen({Key? key, required this.shopId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
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
              const SizedBox(width: 10),
              const Icon(Icons.manage_accounts, color: Colors.white),
              const SizedBox(width: 10),
              const Text(
                'Update Repair Requests',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('repair_requests')
            .where('shopId', isEqualTo: shopId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return const Center(child: Text('No repair requests found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              final docId = requests[index].id;
              final deviceName = data['deviceName'] ?? 'Unknown Device';
              final issue = data['issue'] ?? 'No issue provided';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final status = data['status'] ?? 'Pending';

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
                              Text(
                                deviceName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              if (createdAt != null)
                                Text(
                                  'Submitted: ${DateFormat('MMM d, yyyy h:mm a').format(createdAt)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(issue),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusChip(status),
                          ElevatedButton.icon(
                            onPressed: () => _changeStatus(context, docId, data['userId']),
                            icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                            label: const Text('Change Status'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF39ef64),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  void _changeStatus(BuildContext context, String docId, String customerId) async {
    final statuses = ['Pending', 'In Progress', 'Completed'];
    String? newStatus = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select New Status'),
        children: statuses.map((status) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, status),
          child: Text(status),
        )).toList(),
      ),
    );

    if (newStatus != null) {
      await FirebaseFirestore.instance
          .collection('repair_requests')
          .doc(docId)
          .update({'status': newStatus});

      try {
        final callable = FirebaseFunctions.instance.httpsCallable('sendStatusUpdateNotification');
        await callable.call({
          'receiverId': customerId,
          'status': newStatus,
        });
      } catch (e) {
        print('Failed to send notification: \$e');
      }
    }
  }
}
