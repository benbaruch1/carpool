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
  String confirmPassword = '';
  String firstName = '';
  String phoneNumber = '';
  String address = '';
  int availableSeats = 5; // Default value is 5
  String error = '';
  bool loading = false;
  bool _obscureTextPassword = true; // Controls password visibility
  bool _obscureTextConfirmPassword =
      true; // Controls confirm password visibility
  bool _hasAcknowledged =
      false; // Tracks if the user has acknowledged the project overview

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            body: Stack(
              children: [
                Container(
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
                                style: TextStyle(
                                    fontSize: 18, color: Colors.black),
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
                              buildTextField('Address', (val) {
                                setState(() => address = val);
                              }, 'Enter your address', false),
                              SizedBox(height: 20),
                              buildDropdownField('Available Seats', (val) {
                                setState(
                                    () => availableSeats = int.parse(val!));
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
                                      _obscureTextPassword =
                                          !_obscureTextPassword;
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
                              CustomButton(
                                label: 'Register',
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    if (!_hasAcknowledged) {
                                      showProjectOverview(context);
                                    } else {
                                      setState(() => loading = true);
                                      dynamic result = await _auth
                                          .registerWithEmailAndPassword(
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
                                        Navigator.of(context)
                                            .pushAndRemoveUntil(
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
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 18),
                                ),
                              ),
                              SizedBox(
                                height: 12.0,
                              ),
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
                if (!_hasAcknowledged)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.6), // Dimmed background
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "CarPool Project Overview",
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  bulletPoint(
                                      "Facilitates carpooling among drivers heading to Ort Braude College."),
                                  bulletPoint(
                                      "Drivers can create or join carpool groups based on specific details like location, available seats, and schedule."),
                                  bulletPoint(
                                      "Groups are closed to new members once they reach their seat capacity."),
                                  bulletPoint(
                                      "The system automatically selects the daily driver based on the lowest point total."),
                                  bulletPoint(
                                      "Participants can choose from predefined pick-up points."),
                                  bulletPoint(
                                      "Groups automatically delete when no participants remain."),
                                ],
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: _hasAcknowledged,
                                    onChanged: (value) {
                                      setState(() {
                                        _hasAcknowledged = value ?? false;
                                      });
                                    },
                                  ),
                                  Text("I have read and understood"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
  }

// Function to display the project overview in a modal
  void showProjectOverview(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('CarPool Project Overview'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                bulletPoint(
                    "Facilitates carpooling among drivers heading to Ort Braude College."),
                bulletPoint(
                    "Drivers can create or join carpool groups based on specific details like location, available seats, and schedule."),
                bulletPoint(
                    "Groups are closed to new members once they reach their seat capacity."),
                bulletPoint(
                    "The system automatically selects the daily driver based on the lowest point total."),
                bulletPoint(
                    "Participants can choose from predefined pick-up points."),
                bulletPoint(
                    "Groups automatically delete when no participants remain."),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _hasAcknowledged,
                  onChanged: (value) {
                    setState(() {
                      _hasAcknowledged = value ?? false;
                    });
                    Navigator.of(context)
                        .pop(); // Close the dialog after acknowledging
                  },
                ),
                Text("I have read and understood"),
              ],
            ),
          ],
        );
      },
    );
  }

  // Function to create a custom text field
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

  // Function to create a custom password field with a visibility toggle button
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

  // Validation to ensure passwords match
  String? validatePasswordMatch(String? value) {
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Validation to ensure the password is at least 6 characters long
  String? validatePasswordLength(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  // Validation for a valid email address
  String? validateEmail(String? value) {
    if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  // Validation for a valid phone number
  String? validatePhoneNumber(String? value) {
    if (value == null || !RegExp(r'^\d+$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // Function to create a dropdown with information about available seats
  Widget buildDropdownField(
    String label,
    Function(String?) onChanged,
    String validatorText,
    bool obscureText,
    String tooltipMessage,
    BuildContext context,
  ) {
    void _showInfoDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Available Seats Information'),
            content: Text(
                'Please choose your number of seats available in your car, including you as a driver.\n'
                'For example, \nif you have 4 seats for passengers, please choose 5 available seats.'),
            actions: <Widget>[
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

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

  // Function to get the initial value fields
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

  // Function to display bullet points
  Widget bulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("• ", style: TextStyle(fontSize: 16)),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
