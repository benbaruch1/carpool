import 'package:flutter/material.dart';
import 'package:carpool_app/views/home_page.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/notification_page.dart';
import 'package:carpool_app/views/myprofile_page.dart';

class BottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomBar({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
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
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car, size: 30),
              label: 'My Rides',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications, size: 30),
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
            onItemTapped(index);
            Navigator.pushAndRemoveUntil(
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
              (Route<dynamic> route) => false,
            );
          },
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
