import 'package:carpool_app/services/database.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carpool_app/widgets/custom_button.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  int _selectedIndex = 3;
  String error = '';

  // State variables for form fields
  String _name = '';
  String _address = '';
  String _phoneNumber = '';
  String _email = '';
  int _availableSeats = 5;

  Future<Map<String, dynamic>> _fetchUserData() async {
    var user = FirebaseAuth.instance.currentUser;
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    if (snapshot.exists) {
      return snapshot.data()!;
    }
    return {};
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("[LOG] my profile opened ");
    return Scaffold(
      appBar: TopBar(title: 'My Profile', showBackButton: false),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No user data found'));
          }

          var userData = snapshot.data!;
          // Initialize state variables with Firestore data
          _name = userData['firstName'] ?? '';
          _address = userData['address'] ?? '';
          _phoneNumber = userData['phoneNumber'] ?? '';
          _email = userData['email'] ?? '';
          _availableSeats = userData['availableSeats'] ?? 5;

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateLocal) {
              return _buildProfileForm(setStateLocal);
            },
          );
        },
      ),
      bottomNavigationBar: BottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildProfileForm(StateSetter setStateLocal) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color.fromARGB(0, 165, 214, 167), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Edit profile',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Personal info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: _email,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      fillColor: Colors.grey.shade300,
                      filled: true,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: _name,
                    decoration: InputDecoration(
                      labelText: 'Name',
                    ),
                    onChanged: (value) => setStateLocal(() => _name = value),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: _phoneNumber,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                    ),
                    onChanged: (value) =>
                        setStateLocal(() => _phoneNumber = value),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: _address,
                    decoration: InputDecoration(
                      labelText: 'Address',
                    ),
                    onChanged: (value) => setStateLocal(() => _address = value),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _availableSeats,
                          decoration: InputDecoration(
                            labelText: 'Available Seats',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.green),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.green),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.green),
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(0, 255, 255, 255),
                          ),
                          items: [1, 2, 3, 4, 5].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setStateLocal(() {
                              _availableSeats = val!;
                            });
                          },
                          validator: (val) => val == null
                              ? 'Select the number of available seats'
                              : null,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.info, color: Colors.green),
                        onPressed: _showInfoDialog,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: CustomButton(
                      label: 'Update',
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          bool canUpdate =
                              await _checkGroupsForSeats(_availableSeats);
                          if (canUpdate) {
                            _updateProfile(
                              _name,
                              _phoneNumber,
                              _address,
                              _availableSeats,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    error,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _checkGroupsForSeats(int newAvailableSeats) async {
    final user = FirebaseAuth.instance.currentUser;
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    final userGroups = userSnapshot.data()!['groups'] as List<dynamic>? ?? [];

    if (userGroups.isEmpty) {
      return true;
    }

    List<String> problematicGroups = [];

    for (String groupId in userGroups) {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();
      if (groupSnapshot.exists) {
        var groupData = groupSnapshot.data() as Map<String, dynamic>;
        if (groupData['availableSeats'] > newAvailableSeats) {
          problematicGroups.add(groupData['rideName']);
        }
      }
    }

    if (problematicGroups.isNotEmpty) {
      _showProblematicGroupsDialog(problematicGroups);
      return false;
    }
    return true;
  }

  void _showProblematicGroupsDialog(List<String> groups) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Cannot Update Available Seats"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "You need to leave the following groups before reducing the available seats:"),
              ...groups.map((group) => Text(group)).toList(),
            ],
          ),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateProfile(
      String name, String phoneNumber, String address, int availableSeats) {
    final user = FirebaseAuth.instance.currentUser;
    DatabaseService databaseService = DatabaseService(user!.uid);
    databaseService
        .updateExistingUserData(name, phoneNumber, address, availableSeats)
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile Updated Successfully'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.lightGreen,
        ),
      );
    }).catchError((error) {
      setState(() {
        this.error = 'Failed to update profile: $error';
      });
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Available Seats Information',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Select the number of seats available for carpooling:',
                ),
                bulletPoint('Include the driver\'s seat.'),
                bulletPoint('Exclude any baby or child seats.'),
                bulletPoint('Count only seats with seatbelts.'),
                SizedBox(height: 10),
                Text('Examples:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                bulletPoint('5-seater car: Select 5.'),
                bulletPoint('5-seater car with one baby seat: Select 4.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          elevation: 5,
        );
      },
    );
  }

  Widget bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
