import 'package:carpool_app/services/firebase_auth_service.dart';
import 'package:carpool_app/shared/loading.dart';
import 'package:carpool_app/views/home_page.dart';
import 'package:carpool_app/views/home_wrapper.dart';
import 'package:carpool_app/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:carpool_app/shared/constants.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  String email = '';
  String password = '';
  String confirmPassword = '';
  String firstName = '';
  String phoneNumber = '';
  String address = '';
  int availableSeats = 5; // Default value is 5
  String error = '';
  bool loading = false;
  bool _obscureTextPassword = true;
  bool _obscureTextConfirmPassword = true;
  bool _hasAcknowledged = false;

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
                            setState(() => email = val);
                          }, 'Enter a valid email', false, validateEmail),
                          SizedBox(height: 20),
                          buildTextField('First name', (val) {
                            setState(() => firstName = val);
                          }, 'Enter your first name', false),
                          SizedBox(height: 20),
                          buildTextField('Phone number', (val) {
                            setState(() => phoneNumber = val);
                          }, 'Enter a valid phone number', false,
                              validatePhoneNumber),
                          SizedBox(height: 20),
                          buildTextField(
                              'Address (city -> street -> house number)',
                              (val) {
                            setState(() => address = val);
                          }, 'Enter your address', false),
                          SizedBox(height: 20),
                          buildDropdownField('Available Seats', (val) {
                            setState(() => availableSeats = int.parse(val!));
                          }, 'Select the number of available seats', false,
                              "Info", context),
                          SizedBox(height: 20),
                          buildPasswordField(
                              'Password',
                              (val) {
                                setState(() => password = val);
                              },
                              'Password must be at least 6 characters long',
                              _obscureTextPassword,
                              () {
                                setState(() {
                                  _obscureTextPassword = !_obscureTextPassword;
                                });
                              },
                              validatePasswordLength),
                          SizedBox(height: 20),
                          buildPasswordField(
                              'Confirm Password',
                              (val) {
                                setState(() => confirmPassword = val);
                              },
                              'Passwords do not match',
                              _obscureTextConfirmPassword,
                              () {
                                setState(() {
                                  _obscureTextConfirmPassword =
                                      !_obscureTextConfirmPassword;
                                });
                              },
                              validatePasswordMatch),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Checkbox(
                                value: _hasAcknowledged,
                                onChanged: (value) {
                                  setState(() {
                                    _hasAcknowledged = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => showProjectOverview(context),
                                  child: Text(
                                    "I understand the Carpool app's purpose and features",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          CustomButton(
                            label: 'Register',
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                if (!_hasAcknowledged) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Join Our Driving Community',
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green)),
                                      content: Text(
                                          'To ensure a great experience for everyone, please verify that you\'ve read about how our carpooling system works. Remember, all members are drivers who share rides!'),
                                      actions: [
                                        TextButton(
                                          child: Text('OK',
                                              style: TextStyle(
                                                  color: Colors.green)),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      backgroundColor: Colors.white,
                                      elevation: 5,
                                    ),
                                  );
                                } else {
                                  setState(() => loading = true);
                                  dynamic result =
                                      await _auth.registerWithEmailAndPassword(
                                    email,
                                    password,
                                    firstName,
                                    phoneNumber,
                                    address,
                                    availableSeats,
                                  );
                                  if (result == null) {
                                    setState(() {
                                      loading = false;
                                      error =
                                          'Failed to register. Please check the highlighted fields.';
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
                          SizedBox(height: 12.0),
                          error.isNotEmpty
                              ? Text(
                                  error,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12.0),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  void showProjectOverview(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Carpool Project Overview',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                bulletPoint(
                    "Exclusively for drivers: all users must have a car and be willing to drive"),
                bulletPoint(
                    "Carpool to ${Constants.destinationName} - save money and reduce traffic!"),
                bulletPoint(
                    "Create or join driver groups based on your route and schedule"),
                bulletPoint(
                    "Fair rotation: the app automatically selects each day's driver"),
                bulletPoint("Flexible meet-up locations set by group creators"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          elevation: 5,
        );
      },
    );
  }

  Widget buildTextField(String label, Function(String) onChanged,
      String validatorText, bool obscureText,
      [String? Function(String?)? validator]) {
    return TextFormField(
      onChanged: onChanged,
      initialValue: getInitialValue(label),
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
      validator: validator ?? (val) => val!.isEmpty ? validatorText : null,
    );
  }

  Widget buildPasswordField(String label, Function(String) onChanged,
      String validatorText, bool obscureText, VoidCallback toggleVisibility,
      [String? Function(String?)? validator]) {
    return TextFormField(
      onChanged: onChanged,
      initialValue: getInitialValue(label),
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
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.green,
          ),
          onPressed: toggleVisibility,
        ),
      ),
      obscureText: obscureText,
      validator: validator ?? (val) => val!.isEmpty ? validatorText : null,
    );
  }

  String? validatePasswordMatch(String? value) {
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validatePasswordLength(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || !RegExp(r'^\d+$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Widget buildDropdownField(
      String label,
      Function(String?) onChanged,
      String validatorText,
      bool obscureText,
      String tooltipMessage,
      BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
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
            validator: (val) =>
                val == null || val.isEmpty ? validatorText : null,
          ),
        ),
        SizedBox(width: 2),
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: IconButton(
            icon: Icon(Icons.info_outline, color: Colors.green, size: 20),
            onPressed: _showInfoDialog,
            tooltip: tooltipMessage,
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Available Seats Information',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Select the number of seats available for carpooling:',
                ),
                bulletPoint('Include the driver\'s seat.'),
                bulletPoint('Exclude any baby or child seats.'),
                bulletPoint('Count only seats with seatbelts.'),
                SizedBox(height: 10),
                Text('Examples:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                bulletPoint('5-seater car: Select 5.'),
                bulletPoint('5-seater car with one baby seat: Select 4.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          elevation: 5,
        );
      },
    );
  }

  String getInitialValue(String label) {
    switch (label) {
      case 'Email':
        return email;
      case 'First name':
        return firstName;
      case 'Phone number':
        return phoneNumber;
      case 'Address':
        return address;
      default:
        return '';
    }
  }

  Widget bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
