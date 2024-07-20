import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_app/models/group.dart';
import 'package:carpool_app/views/notification_page.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

class GroupPage extends StatefulWidget {
  final Group group;
  final String currentUserId;

  GroupPage({required this.group, required this.currentUserId});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  @override
  Widget build(BuildContext context) {
    bool isMember = widget.group.members.contains(widget.currentUserId);
    bool isFull = widget.group.members.length >= 5;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.rideName),
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
                        'First Meeting Point', widget.group.firstMeetingPoint),
                    _buildMeetingPoint('Second Meeting Point',
                        widget.group.secondMeetingPoint),
                    _buildMeetingPoint(
                        'Third Meeting Point', widget.group.thirdMeetingPoint),
                    SizedBox(height: 20),
                    _buildSectionTitle('Ride Details'),
                    _buildRideDetail('Ride Name', widget.group.rideName),
                    _buildRideDetail(
                        'Selected Days', widget.group.selectedDays.join(', ')),
                    _buildTimesSection(widget.group.times),
                    SizedBox(height: 20),
                    _buildMembersAndPointsHeader(),
                    _buildMembersList(
                        widget.group.members, widget.group.userId),
                    SizedBox(height: 20),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.group.uid)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error loading group status');
                        } else {
                          var groupData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          String status = groupData['status'] ?? 'not started';

                          if (status == 'started') {
                            return FutureBuilder<bool>(
                              future: _canEndDriveToday(),
                              builder: (context, endDriveSnapshot) {
                                if (endDriveSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (endDriveSnapshot.hasError) {
                                  return Text('Error');
                                } else if (endDriveSnapshot.data!) {
                                  return _buildEndDriveButton(context);
                                } else {
                                  return Text(
                                    'You can end the drive 10 minutes before the return time or until midnight.',
                                    style: TextStyle(color: Colors.red),
                                  );
                                }
                              },
                            );
                          } else {
                            return FutureBuilder<String>(
                              future: _getDriverWithLowestPoints(),
                              builder: (context, driverSnapshot) {
                                if (driverSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (driverSnapshot.hasError) {
                                  return Text('Error loading driver info');
                                } else {
                                  return Column(children: [
                                    _buildDriverInfo(driverSnapshot.data!),
                                    if (driverSnapshot.data ==
                                        widget.currentUserId)
                                      FutureBuilder<bool>(
                                        future: _canStartDriveToday(),
                                        builder: (context, startDriveSnapshot) {
                                          if (startDriveSnapshot
                                                  .connectionState ==
                                              ConnectionState.waiting) {
                                            return CircularProgressIndicator();
                                          } else if (startDriveSnapshot
                                              .hasError) {
                                            return Text('Error');
                                          } else if (startDriveSnapshot.data!) {
                                            return _buildStartDriveButton(
                                                context);
                                          } else {
                                            return Text(
                                              'You can start the drive 15 minutes before the departure time.',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            );
                                          }
                                        },
                                      ),
                                  ]);
                                }
                              },
                            );
                          }
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
      future: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.uid)
          .get(),
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
                          return InkWell(
                            onTap: () => _showDriverDetails(context, member),
                            child: Text(
                              memberName,
                              style: TextStyle(
                                color: isCreator ? Colors.green : Colors.black,
                                decoration: TextDecoration.underline,
                              ),
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
          .doc(widget.group.uid)
          .get();

      if (groupSnapshot.exists) {
        Map<String, dynamic> groupData =
            groupSnapshot.data() as Map<String, dynamic>;

        List<dynamic> members = List<String>.from(groupData['members']);
        bool isDriver = groupData['nextDriver'] == widget.currentUserId;
        bool isCreator = groupData['userId'] == widget.currentUserId;

        if (members.length == 1) {
          // Delete the entire group if there's only one member
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.group.uid)
              .delete();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group has been deleted')),
          );
        } else {
          // Remove the member and their points
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.group.uid)
              .update({
            'members': FieldValue.arrayRemove([widget.currentUserId]),
            'memberPoints.${widget.currentUserId}': FieldValue.delete(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have left the group')),
          );

          //after the current user leave the group
          if (members.length == 2) {
            //if there only 1 member left
            String remainMemberId =
                members.firstWhere((member) => member != widget.currentUserId);
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.group.uid)
                .update({
              'memberPoints.$remainMemberId': 0,
            });
          }
          // If the leaving user is the driver, assign a new driver
          if (isDriver) {
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.group.uid)
                .update({
              'nextDriver': FieldValue.delete(),
            });
            await _getDriverWithLowestPoints();
          }
          // If the leaving user is the creator, assign a new creator
          if (isCreator) {
            String newCreatorId =
                members.firstWhere((member) => member != widget.currentUserId);
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.group.uid)
                .update({
              'userId': newCreatorId,
            });
          }
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .update({
          'groups': FieldValue.arrayRemove([widget.group.uid]),
        });

        sendNotification(
          title: 'You have left the group ' + widget.group.rideName,
          body: 'You have successfully left the group ' + widget.group.rideName,
          userId: widget.currentUserId,
        );

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
          .doc(widget.group.uid)
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
        memberPoints[widget.currentUserId] = 0;

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.group.uid)
            .update({
          'members': FieldValue.arrayUnion([widget.currentUserId]),
          'memberPoints': memberPoints,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .update({
          'groups': FieldValue.arrayUnion([widget.group.uid]),
        });
        sendNotification(
            title:
                'Joined to ' + widget.group.rideName + ' group successfully ',
            body: 'You have successfully joined the group',
            userId: widget.currentUserId);
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
            .doc(widget.group.uid)
            .update({
          'status': 'started',
        });
        sendNotification(
          title: 'You have started the ride ' + widget.group.rideName,
          body: 'You have successfully started the ride ' +
              widget.group.rideName +
              '. Please follow the route and pick up the passengers.',
          userId: widget.currentUserId,
        );
        await notifyGroupAboutRideStart(widget.group, widget.currentUserId);
        _showRouteDialog(context);
        setState(() {});
      },
      child: Text('Start Drive'),
    );
  }

  Widget _buildEndDriveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.group.uid)
            .update({
          'status': 'finished',
        });
        DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.group.uid)
            .get();
        inceasePoint(groupSnapshot['nextDriver']);
        sendNotification(
          title: 'You have finished the ride ' + widget.group.rideName,
          body: 'You have successfully finished the ride ' +
              widget.group.rideName,
          userId: widget.currentUserId,
        );
        await notifyGroupAboutRideStart(widget.group, widget.currentUserId);
        setState(() {});
      },
      child: Text('End Drive'),
    );
  }

  Future<void> inceasePoint(String uid) async {
    DocumentReference groupRef =
        FirebaseFirestore.instance.collection('groups').doc(widget.group.uid);

    try {
      await groupRef.update({
        'memberPoints.$uid': FieldValue.increment(1),
      });
      print('Update successful');
      sendNotification(
          title: "Point Received! :)",
          body: "Thanks for your drive. You have received your point.",
          userId: uid);
    } catch (e) {
      print('Error updating document: $e');
    }
  }

  Future<bool> _canStartDriveToday() async {
    DateTime now = DateTime.now();
    String currentDay =
        DateFormat('EEE').format(now); // Get short day name (3 letters)
    String currentTime = DateFormat('HH:mm').format(now); // Get current time

    if (widget.group.times.containsKey(currentDay)) {
      String departureTime = widget.group.times[currentDay]['departureTime'];
      DateTime departureDateTime = DateFormat('HH:mm').parse(departureTime);
      DateTime currentDateTime = DateFormat('HH:mm').parse(currentTime);

      Duration difference = departureDateTime.difference(currentDateTime);
      if (difference.inMinutes <= 15 && difference.inMinutes >= -15) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _canEndDriveToday() async {
    DateTime now = DateTime.now();
    String currentDay =
        DateFormat('EEE').format(now); // Get short day name (3 letters)
    String currentTime = DateFormat('HH:mm').format(now); // Get current time

    if (widget.group.times.containsKey(currentDay)) {
      String returnTime = widget.group.times[currentDay]['returnTime'];
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

  Future<String> _getDriverWithLowestPoints() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.uid)
        .get();
    Map<String, dynamic> groupData =
        groupSnapshot.data() as Map<String, dynamic>;
    Map<String, int> memberPoints =
        Map<String, int>.from(groupData['memberPoints'] ?? {});

    // // Check if the group already has a designated driver
    // if (groupData.containsKey('nextDriver')) {
    //   return groupData['nextDriver'];
    // }

    // If no designated driver, find the one with the lowest points
    String driverWithLowestPoints =
        memberPoints.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    // Update the group with the designated driver
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.uid)
        .update({
      'nextDriver': driverWithLowestPoints,
    });

    return driverWithLowestPoints;
  }

  Future<bool> _hasDriveStarted() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.uid)
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
                  'First Meeting Point', widget.group.firstMeetingPoint),
              SizedBox(height: 10),
              _buildStyledMeetingPoint(
                  'Second Meeting Point', widget.group.secondMeetingPoint),
              SizedBox(height: 10),
              _buildStyledMeetingPoint(
                  'Third Meeting Point', widget.group.thirdMeetingPoint),
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

Future<void> _showDriverDetails(BuildContext context, String driverId) async {
  DocumentSnapshot driverSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(driverId).get();

  if (driverSnapshot.exists) {
    Map<String, dynamic> driverData =
        driverSnapshot.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person, color: Colors.blue),
              SizedBox(width: 8),
              Text('${driverData['firstName']}\'s Details'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('Phone Number'),
                subtitle: Text(driverData['phoneNumber'] ?? 'N/A'),
                onTap: () {
                  _makePhoneCall(driverData['phoneNumber']);
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Close", style: TextStyle(color: Colors.green)),
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
}

Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  await launch(launchUri.toString());
}

Future<void> notifyGroupAboutRideStart(
    Group group, String currentUserId) async {
  // Filter out the current driver from the user IDs
  List<String> userIds =
      group.members.where((userId) => userId != currentUserId).toList();

  await sendNotificationToGroupMembers(
    title: 'The ride ' + group.rideName + ' has started!',
    body: 'Your ride to ' +
        group.rideName +
        ' has just started. Please be ready at the meeting point.',
    userIds: userIds,
  );
}
