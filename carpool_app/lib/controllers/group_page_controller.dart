import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_app/models/group.dart';
import 'package:carpool_app/controllers/notification_page_controller.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class GroupPageController {
  final Group group;
  final String currentUserId;
  bool isDriverOnTheWay = false;
  DateTime? startTime;
  String? selectedPickupPoint;

  GroupPageController({required this.group, required this.currentUserId});

  Future<void> joinGroup(String selectedPickupPoint) async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .get();

      if (groupSnapshot.exists) {
        Map<String, dynamic> groupData =
            groupSnapshot.data() as Map<String, dynamic>;
        Map<String, int> memberPoints =
            Map<String, int>.from(groupData['memberPoints'] ?? {});

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

        if (userSnapshot.exists) {
          int userAvailableSeats = userSnapshot['availableSeats'];
          int groupMembersCount = groupData['availableSeats'];

          if (userAvailableSeats < groupMembersCount) {
            throw Exception(
                'Cannot join the group due to insufficient available seats.');
          }
        } else {
          throw Exception('User data not found.');
        }

        bool hasZeroPoints = memberPoints.values.any((points) => points == 0);

        if (!hasZeroPoints) {
          int minPoints = memberPoints.values.reduce((a, b) => a < b ? a : b);
          int maxPoints = memberPoints.values.reduce((a, b) => a > b ? a : b);

          memberPoints.updateAll((member, points) {
            if (points == maxPoints) {
              return points - minPoints;
            } else if (points == minPoints) {
              return points - minPoints;
            } else {
              return points;
            }
          });
        }

        memberPoints[currentUserId] = 0;

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(group.uid)
            .update({
          'members': FieldValue.arrayUnion([currentUserId]),
          'memberPoints': memberPoints,
          'pickupPoints.$currentUserId': selectedPickupPoint,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'groups': FieldValue.arrayUnion([group.uid]),
        });

        await NotificationPageController.sendNotification(
          title: 'Joined to ${group.rideName} group successfully',
          body:
              'You have successfully joined the group and selected your pickup point.',
          userId: currentUserId,
        );

        await notifyGroupForNewUserJoin();
      } else {
        throw Exception('Group not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveGroup([String? memberId]) async {
    String userIdToRemove = memberId ?? currentUserId;

    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .get();

      if (groupSnapshot.exists) {
        Map<String, dynamic> groupData =
            groupSnapshot.data() as Map<String, dynamic>;

        List<dynamic> members = List<String>.from(groupData['members']);
        bool isDriver = groupData['nextDriver'] == userIdToRemove;
        bool isCreator = groupData['userId'] == userIdToRemove;

        if (members.length == 1) {
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(group.uid)
              .delete();
        } else {
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(group.uid)
              .update({
            'members': FieldValue.arrayRemove([userIdToRemove]),
            'memberPoints.$userIdToRemove': FieldValue.delete(),
            'pickupPoints.$userIdToRemove': FieldValue.delete(),
          });

          if (members.length == 2) {
            String remainMemberId =
                members.firstWhere((member) => member != currentUserId);
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(group.uid)
                .update({
              'memberPoints.$remainMemberId': 0,
            });
          }

          if (isDriver) {
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(group.uid)
                .update({
              'nextDriver': FieldValue.delete(),
            });
            await getDriverWithLowestPoints();
          }

          if (isCreator) {
            String newCreatorId =
                members.firstWhere((member) => member != currentUserId);
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(group.uid)
                .update({
              'userId': newCreatorId,
            });
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userIdToRemove)
            .update({
          'groups': FieldValue.arrayRemove([group.uid]),
        });

        await NotificationPageController.sendNotification(
          title: 'You have left the group ${group.rideName}',
          body: 'You have successfully left the group ${group.rideName}',
          userId: userIdToRemove,
        );

        await notifyGroupForUserLeaving(groupData, userIdToRemove);
      } else {
        throw Exception('Group not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePickupPoint(String selectedPickupPoint) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .update({
        'pickupPoints.$currentUserId': selectedPickupPoint,
      });

      await NotificationPageController.sendNotification(
        title: 'Pickup Point Updated',
        body: 'Your pickup point has been updated to $selectedPickupPoint.',
        userId: currentUserId,
      );

      this.selectedPickupPoint = selectedPickupPoint;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startDrive() async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .update({
        'status': 'started',
      });

      startTime = DateTime.now();
      isDriverOnTheWay = true;

      await NotificationPageController.sendNotification(
        title: 'You have started the ride ${group.rideName}',
        body:
            'You have successfully started the ride ${group.rideName}. Please follow the route and pick up the passengers.',
        userId: currentUserId,
      );

      await notifyGroupAboutRideStart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> endDrive() async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .update({
        'status': 'finished',
      });

      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .get();

      await increasePoint(groupSnapshot['nextDriver']);

      await NotificationPageController.sendNotification(
        title: 'You have finished the ride ${group.rideName}',
        body: 'You have successfully finished the ride ${group.rideName}',
        userId: currentUserId,
      );

      await notifyGroupAboutRideEnd();

      isDriverOnTheWay = false;
      startTime = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> notifyGroupForNewUserJoin() async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      String newUserName = userData['firstName'] ?? 'User';

      List<String> userIds =
          group.members.where((userId) => userId != currentUserId).toList();
      await NotificationPageController.sendNotificationToGroupMembers(
        title: "New user join to ${group.rideName} ride",
        body: "Welcome $newUserName to the ride.",
        userIds: userIds,
      );
    }
  }

  Future<void> notifyGroupForUserLeaving(
      Map<String, dynamic> groupData, String userIdToRemove) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userIdToRemove)
        .get();
    String userName =
        (userSnapshot.data() as Map<String, dynamic>)['firstName'];

    List<String> userIds = List<String>.from(groupData['members'])
        .where((userId) => userId != userIdToRemove)
        .toList();

    await NotificationPageController.sendNotificationToGroupMembers(
      title: '$userName has left the group',
      body: '$userName has left the group ${group.rideName}.',
      userIds: userIds,
    );
  }

  Future<String> getDriverWithLowestPoints() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .get();
    Map<String, dynamic> groupData =
        groupSnapshot.data() as Map<String, dynamic>;
    Map<String, int> memberPoints =
        Map<String, int>.from(groupData['memberPoints'] ?? {});

    if (groupData.containsKey('nextDriver') &&
        groupData['nextDriver'] != null) {
      return groupData['nextDriver'];
    }

    String driverWithLowestPoints =
        memberPoints.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .update({
      'nextDriver': driverWithLowestPoints,
    });

    return driverWithLowestPoints;
  }

  Future<void> increasePoint(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .update({
        'memberPoints.$uid': FieldValue.increment(1),
      });

      await NotificationPageController.sendNotification(
        title: "Point Received! :)",
        body:
            "Thanks for your drive. You have received your point in the group '${group.rideName}'.",
        userId: uid,
      );

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .update({'nextDriver': FieldValue.delete()});
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> canStartDriveToday() async {
    DateTime now = DateTime.now();
    String currentDay = DateFormat('EEE').format(now);
    String currentTime = DateFormat('HH:mm').format(now);

    if (group.times.containsKey(currentDay)) {
      String departureTime = group.times[currentDay]['departureTime'];
      DateTime departureDateTime = DateFormat('HH:mm').parse(departureTime);
      DateTime currentDateTime = DateFormat('HH:mm').parse(currentTime);

      Duration difference = departureDateTime.difference(currentDateTime);
      if (difference.inMinutes <= 15 && difference.inMinutes >= -15) {
        return true;
      }
    }
    return false;
  }

  Future<bool> canEndDriveToday() async {
    DateTime now = DateTime.now();
    String currentDay = DateFormat('EEE').format(now);
    String currentTime = DateFormat('HH:mm').format(now);

    if (group.times.containsKey(currentDay)) {
      String returnTime = group.times[currentDay]['returnTime'];
      DateTime returnDateTime = DateFormat('HH:mm').parse(returnTime);
      DateTime currentDateTime = DateFormat('HH:mm').parse(currentTime);

      Duration difference = returnDateTime.difference(currentDateTime);
      if (difference.inMinutes <= 10 &&
          now.isBefore(DateTime(now.year, now.month, now.day, 23, 59, 59))) {
        return true;
      }
    }
    return false;
  }

  Future<void> notifyGroupAboutRideStart() async {
    List<String> userIds =
        group.members.where((userId) => userId != currentUserId).toList();

    await NotificationPageController.sendNotificationToGroupMembers(
      title: 'The ride ${group.rideName} has started!',
      body:
          'Your ride to ${group.rideName} has just started. Please be ready at the meeting point.',
      userIds: userIds,
    );
  }

  Future<void> notifyGroupAboutRideEnd() async {
    List<String> userIds =
        group.members.where((userId) => userId != currentUserId).toList();

    await NotificationPageController.sendNotificationToGroupMembers(
      title: 'Ride ${group.rideName} has ended!',
      body:
          'Your ride to ${group.rideName} has ended. See you on the next ride!',
      userIds: userIds,
    );
  }

  Future<List<LatLng>> getLatLngFromAddresses(List<String> addresses) async {
    List<LatLng> latLngList = [];
    for (String address in addresses) {
      try {
        List<Location> locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          latLngList.add(LatLng(locations[0].latitude, locations[0].longitude));
        }
      } catch (e) {
        String newAddress = "$address, Israel";
        try {
          List<Location> locations = await locationFromAddress(newAddress);
          if (locations.isNotEmpty) {
            latLngList
                .add(LatLng(locations[0].latitude, locations[0].longitude));
          }
        } catch (e) {
          print('Failed to get location for address: $address. Error: $e');
        }
      }
    }
    return latLngList;
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunch(launchUri.toString())) {
      await launch(launchUri.toString());
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  Future<void> initiateVote(String selectedMemberId) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .update({
      'selectedForKick': selectedMemberId,
    });
  }

  Future<void> castVote(String memberId, bool voteYes) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .update({
        'voting.$currentUserId': voteYes ? 'yes' : 'no',
      });

      await checkForKickOutcome(memberId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkForKickOutcome(String memberId) async {
    var groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .get();
    var groupData = groupSnapshot.data() as Map<String, dynamic>;

    Map<String, dynamic> votingData = groupData['voting'] ?? {};
    int yesVotes = votingData.values.where((vote) => vote == 'yes').length;

    if (yesVotes > group.members.length / 2) {
      await leaveGroup(memberId);
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .update({
        'selectedForKick': FieldValue.delete(),
        'voting': FieldValue.delete(),
      });
      await NotificationPageController.sendNotification(
        title: 'You were removed from the group',
        body: 'You have been removed from the group ${group.rideName}.',
        userId: memberId,
      );
      await notifyGroupForUserRemoval(memberId);
    }

    if (votingData.length == group.members.length) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .update({
        'selectedForKick': FieldValue.delete(),
        'voting': FieldValue.delete(),
      });
    }
  }

  Future<void> notifyGroupForUserRemoval(String removedUserId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(removedUserId)
        .get();
    String removedUserName =
        (userSnapshot.data() as Map<String, dynamic>)['firstName'];

    List<String> userIds =
        group.members.where((userId) => userId != removedUserId).toList();
    await NotificationPageController.sendNotificationToGroupMembers(
      title: 'Member removed from the group',
      body:
          '$removedUserName has been removed from the group ${group.rideName}.',
      userIds: userIds,
    );
  }

  Future<List<Map<String, dynamic>>> getMemberNames() async {
    List<Map<String, dynamic>> memberNames = [];
    for (String memberId in group.members) {
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();
      if (userSnapshot.exists) {
        var userData = userSnapshot.data() as Map<String, dynamic>;
        memberNames.add({'id': memberId, 'name': userData['firstName']});
      }
    }
    return memberNames;
  }

  Future<bool> hasDriveStarted() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .get();
    Map<String, dynamic> groupData =
        groupSnapshot.data() as Map<String, dynamic>;
    return groupData['status'] == 'started';
  }

  Future<String?> getCurrentDriver() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .get();
    Map<String, dynamic> groupData =
        groupSnapshot.data() as Map<String, dynamic>;
    return groupData['nextDriver'];
  }

  Future<Map<String, dynamic>> getDriverInfo(String driverId) async {
    DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(driverId)
        .get();
    return driverSnapshot.data() as Map<String, dynamic>;
  }

  Future<Map<String, String>> getGroupPickupPoints() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .get();
    Map<String, dynamic> groupData =
        groupSnapshot.data() as Map<String, dynamic>;
    return Map<String, String>.from(groupData['pickupPoints'] ?? {});
  }

  Future<List<Map<String, String>>> getPickupPointDetails() async {
    Map<String, String> pickupPoints = await getGroupPickupPoints();
    List<Map<String, String>> details = [];

    for (var entry in pickupPoints.entries) {
      String userId = entry.key;
      String pickupPoint = entry.value;

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      String userName = userData['firstName'];
      String phoneNumber = userData['phoneNumber'];

      details.add({
        'name': userName,
        'phone': phoneNumber,
        'pickupPoint': pickupPoint,
      });
    }

    return details;
  }

  Stream<DocumentSnapshot> getGroupStream() {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .snapshots();
  }

  Future<void> updateUserGroups(
      String userId, String groupId, bool isJoining) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'groups': isJoining
          ? FieldValue.arrayUnion([groupId])
          : FieldValue.arrayRemove([groupId]),
    });
  }

  bool isCurrentUserCreator() {
    return group.userId == currentUserId;
  }

  Future<String?> getCurrentUserPickupPoint() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .get();
    Map<String, dynamic> groupData =
        groupSnapshot.data() as Map<String, dynamic>;
    Map<String, dynamic> pickupPoints = groupData['pickupPoints'] ?? {};
    return pickupPoints[currentUserId];
  }
}
