import 'package:carpool_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carpool_app/shared/loading.dart';
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
  int _selectedIndex = 3;

  String error = '';

  Future<Map<String, dynamic>> _fetchUserData() async {
    var user = FirebaseAuth.instance.currentUser;
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    return snapshot.data()!;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Loading();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          _emailController.text = snapshot.data!['email'] ?? '';
          _nameController.text = snapshot.data!['firstName'] ?? '';
          _addressController.text = snapshot.data!['address'] ?? '';
          _phoneNumberController.text = snapshot.data!['phoneNumber'] ?? '';

          return Scaffold(
            appBar: TopBar(title: 'My Profile', showBackButton: false),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(0, 165, 214, 167),
                    Colors.white
                  ],
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
                          SizedBox(height: 20),
                          Center(
                            child: CustomButton(
                              label: 'Update',
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _updateProfile();
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
        } else {
          return Text('No user data available');
        }
      },
    );
  }

  void _updateProfile() {
    final user = FirebaseAuth.instance.currentUser;
    DatabaseService databaseService = DatabaseService(user!.uid);
    databaseService
        .updateExistingUserData(_nameController.text,
            _phoneNumberController.text, _addressController.text)
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
}
