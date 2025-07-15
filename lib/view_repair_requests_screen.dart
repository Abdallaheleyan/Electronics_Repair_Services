import 'shop_request_tab.dart';
import 'package:flutter/material.dart';

class ViewRepairRequestsScreen extends StatelessWidget {
  const ViewRepairRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF39ef64),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Repair Requests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ShopRequestTab(status: 'Pending'),
            ShopRequestTab(status: 'In Progress'),
            ShopRequestTab(status: 'Completed'),
          ],
        ),
      ),
    );
  }
}
