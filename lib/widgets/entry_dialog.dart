import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import '../models/cell_data.dart';

// ✨ 외부에서 이 창을 띄울 수 있도록 독립된 함수로 정의합니다.
void showEntryDialog({
  required BuildContext context,
  required DateTime date,
  required CalendarCellData? existingData,
  required Function(CalendarCellData) onSave, // 💡 저장이 완료되면 main.dart에 데이터를 넘겨줄 콜백 함수
}) {
  final TextEditingController memoController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  
  // 기존 데이터가 있다면 채워넣기
  memoController.text = existingData?.memo ?? "";
  File? tempImage = existingData?.image;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('${date.month}월 ${date.day}일 기록'),
            content: SingleChildScrollView( // 키보드가 올라올 때 대비해 스크롤뷰 장착
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: memoController,
                    decoration: const InputDecoration(hintText: "오늘의 메모를 적어주세요"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
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
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: tempImage != null
                          ? Image.file(tempImage!, fit: BoxFit.cover)
                          : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  // 💡 새 데이터를 세트로 묶어서 위로 던져줍니다.
                  final newData = CalendarCellData(
                    memo: memoController.text,
                    image: tempImage,
                  );
                  onSave(newData); // main.dart의 setState 실행 유도
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