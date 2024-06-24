import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSerivce {
  final String uid;

  DatabaseSerivce(this.uid);

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future updateUserData(String email, String firstName, String phoneNumber,
      String address) async {
    return await usersCollection.doc(uid).set({
      'email': email,
      'firstName': firstName,
      'phoneNumber': phoneNumber,
      'address': address,
    });
  }
}
