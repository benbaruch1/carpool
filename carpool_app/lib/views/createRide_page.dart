import 'package:flutter/material.dart';
import 'package:carpool_app/views/myRides_page.dart';
//import 'package:carpool_app/views/notifications_page.dart';
//import 'package:carpool_app/views/profile_page.dart';
import 'package:carpool_app/views/home_page.dart';

class CreateRidePage extends StatefulWidget {
  @override
  _CreateRidePageState createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  final List<String> daysOfWeek = [
    'Sun',
    'Mon',
    'Tues',
    'Wed',
    'Thurs',
    'Fri',
    'Sat'
  ];
  final Set<String> selectedDays = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create ride'),
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Create ride',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  buildTextFieldWithAsterisk('Set first meeting point:', true),
                  SizedBox(height: 10),
                  buildTextFieldWithAsterisk(
                      'Set second meeting point:', false),
                  SizedBox(height: 10),
                  buildTextFieldWithAsterisk('Set third meeting point:', false),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    children: daysOfWeek.map((day) {
                      return ChoiceChip(
                        label: Text(day),
                        selected: selectedDays.contains(day),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  buildTextFieldWithAsterisk('Set departure time:', true),
                  SizedBox(height: 10),
                  buildTextFieldWithAsterisk('Return time:', true),
                  SizedBox(height: 10),
                  buildTextFieldWithAsterisk('Ride name:', true),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Implement create ride functionality
                    },
                    child: Text('Create new ride'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 20),
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
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.green)),
                            ],
                          ),
                        ),
                        InkWell(
                          //  onTap: () {
                          //    Navigator.push(
                          //      context,
                          //      MaterialPageRoute(
                          //          builder: (context) => NotificationsPage()),
                          //    );
                          //  },
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
                          //  onTap: () {
                          //    Navigator.push(
                          //      context,
                          //      MaterialPageRoute(
                          //          builder: (context) => ProfilePage()),
                          //    );
                          //  },
                          child: Column(
                            children: [
                              Icon(Icons.person, size: 50, color: Colors.green),
                              Text('My profile',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.green)),
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
        ),
      ),
    );
  }

  Widget buildTextFieldWithAsterisk(String label, bool isRequired) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        if (isRequired)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              '*',
              style: TextStyle(color: Colors.red, fontSize: 24),
            ),
          ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: CreateRidePage(),
  ));
}
