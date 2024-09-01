import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_app/models/group.dart';
import 'package:carpool_app/controllers/group_page_controller.dart';
import 'package:carpool_app/views/notification_page.dart';
import 'package:carpool_app/views/home_page.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/myprofile_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';
import 'package:carpool_app/widgets/custom_button.dart';
import 'package:carpool_app/widgets/small_custom_button.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/shared/constants.dart';

class GroupPage extends StatefulWidget {
  static const String routeName = '/groupPage';

  final Group group;
  final String currentUserId;

  GroupPage({required this.group, required this.currentUserId});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late GroupPageController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = GroupPageController(
        group: widget.group, currentUserId: widget.currentUserId);
  }

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
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight + kTextTabBarHeight),
          child: Column(
            children: [
              TopBar(
                title: widget.group.rideName,
                showBackButton: true,
                isGroupDetailsPage: true,
                isMember: isMember,
                onLeaveGroup: () async {
                  try {
                    await _controller.leaveGroup();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You have left the group')),
                    );
                    Navigator.pop(context, true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to leave the group: $e')),
                    );
                  }
                },
                onJoinGroup: () async {
                  String? selectedPickupPoint = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildPickupPointDialog();
                    },
                  );

                  if (selectedPickupPoint != null) {
                    try {
                      await _controller.joinGroup(selectedPickupPoint);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('You have joined the group')),
                      );
                      Navigator.pop(context, true);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to join the group: $e')),
                      );
                    }
                  }
                },
                onReport: () {
                  _showVotingSystemPopup(context);
                },
              ),
              TabBar(
                indicatorColor: Colors.green,
                labelStyle: TextStyle(fontSize: 18.0, color: Colors.green),
                tabs: [
                  Tab(text: "Details"),
                  Tab(text: "Map"),
                ],
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDetailsTab(isMember, isFull),
            _buildMapTab(addresses),
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
              MaterialPageRoute(builder: (context) => _getPageForIndex(index)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailsTab(bool isMember, bool isFull) {
    return Container(
      color: Colors.white,
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
                  _buildMeetingPoint(
                      'Second Meeting Point', widget.group.secondMeetingPoint),
                  _buildMeetingPoint(
                      'Third Meeting Point', widget.group.thirdMeetingPoint),
                  SizedBox(height: 20),
                  if (isMember) ...[
                    _buildChangePickupPointDropdown(),
                    SizedBox(height: 20),
                  ],
                  _buildTimesSection(widget.group.times),
                  SizedBox(height: 20),
                  _buildMembersAndPointsHeader(),
                  _buildMembersList(),
                  SizedBox(height: 10),
                  _buildDriverSection(),
                ],
              ),
            ),
          ),
          if (isFull)
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Text(
                'This ride is full.',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapTab(List<String> addresses) {
    return FutureBuilder<List<LatLng>>(
      future: _controller.getLatLngFromAddresses(addresses),
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

        return FlutterMap(
          options: MapOptions(
            initialCenter: Constants.initialCenter,
            initialZoom: 9.9,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.carpool.app',
            ),
            MarkerLayer(
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildPickupPointDialog() {
    return AlertDialog(
      title: Text('Select Pickup Point'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPickupOption(widget.group.firstMeetingPoint),
          if (widget.group.secondMeetingPoint.isNotEmpty)
            _buildPickupOption(widget.group.secondMeetingPoint),
          if (widget.group.thirdMeetingPoint.isNotEmpty)
            _buildPickupOption(widget.group.thirdMeetingPoint),
        ],
      ),
    );
  }

  Widget _buildPickupOption(String meetingPoint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop(meetingPoint);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 1),
          ),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Center(
            child: Text(
              meetingPoint,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
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
    if (point.isEmpty) {
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

  Widget _buildChangePickupPointDropdown() {
    return FutureBuilder<String?>(
      future: _controller.getCurrentUserPickupPoint(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        String currentPickupPoint = snapshot.data ?? "Not set";

        return StatefulBuilder(
          builder: (context, setState) {
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your current pickup point:',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        currentPickupPoint,
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
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
                    hint: Text('Change',
                        style: TextStyle(color: Colors.grey[600])),
                    value: _controller.selectedPickupPoint,
                    items: [
                      widget.group.firstMeetingPoint,
                      if (widget.group.secondMeetingPoint.isNotEmpty)
                        widget.group.secondMeetingPoint,
                      if (widget.group.thirdMeetingPoint.isNotEmpty)
                        widget.group.thirdMeetingPoint,
                    ].map((String point) {
                      return DropdownMenuItem<String>(
                        value: point,
                        child: Text(point),
                      );
                    }).toList(),
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        await _controller.updatePickupPoint(newValue);
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
      },
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

  Widget _buildMembersList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _controller.getGroupStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text('Group data not found.');
        }

        Map<String, dynamic> groupData =
            snapshot.data!.data() as Map<String, dynamic>;
        Map<String, dynamic> memberPoints =
            groupData['memberPoints'] as Map<String, dynamic>? ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.group.members.map((member) {
            bool isCreator = member == widget.group.userId;
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
                          if (snapshot.data == null || !snapshot.data!.exists) {
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
      },
    );
  }

  Widget _buildDriverSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _controller.getGroupStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading group status');
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text('Group data not found');
        }

        var groupData = snapshot.data!.data() as Map<String, dynamic>;
        String status = groupData['status'] ?? 'not started';

        if (status == 'started') {
          String currentDriver = groupData['nextDriver'];
          return Column(
            children: [
              _buildDriverInfo(currentDriver),
              SizedBox(height: 20),
              if (currentDriver == widget.currentUserId)
                FutureBuilder<bool>(
                  future: _controller.canEndDriveToday(),
                  builder: (context, endDriveSnapshot) {
                    if (endDriveSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (endDriveSnapshot.hasError) {
                      return Text('Error');
                    } else if (endDriveSnapshot.data!) {
                      return _buildEndDriveButton(context, currentDriver);
                    } else {
                      return Text(
                        'You can end the drive 10 minutes before the return time or until midnight.',
                        style: TextStyle(color: Colors.red),
                      );
                    }
                  },
                ),
            ],
          );
        } else {
          return FutureBuilder<String>(
            future: _controller.getDriverWithLowestPoints(),
            builder: (context, driverSnapshot) {
              if (driverSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (driverSnapshot.hasError) {
                return Text('Error loading driver info');
              } else {
                return Column(
                  children: [
                    _buildDriverInfo(driverSnapshot.data!),
                    if (driverSnapshot.data == widget.currentUserId)
                      FutureBuilder<bool>(
                        future: _controller.canStartDriveToday(),
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
                  ],
                );
              }
            },
          );
        }
      },
    );
  }

  Widget _buildDriverInfo(String driverId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _controller.getDriverInfo(driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading driver info');
        } else {
          Map<String, dynamic> driverData = snapshot.data!;
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
        await _controller.startDrive();
        setState(() {});
        await _showRouteDialog();
      },
      label: 'Start Drive',
    );
  }

  Widget _buildEndDriveButton(BuildContext context, String driverId) {
    if (widget.currentUserId != driverId) {
      return SizedBox.shrink();
    }
    return SmallCustomButton(
      onPressed: () async {
        await _controller.endDrive();
        setState(() {});
      },
      label: 'End Drive',
      color: Colors.red,
    );
  }

  Future<void> _showRouteDialog() async {
    // Fetch the details of the pickup points
    List<Map<String, String>> pickupDetails =
        await _controller.getPickupPointDetails();

    // Group the pickup details by pickup point
    Map<String, List<Map<String, String>>> groupedDetails = {};
    for (var detail in pickupDetails) {
      String pickupPoint = detail['pickupPoint']!;
      if (groupedDetails.containsKey(pickupPoint)) {
        groupedDetails[pickupPoint]!.add(detail);
      } else {
        groupedDetails[pickupPoint] = [detail];
      }
    }

    // Display the dialog with route details
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
                    // Display the start time of the ride, if available
                    if (_controller.startTime != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Driver started the ride at:'),
                          SizedBox(height: 10),
                          Text(
                            DateFormat('HH:mm:ss')
                                .format(_controller.startTime!),
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                          // Display the elapsed time since the ride started
                          StreamBuilder<int>(
                            stream:
                                Stream.periodic(Duration(seconds: 1), (i) => i),
                            builder: (context, snapshot) {
                              Duration elapsed = DateTime.now()
                                  .difference(_controller.startTime!);
                              return Text(
                                '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')} minutes passed',
                                style: TextStyle(fontSize: 18),
                              );
                            },
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    // Display the grouped pickup details
                    ...groupedDetails.entries.map((entry) =>
                        _buildStyledRoutePoint(entry.key, entry.value)),
                  ],
                ),
              ),
              actions: <Widget>[
                // OK button to close the dialog
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

  Widget _buildStyledRoutePoint(
      String pickupPoint, List<Map<String, String>> details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300] ?? Colors.grey,
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the pickup point location
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupPoint,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Divider(color: Colors.grey),
            // Display the details of each user at this pickup point
            ...details.map((detail) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display the user's name
                            Text(
                              detail['name']!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            // Display the user's phone number
                            Text(
                              'Phone: ${detail['phone']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Button to initiate a phone call to the user
                      IconButton(
                        icon: Icon(Icons.call, color: Colors.green),
                        onPressed: () =>
                            _controller.makePhoneCall(detail['phone']!),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _showDriverDetails(BuildContext context, String driverId) async {
    Map<String, dynamic> driverData = await _controller.getDriverInfo(driverId);

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
                  _controller.makePhoneCall(driverData['phoneNumber']);
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

  void _showVotingSystemPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Voting System'),
          content: SingleChildScrollView(
            child: _buildVotingSystem(),
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

  Widget _buildVotingSystem() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _controller.getGroupStream(),
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
          ],
        );
      },
    );
  }

  Widget _buildMemberDropdown(Map<String, dynamic> votingData) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _controller.getMemberNames(),
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
              await _controller.initiateVote(selectedMemberId);
            }
          },
        );
      },
    );
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

        int yesVotes = votingData.values.where((vote) => vote == 'yes').length;
        int noVotes = votingData.values.where((vote) => vote == 'no').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vote to kick $memberName:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _castVote(selectedMember, true),
                  child: Text(
                    'Yes ($yesVotes)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _castVote(selectedMember, false),
                  child: Text(
                    'No ($noVotes)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _castVote(String memberId, bool voteYes) async {
    try {
      await _controller.castVote(memberId, voteYes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cast vote: $e')),
      );
    }
  }

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return HomePage();
      case 1:
        return MyRidesPage();
      case 2:
        return NotificationPage();
      case 3:
        return ProfilePage();
      default:
        return HomePage();
    }
  }
}
