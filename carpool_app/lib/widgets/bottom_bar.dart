import 'package:flutter/material.dart';
import 'package:carpool_app/views/home_page.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/notification_page.dart';
import 'package:carpool_app/views/myprofile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;

class BottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomBar({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Container(
      margin: EdgeInsets.only(bottom: 10, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car, size: 30),
              label: 'My Rides',
            ),
            BottomNavigationBarItem(
              icon: _buildNotificationIcon(currentUserId),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 30),
              label: 'My Profile',
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle:
              TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          onTap: (index) {
            print("[LOG1] Navigating to page with index: $index");
            onItemTapped(index);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) {
                switch (index) {
                  case 0:
                    return HomePage();
                  case 1:
                    return MyRidesPage();
                  case 2:
                    return NotificationPage();
                  case 3:
                    return ProfilePage();
                  default:
                    return HomePage();
                }
              }),
            );
          },
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          int unreadCount = snapshot.data!.docs.length;
          return badges.Badge(
            badgeContent: Text(
              unreadCount.toString(),
              style: TextStyle(color: Colors.white),
            ),
            child: Icon(Icons.notifications, size: 30),
          );
        } else {
          return Icon(Icons.notifications, size: 30);
        }
      },
    );
  }
}
