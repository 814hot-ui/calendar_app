import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() => runApp(MaterialApp(home: ImageCalendar()));

class ImageCalendar extends StatefulWidget {
  const ImageCalendar({super.key}); 

  @override
  State<ImageCalendar> createState() => _ImageCalendarState(); 
}

class _ImageCalendarState extends State<ImageCalendar> {
  File? _selectedImage; // 선택된 이미지 파일을 담는 변수
  final ImagePicker _picker = ImagePicker();

  // 갤러리에서 이미지를 가져오는 함수
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('나만의 이미지 달력')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 이미지 표시 영역
            GestureDetector(
              onTap: _pickImage, // 클릭하면 이미지 선택 실행
              child: Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[300],
                child: _selectedImage == null
                    ? Center(child: Text('여기를 눌러 사진을 추가하세요'))
                    : Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            ),
            
            // 2. 달력 영역
            TableCalendar(
              focusedDay: DateTime.now(),
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}