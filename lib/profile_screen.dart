import 'package:flutter/material.dart';
import 'package:smartcare/app_colors.dart';
import 'package:smartcare/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Demo user data
  final Map<String, String> _userData = {
    'name': 'Mohammed Al-Ahmed',
    'email': 'mohammed@example.com',
    'phone': '+966 55 123 4567',
    'address': 'Riyadh, Saudi Arabia',
    'memberSince': 'January 2023',
  };

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'My Requests',
      'subtitle': 'View and track your maintenance requests',
      'icon': Icons.assignment,
      'color': Color(0xFF4C837A),
    },
    {
      'title': 'Personal Information',
      'subtitle': 'Manage your personal details',
      'icon': Icons.person,
      'color': Color(0xFFC3CE28),
    },
    {
      'title': 'Settings',
      'subtitle': 'App preferences and notifications',
      'icon': Icons.settings,
      'color': Color(0xFF377268),
    },
    {
      'title': 'Help & Support',
      'subtitle': 'FAQs and customer support',
      'icon': Icons.help,
      'color': Color(0xFF1A4C44),
    },
    {
      'title': 'About',
      'subtitle': 'App information and version',
      'icon': Icons.info,
      'color': Color(0xFF757575),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.titleColor,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with user information
            Container(
              padding: EdgeInsets.only(top: 20, bottom: 30),
              decoration: BoxDecoration(
                color: AppColors.titleColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      _userData['name']![0],
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  // User Name
                  Text(
                    _userData['name']!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  // User Email
                  Text(
                    _userData['email']!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Member Since Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.iconColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Member since ${_userData['memberSince']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Profile Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _menuItems.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item['color'].withOpacity(0.2),
                        child: Icon(item['icon'], color: item['color']),
                      ),
                      title: Text(
                        item['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.subtitleColor,
                        ),
                      ),
                      subtitle: Text(
                        item['subtitle'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Handle menu item tap
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item['title']} selected'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 30),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  onPressed: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirm Logout'),
                          content: Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.errorColor,
                              ),
                              child: Text('Logout'),
                              onPressed: () {
                                // Navigate to login screen
                                Navigator.of(context).pop();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginScreen()),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // App Version
            Text(
              'App Version 1.0.0',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: 12,
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
