import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_app/controllers/notification_page_controller.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("[LOG] notif opened ");
    return ChangeNotifierProvider(
      create: (_) => NotificationPageController(),
      child: _NotificationPageContent(),
    );
  }
}

class _NotificationPageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NotificationPageController>(context);

    return Scaffold(
      appBar: TopBar(title: 'Notifications', showBackButton: false),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.mark_email_read, color: Colors.green),
                onPressed: () => controller.markAllAsRead(context),
              ),
              IconButton(
                icon: Icon(Icons.delete_forever, color: Colors.green),
                onPressed: () => controller.deleteAllNotifications(context),
              ),
            ],
          ),
          Expanded(
            child: NotificationList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        selectedIndex: controller.selectedIndex,
        onItemTapped: controller.setSelectedIndex,
      ),
    );
  }
}

class NotificationList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller =
        Provider.of<NotificationPageController>(context, listen: false);

    return StreamBuilder<QuerySnapshot>(
      stream: controller.getNotificationsStream(),
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
    final controller =
        Provider.of<NotificationPageController>(context, listen: false);
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
          onPressed: () => controller.deleteNotification(notification.id),
        ),
        onTap: () => controller.markAsRead(notification.id),
      ),
    );
  }
}
