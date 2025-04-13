import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smartcare/app_colors.dart';
import 'package:smartcare/home_screen.dart';
import 'package:smartcare/register_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  Future<void> _login() async {
    final String apiUrl =
        'https://smart-care-backend-i2pg.onrender.com/auth/login';

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('Attempting to connect to: $apiUrl');
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true'
          },
          body: json.encode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print(responseData);

          if (responseData['status'] == 'success') {
            // حفظ بيانات المستخدم في التخزين المحلي
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', responseData['data']['token']);
            await prefs.setString('userId', responseData['data']['userId']);
            await prefs.setString(
                'firstName', responseData['data']['firstName']);
            await prefs.setString('lastName', responseData['data']['lastName']);
            await prefs.setString('email', responseData['data']['email']);
            await prefs.setString(
                'community', responseData['data']['community']);
            await prefs.setString(
                'unitNumber', responseData['data']['unitNumber']);
            await prefs.setString('phone', responseData['data']['phone']);

            // حفظ حالة تذكرني إذا تم اختيارها
            if (_rememberMe) {
              await prefs.setBool('rememberMe', true);
              await prefs.setString('savedEmail', _emailController.text);
            } else {
              await prefs.setBool('rememberMe', false);
              await prefs.remove('savedEmail');
            }

            // عرض رسالة نجاح
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login successful!'),
                backgroundColor: AppColors.successColor,
              ),
            );

            // الانتقال إلى الشاشة الرئيسية
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else {
            print(responseData);
            // عرض رسالة الخطأ
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Login failed'),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        } else {
          // عرض رسالة الخطأ في حالة فشل الاتصال
          final responseData = json.decode(response.body);
          print(responseData);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Login failed'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      } catch (e) {
        print('$e');
        setState(() {
          _isLoading = false;
        });

        // عرض رسالة الخطأ في حالة حدوث استثناء
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error. Please try again.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  // التحقق من حالة تذكرني عند بدء التطبيق
  Future<void> _checkRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _emailController.text = prefs.getString('savedEmail') ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkRememberMe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 150,
                      height: 150,
                    ),
                  ),
                  SizedBox(height: 30),
                  // Welcome Text
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 40),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email, color: AppColors.iconColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock, color: AppColors.iconColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.iconColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.iconColor,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to forgot password
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.titleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.titleColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Sign Up Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AppColors.titleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
