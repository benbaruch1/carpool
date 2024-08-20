import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpool_app/controllers/create_ride_page_controller.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';
import 'package:carpool_app/widgets/custom_button.dart';

class CreateRidePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("[LOG] Create ride opened ");
    return ChangeNotifierProvider(
      create: (_) => CreateRidePageController(),
      child: _CreateRidePageContent(),
    );
  }
}

class _CreateRidePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<CreateRidePageController>(context);

    return Scaffold(
      appBar: TopBar(
        title: 'Create group',
        showBackButton: true,
      ),
      body: controller.isLoading
          ? Loading()
          : Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _buildTextFieldWithAsterisk('Group name:',
                              controller.rideNameController, true, Icons.group),
                          _buildTextFieldWithAsterisk(
                              'Set first meeting point:',
                              controller.firstMeetingPointController,
                              true,
                              Icons.location_on),
                          if (controller.meetingPointsCount > 1)
                            _buildTextFieldWithAsterisk(
                                'Set second meeting point:',
                                controller.secondMeetingPointController,
                                false,
                                Icons.location_on),
                          if (controller.meetingPointsCount > 2)
                            _buildTextFieldWithAsterisk(
                                'Set third meeting point:',
                                controller.thirdMeetingPointController,
                                false,
                                Icons.location_on),
                          if (controller.meetingPointsCount < 3)
                            TextButton.icon(
                              onPressed: controller.addMeetingPoint,
                              icon: Icon(Icons.add, color: Colors.green),
                              label: Text('Add another meeting point',
                                  style: TextStyle(color: Colors.green)),
                            ),
                          SizedBox(height: 10),
                          _buildSeatsPicker(controller, context),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Text('Please select at least one day:',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              Text('*',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 24)),
                            ],
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: controller.daysOfWeek.map((day) {
                              return ChoiceChip(
                                label: Text(day),
                                selected: controller.selectedDays.contains(day),
                                onSelected: (bool selected) =>
                                    controller.toggleDaySelection(day),
                                shape: RoundedRectangleBorder(
                                  side:
                                      BorderSide(color: Colors.green, width: 2),
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
                          ...controller.selectedDays.map((day) {
                            return Column(
                              children: [
                                Text(day,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                _buildTimePicker(
                                    'Departure time:',
                                    controller.departureTimes[day]!,
                                    context,
                                    controller),
                                _buildTimePicker(
                                    'Return time:',
                                    controller.returnTimes[day]!,
                                    context,
                                    controller),
                                SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
                          SizedBox(height: 20),
                          CustomButton(
                            label: 'Create',
                            onPressed: () => controller.createRide(context),
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
        selectedIndex: controller.selectedIndex,
        onItemTapped: controller.setSelectedIndex,
      ),
    );
  }

  Widget _buildTextFieldWithAsterisk(String label,
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

  Widget _buildTimePicker(String label, TextEditingController controller,
      BuildContext context, CreateRidePageController pageController) {
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
                  onTap: () => pageController.selectTime(context, controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatsPicker(
      CreateRidePageController controller, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car, color: Colors.green),
                    SizedBox(width: 10),
                    Text(
                      'Available Seats',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 0),
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: controller.decrementSeats,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(
                      width: 20,
                      child: Text(
                        controller.availableSeats.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: controller.incrementSeats,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.info, color: Colors.green),
              onPressed: () => controller.showInfoDialog(context),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
