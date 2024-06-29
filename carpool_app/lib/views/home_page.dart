import 'package:carpool_app/models/user.dart';
import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:flutter/material.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/createRide_page.dart';
import 'package:carpool_app/views/searchRide_page.dart';
import 'package:provider/provider.dart';
import 'package:carpool_app/views/myprofile_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();

  MyUser? myFullUser;

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final myUser = Provider.of<MyUser?>(context);
    print("[LOG] Home page opened with user logged in : ${myUser?.uid}");
    return loading
        ? Loading()
        : Scaffold(
            appBar: AppBar(
              title: Text('Home'),
              backgroundColor: Colors.green,
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade200, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FutureBuilder<MyUser?>(
                      future: _auth.getMyUserFromUid(myUser?.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData || snapshot.data == null) {
                          return Text('User data not found');
                        } else {
                          myFullUser = snapshot.data;
                          return Text(
                            'Welcome, ${myFullUser!.firstName}',
                            style: TextStyle(fontSize: 24, color: Colors.black),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchRidePage()),
                        );
                        // Implement search ride functionality
                      },
                      icon: Icon(Icons.search),
                      label: Text('Search a ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Implement create ride functionality
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CreateRidePage()),
                        );
                      },
                      icon: Icon(Icons.add),
                      label: Text('Create a ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          InkWell(
                            onTap: () {
                              // Implement navigation to My Rides
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MyRidesPage()),
                              );
                            },
                            child: Column(
                              children: [
                                Icon(Icons.directions_car,
                                    size: 50, color: Colors.green),
                                Text('My rides',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.green)),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              // Implement navigation to Notifications
                            },
                            child: Column(
                              children: [
                                Icon(Icons.notifications,
                                    size: 50, color: Colors.green),
                                Text('Notification',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.green)),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              goToMyProfilePage(context);
                            },
                            child: Column(
                              children: [
                                Icon(Icons.person,
                                    size: 50, color: Colors.green),
                                Text('My Profile',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () async {
                        await _auth.signOut();
                      },
                      child: Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  void goToMyProfilePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    ).then((_) {
      // Refresh the data when coming back from the profile page
      setState(() {});
    });
  }
}

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}
