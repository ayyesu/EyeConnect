import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _logger = Logger();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService() {
    _setupTokenRefresh();
    _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        _logger.i('Notification tapped: ${details.payload}');
      },
    );

    // Set up Firebase message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> initializeNotifications() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _fcm.getToken();
        if (token != null) {
          await _updateUserToken(token);
        }
      }
    } catch (e) {
      _logger.e('Error initializing notifications: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.i('Received foreground message: ${message.notification?.title}');

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'help_requests',
          'Help Requests',
          channelDescription: 'Notifications for help requests',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _updateUserToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }

  Future<void> sendHelpRequestNotification() async {
    try {
      // Get current user details
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final requesterName = userDoc.data()?['username'] ?? 'Unknown User';

      // Get all volunteer tokens
      final volunteers = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Volunteer')
          .get();

      // Create help request document
      final helpRequestRef = await _firestore.collection('helpRequests').add({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'requesterId': user.uid,
        'requesterName': requesterName,
      });

      // Update all volunteer documents with the new help request
      for (var volunteer in volunteers.docs) {
        await _firestore
            .collection('users')
            .doc(volunteer.id)
            .collection('pendingRequests')
            .doc(helpRequestRef.id)
            .set({
          'timestamp': FieldValue.serverTimestamp(),
          'requesterId': user.uid,
          'requesterName': requesterName,
        });
      }
    } catch (e) {
      _logger.e('Error sending help request: $e');
    }
  }

  void _setupTokenRefresh() {
    _fcm.onTokenRefresh.listen((newToken) async {
      await _updateUserToken(newToken);
    });
  }
}

// This needs to be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = Logger();
  logger.i('Handling background message: ${message.notification?.title}');
}
