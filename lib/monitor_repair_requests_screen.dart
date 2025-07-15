import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MonitorRepairRequestsScreen extends StatefulWidget {
  const MonitorRepairRequestsScreen({Key? key}) : super(key: key);

  @override
  State<MonitorRepairRequestsScreen> createState() =>
      _MonitorRepairRequestsScreenState();
}

class _MonitorRepairRequestsScreenState
    extends State<MonitorRepairRequestsScreen> {
  final Set<String> _selectedRequests = {};
  List<QueryDocumentSnapshot> _currentRequests = [];

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM d, yyyy  h:mm a').format(date);
  }

  Future<void> _deleteSelectedRequests() async {
    if (_selectedRequests.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected Requests'),
        content: const Text(
          'Are you sure you want to delete selected requests? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        for (var id in _selectedRequests) {
          await FirebaseFirestore.instance
              .collection('repair_requests')
              .doc(id)
              .delete();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected repair requests deleted successfully.'),
          ),
        );
        setState(() => _selectedRequests.clear());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete selected requests: $e')),
        );
      }
    }
  }

  void _toggleSelectAll(List<QueryDocumentSnapshot> requests, bool selectAll) {
    setState(() {
      if (selectAll) {
        _selectedRequests.addAll(requests.map((r) => r.id));
      } else {
        _selectedRequests.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Column(
        children: [
          _buildModernAppBar(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedRequests.length == _currentRequests.length &&
                      _currentRequests.isNotEmpty,
                  onChanged: (value) {
                    _toggleSelectAll(_currentRequests, value ?? false);
                  },
                ),
                const Text('Select All'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('repair_requests')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No repair requests available.'),
                  );
                }

                _currentRequests = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _currentRequests.length,
                  itemBuilder: (context, index) {
                    final request = _currentRequests[index];
                    final data = request.data() as Map<String, dynamic>;
                    final deviceName = data['deviceName'] ?? 'Unknown Device';
                    final issue = data['issue'] ?? 'No issue provided';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final status = data['status'] ?? 'Pending';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: const Color(0xFFE8F9F1),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    deviceName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                                  'Submitted: ${_formatTimestamp(createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Checkbox(
                                  value: _selectedRequests.contains(request.id),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedRequests.add(request.id);
                                      } else {
                                        _selectedRequests.remove(request.id);
                                      }
                                    });
                                  },
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
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
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
          const Icon(Icons.assignment, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Monitor Repair Requests',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_selectedRequests.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              onPressed: _deleteSelectedRequests,
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
