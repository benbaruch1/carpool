import 'package:carpool_app/shared/constants.dart';
import 'package:carpool_app/views/createRide_page.dart';
import 'package:carpool_app/views/searchRide_page.dart';
import 'package:flutter/material.dart';
import 'package:carpool_app/models/user.dart';
import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePageController extends ChangeNotifier {
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;
  bool _loading = false;

  int get selectedIndex => _selectedIndex;
  bool get loading => _loading;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> signOut(BuildContext context) async {
    try {
      setLoading(true);
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('Error signing out: $e');
      // You might want to show an error message to the user here
    } finally {
      setLoading(false);
    }
  }

  Future<MyUser?> getMyUserFromUid(String? uid) async {
    if (uid == null) return null;
    try {
      return await _auth.getMyUserFromUid(uid);
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  void showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About CarPool'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'CarPool is a ride-sharing application designed to help drivers find carpool groups heading to ${Constants.destinationName}. The app enables users to register and log in, with all participants being drivers. Drivers can create new carpool groups or search for existing ones based on criteria such as starting location, schedule, or group creator name.'),
                SizedBox(height: 10),
                Text(
                    'Once a group reaches its maximum number of participants, it is closed to new members. After a group is created, the creator cannot make changes or delete the group but can leave it without affecting its existence. A group is automatically deleted when it has no participants.'),
                SizedBox(height: 10),
                Text(
                    'Each group has a dedicated page where the system calculates the driver for the day based on the lowest points. Drivers earn points each time they drive, and the system selects the next day\'s driver based on the lowest point total.'),
                SizedBox(height: 10),
                Text(
                    'Each group also includes predefined pick-up points, and participants can select their preferred pick-up point.'),
              ],
            ),
          ),
          actions: <Widget>[
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

  void showContactUsDialog(BuildContext context) {
    final TextEditingController _messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact Us'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Please enter your message below:',
              ),
              SizedBox(height: 10),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Your message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Send'),
              onPressed: () {
                final String message = _messageController.text;
                if (message.isNotEmpty) {
                  sendEmail(message);
                  Navigator.of(context).pop();
                } else {
                  // You might want to show an error message here
                  print('Message is empty');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void sendEmail(String message) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'ravidp30@walla.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Contact Us Message from CarPool App',
        'body': message,
      }),
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      print('Could not launch email: $e');
      // You might want to show an error message to the user here
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void navigateToSearchRide(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchRidePage()),
    );
  }

  void navigateToCreateRide(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRidePage()),
    );
  }
}
