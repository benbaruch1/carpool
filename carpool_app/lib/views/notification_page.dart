import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.mark_email_read),
            onPressed: () {
              _markAllAsRead(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: () {
              _deleteAllNotifications(context);
            },
          ),
        ],
      ),
      body: NotificationList(),
    );
  }

  void _markAllAsRead(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'isRead': true});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All notifications marked as read')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notifications as read')),
      );
    });
  }

  void _deleteAllNotifications(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All notifications deleted')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notifications')),
      );
    });
  }
}

class NotificationList extends StatefulWidget {
  @override
  _NotificationListState createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No notifications found'));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return NotificationTile(notification: doc);
          }).toList(),
        );
      },
    );
  }
}

class NotificationTile extends StatelessWidget {
  final QueryDocumentSnapshot notification;

  NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = notification.data() as Map<String, dynamic>;
    bool isRead = data['isRead'] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Color(0xFF09D36B).withOpacity(0.2),
        border: Border.all(
          color: isRead ? Colors.transparent : Color(0xFF09D36B),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          data['title'] ?? 'No Title',
          style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
        ),
        subtitle: Text(data['body'] ?? 'No Body'),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            FirebaseFirestore.instance
                .collection('notifications')
                .doc(notification.id)
                .delete();
          },
        ),
        onTap: () {
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(notification.id)
              .update({'isRead': true});
        },
      ),
    );
  }
}

Future<void> sendNotification({
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

Future<void> sendNotificationToGroupMembers({
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
