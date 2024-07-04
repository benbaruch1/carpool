import 'package:carpool_app/models/group.dart';
import 'package:carpool_app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;

  DatabaseService(this.uid);

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference groupsCollection =
      FirebaseFirestore.instance.collection('groups');

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

  Future<List<Group>> searchGroups({
    String? meetingPoint,
    List<String>? selectedDays,
    String? departureTime,
    String? returnTime,
    String? rideName,
    String? userId,
  }) async {
    List<Group> results = [];

    // If all search parameters are empty or null, return all groups
    if ((meetingPoint == null || meetingPoint.isEmpty) &&
        (selectedDays == null || selectedDays.isEmpty) &&
        (departureTime == null || departureTime.isEmpty) &&
        (returnTime == null || returnTime.isEmpty) &&
        (rideName == null || rideName.isEmpty) &&
        (userId == null || userId.isEmpty)) {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('groups').get();
      return snapshot.docs.map((doc) {
        return Group.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    }

    // Helper function to fetch groups by meeting point
    Future<void> fetchGroupsByMeetingPoint(String field, String value) async {
      Query query = FirebaseFirestore.instance
          .collection('groups')
          .where(field, isEqualTo: value);
      QuerySnapshot querySnapshot = await query.get();
      results.addAll(querySnapshot.docs.map((doc) {
        return Group.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }));
    }

    // Fetch groups by meeting point if provided
    if (meetingPoint != null && meetingPoint.isNotEmpty) {
      await fetchGroupsByMeetingPoint('firstMeetingPoint', meetingPoint);
      await fetchGroupsByMeetingPoint('secondMeetingPoint', meetingPoint);
      await fetchGroupsByMeetingPoint('thirdMeetingPoint', meetingPoint);
    }

    // Additional filters for selectedDays, rideName, userId
    if (selectedDays != null && selectedDays.isNotEmpty) {
      for (String day in selectedDays) {
        Query dayQuery = FirebaseFirestore.instance
            .collection('groups')
            .where('selectedDays', arrayContains: day);
        QuerySnapshot daySnapshot = await dayQuery.get();
        results.addAll(daySnapshot.docs.map((doc) {
          return Group.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }));
      }
    }

    if (rideName != null && rideName.isNotEmpty) {
      Query rideQuery = FirebaseFirestore.instance
          .collection('groups')
          .where('rideName', isEqualTo: rideName);
      QuerySnapshot rideSnapshot = await rideQuery.get();
      results.addAll(rideSnapshot.docs.map((doc) {
        return Group.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }));
    }

    // Fetch user IDs by user name
    List<String> userIds = [];
    if (userId != null && userId.isNotEmpty) {
      Query userQuery = FirebaseFirestore.instance
          .collection('users')
          .where('firstName', isEqualTo: userId);
      QuerySnapshot userSnapshot = await userQuery.get();
      userIds = userSnapshot.docs.map((doc) => doc.id).toList();
    }

    // Fetch groups by user IDs if userName is provided
    if (userIds.isNotEmpty) {
      for (String userId in userIds) {
        Query userGroupQuery = FirebaseFirestore.instance
            .collection('groups')
            .where('userId', isEqualTo: userId);
        QuerySnapshot userGroupSnapshot = await userGroupQuery.get();
        results.addAll(userGroupSnapshot.docs.map((doc) {
          return Group.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }));
      }
    }

    // Fetch all groups for departureTime filtering
    if (departureTime != null && departureTime.isNotEmpty) {
      Query query = FirebaseFirestore.instance.collection('groups');
      QuerySnapshot snapshot = await query.get();
      List<Group> allGroups = snapshot.docs.map((doc) {
        return Group.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      results.addAll(allGroups.where((group) {
        bool match = false;
        group.times.forEach((day, time) {
          if (time['departureTime'] == departureTime) {
            match = true;
          }
        });
        return match;
      }).toList());
    }

    // Remove duplicates if necessary
    final uniqueResults = results.toSet().toList();

    return uniqueResults;
  }
}
