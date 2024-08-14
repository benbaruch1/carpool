import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carpool_app/widgets/custom_button.dart';
import 'package:carpool_app/shared/loading.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  bool loading = false;
  String email = '';
  String error = '';

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: email.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent')),
        );
        setState(() => loading = false);
      } on FirebaseAuthException catch (e) {
        setState(() {
          loading = false;
          error = e.message ?? 'An error occurred';
        });
      }
    }
  }

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
                    padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.topCenter,
                            child: Column(
                              children: [
                                Text(
                                  'Forgot Password',
                                  style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                Text(
                                  'Enter your email to reset password',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                          buildTextField('Email', (val) {
                            email = val;
                          }, 'Enter your email', false),
                          SizedBox(height: 20),
                          CustomButton(
                            label: 'Reset',
                            onPressed: _resetPassword,
                          ),
                          SizedBox(height: 3),
                          Text(
                            error,
                            style: TextStyle(color: Colors.red, fontSize: 16.0),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Back to Login",
                              style:
                                  TextStyle(color: Colors.green, fontSize: 16),
                            ),
                          ),
                          SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/car_image.png',
                              height: 250,
                            ),
                          ),
                          SizedBox(height: 12.0),
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
