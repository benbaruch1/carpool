import 'package:flutter/material.dart';

class ProfileContent extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneNumberController;
  final TextEditingController emailController;
  final GlobalKey<FormState> formKey;
  final String error;
  final Function onUpdate;

  ProfileContent({
    required this.nameController,
    required this.addressController,
    required this.phoneNumberController,
    required this.emailController,
    required this.formKey,
    required this.error,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(0, 165, 214, 167), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Edit profile',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Personal info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: emailController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        fillColor: Colors.grey.shade300,
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: phoneNumberController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          if (formKey.currentState!.validate()) {
                            onUpdate();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 70, // כאן הוקטן גודל הכפתורים
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 217, 239, 220),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 18, // שינוי גודל הפונט
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      error,
                      style: TextStyle(color: Colors.red, fontSize: 14),
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
}
