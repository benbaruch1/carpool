import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final Set<String> selectedDays = {};
  bool _showFullGroups = true;
  Future<List<DocumentSnapshot>>? _searchResults;

  Future<void> _searchRides() async {
    List<DocumentSnapshot> results = [];

    bool searchedByUserName = false;
    bool searchedByMeetingPoint = false;

    // search by user name
    if (_userNameController.text.isNotEmpty) {
      searchedByUserName = true;

      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('firstName', isEqualTo: _userNameController.text)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userSnapshot.docs.first;
        List<dynamic> rideIds = userDoc['groups'];

        for (var rideId in rideIds) {
          DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
              .collection('groups')
              .doc(rideId)
              .get();
          if (groupSnapshot.exists) {
            results.add(groupSnapshot);
          }
        }
      }
    }

    // search by meeting point
    if (_meetingPointController.text.isNotEmpty) {
      searchedByMeetingPoint = true;

      QuerySnapshot groupsSnapshot =
          await FirebaseFirestore.instance.collection('groups').get();

      List<DocumentSnapshot> meetingPointResults = [];
      for (var groupDoc in groupsSnapshot.docs) {
        if (groupDoc['firstMeetingPoint'] == _meetingPointController.text ||
            groupDoc['secondMeetingPoint'] == _meetingPointController.text ||
            groupDoc['thirdMeetingPoint'] == _meetingPointController.text) {
          meetingPointResults.add(groupDoc);
        }
      }

      // search by meeting point && by user name
      if (searchedByUserName) {
        results = results
            .where((ride) => meetingPointResults
                .any((meetingPointRide) => meetingPointRide.id == ride.id))
            .toList();
      } else {
        results = meetingPointResults;
      }
    }

    // empty search
    if (!searchedByUserName && !searchedByMeetingPoint) {
      QuerySnapshot groupsSnapshot =
          await FirebaseFirestore.instance.collection('groups').get();
      results = groupsSnapshot.docs;
    }

    setState(() {
      _searchResults = Future.value(results);
    });
  }

  void _showRideDetails(BuildContext context, DocumentSnapshot ride) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(ride['rideName']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRichText(
                  'First Meeting Point: ', ride['firstMeetingPoint']),
              _buildRichText(
                  'Second Meeting Point: ', ride['secondMeetingPoint']),
              _buildRichText(
                  'Third Meeting Point: ', ride['thirdMeetingPoint']),
              _buildRichText(
                  'Selected Days: ', ride['selectedDays'].join(', ')),
              ...ride['selectedDays'].map<Widget>((day) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$day:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                        '  Departure Time: ${ride['times'][day]['departureTime']}'),
                    Text('  Return Time: ${ride['times'][day]['returnTime']}'),
                  ],
                );
              }).toList(),
              Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...ride['members'].map<Widget>((member) {
                bool isCreator = member == ride['userId'];
                return Row(
                  children: [
                    if (isCreator) Icon(Icons.star, color: Colors.green),
                    FutureBuilder<DocumentSnapshot>(
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
                          String memberName =
                              snapshot.data!['firstName'] ?? 'Unknown';
                          return Text(memberName,
                              style: TextStyle(
                                  color:
                                      isCreator ? Colors.green : Colors.black));
                        }
                      },
                    ),
                  ],
                );
              }).toList(),
            ],
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

  static Widget _buildRichText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.black),
        children: [
          TextSpan(
            text: label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search a ride'),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Search a ride',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextField('User name:', _userNameController),
                  SizedBox(height: 10),
                  _buildTextField('Meeting point:', _meetingPointController),
                  SizedBox(height: 10),
                  Text(
                    'Schedule:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 10,
                    children: [
                      'Sun',
                      'Mon',
                      'Tues',
                      'Wed',
                      'Thurs',
                      'Fri',
                      'Sat'
                    ].map((day) {
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
                      isTime: true),
                  SizedBox(height: 10),
                  _buildTextField('Ride name:', _rideNameController),
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
                  ElevatedButton(
                    onPressed: _searchRides,
                    child: Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 20),
                  _searchResults != null
                      ? FutureBuilder<List<DocumentSnapshot>>(
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
                                  DocumentSnapshot ride = snapshot.data![index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 15),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(15),
                                      title: Text(
                                        ride['rideName'],
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'First Meeting Point: ${ride['firstMeetingPoint']}'),
                                          Text(
                                              'Second Meeting Point: ${ride['secondMeetingPoint']}'),
                                          Text(
                                              'Third Meeting Point: ${ride['thirdMeetingPoint']}'),
                                        ],
                                      ),
                                      trailing: Text(
                                          'Members: ${ride['members'].length}/5'),
                                      onTap: () {
                                        _showRideDetails(context, ride);
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
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.green, size: 50),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isTime = false}) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: isTime,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
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
