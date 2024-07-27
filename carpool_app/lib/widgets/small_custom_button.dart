import 'package:flutter/material.dart';

class SmallCustomButton extends StatelessWidget {
  final String label;
  final Function onPressed;
  final Color? color; // Optional color parameter

  SmallCustomButton({
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
        width: 150, // Adjust width of the button
        height: 35, // Adjust height of the button
        //margin: EdgeInsets.symmetric(vertical: 1.0),
        decoration: BoxDecoration(
          color: buttonColor, // Use the color parameter or default color
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 22), // Adjust padding to move text
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16, // Adjust font size
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Spacer(), // Add Spacer to push the icon to the right
            Container(
              width: 30, // Adjust size of the icon container
              height: 30, // Adjust size of the icon container
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
