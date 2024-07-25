import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpool_app/models/user.dart';
import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:carpool_app/views/home_wrapper.dart';
import 'package:carpool_app/widgets/home_content.dart';
import 'package:carpool_app/views/myprofile_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();
  MyUser? myFullUser;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final myUser = Provider.of<MyUser?>(context);
    print("[LOG] Home page opened with user logged in : ${myUser?.uid}");
    return loading
        ? Loading()
        : HomeContent(
            auth: _auth,
            myUser: myUser,
            myFullUser: myFullUser,
            loading: loading,
            goToMyProfilePage: goToMyProfilePage,
            onLogout: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeWrapper()),
              );
            },
          );
  }

  void goToMyProfilePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    ).then((_) {
      // Refresh the data when coming back from the profile page
      setState(() {});
    });
  }
}

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}
