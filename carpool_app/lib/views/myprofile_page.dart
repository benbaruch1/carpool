import 'package:carpool_app/services/database.dart';
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
  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  int _availableSeats = 5; // Default value
  int _selectedIndex = 3;

  String error = '';

  Future<void> _fetchUserData() async {
    var user = FirebaseAuth.instance.currentUser;
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    if (snapshot.exists) {
      var data = snapshot.data()!;
      setState(() {
        _emailController.text = data['email'] ?? '';
        _nameController.text = data['firstName'] ?? '';
        _addressController.text = data['address'] ?? '';
        _phoneNumberController.text = data['phoneNumber'] ?? '';
        _availableSeats = data['availableSeats'] ?? 5;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    print("[LOG] my profile opened ");
    return Scaffold(
      appBar: TopBar(title: 'My Profile', showBackButton: false),
      body: Container(
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
                      controller: _emailController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        fillColor: Colors.grey.shade300,
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                      ),
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
                              setState(() {
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
                            bool canUpdate = await _checkGroupsForSeats();
                            if (canUpdate) {
                              _updateProfile();
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
      ),
      bottomNavigationBar: BottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Future<bool> _checkGroupsForSeats() async {
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
        if (groupData['availableSeats'] > _availableSeats) {
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

  void _updateProfile() {
    final user = FirebaseAuth.instance.currentUser;
    DatabaseService databaseService = DatabaseService(user!.uid);
    databaseService
        .updateExistingUserData(
            _nameController.text,
            _phoneNumberController.text,
            _addressController.text,
            _availableSeats)
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile Updated Successfully'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.lightGreen,
        ),
      );
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Available Seats Information'),
          content: Text(
              'Please choose your number of seats available in your car, including you as a driver.\n'
              'For example, \nif you have 4 seats for passengers, please choose 5 available seats.'),
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
}
