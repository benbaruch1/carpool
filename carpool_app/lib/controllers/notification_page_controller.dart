import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPageController extends ChangeNotifier {
  int _selectedIndex = 2;
  int get selectedIndex => _selectedIndex;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  Stream<QuerySnapshot> getNotificationsStream() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markAllAsRead(BuildContext context) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notifications as read')),
      );
    }
  }

  Future<void> deleteAllNotifications(BuildContext context) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All notifications deleted')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notifications')),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  static Future<void> sendNotification({
    required String title,
    required String body,
    required String userId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      print('Notification sent successfully');
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  static Future<void> sendNotificationToGroupMembers({
    required String title,
    required String body,
    required List<String> userIds,
  }) async {
    try {
      for (String userId in userIds) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': title,
          'body': body,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
      print('Notifications sent successfully');
    } catch (e) {
      print('Failed to send notifications: $e');
    }
  }
}
