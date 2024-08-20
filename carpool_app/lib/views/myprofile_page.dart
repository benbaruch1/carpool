import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpool_app/controllers/profile_page_controller.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:carpool_app/widgets/custom_button.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("[LOG] my profile opened ");
    return ChangeNotifierProvider(
      create: (_) => ProfilePageController(),
      child: _ProfilePageContent(),
    );
  }
}

class _ProfilePageContent extends StatefulWidget {
  @override
  _ProfilePageContentState createState() => _ProfilePageContentState();
}

class _ProfilePageContentState extends State<_ProfilePageContent> {
  @override
  void initState() {
    super.initState();
    // Initialize data when the widget is inserted into the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfilePageController>(context, listen: false)
          .initializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProfilePageController>(context);

    return Scaffold(
      appBar: TopBar(title: 'My Profile', showBackButton: false),
      body: controller.isLoading
          ? Loading()
          : controller.error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(controller.error),
                      ElevatedButton(
                        onPressed: () => controller.initializeData(),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildProfileForm(context, controller),
      bottomNavigationBar: BottomBar(
        selectedIndex: controller.selectedIndex,
        onItemTapped: controller.setSelectedIndex,
      ),
    );
  }

  Widget _buildProfileForm(
      BuildContext context, ProfilePageController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color.fromARGB(0, 165, 214, 167), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Edit profile',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Personal info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: controller.email,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      fillColor: Colors.grey.shade300,
                      filled: true,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: controller.name,
                    decoration: InputDecoration(
                      labelText: 'Name',
                    ),
                    onChanged: (value) =>
                        controller.updateFormField('name', value),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: controller.phoneNumber,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                    ),
                    onChanged: (value) =>
                        controller.updateFormField('phoneNumber', value),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: controller.address,
                    decoration: InputDecoration(
                      labelText: 'Address',
                    ),
                    onChanged: (value) =>
                        controller.updateFormField('address', value),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: controller.availableSeats,
                          decoration: InputDecoration(
                            labelText: 'Available Seats',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.green),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.green),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.green),
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(0, 255, 255, 255),
                          ),
                          items: [1, 2, 3, 4, 5].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              controller.updateFormField('availableSeats', val),
                          validator: (val) => val == null
                              ? 'Select the number of available seats'
                              : null,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.info, color: Colors.green),
                        onPressed: () => _showInfoDialog(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: CustomButton(
                      label: 'Update',
                      onPressed: () => controller.updateProfile(context),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    controller.error,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
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
