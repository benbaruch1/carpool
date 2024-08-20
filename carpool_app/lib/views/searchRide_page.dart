import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpool_app/controllers/search_ride_page_controller.dart';
import 'package:carpool_app/models/group.dart';
import 'package:carpool_app/views/group_page.dart';
import 'package:carpool_app/widgets/custom_button.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchRidePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("[LOG] Search page opened");
    return ChangeNotifierProvider(
      create: (_) => SearchRidePageController(),
      child: _SearchRidePageContent(),
    );
  }
}

class _SearchRidePageContent extends StatelessWidget {
  void _navigateToGroupPage(BuildContext context, Group group) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    bool? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GroupPage(group: group, currentUserId: currentUserId),
      ),
    );

    if (result == true) {
      Provider.of<SearchRidePageController>(context, listen: false)
          .searchRides();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SearchRidePageController>(context);

    return Scaffold(
      appBar: TopBar(title: 'Search a ride', showBackButton: false),
      body: Container(
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            controller: controller.scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20),
                  _buildTextField('Group name:', controller.groupNameController,
                      icon: Icons.directions_car),
                  SizedBox(height: 10),
                  _buildTextField(
                      'User\'s first name:', controller.userNameController,
                      icon: Icons.person),
                  SizedBox(height: 10),
                  _buildTextField(
                      'Meeting point:', controller.meetingPointController,
                      icon: Icons.location_on),
                  SizedBox(height: 10),
                  Text('Schedule:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 10,
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map((day) {
                      return ChoiceChip(
                        label: Text(day),
                        selected: controller.selectedDays.contains(day),
                        onSelected: (bool selected) =>
                            controller.toggleDay(day),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Colors.transparent,
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: controller.selectedDays.contains(day)
                              ? Colors.white
                              : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  _buildTextField(
                      'Departure time:', controller.departureTimeController,
                      icon: Icons.access_time, isTime: true, context: context),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: controller.showFullGroups,
                        onChanged: (bool? value) =>
                            controller.setShowFullGroups(value ?? true),
                      ),
                      Text('Show also full groups '),
                      Spacer(),
                      ElevatedButton(
                        onPressed: controller.resetSearchFields,
                        child: Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(70, 0, 255, 0),
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  CustomButton(
                    label: 'Search',
                    onPressed: controller.searchRides,
                  ),
                  SizedBox(height: 20),
                  _buildSearchResults(controller),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(
        selectedIndex: controller.selectedIndex,
        onItemTapped: controller.setSelectedIndex,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {IconData? icon, bool isTime = false, BuildContext? context}) {
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
                borderSide: BorderSide(color: Colors.green, width: 2.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: BorderSide(color: Colors.green, width: 2.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: BorderSide(color: Colors.green, width: 2.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onTap: isTime && context != null
                ? () => Provider.of<SearchRidePageController>(context,
                        listen: false)
                    .selectTime(context, controller)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(SearchRidePageController controller) {
    if (controller.searchResults == null) {
      return Container();
    }

    return FutureBuilder<List<Group>>(
      future: controller.searchResults,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No rides found');
        } else {
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Group group = snapshot.data![index];
              return FutureBuilder<String>(
                future: controller.fetchUserName(group.userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (userSnapshot.hasError) {
                    return Text('Error: ${userSnapshot.error}');
                  } else {
                    String userName = userSnapshot.data!;
                    return _buildGroupCard(context, group, userName);
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, Group group, String userName) {
    return GestureDetector(
      onTap: () => _navigateToGroupPage(context, group),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side: BorderSide(color: Colors.green, width: 2),
        ),
        child: Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 217, 239, 220),
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.rideName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Wrap(
                children: [
                  Text(group.firstMeetingPoint),
                  if (group.secondMeetingPoint.isNotEmpty)
                    Icon(Icons.arrow_forward, color: Colors.green),
                  if (group.secondMeetingPoint.isNotEmpty)
                    Text(group.secondMeetingPoint),
                  if (group.thirdMeetingPoint.isNotEmpty)
                    Icon(Icons.arrow_forward, color: Colors.green),
                  if (group.thirdMeetingPoint.isNotEmpty)
                    Text(group.thirdMeetingPoint),
                  Icon(Icons.arrow_forward, color: Colors.green),
                  Icon(Icons.flag, color: Colors.green),
                ],
              ),
              SizedBox(height: 10),
              Text('Days: ${group.selectedDays.join(', ')}',
                  style: TextStyle(fontSize: 16)),
              Divider(
                  color: Colors.green, thickness: 1, indent: 5, endIndent: 5),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.green),
                  SizedBox(width: 5),
                  Text('Created by $userName'),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.group, color: Colors.green),
                  SizedBox(width: 5),
                  Text(
                      'Members: ${group.members.length}/${group.availableSeats}'),
                  if (group.members.length >= group.availableSeats)
                    Text(' (FULL)',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
