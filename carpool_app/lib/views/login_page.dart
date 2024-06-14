import 'package:carpool_app/views/home_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
                //controller: _emailController,
                decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            )),
            SizedBox(height: 16.0),
            TextFormField(
                //controller: _passwordController,
                decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            )),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
