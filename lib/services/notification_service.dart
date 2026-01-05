import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Call this AFTER user login
  static Future<void> init() async {
    await _requestPermission();
    await _saveToken();
    _listenForTokenRefresh();
  }

  // 🔔 Ask permission
  static Future<void> _requestPermission() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } else {
      // Android 13+
      await _messaging.requestPermission();
    }
  }

  // 📱 Save token to Firestore
  static Future<void> _saveToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (kDebugMode) {
      debugPrint("✅ FCM token saved: $token");
    }
  }

  // 🔄 Token can change → update automatically
  static void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': newToken,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint("🔄 FCM token refreshed: $newToken");
      }
    });
  }
}
