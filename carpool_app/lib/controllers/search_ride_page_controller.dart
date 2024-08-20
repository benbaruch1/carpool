import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carpool_app/models/group.dart';
import 'package:carpool_app/services/database.dart';

class SearchRidePageController extends ChangeNotifier {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController meetingPointController = TextEditingController();
  final TextEditingController departureTimeController = TextEditingController();
  final TextEditingController groupNameController = TextEditingController();
  final List<String> selectedDays = [];
  bool showFullGroups = true;
  Future<List<Group>>? searchResults;
  int selectedIndex = 0;

  final ScrollController scrollController = ScrollController();
  final DatabaseService databaseService =
      DatabaseService(FirebaseAuth.instance.currentUser!.uid);

  void toggleDay(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    notifyListeners();
  }

  void setShowFullGroups(bool value) {
    showFullGroups = value;
    notifyListeners();
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  Future<void> searchRides() async {
    List<Group> results = await databaseService.searchGroups(
      meetingPoint: meetingPointController.text,
      departureTime: departureTimeController.text,
      selectedDays: selectedDays,
      userId: userNameController.text,
      rideName: groupNameController.text,
      showFullGroups: showFullGroups,
    );

    searchResults = Future.value(results);
    notifyListeners();

    if (results.isNotEmpty) {
      Future.delayed(Duration(milliseconds: 200), () {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 150,
          duration: Duration(milliseconds: 10),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void resetSearchFields() {
    userNameController.clear();
    meetingPointController.clear();
    departureTimeController.clear();
    groupNameController.clear();
    selectedDays.clear();
    showFullGroups = true;
    searchResults = null;
    notifyListeners();
  }

  Future<String> fetchUserName(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot['firstName'];
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
}
