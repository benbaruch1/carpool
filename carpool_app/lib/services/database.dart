import 'package:carpool_app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;

  DatabaseService(this.uid);

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

  Future updateExistingUserData(
      String firstName, String phoneNumber, String address) async {
    return await usersCollection.doc(uid).update({
      'firstName': firstName,
      'phoneNumber': phoneNumber,
      'address': address,
    });
  }

  Future<MyUser?> getFullMyUser() async {
    DocumentSnapshot snapshot = await usersCollection.doc(uid).get();

    if (!snapshot.exists) {
      return null; // Return null if the document does not exist
    }

    var data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      return null; // Return null if the data is null
    }

    return MyUser.full(
      uid,
      data['email'],
      data['firstName'],
      data['phoneNumber'],
      data['address'],
    );
  }
}
