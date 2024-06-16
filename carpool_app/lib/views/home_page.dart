import 'package:flutter/material.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/createRide_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Text(
                'Welcome, Ravid',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Implement search ride functionality
                },
                icon: Icon(Icons.search),
                label: Text('Search a ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Implement create ride functionality
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateRidePage()),
                  );
                },
                icon: Icon(Icons.add),
                label: Text('Create a ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
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
                              style:
                                  TextStyle(fontSize: 16, color: Colors.green)),
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
                              style:
                                  TextStyle(fontSize: 16, color: Colors.green)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Implement navigation to Profile
                      },
                      child: Column(
                        children: [
                          Icon(Icons.person, size: 50, color: Colors.green),
                          Text('My profile',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Implement logout functionality
                },
                child: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 20),
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.green, size: 50),
                onPressed: () {
                  // Implement back button functionality
                },
              ),
            ],
          ),
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
