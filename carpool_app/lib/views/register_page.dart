import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:carpool_app/views/home_page.dart';
import 'package:carpool_app/views/home_wrapper.dart';
import 'package:carpool_app/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  String email = '';
  String password = '';
  String firstName = '';
  String phoneNumber = '';
  String address = '';
  int availableSeats = 5; // Default value is 5
  String error = '';
  bool loading = false;

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
                    padding: const EdgeInsets.all(16.0),
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
                          buildTextField('First name', (val) {
                            firstName = val;
                          }, 'Enter your first name', false),
                          SizedBox(height: 20),
                          buildTextField('Phone number', (val) {
                            phoneNumber = val;
                          }, 'Enter your phone number', false),
                          SizedBox(height: 20),
                          buildTextField('Address', (val) {
                            address = val;
                          }, 'Enter your address', false),
                          SizedBox(height: 20),
                          buildDropdownField('Available Seats', (val) {
                            availableSeats = int.parse(val!);
                          }, 'Select the number of available seats', false),
                          SizedBox(height: 20),
                          buildTextField('Password', (val) {
                            password = val;
                          }, 'Enter a password 6+ chars long', true),
                          SizedBox(height: 20),
                          CustomButton(
                            label: 'Register',
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => loading = true);
                                dynamic result =
                                    await _auth.registerWithEmailAndPassword(
                                        email,
                                        password,
                                        firstName,
                                        phoneNumber,
                                        address,
                                        availableSeats);
                                if (result == null) {
                                  setState(() {
                                    loading = false;
                                    error =
                                        'Could not register with those credentials';
                                  });
                                } else {
                                  print(
                                      "[LOG] New user registered successfully ${email}");
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) => HomePage()),
                                    (Route<dynamic> route) => false,
                                  );
                                }
                              }
                            },
                          ),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomeWrapper()),
                              );
                            },
                            child: Text(
                              'Already registered? Click to login',
                              style:
                                  TextStyle(color: Colors.green, fontSize: 18),
                            ),
                          ),
                          SizedBox(
                            height: 12.0,
                          ),
                          Text(
                            error,
                            style: TextStyle(color: Colors.red, fontSize: 12.0),
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

  Widget buildDropdownField(String label, Function(String?) onChanged,
      String validatorText, bool obscureText) {
    return DropdownButtonFormField<String>(
      value: availableSeats.toString(),
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
      items: ['1', '2', '3', '4', '5'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null || val.isEmpty ? validatorText : null,
    );
  }
}
