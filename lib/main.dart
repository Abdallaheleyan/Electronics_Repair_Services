import 'login_screen.dart';
import 'register_screen.dart';
import 'chat_list_screen.dart';
import 'customer_dashboard.dart';
import 'package:flutter/material.dart';
import 'track_repair_status_screen.dart';
import 'view_repair_requests_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notification = message.notification;
  final data = message.data;

  flutterLocalNotificationsPlugin.show(
    notification.hashCode,
    notification?.title ?? data['title'],
    notification?.body ?? data['body'],
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    payload: data['target'], // ✅ added payload for navigation
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      final target = details.payload;
      print('🔔 Notification tapped: $target');
      if (target == 'requests') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ViewRepairRequestsScreen()),
        );
      } else if (target == 'track') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const TrackRepairStatusScreen()),
        );
      } else if (target == 'chat') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
      }
    },
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final target = data['target'];
    print('📦 Notification target payload: $target');

    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification?.title ?? data['title'],
      notification?.body ?? data['body'],
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: target, //  this must not be null
    );
  });

  String? token = await messaging.getToken();
  print('🔐 FCM Token: $token');

  final user = FirebaseAuth.instance.currentUser;
  if (user != null && token != null) {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({'fcmToken': token});
    } else {
      print("❌ No user doc found for: ${user.uid}");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey, // ✅ needed for navigation
      title: 'Electronics Repair App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginScreen(),
      routes: {
        '/customer_home': (context) => const CustomerDashboard(),
        '/shop_home': (context) => const ShopDashboard(),
        '/admin_home': (context) => const AdminDashboard(),
      },
    );
  }
}

class ShopDashboard extends StatelessWidget {
  const ShopDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop Dashboard')),
      body: const Center(child: Text('Welcome Shop!')),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(child: Text('Welcome Admin!')),
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[200],
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Who are you?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Please select your user type to continue.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerRegisterScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39ef64),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text('Customer'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Admin login/home (Implement later)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39ef64),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.security, color: Colors.white),
              label: const Text('Admin'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Shop login/home (Implement later)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39ef64),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.store, color: Colors.white),
              label: const Text('Shop'),
            ),
          ],
        ),
      ),
    ),
  );
}
