import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpool_app/models/user.dart';
import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:carpool_app/views/home_wrapper.dart';
import 'package:carpool_app/views/myprofile_page.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/notification_page.dart';
import 'package:carpool_app/views/createRide_page.dart';
import 'package:carpool_app/views/searchRide_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();
  MyUser? myFullUser;
  bool loading = false;
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
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
    final myUser = Provider.of<MyUser?>(context);
    print("[LOG] Home page opened with user logged in : ${myUser?.uid}");
    return loading
        ? Loading()
        : Scaffold(
            appBar: AppBar(
              title:
                  Text(_selectedIndex == 0 ? 'Home' : _titles[_selectedIndex]),
              backgroundColor: Color.fromARGB(0, 113, 183, 115),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeWrapper()),
                    );
                  },
                )
              ],
            ),
            body: _selectedIndex == 0
                ? _buildHomePage(context, myUser)
                : _widgetOptions.elementAt(_selectedIndex - 1),
            bottomNavigationBar: _buildBottomNavigationBar(),
          );
  }

  Widget _buildHomePage(BuildContext context, MyUser? myUser) {
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FutureBuilder<MyUser?>(
                  future: _auth.getMyUserFromUid(myUser?.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Text('User data not found');
                    } else {
                      return _buildWelcomeCard(
                        'Welcome back, ${snapshot.data!.firstName}',
                      );
                    }
                  },
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildSquareButton(
                        context,
                        label: 'Find a Ride',
                        iconAsset: 'assets/search.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SearchRidePage()),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSquareButton(
                        context,
                        label: 'Create a Ride',
                        iconAsset: 'assets/create.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CreateRidePage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/home.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(String message) {
    return Container(
      padding: EdgeInsets.all(7),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 20, color: Colors.green),
          SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareButton(BuildContext context,
      {required String label,
      required Function() onTap,
      IconData? icon,
      String? iconAsset}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 150,
        margin: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 217, 239, 220),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconAsset != null)
              Image.asset(iconAsset, width: 70, height: 70)
            else if (icon != null)
              Icon(icon, size: 50, color: Colors.green),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
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
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle:
              TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}
