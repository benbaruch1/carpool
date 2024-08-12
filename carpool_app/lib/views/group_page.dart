import 'package:carpool_app/shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_app/models/group.dart';
import 'package:carpool_app/views/notification_page.dart';
import 'package:carpool_app/views/home_page.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/myprofile_page.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';
import 'package:carpool_app/widgets/custom_button.dart';
import 'package:carpool_app/widgets/small_custom_button.dart';
import 'package:carpool_app/widgets/top_bar.dart';

class GroupPage extends StatefulWidget {
  final Group group;
  final String currentUserId;

  GroupPage({required this.group, required this.currentUserId});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  bool isDriverOnTheWay = false;
  int _selectedIndex = 0;
  DateTime? _startTime;

  static List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    MyRidesPage(),
    NotificationPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isMember = widget.group.members.contains(widget.currentUserId);
    bool isFull = widget.group.members.length >= widget.group.availableSeats;

    List<String> addresses = [
      widget.group.firstMeetingPoint,
      if (widget.group.secondMeetingPoint.isNotEmpty)
        widget.group.secondMeetingPoint,
      if (widget.group.thirdMeetingPoint.isNotEmpty)
        widget.group.thirdMeetingPoint,
    ];

    return DefaultTabController(
      length: 2, // Two tabs: Details and Map
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight + kTextTabBarHeight),
          child: Column(
            children: [
              TopBar(
                title: widget.group.rideName,
                showBackButton: true,
              ),
              Container(
                color: Colors.grey[200],
                child: TabBar(
                  indicatorColor: Colors.green,
                  labelStyle: TextStyle(fontSize: 18.0, color: Colors.green),
                  tabs: [
                    Tab(text: "Details"),
                    Tab(text: "Map"),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // First tab: Details
            Container(
              color: const Color.fromARGB(
                  255, 255, 255, 255), // Set the background color to white
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Meeting Points'),
                          _buildMeetingPoint('First Meeting Point',
                              widget.group.firstMeetingPoint),
                          _buildMeetingPoint('Second Meeting Point',
                              widget.group.secondMeetingPoint),
                          _buildMeetingPoint('Third Meeting Point',
                              widget.group.thirdMeetingPoint),
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
                                var groupData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                String status =
                                    groupData['status'] ?? 'not started';

                                if (status == 'started') {
                                  String currentDriver =
                                      groupData['nextDriver'];
                                  return FutureBuilder<bool>(
                                    future: _canEndDriveToday(),
                                    builder: (context, endDriveSnapshot) {
                                      if (endDriveSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (endDriveSnapshot.hasError) {
                                        return Text('Error');
                                      } else if (endDriveSnapshot.data! &&
                                          currentDriver ==
                                              widget.currentUserId) {
                                        return _buildEndDriveButton(
                                            context, currentDriver);
                                      } else if (endDriveSnapshot.data! &&
                                          currentDriver !=
                                              widget.currentUserId) {
                                        return Text(
                                            'The driver is on their way.',
                                            style:
                                                TextStyle(color: Colors.green));
                                      } else if (currentDriver ==
                                          widget.currentUserId) {
                                        return Text(
                                          'You can end the drive 10 minutes before the return time or until midnight.',
                                          style: TextStyle(color: Colors.red),
                                        );
                                      } else {
                                        return Text(
                                            'The driver is on their way.',
                                            style:
                                                TextStyle(color: Colors.green));
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
                                        return Text(
                                            'Error loading driver info');
                                      } else {
                                        return Column(children: [
                                          _buildDriverInfo(
                                              driverSnapshot.data!),
                                          if (driverSnapshot.data ==
                                              widget.currentUserId)
                                            FutureBuilder<bool>(
                                              future: _canStartDriveToday(),
                                              builder: (context,
                                                  startDriveSnapshot) {
                                                if (startDriveSnapshot
                                                        .connectionState ==
                                                    ConnectionState.waiting) {
                                                  return CircularProgressIndicator();
                                                } else if (startDriveSnapshot
                                                    .hasError) {
                                                  return Text('Error');
                                                } else if (startDriveSnapshot
                                                    .data!) {
                                                  return _buildStartDriveButton(
                                                      context);
                                                } else {
                                                  return Text(
                                                    'You can start the drive 15 minutes before the departure time.',
                                                    style: TextStyle(
                                                        color: Colors.red),
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
                      padding: const EdgeInsets.all(10.0),
                      child: CustomButton(
                        label: 'Leave',
                        color: Colors.red,
                        onPressed: () async {
                          await _leaveGroup(context);
                        },
                      ),
                    ),
                  if (!isMember && !isFull)
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: CustomButton(
                        label: 'Join',
                        color: Colors.green,
                        onPressed: () async {
                          await _joinGroup(context);
                        },
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
            // Second tab: Map
            SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: Constants.initialCenter,
                  initialZoom: 9.9,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.carpool.app',
                  ),
                  buildMarkerLayer(addresses),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(
                            Uri.parse('https://openstreetmap.org/copyright')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            setState(() {
              _selectedIndex = index;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => _widgetOptions[index]),
            );
          },
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
    if (point == "") {
      return SizedBox.shrink();
    }
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
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    if (isCreator) Text('(Creator) '),
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
                            if (snapshot.data == null ||
                                !snapshot.data!.exists) {
                              return Text('User not found');
                            }

                            Map<String, dynamic> userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            String memberName =
                                userData['firstName'] ?? 'Unknown';
                            return InkWell(
                              onTap: () => _showDriverDetails(context, member),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  memberName,
                                  style: TextStyle(
                                    color:
                                        isCreator ? Colors.green : Colors.black,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          points.toString(),
                          style: TextStyle(
                            color: isCreator ? Colors.green : Colors.black,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
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

        // Check if the user's availableSeats is greater than or equal to the number of members in the group
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .get();
        if (userSnapshot.exists) {
          int userAvailableSeats = userSnapshot['availableSeats'];
          int groupMembersCount = groupData['availableSeats'];

          if (userAvailableSeats < groupMembersCount) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Cannot join the group because your available seats (${userAvailableSeats}) are less than the available seats (${groupMembersCount}) in this group.'),
                duration: Duration(seconds: 5),
              ),
            );
            return;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User data not found.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // Check if user point == 0
        bool hasZeroPoints = memberPoints.values.any((points) => points == 0);

        if (!hasZeroPoints) {
          int minPoints = memberPoints.values.reduce((a, b) => a < b ? a : b);
          int maxPoints = memberPoints.values.reduce((a, b) => a > b ? a : b);

          // Update all users points
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

        // Adding new user with point = 0
        memberPoints[widget.currentUserId] = 0;

        // Show dialog to select pickup point
        String selectedPickupPoint = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select Pickup Point'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(widget.group.firstMeetingPoint),
                    onTap: () {
                      Navigator.of(context).pop(widget.group.firstMeetingPoint);
                    },
                  ),
                  if (widget.group.secondMeetingPoint.isNotEmpty)
                    ListTile(
                      title: Text(widget.group.secondMeetingPoint),
                      onTap: () {
                        Navigator.of(context)
                            .pop(widget.group.secondMeetingPoint);
                      },
                    ),
                  if (widget.group.thirdMeetingPoint.isNotEmpty)
                    ListTile(
                      title: Text(widget.group.thirdMeetingPoint),
                      onTap: () {
                        Navigator.of(context)
                            .pop(widget.group.thirdMeetingPoint);
                      },
                    ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            );
          },
        );

        if (selectedPickupPoint == null) {
          // User canceled the dialog, do nothing
          return;
        }

        // Update the group's document with the new member and their pickup point
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.group.uid)
            .update({
          'members': FieldValue.arrayUnion([widget.currentUserId]),
          'memberPoints': memberPoints,
          'pickupPoints.${widget.currentUserId}': selectedPickupPoint,
        });

        // Update the user's document with the group ID
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .update({
          'groups': FieldValue.arrayUnion([widget.group.uid]),
        });

        sendNotification(
          title: 'Joined to ' + widget.group.rideName + ' group successfully ',
          body:
              'You have successfully joined the group and selected your pickup point.',
          userId: widget.currentUserId,
        );

        notifyGroupForNewUserJoin(widget.group, widget.currentUserId);

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
          return Column(
            children: [
              Row(
                children: [
                  Icon(Icons.time_to_leave, size: 34.0),
                  SizedBox(width: 8),
                  Text(
                    '${driverData['firstName']} is the next driver',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  IconButton(
                    icon: Icon(Icons.info),
                    onPressed: _showRouteDialog,
                  ), // Add this IconButton
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStartDriveButton(BuildContext context) {
    return SmallCustomButton(
      onPressed: () async {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.group.uid)
            .update({
          'status': 'started',
        });

        // save the start time
        setState(() {
          _startTime = DateTime.now();
        });

        sendNotification(
          title: 'You have started the ride ' + widget.group.rideName,
          body: 'You have successfully started the ride ' +
              widget.group.rideName +
              '. Please follow the route and pick up the passengers.',
          userId: widget.currentUserId,
        );
        await notifyGroupAboutRideStart(widget.group, widget.currentUserId);

        setState(() {
          isDriverOnTheWay = true;
        });

        await _showRouteDialog();
      },
      label: 'Start Drive',
    );
  }

  Widget _buildEndDriveButton(BuildContext context, String driverId) {
    // Check if the current user is the driver
    if (widget.currentUserId != driverId) {
      return SizedBox
          .shrink(); // Return an empty widget if the user is not the driver
    }
    return SmallCustomButton(
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
        await notifyGroupAboutRideEnd(widget.group, widget.currentUserId);
        setState(() {});
      },
      label: 'End Drive',
      color: Colors.red,
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

      // delete the nextDriver after he earn a point
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.uid)
          .update({'nextDriver': FieldValue.delete()});
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

    // Check if the group already has a designated driver
    if (groupData.containsKey('nextDriver') &&
        groupData['nextDriver'] != null) {
      return groupData['nextDriver'];
    }

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

  Future<void> _showRouteDialog() async {
    // Route dialog
    List<String> addresses = [
      widget.group.firstMeetingPoint,
      if (widget.group.secondMeetingPoint.isNotEmpty)
        widget.group.secondMeetingPoint,
      if (widget.group.thirdMeetingPoint.isNotEmpty)
        widget.group.thirdMeetingPoint,
    ];

    Map<String, List<Map<String, String>>> details = {};
    addresses.forEach((address) {
      details[address] = [];
    });

    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.uid)
        .get();
    Map<String, dynamic> groupData =
        groupSnapshot.data() as Map<String, dynamic>;

    Map<String, dynamic> pickupPoints = groupData['pickupPoints'] ?? {};
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

      if (details.containsKey(pickupPoint)) {
        details[pickupPoint]!.add({'name': userName, 'phone': phoneNumber});
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.green),
                  SizedBox(width: 10),
                  Text("Ride Started", style: TextStyle(color: Colors.green)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_startTime != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Driver started the ride at:'),
                          SizedBox(height: 10),
                          Text(
                            DateFormat('HH:mm:ss').format(_startTime!),
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                          StreamBuilder<int>(
                            stream:
                                Stream.periodic(Duration(seconds: 1), (i) => i),
                            builder: (context, snapshot) {
                              int elapsedSeconds = snapshot.data ?? 0;
                              Duration elapsed =
                                  DateTime.now().difference(_startTime!);
                              return Text(
                                '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')} minutes passed',
                                style: TextStyle(fontSize: 18),
                              );
                            },
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    _buildStyledRoutePoint('First Meeting Point',
                        widget.group.firstMeetingPoint, details),
                    _buildStyledRoutePoint('Second Meeting Point',
                        widget.group.secondMeetingPoint, details),
                    _buildStyledRoutePoint('Third Meeting Point',
                        widget.group.thirdMeetingPoint, details),
                  ],
                ),
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
      },
    );
  }

  Widget _buildStyledRoutePoint(String title, String point,
      Map<String, List<Map<String, String>>> details) {
    if (point.isEmpty) {
      return SizedBox.shrink();
    }

    List<Map<String, String>> users = details[point] ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green, width: 2),
            ),
            padding: EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.location_pin, color: Colors.red, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        point,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          ...users.map((user) => Card(
                color: Colors.blue[50],
                margin: EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue[800]),
                  ),
                  title: Text(
                    user['name']!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Phone: ${user['phone']}',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.call, color: Colors.green),
                    onPressed: () => _makePhoneCall(user['phone']!),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStyledMeetingPoint(String title, String point,
      Map<String, List<Map<String, String>>> details) {
    List<Map<String, String>> users = details[point] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            border: Border.all(color: Colors.green, width: 2.0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      point,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        ...users.map((user) => ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text(
                user['name']!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.call, color: Colors.green),
                onPressed: () => _makePhoneCall(user['phone']!),
              ),
            )),
      ],
    );
  }

  Future<void> _showDriverDetails(BuildContext context, String driverId) async {
    DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(driverId)
        .get();

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

  Future<void> notifyGroupAboutRideEnd(
      Group group, String currentUserId) async {
    // Filter out the current driver from the user IDs
    List<String> userIds =
        group.members.where((userId) => userId != currentUserId).toList();

    await sendNotificationToGroupMembers(
      title: 'Ride ' + group.rideName + ' has ended!',
      body: 'Your ride to ' +
          group.rideName +
          ' has ended. See you on the next ride!',
      userIds: userIds,
    );
  }

  Future<void> notifyGroupForNewUserJoin(
      Group group, String currentUserId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      String newUserName = userData['firstName'] ?? 'User';

      // Filter out the current driver from the user IDs
      List<String> userIds =
          group.members.where((userId) => userId != currentUserId).toList();
      await sendNotificationToGroupMembers(
        title: "New user join to " + group.rideName + " ride",
        body: "Welcome " + newUserName + " to the ride.",
        userIds: userIds,
      );
    }
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
        // if it is not recognized, try with Israel suffix
        String newAddress = address + ", Israel";
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

  FutureBuilder<List<LatLng>> buildMarkerLayer(List<String> addresses) {
    return FutureBuilder<List<LatLng>>(
      future: getLatLngFromAddresses(addresses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No locations found'));
        }

        List<LatLng> latLngList = snapshot.data!;
        latLngList.add(Constants.destination); // braude latlng

        return MarkerLayer(
          markers: latLngList.map((latLng) {
            return Marker(
              width: 80.0,
              height: 80.0,
              point: latLng,
              child: Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 20.0,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
