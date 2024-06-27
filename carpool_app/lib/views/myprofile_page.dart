import 'package:carpool_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carpool_app/shared/loading.dart';

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

  String error = '';

  Future<Map<String, dynamic>> _fetchUserData() async {
    var user = FirebaseAuth.instance.currentUser;
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    return snapshot.data()!;
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

          return ProfileForm();
        } else {
          return Text('No user data available');
        }
      },
    );
  }

  Scaffold ProfileForm() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update your profile"),
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Update Profile',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      enabled: false, // Disable the email field
                      decoration: InputDecoration(
                        hintText: 'Email',
                        fillColor: Colors.grey.shade300,
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      initialValue: "Not working yet",
                      obscureText: true,
                      onChanged: (val) {
                        // setState(() => password = val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Password',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'First Name',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Address',
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _updateProfile();
                        }
                      },
                      child: Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
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
    );
  }

  void _updateProfile() {
    final user = FirebaseAuth.instance.currentUser;
    DatabaseSerivce databaseSerivce = DatabaseSerivce(user!.uid);
    databaseSerivce
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
