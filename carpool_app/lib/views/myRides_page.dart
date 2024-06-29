import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carpool_app/views/home_page.dart';

class MyRidesPage extends StatelessWidget {
  Future<List<DocumentSnapshot>> _fetchUserRides() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('rides')
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs;
  }

  void _showRideDetails(BuildContext context, DocumentSnapshot ride) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(ride['rideName']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: 'First Meeting Point: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ride['firstMeetingPoint']),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: 'Second Meeting Point: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ride['secondMeetingPoint']),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: 'Third Meeting Point: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ride['thirdMeetingPoint']),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: 'Selected Days: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ride['selectedDays'].join(', ')),
                  ],
                ),
              ),
            ],
          ),
          actions: [
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

  void _showFullRideDetails(BuildContext context, DocumentSnapshot ride) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullRideDetailsPage(ride: ride),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Rides'),
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
          child: FutureBuilder<List<DocumentSnapshot>>(
            future: _fetchUserRides(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No rides found');
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ride = snapshot.data![index];
                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(15),
                        title: Text(
                          ride['rideName'],
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.info, color: Colors.green),
                          onPressed: () {
                            _showRideDetails(context, ride);
                          },
                        ),
                        onTap: () {
                          _showFullRideDetails(context, ride);
                        },
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class FullRideDetailsPage extends StatelessWidget {
  final DocumentSnapshot ride;

  FullRideDetailsPage({required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ride['rideName']),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride['rideName'],
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                SizedBox(height: 10),
                Text('Meeting Points:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('1. ${ride['firstMeetingPoint']}'),
                Text('2. ${ride['secondMeetingPoint']}'),
                Text('3. ${ride['thirdMeetingPoint']}'),
                SizedBox(height: 10),
                Text('Days and Times:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...ride['selectedDays'].map<Widget>((day) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$day:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                          '  Departure Time: ${ride['times'][day]['departureTime']}'),
                      Text(
                          '  Return Time: ${ride['times'][day]['returnTime']}'),
                    ],
                  );
                }).toList(),
                SizedBox(height: 10),
                // Add more details as needed, including members and the "Start drive" button
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Implement the start drive functionality
                  },
                  child: Text('Start drive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),
                /* Center(  
                  child: Image.asset(
                    'assets/steering_wheel.png', //this image dosnt work - idk why??
                    height: 100,
                  ),
                ),
              */
              ],
            ),
          ),
        ),
      ),
    );
  }
}
