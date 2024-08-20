import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpool_app/models/user.dart';
import 'package:carpool_app/controllers/home_page_controller.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:carpool_app/views/myprofile_page.dart';
import 'package:carpool_app/views/myRides_page.dart';
import 'package:carpool_app/views/notification_page.dart';
import 'package:carpool_app/widgets/top_bar.dart';
import 'package:carpool_app/widgets/bottom_bar.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomePageController(),
      child: _HomePageContent(),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  final List<Widget> _widgetOptions = <Widget>[
    MyRidesPage(),
    NotificationPage(),
    ProfilePage(),
  ];

  static const List<String> _titles = <String>[
    'Home',
    'My Rides',
    'Notifications',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomePageController>(context);
    final myUser = Provider.of<MyUser?>(context);

    return controller.loading
        ? Loading()
        : Scaffold(
            appBar: TopBar(
              title: _titles[controller.selectedIndex],
              showBackButton: false,
              isHomePage: true,
              onLogout: () => controller.signOut(context),
            ),
            body: controller.selectedIndex == 0
                ? _buildHomePage(context, myUser)
                : _widgetOptions.elementAt(controller.selectedIndex - 1),
            bottomNavigationBar: BottomBar(
              selectedIndex: controller.selectedIndex,
              onItemTapped: controller.setSelectedIndex,
            ),
            drawer: _buildDrawer(context, controller),
          );
  }

  Widget _buildDrawer(BuildContext context, HomePageController controller) {
    return Drawer(
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green,
                ),
                child: Text(
                  'Carpool',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  controller.showAboutDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.contact_mail),
                title: Text('Contact Us'),
                onTap: () {
                  Navigator.pop(context);
                  controller.showContactUsDialog(context);
                },
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => controller.signOut(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(BuildContext context, MyUser? myUser) {
    final controller = Provider.of<HomePageController>(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FutureBuilder<MyUser?>(
                  future: controller.getMyUserFromUid(myUser?.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Text('User data not found');
                    } else {
                      return _buildWelcomeCard(
                        'Welcome, ${snapshot.data!.firstName}',
                      );
                    }
                  },
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildSquareButton(
                        context,
                        label: 'Find a Ride',
                        iconAsset: 'assets/search.png',
                        onTap: () => controller.navigateToSearchRide(context),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _buildSquareButton(
                        context,
                        label: 'Create a Ride',
                        iconAsset: 'assets/create.png',
                        onTap: () => controller.navigateToCreateRide(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/home.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(String message) {
    return Container(
      padding: EdgeInsets.all(7),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 20, color: Colors.green),
          SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareButton(BuildContext context,
      {required String label,
      required Function() onTap,
      IconData? icon,
      String? iconAsset}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 150,
        margin: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 217, 239, 220),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconAsset != null)
              Image.asset(iconAsset, width: 70, height: 70)
            else if (icon != null)
              Icon(icon, size: 50, color: Colors.green),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
