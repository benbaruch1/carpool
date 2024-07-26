import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carpool_app/views/home_page.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/notification_page.dart';
import 'package:carpool_app/views/myprofile_page.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';
import 'package:carpool_app/widgets/custom_button.dart';

class CreateRidePage extends StatefulWidget {
  @override
  _CreateRidePageState createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  final List<String> daysOfWeek = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];
  final Set<String> selectedDays = {};
  final Map<String, TextEditingController> departureTimes = {};
  final Map<String, TextEditingController> returnTimes = {};

  final TextEditingController _rideNameController = TextEditingController();
  final TextEditingController _firstMeetingPointController =
      TextEditingController();
  final TextEditingController _secondMeetingPointController =
      TextEditingController();
  final TextEditingController _thirdMeetingPointController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _selectedIndex = 0;
  int _meetingPointsCount = 1;

  static List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    MyRidesPage(),
    NotificationPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    for (String day in daysOfWeek) {
      departureTimes[day] = TextEditingController();
      returnTimes[day] = TextEditingController();
    }
  }

  Future<void> _createRide() async {
    if (_formKey.currentState!.validate()) {
      if (selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please select at least one day'),
              duration: Duration(seconds: 2)),
        );
        return;
      }

      // Check if user inserted departure & return time for each selected day
      bool allTimesValid = true;
      selectedDays.forEach((day) {
        if (departureTimes[day]!.text.isEmpty ||
            returnTimes[day]!.text.isEmpty) {
          allTimesValid = false;
        }
      });

      if (!allTimesValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Please select departure and return times for all selected days'),
              duration: Duration(seconds: 2)),
        );
        return;
      }

      Map<String, Map<String, String>> times = {};
      selectedDays.forEach((day) {
        times[day] = {
          'departureTime': departureTimes[day]!.text,
          'returnTime': returnTimes[day]!.text,
        };
      });
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user logged in')),
        );
        return;
      }
      try {
        DocumentReference groupRef =
            await FirebaseFirestore.instance.collection('groups').add({
          'rideName': _rideNameController.text,
          'firstMeetingPoint': _firstMeetingPointController.text,
          'secondMeetingPoint': _secondMeetingPointController.text,
          'thirdMeetingPoint': _thirdMeetingPointController.text,
          'selectedDays': selectedDays.toList(),
          'times': times,
          'userId': user.uid,
          'members': [
            user.uid
          ], // Add the user who created the group as the first member
          'memberPoints': {user.uid: 0}, // Add the user with initial points 0
        });

        // Update the user's collection with array of groups (created by them)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'groups': FieldValue.arrayUnion([groupRef.id])
        });

        sendNotification(
          title: 'Group Created ${_rideNameController.text}.',
          body:
              'You have successfully created the group ${_rideNameController.text}.',
          userId: user.uid,
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Group created successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.lightGreen,
        ));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    }
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _widgetOptions[index]),
    );
  }

  void _addMeetingPoint() {
    if (_meetingPointsCount < 3) {
      setState(() {
        _meetingPointsCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        title: 'Create group',
        showBackButton: true,
      ),
      body: Container(
        color: Colors.white, // Set the background color to white
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    buildTextFieldWithAsterisk(
                        'Group name:', _rideNameController, true, Icons.group),
                    SizedBox(height: 20),
                    buildTextFieldWithAsterisk('Set first meeting point:',
                        _firstMeetingPointController, true, Icons.location_on),
                    if (_meetingPointsCount > 1) SizedBox(height: 20),
                    if (_meetingPointsCount > 1)
                      buildTextFieldWithAsterisk(
                          'Set second meeting point:',
                          _secondMeetingPointController,
                          false,
                          Icons.location_on),
                    if (_meetingPointsCount > 2) SizedBox(height: 20),
                    if (_meetingPointsCount > 2)
                      buildTextFieldWithAsterisk(
                          'Set third meeting point:',
                          _thirdMeetingPointController,
                          false,
                          Icons.location_on),
                    SizedBox(height: 10),
                    if (_meetingPointsCount < 3)
                      TextButton.icon(
                        onPressed: _addMeetingPoint,
                        icon: Icon(Icons.add, color: Colors.green),
                        label: Text(
                          'Add another meeting point',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Please select at least one day:',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        Text(
                          '*',
                          style: TextStyle(color: Colors.red, fontSize: 24),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: daysOfWeek.map((day) {
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
                    SizedBox(height: 20),
                    ...selectedDays.map((day) {
                      return Column(
                        children: [
                          Text("$day",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          buildTimePicker(
                              'Departure time:', departureTimes[day]!),
                          buildTimePicker('Return time:', returnTimes[day]!),
                          SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                    SizedBox(height: 20),
                    CustomButton(
                      label: 'Create',
                      onPressed: _createRide,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
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

  Widget buildTextFieldWithAsterisk(String label,
      TextEditingController controller, bool isRequired, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.green),
              SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (val) {
                    if (isRequired && (val == null || val.isEmpty)) {
                      return 'This field is required';
                    }
                    return null;
                  },
                ),
              ),
              if (isRequired)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    '*',
                    style: TextStyle(color: Colors.red, fontSize: 24),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTimePicker(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Colors.green),
              SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: label,
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onTap: () => _selectTime(context, controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
