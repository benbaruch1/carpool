import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpool_app/models/user.dart';
import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:carpool_app/views/myprofile_page.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/notification_page.dart';
import 'package:carpool_app/views/createRide_page.dart';
import 'package:carpool_app/views/searchRide_page.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carpool_app/views/home_wrapper.dart';

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
            appBar: TopBar(
              title: _titles[_selectedIndex],
              showBackButton: false,
            ),
            body: _selectedIndex == 0
                ? _buildHomePage(context, myUser)
                : _widgetOptions.elementAt(_selectedIndex - 1),
            bottomNavigationBar: BottomBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
            drawer: _buildDrawer(context),
          );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green,
                ),
                child: Text(
                  'Carpool',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _showAboutDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.contact_mail),
                title: Text('Contact Us'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _showContactUsDialog(context);
                },
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  await _auth.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeWrapper()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
                        'Welcome, ${snapshot.data!.firstName}',
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
                    SizedBox(width: 14),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About CarPool'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'CarPool is a ride-sharing application designed to help drivers find carpool groups heading to Ort Braude College. The app enables users to register and log in, with all participants being drivers. Drivers can create new carpool groups or search for existing ones based on criteria such as starting location, schedule, or group creator name.'),
                SizedBox(height: 10),
                Text(
                    'Once a group reaches its maximum number of participants, it is closed to new members. After a group is created, the creator cannot make changes or delete the group but can leave it without affecting its existence. A group is automatically deleted when it has no participants.'),
                SizedBox(height: 10),
                Text(
                    'Each group has a dedicated page where the system calculates the driver for the day based on the lowest points. Drivers earn points each time they drive, and the system selects the next day\'s driver based on the lowest point total.'),
                SizedBox(height: 10),
                Text(
                    'Each group also includes predefined pick-up points, and participants can select their preferred pick-up point.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showContactUsDialog(BuildContext context) {
    final TextEditingController _messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact Us'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Please enter your message below:',
              ),
              SizedBox(height: 10),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Your message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Send'),
              onPressed: () {
                final String message = _messageController.text;
                if (message.isNotEmpty) {
                  _sendEmail(message);
                  Navigator.of(context).pop();
                } else {
                  print('Message is empty');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _sendEmail(String message) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'ravidp30@walla.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Contact Us Message from CarPool App',
        'body': message,
      }),
    );

    launchUrl(emailLaunchUri);
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
