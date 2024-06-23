import 'package:carpool_app/models/user.dart';
import 'package:carpool_app/views/home_page.dart';
import 'package:carpool_app/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final myUser = Provider.of<MyUser?>(context);
    print("Home_wrapper Launched\n[LOG] User is: ${myUser?.email}");

    return myUser == null ? LoginPage() : HomePage();
  }
}
