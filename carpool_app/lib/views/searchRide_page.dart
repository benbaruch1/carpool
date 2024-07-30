import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_app/models/group.dart';
import 'package:carpool_app/views/group_page.dart';
import 'package:carpool_app/services/database.dart';
import 'package:carpool_app/widgets/custom_button.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';

class SearchRidePage extends StatefulWidget {
  @override
  _SearchRidePageState createState() => _SearchRidePageState();
}

class _SearchRidePageState extends State<SearchRidePage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _meetingPointController = TextEditingController();
  final TextEditingController _departureTimeController =
      TextEditingController();
  final TextEditingController _rideNameController = TextEditingController();
  final List<String> selectedDays = [];
  bool _showFullGroups = true;
  Future<List<Group>>? _searchResults;
  int _selectedIndex = 0;

  DatabaseService databaseService =
      DatabaseService(FirebaseAuth.instance.currentUser!.uid);

  Future<void> _searchRides() async {
    List<Group> results = await databaseService.searchGroups(
      meetingPoint: _meetingPointController.text,
      departureTime: _departureTimeController.text,
      selectedDays: selectedDays,
      userId: _userNameController.text,
      rideName: _rideNameController.text,
      showFullGroups: _showFullGroups,
    );

    setState(() {
      _searchResults = Future.value(results);
    });
  }

  void _resetSearchFields() {
    _userNameController.clear();
    _meetingPointController.clear();
    _departureTimeController.clear();
    _rideNameController.clear();
    setState(() {
      selectedDays.clear();
      _showFullGroups = true;
      _searchResults = null;
    });
  }

  void _navigateToGroupPage(BuildContext context, Group group) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    bool? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GroupPage(group: group, currentUserId: currentUserId),
      ),
    );

    if (result == true) {
      _searchRides(); // Refresh the search results if the group was joined or left
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<String> _fetchUserName(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot['firstName'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(title: 'Search a ride', showBackButton: false),
      body: Container(
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20),
                  _buildTextField('Creator\'s first name:', _userNameController,
                      icon: Icons.person),
                  SizedBox(height: 10),
                  _buildTextField('Meeting point:', _meetingPointController,
                      icon: Icons.location_on),
                  SizedBox(height: 10),
                  Text(
                    'Schedule:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 10,
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map((day) {
                      return ChoiceChip(
                        label: Text(day),
                        selected: selectedDays.contains(day),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                            ;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Colors.transparent,
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: selectedDays.contains(day)
                              ? Colors.white
                              : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  _buildTextField('Departure time:', _departureTimeController,
                      icon: Icons.access_time, isTime: true),
                  SizedBox(height: 10),
                  _buildTextField('Ride name:', _rideNameController,
                      icon: Icons.directions_car),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: _showFullGroups,
                        onChanged: (bool? value) {
                          setState(() {
                            _showFullGroups = value ?? true;
                          });
                        },
                      ),
                      Text('Show full groups '),
                      Spacer(),
                      ElevatedButton(
                        onPressed: _resetSearchFields,
                        child: Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 76, 244, 54),
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  CustomButton(
                    label: 'Search',
                    onPressed: _searchRides,
                  ),
                  SizedBox(height: 20),
                  _searchResults != null
                      ? FutureBuilder<List<Group>>(
                          future: _searchResults,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Text('No rides found');
                            } else {
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  Group group = snapshot.data![index];
                                  return FutureBuilder<String>(
                                    future: _fetchUserName(group.userId),
                                    builder: (context, userSnapshot) {
                                      if (userSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (userSnapshot.hasError) {
                                        return Text(
                                            'Error: ${userSnapshot.error}');
                                      } else {
                                        String userName = userSnapshot.data!;
                                        return GestureDetector(
                                          onTap: () {
                                            _navigateToGroupPage(
                                                context, group);
                                          },
                                          child: Card(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 15),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15.0),
                                              side: BorderSide(
                                                  color: Colors.green,
                                                  width: 2),
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(15),
                                              decoration: BoxDecoration(
                                                color: Color.fromARGB(
                                                    255, 217, 239, 220),
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    group.rideName,
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Wrap(
                                                    children: [
                                                      Text(group
                                                          .firstMeetingPoint),
                                                      if (group
                                                          .secondMeetingPoint
                                                          .isNotEmpty)
                                                        Icon(
                                                            Icons.arrow_forward,
                                                            color:
                                                                Colors.green),
                                                      if (group
                                                          .secondMeetingPoint
                                                          .isNotEmpty)
                                                        Text(group
                                                            .secondMeetingPoint),
                                                      if (group
                                                          .thirdMeetingPoint
                                                          .isNotEmpty)
                                                        Icon(
                                                            Icons.arrow_forward,
                                                            color:
                                                                Colors.green),
                                                      if (group
                                                          .thirdMeetingPoint
                                                          .isNotEmpty)
                                                        Text(group
                                                            .thirdMeetingPoint),
                                                      Icon(Icons.arrow_forward,
                                                          color: Colors.green),
                                                      Icon(Icons.flag,
                                                          color: Colors.green),
                                                    ],
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text(
                                                    'Days: ${group.selectedDays.join(', ')}',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                  Divider(
                                                    color: Colors.green,
                                                    thickness: 1,
                                                    indent: 5,
                                                    endIndent: 5,
                                                  ),
                                                  SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.person,
                                                          color: Colors.green),
                                                      SizedBox(width: 5),
                                                      Text(
                                                          'Created by $userName'),
                                                    ],
                                                  ),
                                                  SizedBox(height: 10),
                                                  // Modified to show members out of availableSeats
                                                  Row(
                                                    children: [
                                                      Icon(Icons.group,
                                                          color: Colors.green),
                                                      SizedBox(width: 5),
                                                      Text(
                                                          'Members: ${group.members.length}/${group.availableSeats}'),
                                                      if (group
                                                              .members.length >=
                                                          group.availableSeats)
                                                        Text(
                                                          ' (FULL)',
                                                          style: TextStyle(
                                                              color: Colors.red,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                    ],
                                                  ),
                                                  // End of modification
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            }
                          },
                        )
                      : Container(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {IconData? icon, bool isTime = false}) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: isTime,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: icon != null ? Icon(icon, color: Colors.green) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: BorderSide(
                  color: Colors.green,
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: BorderSide(
                  color: Colors.green,
                  width: 2.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: BorderSide(
                  color: Colors.green,
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onTap: isTime ? () => _selectTime(context, controller) : null,
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
    }
  }
}
