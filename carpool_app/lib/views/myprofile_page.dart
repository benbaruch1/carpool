import 'package:carpool_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:carpool_app/widgets/myProfile_content.dart';

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

          return ProfileContent(
            nameController: _nameController,
            addressController: _addressController,
            phoneNumberController: _phoneNumberController,
            emailController: _emailController,
            formKey: _formKey,
            error: error,
            onUpdate: _updateProfile,
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
