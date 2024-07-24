import 'package:flutter/material.dart';
import 'package:carpool_app/models/user.dart';
import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/createRide_page.dart';
import 'package:carpool_app/views/searchRide_page.dart';
import 'package:carpool_app/views/notification_page.dart';
import 'package:carpool_app/views/myprofile_page.dart';

class HomeContent extends StatefulWidget {
  final AuthService auth;
  final MyUser? myUser;
  final MyUser? myFullUser;
  final bool loading;
  final Function(BuildContext) goToMyProfilePage;
  final Function() onLogout;

  HomeContent({
    required this.auth,
    required this.myUser,
    required this.myFullUser,
    required this.loading,
    required this.goToMyProfilePage,
    required this.onLogout,
  });

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    MyRidesPage(),
    NotificationPage(),
    ProfilePage(),
  ];

  static const List<String> _titles = <String>[
    'Home',
    'My Rides',
    'Notifications',
    'My Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.loading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title:
                  Text(_selectedIndex == 0 ? 'Home' : _titles[_selectedIndex]),
              backgroundColor: Colors.green,
              actions: [
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    await widget.auth.signOut();
                    widget.onLogout();
                  },
                )
              ],
            ),
            body: _selectedIndex == 0
                ? _buildHomePage(context)
                : _widgetOptions.elementAt(_selectedIndex - 1),
            bottomNavigationBar: BottomNavigationBar(
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
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.green,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontSize: 12),
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            ),
          );
  }

  Widget _buildHomePage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade200, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FutureBuilder<MyUser?>(
                  future: widget.auth.getMyUserFromUid(widget.myUser?.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Text('User data not found');
                    } else {
                      return _buildWelcomeCard(
                        'Welcome, ${snapshot.data!.firstName}',
                      );
                    }
                  },
                ),
                SizedBox(height: 30),
                _buildCardButton(
                  context,
                  icon: Icons.search,
                  label: 'Search a Ride',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchRidePage()),
                    );
                  },
                ),
                SizedBox(height: 30),
                _buildCardButton(
                  context,
                  icon: Icons.add,
                  label: 'Create a Ride',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateRidePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String message) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: Colors.green,
                size: 30,
              ),
            ),
            SizedBox(width: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required Function() onTap}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: color),
              SizedBox(width: 20),
              Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
