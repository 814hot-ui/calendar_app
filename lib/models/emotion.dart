import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

// 감정 데이터의 틀을 정의합니다.
class EmotionData {
  final String id;          // 💾 DB 저장용 고유 키 (예: 'stressed', 'angry', 'sad')
  final String translationKey; // 🌐 번역 파일(ko.json, en.json)에 등록된 키 (예: 'emotion_sad')
  final String imagePath;
  final Color color;

  const EmotionData({
    required this.id,
    required this.translationKey,
    required this.imagePath,
    required this.color,
  });

  // UI 화면에 띄울 때만 이 게터를 불러서 보여줍니다.
  String get displayName => translationKey.tr();
}

// 🟢 긍정 감정 세트 (json 파일의 'emoticon_' 키값과 대소문자까지 완벽 매칭!)
final List<EmotionData> positiveEmotions = [
  EmotionData(id: 'happy', translationKey: 'emoticon_happy', imagePath: 'assets/emotions/happy.png', color: Color(0xFFF2D069)),
  EmotionData(id: 'joy', translationKey: 'emoticon_joy', imagePath: 'assets/emotions/joy.png', color: Color(0xFFFF8C6B)),
  EmotionData(id: 'love', translationKey: 'emoticon_love', imagePath: 'assets/emotions/love.png', color: Color(0xFFF09A9D)),
  EmotionData(id: 'proud', translationKey: 'emoticon_proud', imagePath: 'assets/emotions/proud.png', color: Color(0xFFD6AF75)),
  EmotionData(id: 'calm', translationKey: 'emoticon_calm', imagePath: 'assets/emotions/calm.png', color: Color(0xFFA7D1C3)),
];

// 🔴 부정 감정 세트 (json 파일의 'emoticon_' 키값과 대소문자까지 완벽 매칭!)
final List<EmotionData> negativeEmotions = [
  EmotionData(id: 'sad', translationKey: 'emoticon_sad', imagePath: 'assets/emotions/sad.png', color: Color(0xFF5C768D)),
  EmotionData(id: 'stressed', translationKey: 'emoticon_stressed', imagePath: 'assets/emotions/stress.png', color: Color(0xFF7A5141)),
  EmotionData(id: 'angry', translationKey: 'emoticon_angry', imagePath: 'assets/emotions/angry.png', color: Color(0xFF734950)),
  EmotionData(id: 'anxious', translationKey: 'emoticon_anxious', imagePath: 'assets/emotions/anxious.png', color: Color(0xFF6C608A)),
  EmotionData(id: 'tired', translationKey: 'emoticon_tired', imagePath: 'assets/emotions/tired.png', color: Color(0xFF5A5666)),
];

// 🤔 감정 이름만 던지면 그 감정의 색상을 쏙 뽑아주는 편리한 기능
// 💡 [완벽 수정] 이제 언어(한/영)와 상관없이 고유 ID만 던지면 색상을 쏙 뽑아줍니다!
Color getEmotionColor(String emotionId) {
  final allEmotions = [...positiveEmotions, ...negativeEmotions];
  
  final match = allEmotions.firstWhere(
    // 💡 e.name 대신 고유 고정값인 e.id를 비교합니다!
    (e) => e.id == emotionId.trim(), 
    orElse: () => const EmotionData(
      id: '', 
      translationKey: '', 
      imagePath: '', 
      color: Colors.transparent,
    ),
  );
  
  return match.color;
}