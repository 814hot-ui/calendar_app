import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'main.dart'; // 💡 메인 달력(ImageCalendar)이 선언된 곳입니다.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // ⏳ 2초 동안 정중앙의 로고를 보여준 뒤 메인 달력 화면으로 자동 전환합니다.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ImageCalendar(), // 💡 메인 화면으로 이동
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🟢 요청하신 완전한 하얀 바탕화면
      backgroundColor: Colors.white, 
      body: Center(
        child: Text(
          'app_title'.tr(), // 💡 기존 다국어 키를 그대로 활용해 'Biscuit Calendar 🐾'를 출력합니다.
          style: GoogleFonts.quicksand(
            fontSize: 28.0,               // 정중앙에서 존재감을 드러내는 큼직한 크기
            fontWeight: FontWeight.w700,  // 기하학 산세리프 특유의 도톰하고 이쁜 굵기
            color: const Color(0xFF2D2D2D), // 세련된 소프트 블랙 (너무 진한 검은색보다 고급스러움)
            letterSpacing: -0.5,          // 자간을 아주 미세하게 좁혀서 '로고' 같은 밀도감을 줍니다.
          ),
        ),
      ),
    );
  }
}