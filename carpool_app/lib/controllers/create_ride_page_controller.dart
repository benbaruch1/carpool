import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carpool_app/controllers/notification_page_controller.dart';

class CreateRidePageController extends ChangeNotifier {
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

  final TextEditingController rideNameController = TextEditingController();
  final TextEditingController firstMeetingPointController =
      TextEditingController();
  final TextEditingController secondMeetingPointController =
      TextEditingController();
  final TextEditingController thirdMeetingPointController =
      TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  int selectedIndex = 0;
  int meetingPointsCount = 1;
  int maxSeats = 5;
  int availableSeats = 5;
  bool isLoading = true;

  CreateRidePageController() {
    for (String day in daysOfWeek) {
      departureTimes[day] = TextEditingController();
      returnTimes[day] = TextEditingController();
    }
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        var userData = snapshot.data() ?? {};
        maxSeats = userData['availableSeats'] ?? 5;
        availableSeats = maxSeats;
      }
    }
    isLoading = false;
    notifyListeners();
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void addMeetingPoint() {
    if (meetingPointsCount < 3) {
      meetingPointsCount++;
      notifyListeners();
    }
  }

  void incrementSeats() {
    if (availableSeats < maxSeats) {
      availableSeats++;
      notifyListeners();
    }
  }

  void decrementSeats() {
    if (availableSeats > 1) {
      availableSeats--;
      notifyListeners();
    }
  }

  void toggleDaySelection(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    notifyListeners();
  }

  Future<void> createRide(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      if (selectedDays.isEmpty) {
        _showSnackBar(context, 'Please select at least one day');
        return;
      }

      if (!_validateTimes()) {
        _showSnackBar(context,
            'Please select departure and return times for all selected days');
        return;
      }

      if (!_validateReturnAfterDeparture()) {
        _showSnackBar(context, 'Return time must be after the departure time');
        return;
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar(context, 'No user logged in');
        return;
      }

      List<String> pickupPoints = [
        firstMeetingPointController.text,
        if (secondMeetingPointController.text.isNotEmpty)
          secondMeetingPointController.text,
        if (thirdMeetingPointController.text.isNotEmpty)
          thirdMeetingPointController.text,
      ];

      String? selectedPickupPoint =
          await _showPickupPointDialog(context, pickupPoints);

      if (selectedPickupPoint == null) {
        _showSnackBar(context, 'Please select a pickup point');
        return;
      }

      try {
        await _saveRideToFirestore(user, selectedPickupPoint);
        _showSnackBar(context, 'Group created successfully!',
            backgroundColor: Colors.lightGreen);
        Navigator.pop(context);
      } catch (e) {
        _showSnackBar(context, 'Failed to create group: $e');
      }
    }
  }

  bool _validateTimes() {
    return selectedDays.every((day) =>
        departureTimes[day]!.text.isNotEmpty &&
        returnTimes[day]!.text.isNotEmpty);
  }

  bool _validateReturnAfterDeparture() {
    return selectedDays.every((day) {
      TimeOfDay departureTime = _parseTime(departureTimes[day]!.text);
      TimeOfDay returnTime = _parseTime(returnTimes[day]!.text);
      return _isReturnAfterDeparture(departureTime, returnTime);
    });
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isReturnAfterDeparture(TimeOfDay departureTime, TimeOfDay returnTime) {
    return returnTime.hour > departureTime.hour ||
        (returnTime.hour == departureTime.hour &&
            returnTime.minute > departureTime.minute);
  }

  void _showSnackBar(BuildContext context, String message,
      {Color backgroundColor = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<String?> _showPickupPointDialog(
      BuildContext context, List<String> pickupPoints) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Pickup Point'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: pickupPoints.map((point) {
              return ListTile(
                title: Text(point),
                onTap: () {
                  Navigator.of(context).pop(point);
                },
              );
            }).toList(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        );
      },
    );
  }

  Future<void> _saveRideToFirestore(
      User user, String selectedPickupPoint) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    int maxSeats = snapshot.data()?['availableSeats'] ?? 5;

    if (availableSeats > maxSeats) {
      throw Exception('Selected seats exceed available seats');
    }

    Map<String, Map<String, String>> times = {};
    selectedDays.forEach((day) {
      times[day] = {
        'departureTime': departureTimes[day]!.text,
        'returnTime': returnTimes[day]!.text,
      };
    });

    DocumentReference groupRef =
        await FirebaseFirestore.instance.collection('groups').add({
      'rideName': rideNameController.text,
      'firstMeetingPoint': firstMeetingPointController.text,
      'secondMeetingPoint': secondMeetingPointController.text,
      'thirdMeetingPoint': thirdMeetingPointController.text,
      'selectedDays': selectedDays.toList(),
      'times': times,
      'userId': user.uid,
      'nextDriver': user.uid,
      'members': [user.uid],
      'memberPoints': {user.uid: 0},
      'pickupPoints': {user.uid: selectedPickupPoint},
      'availableSeats': availableSeats,
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'groups': FieldValue.arrayUnion([groupRef.id])
    });

    NotificationPageController.sendNotification(
      title: 'Group Created ${rideNameController.text}',
      body:
          'You have successfully created the group ${rideNameController.text}.',
      userId: user.uid,
    );
  }

  Future<void> selectTime(
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
      notifyListeners();
    }
  }

  void showMeetingPointsInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Meeting Points Information',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                    'Important considerations for setting your meeting points:'),
                _bulletPoint(
                    'Choose locations that are easily identifiable and accessible.'),
                _bulletPoint(
                    'The meeting points should be convenient and relatively central for all group members.'),
                _bulletPoint(
                    'Ensure the locations have reasonable parking or pick-up/drop-off areas.'),
                SizedBox(height: 10),
                Text('Key rules:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                _bulletPoint(
                    'Once a group is created, these points are fixed and cannot be changed.'),
                _bulletPoint(
                    'Passengers can be picked up or dropped off only at these designated points.'),
                _bulletPoint(
                    'Upon joining a group, each member can choose one station from the available meeting points.'),
                SizedBox(height: 10),
                Text('Examples of suitable locations:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                _bulletPoint(
                    'Public parking lots, central landmarks, or main intersections.'),
                _bulletPoint(
                    'Locations that are easy to reach by all members and have low traffic.'),
                _bulletPoint('Kiryat Bialik, Derekh Akko Haifa, 192 '),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          elevation: 5,
        );
      },
    );
  }

  void showSeatsInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Available Seats Information',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Select the number of seats available for carpooling:'),
                _bulletPoint('Include the driver\'s seat.'),
                _bulletPoint('Exclude any baby or child seats.'),
                _bulletPoint('Count only seats with seatbelts.'),
                SizedBox(height: 10),
                Text('Examples:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                _bulletPoint('5-seater car: Select 5.'),
                _bulletPoint('5-seater car with one baby seat: Select 4.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          elevation: 5,
        );
      },
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
