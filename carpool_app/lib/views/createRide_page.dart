import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateRidePage extends StatefulWidget {
  @override
  _CreateRidePageState createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  final List<String> daysOfWeek = [
    'Sun',
    'Mon',
    'Tues',
    'Wed',
    'Thurs',
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

      //check if user insert departure && return time for each day
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
                  'Please select departure and return times \n for all selected days'),
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
        //
      });
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user logged in')),
        );
        return;
      }
      try {
        DocumentReference rideRef =
            await FirebaseFirestore.instance.collection('rides').add({
          'rideName': _rideNameController.text,
          'firstMeetingPoint': _firstMeetingPointController.text,
          'secondMeetingPoint': _secondMeetingPointController.text,
          'thirdMeetingPoint': _thirdMeetingPointController.text,
          'selectedDays': selectedDays.toList(),
          'times': times,
          'userId': user.uid, //save the user.uid inside the ride info
        });

        //update the user collection with array of rides (made by hem)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'rides': FieldValue.arrayUnion([rideRef.id])
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ride created successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.lightGreen,
        ));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create ride: $e')),
        );
      }
    }
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      controller.text =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create ride'),
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
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Create ride',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    SizedBox(height: 20),
                    buildTextFieldWithAsterisk(
                        'Ride name:', _rideNameController, true),
                    SizedBox(height: 20),
                    buildTextFieldWithAsterisk('Set first meeting point:',
                        _firstMeetingPointController, true),
                    SizedBox(height: 20),
                    buildTextFieldWithAsterisk('Set second meeting point:',
                        _secondMeetingPointController, false),
                    SizedBox(height: 10),
                    buildTextFieldWithAsterisk('Set third meeting point:',
                        _thirdMeetingPointController, false),
                    SizedBox(height: 20),
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
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    ...selectedDays.map((day) {
                      return Column(
                        children: [
                          Text("$day"),
                          buildTimePicker(
                              'Departure time:', departureTimes[day]!),
                          buildTimePicker('Return time:', returnTimes[day]!),
                        ],
                      );
                    }).toList(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _createRide,
                      child: Text('Create new ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                      margin: EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MyRidesPage()),
                              );
                            },
                            child: Column(
                              children: [
                                Icon(Icons.directions_car,
                                    size: 50, color: Colors.green),
                                Text('My rides',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.green)),
                              ],
                            ),
                          ),
                          InkWell(
                            // onTap: () {
                            // Navigator.push(
                            // context,
                            // MaterialPageRoute(builder: (context) => NotificationsPage()),
                            // );
                            // },
                            child: Column(
                              children: [
                                Icon(Icons.notifications,
                                    size: 50, color: Colors.green),
                                Text('Notification',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.green)),
                              ],
                            ),
                          ),
                          InkWell(
                            // onTap: () {
                            // Navigator.push(
                            // context,
                            // MaterialPageRoute(builder: (context) => ProfilePage()),
                            // );
                            // },
                            child: Column(
                              children: [
                                Icon(Icons.person,
                                    size: 50, color: Colors.green),
                                Text('My profile',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: Colors.green, size: 50),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextFieldWithAsterisk(
      String label, TextEditingController controller, bool isRequired) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
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
    );
  }

  Widget buildTimePicker(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            onTap: () => _selectTime(context, controller),
          ),
        ),
      ],
    );
  }
}
