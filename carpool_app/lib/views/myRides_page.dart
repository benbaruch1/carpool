import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carpool_app/models/group.dart';
import 'package:carpool_app/views/group_page.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';

class MyRidesPage extends StatefulWidget {
  @override
  _MyRidesPageState createState() => _MyRidesPageState();
}

class _MyRidesPageState extends State<MyRidesPage> {
  int _selectedIndex = 1;

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

  void _navigateToGroupPage(BuildContext context, DocumentSnapshot ride) async {
    Group group = Group.fromMap(ride.data() as Map<String, dynamic>, ride.id);
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    bool? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GroupPage(group: group, currentUserId: currentUserId),
      ),
    );

    if (result == true) {
      // Refresh the rides if the result is true
      setState(() {});
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(title: 'My Rides', showBackButton: false),
      body: Container(
        color: Colors.white,
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
                    return InkWell(
                      onTap: () {
                        _navigateToGroupPage(context, ride);
                      },
                      splashColor: Colors.green.withAlpha(30),
                      highlightColor: Colors.green.withAlpha(50),
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 217, 239, 220),
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15),
                          title: Text(
                            ride['rideName'],
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          trailing: Icon(Icons.info, color: Colors.green),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
