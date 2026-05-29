import 'package:flutter/material.dart';

// 감정 데이터의 틀을 정의합니다.
class EmotionData {
  final String name;
  final String imagePath; // ✨ 기존 'emoji' 대신 'imagePath'로 변경!
  final Color color;
  final bool isPositive;

  const EmotionData({
    required this.name,
    required this.imagePath, // ✨ 변경!
    required this.color,
    required this.isPositive,
  });
}

// 🟢 긍정 감정 세트 (내가 넣은 그림 파일 이름과 똑같이 적어주세요)
const List<EmotionData> positiveEmotions = [
  EmotionData(name: '행복', imagePath: 'assets/emotions/happy.png', color: Color(0xFFF2D069), isPositive: true),
  EmotionData(name: '즐거움', imagePath: 'assets/emotions/joy.png', color:Color(0xFFFF8C6B), isPositive: true),
  EmotionData(name: '사랑', imagePath: 'assets/emotions/love.png', color: Color(0xFFF09A9D), isPositive: true),
  EmotionData(name: '뿌듯', imagePath: 'assets/emotions/proud.png', color: Color(0xFFD6AF75), isPositive: true),
  EmotionData(name: '평온', imagePath: 'assets/emotions/calm.png', color: Color(0xFFA7D1C3), isPositive: true),
];

// 🔴 부정 감정 세트 (내가 넣은 그림 파일 이름과 똑같이 적어주세요)
const List<EmotionData> negativeEmotions = [
  EmotionData(name: '슬픔', imagePath: 'assets/emotions/sad.png', color: Color(0xFF5C768D), isPositive: false),
  EmotionData(name: '스트레스', imagePath: 'assets/emotions/stress.png', color: Color(0xFF7A5141), isPositive: false),
  EmotionData(name: '화남', imagePath: 'assets/emotions/angry.png', color: Color(0xFF734950), isPositive: false),
  EmotionData(name: '불안', imagePath: 'assets/emotions/anxious.png', color: Color(0xFF6C608A), isPositive: false),
  EmotionData(name: '피곤', imagePath: 'assets/emotions/tired.png', color: Color(0xFF5A5666), isPositive: false),
];

// 🤔 감정 이름만 던지면 그 감정의 색상을 쏙 뽑아주는 편리한 기능
Color getEmotionColor(String emotionName) {
  final allEmotions = [...positiveEmotions, ...negativeEmotions];
  final match = allEmotions.firstWhere(
    (e) => e.name == emotionName,
    orElse: () => const EmotionData(name: '', imagePath: '', color: Colors.transparent, isPositive: true),
  );
  return match.color;
}