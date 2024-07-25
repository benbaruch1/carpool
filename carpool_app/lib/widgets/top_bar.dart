import 'package:flutter/material.dart';
import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:carpool_app/views/home_wrapper.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  TopBar({required this.title, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          : null,
      actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () async {
            await AuthService().signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeWrapper()),
            );
          },
        )
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
