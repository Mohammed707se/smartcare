import 'package:flutter/material.dart';
import 'dart:math';

import 'package:smartcare/app_colors.dart';
import 'package:smartcare/login_screen.dart'; // Cambiado de home_screen.dart a login_screen.dart

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // أنيميشن للتحكم في توسيع الدائرة
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;

  // أنيميشن للتحكم في توهج المربع
  late AnimationController _glowController;

  // أنيميشن للتحكم في انزلاق المربع من خارج الشاشة
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isAnimating = false; // للتحكم في ظهور الدائرة
  Offset _containerPosition = Offset.zero; // موقع المربع

  final GlobalKey _containerKey = GlobalKey(); // للحصول على موقع المربع

  @override
  void initState() {
    super.initState();

    // تهيئة أنيميشن الانزلاق
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // لضمان أن المربع يبدأ من خارج الشاشة أسفلًا، نستخدم Offset(0, 2)
    // حيث يمثل y=1 نهاية الشاشة، و y=2 يكون خارج الشاشة تمامًا
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 2), // يبدأ من خارج الشاشة أسفلًا
      end: Offset.zero, // ينتهي في الموقع الأصلي
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // الاستماع لنهاية أنيميشن الانزلاق لبدء أنيميشن الدائرة
    _slideController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // الحصول على موقع المربع بعد الانزلاق
        _getContainerPosition();
        setState(() {
          _isAnimating = true;
        });
        _circleController.forward();
      }
    });

    // تهيئة أنيميشن توسيع الدائرة
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    // الاستماع لنهاية أنيميشن الدائرة للانتقال إلى صفحة تسجيل الدخول
    _circleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) =>
                  const LoginScreen()), // Cambiado a LoginScreen
        );
      }
    });

    // تهيئة أنيميشن التوهج
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // بدء أنيميشن الانزلاق
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _circleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // دالة للحصول على موقع المربع على الشاشة
  void _getContainerPosition() {
    // تأكد من أن البناء قد اكتمل قبل الحصول على الموقع
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RenderBox? renderBox =
          _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        Offset position = renderBox.localToGlobal(Offset.zero);
        setState(() {
          _containerPosition = position +
              Offset(renderBox.size.width / 2, renderBox.size.height / 2);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // خلفية كصورة
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/background_image.png'), // استبدلها بصورة الخلفية الخاصة بك
                fit: BoxFit.cover,
              ),
            ),
          ),
          // المحتوى الرئيسي: اللوجو والمربع
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // اللوجو
                Image.asset(
                  'assets/logo.png', // استبدلها بصورة اللوجو الخاصة بك
                  width: 250,
                  height: 250,
                ),
                const SizedBox(
                  height: 20,
                ),
                // انزلاق المربع باستخدام SlideTransition
                SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    key: _containerKey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 24,
                        color: AppColors.titleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // الدائرة المتحركة
          if (_isAnimating)
            AnimatedBuilder(
              animation: _circleAnimation,
              builder: (context, child) {
                double maxRadius = sqrt(
                    pow(MediaQuery.of(context).size.width, 2) +
                        pow(MediaQuery.of(context).size.height, 2));
                double radius = _circleAnimation.value * maxRadius;

                return Positioned(
                  left: _containerPosition.dx - radius,
                  top: _containerPosition.dy - radius,
                  child: Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
