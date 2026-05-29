import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cell_data.dart';
import '../models/emotion.dart'; // ✨ 통합 감정 파일 연결

void showEntryDialog({
  required BuildContext context,
  required DateTime date,
  CalendarCellData? existingData,
  required Function(CalendarCellData) onSave,
}) {
  final memoController = TextEditingController(text: existingData?.memo ?? '');
  final ImagePicker picker = ImagePicker();
  File? tempImage = existingData?.image;
  List<String> tempEmotions = List<String>.from(existingData?.emotions ?? []);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          
          // 감정 선택/해제 로직
          void toggleEmotion(String emotionName) {
            setDialogState(() {
              if (tempEmotions.contains(emotionName)) {
                tempEmotions.remove(emotionName);
              } else {
                if (tempEmotions.length >= 3) return;
                tempEmotions.add(emotionName);
              }
            });
          }

          // ✨ [수정] 이모티콘 텍스트 대신 '그림(Asset Image)'을 보여주는 버튼 위젯
          Widget buildEmotionButton(EmotionData emotion) {
            final int selectIndex = tempEmotions.indexOf(emotion.name);
            final bool isSelected = selectIndex != -1;

            return GestureDetector(
              onTap: () => toggleEmotion(emotion.name),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // 선택 시 배경색은 감정의 고유 색상을 연하게(opacity 0.2) 사용
                          color: isSelected 
                              ? emotion.color.withValues(alpha: 0.2)
                              : Colors.grey[100],
                          border: Border.all(
                            color: isSelected ? emotion.color : Colors.grey.shade300,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6), // 그림 주변에 6만큼 예쁘게 여백을 줍니다.
                          child: Image.asset(
                            emotion.imagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // 선택 순위 숫자 표시 (①, ②, ③)
                      if (isSelected)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: emotion.color, // 감정 고유 색상으로 표시
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '${selectIndex + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emotion.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return AlertDialog(
            title: Text('${date.month}월 ${date.day}일 기록'),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.6,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: memoController,
                      decoration: const InputDecoration(hintText: "Today's Memo..."),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    const Text('오늘의 감정 (최대 3개)', 
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    
                    // 🟢 긍정 감정 리스트 (emotion.dart의 데이터를 사용)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: positiveEmotions.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: buildEmotionButton(e),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 🔴 부정 감정 리스트 (emotion.dart의 데이터를 사용)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: negativeEmotions.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: buildEmotionButton(e),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 사진 업로드 영역
                    GestureDetector(
                      onTap: () async {
                        final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setDialogState(() {
                            tempImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: tempImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(tempImage!, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.add_a_photo, size: 30, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newData = CalendarCellData(
                    memo: memoController.text,
                    image: tempImage,
                    emotions: tempEmotions, 
                  );
                  onSave(newData);
                  Navigator.pop(context);
                },
                child: const Text('저장'),
              ),
            ],
          );
        },
      );
    },
  );
}