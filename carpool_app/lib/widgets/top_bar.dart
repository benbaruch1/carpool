import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool isGroupDetailsPage;
  final bool isMember;
  final bool isHomePage; // Parameter to determine if it's the home page
  final Future<void> Function()? onLeaveGroup;
  final Future<void> Function()? onJoinGroup;
  final VoidCallback? onReport;
  final VoidCallback? onLogout; // Callback for logout

  TopBar({
    required this.title,
    this.showBackButton = true,
    this.isGroupDetailsPage = false,
    this.isMember = false,
    this.isHomePage = false, // Initialize the new parameter
    this.onLeaveGroup,
    this.onJoinGroup,
    this.onReport,
    this.onLogout, // Initialize the new callback
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          : null,
      actions: [
        if (isHomePage)
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black, size: 20),
            onPressed: () {
              if (onLogout != null) {
                onLogout!();
              }
            },
          ),
        if (isGroupDetailsPage)
          PopupMenuButton<int>(
            icon: Icon(Icons.settings, color: Colors.black, size: 20),
            onSelected: (int value) {
              switch (value) {
                case 0:
                  if (isMember && onLeaveGroup != null) {
                    onLeaveGroup!();
                  } else if (!isMember && onJoinGroup != null) {
                    onJoinGroup!();
                  }
                  break;
                case 1:
                  if (onReport != null) {
                    onReport!();
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<int>(
                value: 0,
                child: _buildPopupMenuItem(
                  icon: isMember ? Icons.exit_to_app : Icons.group_add,
                  text: isMember ? 'Leave Group' : 'Join Group',
                  color: isMember ? Colors.red : Colors.green,
                ),
              ),
              if (isMember)
                PopupMenuItem<int>(
                  value: 1,
                  child: _buildPopupMenuItem(
                    icon: Icons.report,
                    text: 'Report',
                    color: Colors.black,
                  ),
                ),
            ],
            constraints: BoxConstraints(
              minWidth: 120,
              maxWidth: 150,
            ),
          ),
      ],
    );
  }

  Widget _buildPopupMenuItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 8.0,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
