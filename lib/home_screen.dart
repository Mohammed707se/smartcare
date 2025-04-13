// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare/app_colors.dart';
import 'package:smartcare/profile_screen.dart';
import 'package:smartcare/track_reports_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _firstName = '';
  String _lastName = '';
  String _phone = '';
  String _community = '';
  String _unitNumber = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('firstName') ?? '';
      _lastName = prefs.getString('lastName') ?? '';
      _phone = prefs.getString('phone') ?? '';
      _community = prefs.getString('community') ?? '';
      _unitNumber = prefs.getString('unitNumber') ?? '';
    });
    print(_phone);
  }

  Future<void> _showCallDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Call Options"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose how you would like to receive the call",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              if (_phone.isNotEmpty)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.titleColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await _makeApiCall(_phone);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text("Call initiated to your registered number"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text("Use my registered number: $_phone"),
                ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: AppColors.titleColor,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showCustomNumberDialog(context);
                },
                child: Text("Use a different number"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCustomNumberDialog(BuildContext context) async {
    TextEditingController phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Enter Your Number"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Please enter your number with country code to receive a call.",
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "e.g., +966554609631",
                  labelText: "Phone Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.titleColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.titleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("Call"),
              onPressed: () async {
                if (phoneController.text.isNotEmpty) {
                  await _makeApiCall(phoneController.text);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Call initiated"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Display an error message if the field is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Please enter a valid phone number."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _makeApiCall(String phoneNumber) async {
    final url =
        // Uri.parse('https://ce44-46-153-121-70.ngrok-free.app/make-call');
        Uri.parse('https://smart-care-backend-i2pg.onrender.com/make-call');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true"
      },
      body: jsonEncode({"to": phoneNumber}),
    );

    if (response.statusCode == 200) {
      print("Call request successful");
    } else {
      print("Failed to make call: ${response.statusCode}");
      print("Failed to make call: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // تحديد التحية استنادًا إلى وقت اليوم
    String greeting = 'Good Morning 👋';
    final hour = DateTime.now().hour;
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon 👋';
    } else if (hour >= 17) {
      greeting = 'Good Evening 👋';
    }

    // استخدام الاسم المحمل من SharedPreferences
    String displayName = _firstName.isNotEmpty ? _firstName : 'User';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/person_logo.png',
              width: 50,
              height: 50,
            ),
            SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    color: AppColors.iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  displayName,
                  style: TextStyle(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.start,
                )
              ],
            )
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: IconButton(
              onPressed: () {
                // Navigate to profile screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                ).then((_) => _loadUserData()); // تحديث البيانات عند العودة
              },
              icon: Image.asset(
                'assets/settings.png',
                width: 30,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'search',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.titleColor,
                      ),
                      // suffixIcon: Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: SvgPicture.asset(
                      //     'assets/filter.svg',
                      //   ),
                      // ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Our Services',
                      style: TextStyle(
                        color: AppColors.subtitleColor,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: Offset(0, 5),
                            blurRadius: 10,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/Notification.png',
                      width: 30,
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showCallDialog(context);
                      },
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Color(0xffF4F4F4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/sppourt.png',
                                width: 50,
                              ),
                              SizedBox(
                                height: 25,
                              ),
                              Text(
                                'Smart Call',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.titleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Color(0xffF4F4F4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/chatbot_svgrepo.png',
                                width: 50,
                              ),
                              SizedBox(
                                height: 25,
                              ),
                              Text(
                                'Smart Chat',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.titleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navegar a la pantalla de seguimiento de reportes
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrackReportsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Color(0xffF4F4F4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/Frequent.png',
                                width: 50,
                              ),
                              SizedBox(
                                height: 13,
                              ),
                              Text(
                                'Track Reports',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.titleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
