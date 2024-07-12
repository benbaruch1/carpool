import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_app/models/group.dart';
import 'package:intl/intl.dart'; // הייבוא של intl

class GroupPage extends StatelessWidget {
  final Group group;
  final String currentUserId;

  GroupPage({required this.group, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    bool isMember = group.members.contains(currentUserId);
    bool isFull = group.members.length >= 5;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.rideName),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Meeting Points'),
                    _buildMeetingPoint(
                        'First Meeting Point', group.firstMeetingPoint),
                    _buildMeetingPoint(
                        'Second Meeting Point', group.secondMeetingPoint),
                    _buildMeetingPoint(
                        'Third Meeting Point', group.thirdMeetingPoint),
                    SizedBox(height: 20),
                    _buildSectionTitle('Ride Details'),
                    _buildRideDetail('Ride Name', group.rideName),
                    _buildRideDetail(
                        'Selected Days', group.selectedDays.join(', ')),
                    _buildTimesSection(group.times),
                    SizedBox(height: 20),
                    _buildMembersAndPointsHeader(),
                    _buildMembersList(group.members, group.userId),
                    SizedBox(height: 20),
                    FutureBuilder<String>(
                      future: _getDriverWithLowestPoints(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error loading driver info');
                        } else {
                          return Column(children: [
                            _buildDriverInfo(snapshot.data!),
                            if (snapshot.data == currentUserId)
                              FutureBuilder<bool>(
                                future: _canStartDriveToday(),
                                builder: (context, startDriveSnapshot) {
                                  if (startDriveSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (startDriveSnapshot.hasError) {
                                    return Text('Error');
                                  } else if (startDriveSnapshot.data!) {
                                    return _buildStartDriveButton(context);
                                  } else {
                                    return Text(
                                      'You can start the drive 15 minutes before the departure time.',
                                      style: TextStyle(color: Colors.red),
                                    );
                                  }
                                },
                              ),
                            if (snapshot.data != currentUserId)
                              FutureBuilder<bool>(
                                future: _hasDriveStarted(),
                                builder: (context, driveStartedSnapshot) {
                                  if (driveStartedSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (driveStartedSnapshot.hasError) {
                                    return Text('Error');
                                  } else if (driveStartedSnapshot.data!) {
                                    return _buildJoinDriveButton(context);
                                  } else {
                                    return Container();
                                  }
                                },
                              ),
                          ]);
                        }
                      },
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (isMember)
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await _leaveGroup(context);
                  },
                  child: Text('Leave Group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    textStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            if (!isMember && !isFull)
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await _joinGroup(context);
                  },
                  child: Text('Join Group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    textStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            if (isFull)
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Text(
                  'This ride is full.',
                  style: TextStyle(
                      color: const Color.fromARGB(255, 254, 80, 67),
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
    );
  }

  Widget _buildMeetingPoint(String title, String point) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '$title: $point',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildRideDetail(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '$title: $detail',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildTimesSection(Map<String, dynamic> times) {
    List<Widget> timesWidgets = [];
    times.forEach((day, timeDetails) {
      timesWidgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('  Departure Time: ${timeDetails['departureTime']}'),
            Text('  Return Time: ${timeDetails['returnTime']}'),
          ],
        ),
      ));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Times'),
        ...timesWidgets,
      ],
    );
  }

