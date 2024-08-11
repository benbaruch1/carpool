import 'package:carpool_app/models/user.dart';
import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:carpool_app/views/home_wrapper.dart';
import 'package:carpool_app/views/register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:carpool_app/views/login_page.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<MyUser?>.value(
      initialData: null,
      value: AuthService().user,
      child: MaterialApp(
        title: 'Carpool',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Clash Grotesk Light',
        ),
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomeWrapper(),
          '/login': (context) => LoginPage(),
          '/my_Rides': (context) => MyRidesPage(),
          '/createRides': (context) => MyRidesPage(),
          '/register': (context) => RegisterPage(),
        },
      ),
    );
  }
}
