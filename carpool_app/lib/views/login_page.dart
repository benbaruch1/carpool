import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:carpool_app/views/register_page.dart';
import 'package:carpool_app/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:carpool_app/shared/loading.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  bool loading = false;
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(0, 165, 214, 167),
                    Colors.white
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 64.0, 16.0, 16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Carpool',
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          Text(
                            'Match, Drive, Share',
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                          SizedBox(height: 20),
                          buildTextField('Email', (val) {
                            email = val;
                          }, 'Enter an email', false),
                          SizedBox(height: 20),
                          buildTextField('Password', (val) {
                            password = val;
                          }, 'Enter a password 6+ chars long', true),
                          SizedBox(height: 20),
                          CustomButton(
                            label: 'Sign in',
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => loading = true);
                                dynamic result =
                                    await _auth.signInWithEmailAndPassword(
                                        email, password);
                                if (result == null) {
                                  setState(() {
                                    loading = false;
                                    error =
                                        'Could not sign in with those credentials';
                                  });
                                }
                              }
                            },
                          ),
                          SizedBox(height: 10),
                          Text(
                            error,
                            style: TextStyle(color: Colors.red, fontSize: 16.0),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RegisterPage()),
                              );
                            },
                            child: Text(
                              "Don't have an account? Sign up",
                              style:
                                  TextStyle(color: Colors.green, fontSize: 16),
                            ),
                          ),
                          SizedBox(height: 30),
                          Image.asset(
                            'assets/car_image.png',
                            height: 300,
                          ),
                          SizedBox(
                            height: 12.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  Widget buildTextField(String label, Function(String) onChanged,
      String validatorText, bool obscureText) {
    return TextFormField(
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
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
        fillColor: Colors.white,
      ),
      obscureText: obscureText,
      validator: (val) => val!.isEmpty ? validatorText : null,
    );
  }
}
