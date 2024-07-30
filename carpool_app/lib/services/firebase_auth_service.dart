import 'package:carpool_app/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carpool_app/models/user.dart';
import 'package:flutter/widgets.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  // get MyUser(model) from User(Firebase)
  MyUser? _userFromFirebaseUser(User? user) {
    return user != null ? MyUser(user.uid) : null;
  }

  //auth change stream
  Stream<MyUser?> get user {
    return _auth
        .authStateChanges()
        .map((User? user) => _userFromFirebaseUser(user));
  }

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future registerWithEmailAndPassword(
      String email,
      String password,
      String firstName,
      String phoneNumber,
      String address,
      int availableSeats) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      await DatabaseService(user!.uid).updateUserData(
          email, firstName, phoneNumber, address, availableSeats);

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<MyUser?> getMyUserFromUid(String? uid) async {
    var user = _auth.currentUser;
    if (user == null) {
      return null; // Return null if there is no current user
    }
    DatabaseService databaseService = DatabaseService(user.uid);
    return await databaseService.getFullMyUser();
  }
}
