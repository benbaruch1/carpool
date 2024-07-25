import 'package:carpool_app/models/group.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    );

    setState(() {
      _searchResults = Future.value(results);
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
                          });
                        },
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
                      Text('Show full groups (5/5 members)'),
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
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 15),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(15),
                                      title: Text(
                                        group.rideName,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'First Meeting Point: ${group.firstMeetingPoint}'),
                                          Text(
                                              'Second Meeting Point: ${group.secondMeetingPoint}'),
                                          Text(
                                              'Third Meeting Point: ${group.thirdMeetingPoint}'),
                                        ],
                                      ),
                                      trailing: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                                'Members: ${group.members.length}/5'),
                                            if (group.members.length < 5)
                                              TextButton(
                                                child: Text('JOIN'),
                                                onPressed: () {
                                                  _navigateToGroupPage(
                                                      context, group);
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                ),
                                              ),
                                            if (group.members.length >= 5)
                                              Text(
                                                'FULL',
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        _navigateToGroupPage(context, group);
                                      },
                                    ),
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
