import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final Function onPressed;
  final Color? color; // Optional color parameter

  CustomButton({
    required this.label,
    required this.onPressed,
    this.color, // Initialize color parameter
  });

  @override
  Widget build(BuildContext context) {
    Color buttonColor =
        color ?? Color.fromARGB(255, 85, 171, 88); // Default color
    Color iconColor =
        color ?? Color.fromARGB(255, 102, 205, 136); // Default icon color

    return GestureDetector(
      onTap: () => onPressed(),
      child: Container(
        width: 190, // Adjust width of the button
        height: 55, // Adjust height of the button
        margin: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: buttonColor, // Use the color parameter or default color
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 50), // Adjust padding to move text
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 22, // Adjust font size
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Spacer(), // Add Spacer to push the icon to the right
            Container(
              width: 50, // Adjust size of the icon container
              height: 50, // Adjust size of the icon container
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward,
                color: iconColor, // Use the color parameter or default color
                size: 24, // Adjust size of the icon
              ),
            ),
            SizedBox(width: 3), // Adjust padding to move icon to the left
          ],
        ),
      ),
    );
  }
}
