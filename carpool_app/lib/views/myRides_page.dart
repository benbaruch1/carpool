import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carpool_app/models/group.dart';
import 'package:carpool_app/views/group_page.dart';

class MyRidesPage extends StatelessWidget {
  Future<List<DocumentSnapshot>> _fetchUserRides() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    QuerySnapshot createdRidesSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('userId', isEqualTo: user.uid)
        .get();

    QuerySnapshot joinedRidesSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .get();

    // Combine both lists of rides
    List<DocumentSnapshot> allRides = [
      ...createdRidesSnapshot.docs,
      ...joinedRidesSnapshot.docs
    ];
    // Use a set to track unique document IDs
    Set<String> documentIds = Set();
    List<DocumentSnapshot> distinctRides = [];

    for (var ride in allRides) {
      if (!documentIds.contains(ride.id)) {
        documentIds.add(ride.id);
        distinctRides.add(ride);
      }
    }
    return distinctRides;
  }

  void _navigateToGroupPage(BuildContext context, DocumentSnapshot ride) {
    Group group = Group.fromMap(ride.data() as Map<String, dynamic>, ride.id);
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GroupPage(group: group, currentUserId: currentUserId),
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
                            _navigateToGroupPage(context, ride);
                          },
                        ),
                        onTap: () {
                          _navigateToGroupPage(context, ride);
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
