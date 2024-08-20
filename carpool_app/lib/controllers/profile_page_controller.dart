import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_app/services/database.dart';

class ProfilePageController extends ChangeNotifier {
  final _formKey = GlobalKey<FormState>();
  int _selectedIndex = 3;
  String error = '';

  // Form field values
  String _name = '';
  String _address = '';
  String _phoneNumber = '';
  String _email = '';
  int _availableSeats = 5;

  // Getters
  GlobalKey<FormState> get formKey => _formKey;
  int get selectedIndex => _selectedIndex;
  String get name => _name;
  String get address => _address;
  String get phoneNumber => _phoneNumber;
  String get email => _email;
  int get availableSeats => _availableSeats;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  Future<void> initializeData() async {
    print("Initializing data...");
    _isLoading = true;
    notifyListeners();

    try {
      await fetchUserData();
    } catch (e) {
      print("Error initializing data: $e");
      error = "Failed to load user data: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserData() async {
    print("Fetching user data...");
    try {
      var user = FirebaseAuth.instance.currentUser;
      print("Current user: ${user?.uid}");
      if (user == null) {
        print("No user logged in");
        throw Exception("No user logged in");
      }
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      print("Firestore snapshot received");
      if (snapshot.exists) {
        var userData = snapshot.data()!;
        print("User data: $userData");
        _name = userData['firstName'] ?? '';
        _address = userData['address'] ?? '';
        _phoneNumber = userData['phoneNumber'] ?? '';
        _email = userData['email'] ?? '';
        _availableSeats = userData['availableSeats'] ?? 5;
      } else {
        print("No data found for user");
        throw Exception("No data found for user");
      }
    } catch (e) {
      print("Error fetching user data: $e");
      throw e;
    }
  }

  void updateFormField(String field, dynamic value) {
    switch (field) {
      case 'name':
        _name = value;
        break;
      case 'address':
        _address = value;
        break;
      case 'phoneNumber':
        _phoneNumber = value;
        break;
      case 'availableSeats':
        _availableSeats = value;
        break;
    }
    notifyListeners();
  }

  Future<bool> checkGroupsForSeats(int newAvailableSeats) async {
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
      error = 'Cannot update available seats due to group restrictions';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> updateProfile(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      bool canUpdate = await checkGroupsForSeats(_availableSeats);
      if (canUpdate) {
        final user = FirebaseAuth.instance.currentUser;
        DatabaseService databaseService = DatabaseService(user!.uid);
        try {
          await databaseService.updateExistingUserData(
              _name, _phoneNumber, _address, _availableSeats);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile Updated Successfully'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.lightGreen,
            ),
          );
        } catch (e) {
          error = 'Failed to update profile: $e';
          notifyListeners();
        }
      }
    }
  }
}