  Widget _buildMembersAndPointsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Members',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Points',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<String> members, String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('groups').doc(group.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('Loading...');
        } else if (snapshot.hasError) {
          return Text('Error');
        } else {
          if (snapshot.data == null || !snapshot.data!.exists) {
            return Text('Group data not found.');
          }

          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          Map<String, dynamic> memberPoints =
              data['memberPoints'] as Map<String, dynamic>? ?? {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: members.map((member) {
              bool isCreator = member == userId;
              int points = memberPoints[member] ?? 0;
              return Row(
                children: [
                  if (isCreator) Icon(Icons.star, color: Colors.green),
                  Expanded(
                    flex: 2,
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(member)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text('Loading...');
                        } else if (snapshot.hasError) {
                          return Text('Error');
                        } else {
                          if (snapshot.data == null || !snapshot.data!.exists) {
                            return Text('User not found');
                          }

                          Map<String, dynamic> userData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          String memberName =
                              userData['firstName'] ?? 'Unknown';
                          return Text(
                            memberName,
                            style: TextStyle(
                              color: isCreator ? Colors.green : Colors.black,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: Text(
                      points.toString(),
                      style: TextStyle(
                        color: isCreator ? Colors.green : Colors.black,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        }
      },
    );
  }

  Future<void> _leaveGroup(BuildContext context) async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.uid)
          .get();

      if (groupSnapshot.exists) {
        Map<String, dynamic> groupData =
            groupSnapshot.data() as Map<String, dynamic>;

        List<dynamic> members = List<String>.from(groupData['members']);

        if (members.length == 1) {
          // Delete the entire group if there's only one member
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(group.uid)
              .delete();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group has been deleted')),
          );
        } else {
          // Remove the member and their points
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(group.uid)
              .update({
            'members': FieldValue.arrayRemove([currentUserId]),
            'memberPoints.$currentUserId': FieldValue.delete(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have left the group')),
          );

          //after the current user leave the group
          if (members.length == 2) {
            //if there only 1 member left
            String remainMemberId =
                members.firstWhere((member) => member != currentUserId);
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(group.uid)
                .update({
              'memberPoints.$remainMemberId': 0,
            });
          }
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'groups': FieldValue.arrayRemove([group.uid]),
        });
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave the group')),
      );
    }
  }

  Future<void> _joinGroup(BuildContext context) async {
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

        //check if user point == 0
        bool hasZeroPoints = memberPoints.values.any((points) => points == 0);

        if (!hasZeroPoints) {
          int minPoints = memberPoints.values.reduce((a, b) => a < b ? a : b);
          int maxPoints = memberPoints.values.reduce((a, b) => a > b ? a : b);

          //update all users points
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

        //adding new user with point = 0
        memberPoints[currentUserId] = 0;

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(group.uid)
            .update({
          'members': FieldValue.arrayUnion([currentUserId]),
          'memberPoints': memberPoints,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'groups': FieldValue.arrayUnion([group.uid]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have joined the group')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join the group')),
      );
    }
  }

  Widget _buildDriverInfo(String driverId) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(driverId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading driver info');
        } else {
          Map<String, dynamic> driverData =
              snapshot.data!.data() as Map<String, dynamic>;
          return Row(
            children: [
              Icon(Icons.time_to_leave, size: 34.0),
              SizedBox(width: 8),
              Text(
                '${driverData['firstName']} is the next driver',
                style: TextStyle(fontSize: 18.0),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStartDriveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(group.uid)
            .update({
          'status': 'started',
        });
        _showRouteDialog(context);
      },
      child: Text('Start Drive'),
    );
  }

  Widget _buildJoinDriveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(group.uid)
            .update({
          'membersJoined': FieldValue.arrayUnion([currentUserId]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have joined the ride')),
        );
      },
      child: Text('Join Drive'),
    );
  }

  Future<bool> _canStartDriveToday() async {
    DateTime now = DateTime.now();
    String currentDay =
        DateFormat('EEE').format(now); // Get current day name with 3 letters
    String currentTime = DateFormat('HH:mm').format(now); // Get current time

    if (group.times.containsKey(currentDay)) {
      String departureTime = group.times[currentDay]['departureTime'];
      DateTime departureDateTime = DateFormat('HH:mm').parse(departureTime);
      DateTime currentDateTime = DateFormat('HH:mm').parse(currentTime);

      Duration difference = departureDateTime.difference(currentDateTime);
      if (difference.inMinutes <= 15 && difference.inMinutes >= 0) {
        return true;
      }
    }
    return false;
  }

  Future<String> _getDriverWithLowestPoints() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .get();
    Map<String, dynamic> groupData =
        groupSnapshot.data() as Map<String, dynamic>;
    Map<String, int> memberPoints =
        Map<String, int>.from(groupData['memberPoints'] ?? {});

    // Check if the group already has a designated driver
    if (groupData.containsKey('nextDriver')) {
      return groupData['nextDriver'];
    }

    // If no designated driver, find the one with the lowest points
    String driverWithLowestPoints =
        memberPoints.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    // Update the group with the designated driver
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .update({
      'nextDriver': driverWithLowestPoints,
    });

    return driverWithLowestPoints;
  }

  Future<bool> _hasDriveStarted() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.uid)
        .get();
    Map<String, dynamic> groupData =
        groupSnapshot.data() as Map<String, dynamic>;
    return groupData['status'] == 'started';
  }

  Future<void> _showRouteDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.map, color: Colors.green),
              SizedBox(width: 10),
              Text("Route", style: TextStyle(color: Colors.green)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildStyledMeetingPoint(
                  'First Meeting Point', group.firstMeetingPoint),
              SizedBox(height: 10),
              _buildStyledMeetingPoint(
                  'Second Meeting Point', group.secondMeetingPoint),
              SizedBox(height: 10),
              _buildStyledMeetingPoint(
                  'Third Meeting Point', group.thirdMeetingPoint),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("OK", style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        );
      },
    );
  }

  Widget _buildStyledMeetingPoint(String title, String point) {
    return Row(
      children: [
        Icon(Icons.location_on, color: Colors.red),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                point,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
