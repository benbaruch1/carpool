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
    bool showFullGroups = true,
  }) async {
    Query query = FirebaseFirestore.instance.collection('groups');

    // Apply filters to the query
    if (selectedDays != null && selectedDays.isNotEmpty) {
      query = query.where('selectedDays', arrayContainsAny: selectedDays);
    }

    // Fetch the filtered groups
    QuerySnapshot snapshot = await query.get();
    List<Group> results = snapshot.docs.map((doc) {
      return Group.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    // Filter out full groups if showFullGroups is false
    if (!showFullGroups) {
      results = results.where((group) => group.members.length < 5).toList();
    }

    // Apply additional filters
    if (meetingPoint != null && meetingPoint.isNotEmpty) {
      results = results.where((group) {
        return group.firstMeetingPoint
                .toLowerCase()
                .contains(meetingPoint.toLowerCase()) ||
            group.secondMeetingPoint
                .toLowerCase()
                .contains(meetingPoint.toLowerCase()) ||
            group.thirdMeetingPoint
                .toLowerCase()
                .contains(meetingPoint.toLowerCase());
      }).toList();
    }

    if (rideName != null && rideName.isNotEmpty) {
      results = results.where((group) {
        return group.rideName.toLowerCase().contains(rideName.toLowerCase());
      }).toList();
    }

    if (userId != null && userId.isNotEmpty) {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('firstName', isEqualTo: userId)
          .get();
      List<String> userIds = userSnapshot.docs.map((doc) => doc.id).toList();
      results =
          results.where((group) => userIds.contains(group.userId)).toList();
    }

    if (departureTime != null && departureTime.isNotEmpty) {
      int desiredTimeInMinutes = convertTimeToMinutes(departureTime);
      results = results.where((group) {
        return group.times.values.any((time) {
          int groupTimeInMinutes = convertTimeToMinutes(time['departureTime']);
          return (groupTimeInMinutes - desiredTimeInMinutes).abs() <= 30;
        });
      }).toList();
    }

    return results;
  }
}

List<Group> removeDuplicateGroups(List<Group> groups) {
  Set<String> seenUids = {};
  return groups.where((group) => seenUids.add(group.uid)).toList();
}

//calculate the time in minutes
int convertTimeToMinutes(String time) {
  List<String> parts = time.split(':');
  int hours = int.parse(parts[0]);
  int minutes = int.parse(parts[1]);
  return hours * 60 + minutes;
}
