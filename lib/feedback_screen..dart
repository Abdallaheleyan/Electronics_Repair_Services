import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatefulWidget {
  final String requestId;
  const FeedbackScreen({Key? key, required this.requestId}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = true;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _loadExistingFeedback();
  }

  Future<void> _loadExistingFeedback() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('repair_requests')
        .doc(widget.requestId)
        .collection('feedback')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _rating = data['rating'] ?? 0;
      _commentController.text = data['comment'] ?? '';
      _isEdit = true;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('repair_requests')
        .doc(widget.requestId)
        .collection('feedback')
        .doc(uid)
        .set({
      'rating': _rating,
      'comment': _commentController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback submitted successfully.')),
    );
  }

  Widget _buildStar(int star) {
    return IconButton(
      icon: Icon(
        Icons.star,
        color: _rating >= star ? Colors.amber : Colors.grey,
        size: 32,
      ),
      onPressed: () => setState(() => _rating = star),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Feedback' : 'Leave Feedback'),
        backgroundColor: const Color(0xFF39ef64),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rate the service:',
                      style: TextStyle(fontSize: 18)),
                  Row(
                    children:
                        List.generate(5, (index) => _buildStar(index + 1)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Write your feedback:',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Type here...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39ef64),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Submit Feedback',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
