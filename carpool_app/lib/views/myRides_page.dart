import 'package:flutter/material.dart';
//import 'package:carpool_app/views/notifications_page.dart';
//import 'package:carpool_app/views/profile_page.dart';
import 'package:carpool_app/views/home_page.dart';

class MyRidesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My rides'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.directions_car),
            onPressed: () {
              // Add any action you need here
            },
          ),
        ],
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
                'My rides',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Implement navigation to ride details
                },
                child: Text('Team 1'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
              Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                margin: EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    InkWell(
                      onTap: () {
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
                      // onTap: () {
                      //  Navigator.push(
                      //context,
                      //MaterialPageRoute(
                      //    builder: (context) => NotificationsPage()),
                      //    );
                      //},
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
                      // onTap: () {
                      //   Navigator.push(
                      //       // context,
                      //       // MaterialPageRoute(
                      //       //     builder: (context) => ProfilePage()),
                      //       );
                      //  },
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
              SizedBox(height: 20),
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.green, size: 50),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
