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
                          SizedBox(height: 20),
                          _buildChangePickupPointDropdown(),
                          SizedBox(height: 20),
                          _buildTimesSection(widget.group.times),
                          SizedBox(height: 20),
                          _buildMembersAndPointsHeader(),
                          _buildMembersList(
                              widget.group.members, widget.group.userId),
                          _buildReportIcon(),
                          SizedBox(height: 10),
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
                                  return Column(
                                    children: [
                                      _buildDriverInfo(currentDriver),
                                      SizedBox(height: 20),
                                      if (currentDriver == widget.currentUserId)
                                        FutureBuilder<bool>(
                                          future: _canEndDriveToday(),
                                          builder: (context, endDriveSnapshot) {
                                            if (endDriveSnapshot
                                                    .connectionState ==
                                                ConnectionState.waiting) {
                                              return CircularProgressIndicator();
                                            } else if (endDriveSnapshot
                                                .hasError) {
                                              return Text('Error');
                                            } else if (endDriveSnapshot.data!) {
                                              return _buildEndDriveButton(
                                                  context, currentDriver);
                                            } else {
                                              return Text(
                                                'You can end the drive 10 minutes before the return time or until midnight.',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              );
                                            }
                                          },
                                        ),
                                    ],
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

  String? _selectedPickupPoint;

  Widget _buildChangePickupPointDropdown() {
    List<String> pickupPoints = [
      widget.group.firstMeetingPoint,
      if (widget.group.secondMeetingPoint.isNotEmpty)
        widget.group.secondMeetingPoint,
      if (widget.group.thirdMeetingPoint.isNotEmpty)
        widget.group.thirdMeetingPoint,
    ];

    // Get the current pickup point of the user from the group data
    String currentPickupPoint =
        widget.group.pickupPoints?[widget.currentUserId] ?? "Not set";

    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          children: [
            // Display the current pickup point
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your current pickup point:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    currentPickupPoint,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20), // Add space between text and dropdown
            // Dropdown button to change pickup point
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                hint: Text('Change', style: TextStyle(color: Colors.grey[600])),
                value: _selectedPickupPoint,
                items: pickupPoints.map((String point) {
                  return DropdownMenuItem<String>(
                    value: point,
                    child: Text(point),
                  );
                }).toList(),
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    setState(() {
                      _selectedPickupPoint = newValue;
                    });
                    await _updatePickupPointInDB(newValue);
                    // Update the current pickup point display
                    setState(() {
                      currentPickupPoint = newValue;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Pickup point updated to $newValue successfully!'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePickupPointInDB(String selectedPickupPoint) async {
    try {
      // Update the pickup point in the Firestore database
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.uid)
          .update({
        'pickupPoints.${widget.currentUserId}': selectedPickupPoint,
      });

      // Send a notification to the user about the updated pickup point
      await sendNotification(
        title: 'Pickup Point Updated',
        body: 'Your pickup point has been updated to $selectedPickupPoint.',
        userId: widget.currentUserId,
      );

      // show a success message here or handle any additional logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pickup point updated successfully!'),
        ),
      );
    } catch (e) {
      // Handle any errors that might occur during the update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update pickup point: $e'),
        ),
      );
    }
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

  Future<void> _leaveGroup(BuildContext context, [String? memberId]) async {
    String userIdToRemove = memberId ?? widget.currentUserId;

    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.uid)
          .get();

      if (groupSnapshot.exists) {
        Map<String, dynamic> groupData =
            groupSnapshot.data() as Map<String, dynamic>;

        List<dynamic> members = List<String>.from(groupData['members']);
        bool isDriver = groupData['nextDriver'] == userIdToRemove;
        bool isCreator = groupData['userId'] == userIdToRemove;

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
            'members': FieldValue.arrayRemove([userIdToRemove]),
            'memberPoints.$userIdToRemove': FieldValue.delete(),
          });

          if (userIdToRemove == widget.currentUserId) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You have left the group')),
            );
          }
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
            .doc(userIdToRemove)
            .update({
          'groups': FieldValue.arrayRemove([widget.group.uid]),
        });

        sendNotification(
          title: 'You have left the group ' + widget.group.rideName,
          body: 'You have successfully left the group ' + widget.group.rideName,
          userId: userIdToRemove,
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
                  ),
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
          body:
              "Thanks for your drive. You have received your point in the group '${widget.group.rideName}'.",
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
                  Text("Route details", style: TextStyle(color: Colors.green)),
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
    List<Map<String, String>> users = details[point] ?? [];

    // If no users are assigned to this point, do not display it
    if (users.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.grey[300] ?? Colors.grey,
                  width: 1), // Provides a fallback
            ),
            padding: EdgeInsets.all(10.0),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 24),
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
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        point,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          //Display the users relevant to this point within the box
          ...users.map((user) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name']!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Phone: ${user['phone']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.call, color: Colors.green),
                        onPressed: () => _makePhoneCall(user['phone']!),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
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

  //Function to send a notification when a user leaves the group
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

    await sendNotificationToGroupMembers(
      title: '$userName has left the group',
      body: '$userName has left the group ${widget.group.rideName}.',
      userIds: userIds,
    );
  }

  Future<void> notifyGroupForUserRemoval(
      Group group, String removedUserId) async {
    //Fetching the removed user's name
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(removedUserId)
        .get();
    String removedUserName =
        (userSnapshot.data() as Map<String, dynamic>)['firstName'];

    // Sending a notification to all other group members
    List<String> userIds =
        group.members.where((userId) => userId != removedUserId).toList();
    await sendNotificationToGroupMembers(
      title: 'Member removed from the group',
      body:
          '$removedUserName has been removed from the group ${group.rideName}.',
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

  Widget _buildVotingSystem() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading voting data');
        }

        var groupData = snapshot.data!.data() as Map<String, dynamic>;
        Map<String, dynamic> votingData = groupData['voting'] ?? {};

        String? selectedMember = groupData['selectedForKick'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            if (selectedMember == null)
              Column(
                children: [
                  Text(
                    'Vote to kick a member:',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  _buildMemberDropdown(votingData),
                ],
              )
            else
              _buildVotingOptions(selectedMember, votingData),
            SizedBox(height: 20),
            _buildVoteResults(votingData, selectedMember),
          ],
        );
      },
    );
  }

  Widget _buildMemberDropdown(Map<String, dynamic> votingData) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getMemberNames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error fetching members');
        }

        var members = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Select a member',
            border: OutlineInputBorder(),
          ),
          items: members.map((member) {
            return DropdownMenuItem<String>(
              value: member['id'],
              child: Text(member['name']),
            );
          }).toList(),
          onChanged: (String? selectedMemberId) async {
            if (selectedMemberId != null) {
              await _initiateVote(selectedMemberId);
            }
          },
        );
      },
    );
  }

  Future<void> _initiateVote(String selectedMemberId) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.uid)
        .update({
      'selectedForKick': selectedMemberId,
    });
  }

  Future<List<Map<String, dynamic>>> _getMemberNames() async {
    List<Map<String, dynamic>> memberNames = [];
    for (String memberId in widget.group.members) {
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

  Widget _buildVotingOptions(
      String selectedMember, Map<String, dynamic> votingData) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(selectedMember)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error fetching user info');
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String memberName = userData['firstName'];

        return Column(
          children: [
            Text('Vote to kick $memberName:'),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _castVote(selectedMember, true),
                  child: Text('Yes'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _castVote(selectedMember, false),
                  child: Text('No'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _castVote(String memberId, bool voteYes) async {
    // Check if the current user is part of the group's members
    if (!widget.group.members.contains(widget.currentUserId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('You are not a member of this group and cannot vote.')),
      );
      return; // Exit the function early if the user is not a member
    }

    try {
      // Proceed with the voting process
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.uid)
          .update({
        'voting.${widget.currentUserId}': voteYes ? 'yes' : 'no',
      });

      _checkForKickOutcome(memberId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cast vote: $e')),
      );
    }
  }

  void _checkForKickOutcome(String memberId) async {
    var groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.uid)
        .get();
    var groupData = groupSnapshot.data() as Map<String, dynamic>;

    Map<String, dynamic> votingData = groupData['voting'] ?? {};
    int yesVotes = votingData.values.where((vote) => vote == 'yes').length;

    // Check if a majority has voted "yes"
    if (yesVotes > widget.group.members.length / 2) {
      // Kick the member if majority agrees
      await _leaveGroup(context, memberId);
      //reset the voting
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.uid)
          .update({
        'selectedForKick': FieldValue.delete(),
        'voting': FieldValue.delete(),
      });
      // Sending a notification to the user who was removed from the group
      await sendNotification(
        title: 'You were removed from the group',
        body: 'You have been removed from the group ${widget.group.rideName}.',
        userId: memberId,
      );
      // Sending a notification to all other group members that the user was removed
      await notifyGroupForUserRemoval(widget.group, memberId);
    }

    // If all members have voted, reset the voting state
    if (votingData.length == widget.group.members.length) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.uid)
          .update({
        'selectedForKick': FieldValue.delete(),
        'voting': FieldValue.delete(),
      });
    }
    Navigator.pop(context, true);
  }

  Widget _buildVoteResults(
      Map<String, dynamic> votingData, String? selectedMember) {
    int yesVotes = votingData.values.where((vote) => vote == 'yes').length;
    int noVotes = votingData.values.where((vote) => vote == 'no').length;

    return selectedMember != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Voting Results:'),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Yes'),
                trailing: Text(yesVotes.toString()),
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.red),
                title: Text('No'),
                trailing: Text(noVotes.toString()),
              ),
            ],
          )
        : SizedBox.shrink();
  }

  Widget _buildReportIcon() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.report, color: Colors.red, size: 20),
          padding: EdgeInsets.all(0),
          onPressed: () {
            _showVotingSystemPopup(
                context); //Opening the Popup window when clicking the icon
          },
        ),
        Text(
          'Report',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ],
    );
  }

  void _showVotingSystemPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kick Voting System'),
          content: SingleChildScrollView(
            child: _buildVotingSystem(), //The voting system
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
