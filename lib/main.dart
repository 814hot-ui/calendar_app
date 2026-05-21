import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() => runApp(const MaterialApp(home: ImageCalendar()));

class ImageCalendar extends StatefulWidget {
  const ImageCalendar({super.key}); 

  @override
  State<ImageCalendar> createState() => _ImageCalendarState(); 
}

class _ImageCalendarState extends State<ImageCalendar> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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
      resizeToAvoidBottomInset: false, 
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('나만의 이미지 달력', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            // 달력 외곽 테두리
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TableCalendar(
              focusedDay: DateTime.now(),
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              
              // 1. 달력 고유 설정
              rowHeight: 90, // 💡 한 칸이 2단으로 나뉘므로 세로 높이를 넉넉하게 90으로 키웁니다.
              daysOfWeekHeight: 30,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                weekendStyle: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
              ),

              // 💡 중요: 칸 사이의 간격을 없애야 상단바와 격자들이 틈새 없이 딱 붙습니다.
              calendarStyle: const CalendarStyle(
                cellMargin: EdgeInsets.zero, 
              ),

              // 2. ✨ 핵심: 2단 분리 칸을 직접 제작하는 빌더 기능
              calendarBuilders: CalendarBuilders(
                // 💡 평일, 토요일, 일요일을 이 안에서 직접 계산해서 그리도록 통합했습니다.
                defaultBuilder: (context, day, focusedDay) {
                  if (day.weekday == DateTime.sunday) {
                    // 🔴 일요일인 경우: 빨간색 글씨
                    return _buildSplitCell(day, Colors.red.shade700, Colors.grey.shade100);
                  } else if (day.weekday == DateTime.saturday) {
                    // 🔵 토요일인 경우 (DateTime.sat의 오타 방지를 위해 요일값 확인)
                    // day.weekday가 6이면 토요일, 7이면 일요일입니다.
                    return _buildSplitCell(day, Colors.blue.shade700, Colors.grey.shade100);
                  } else {
                    // ⚪ 평일인 경우: 검은색 글씨
                    return _buildSplitCell(day, Colors.black87, Colors.grey.shade100);
                  }
                },
                
                // 오늘 날짜용 칸 빌더 (정상 작동하므로 유지)
                todayBuilder: (context, day, focusedDay) {
                  return _buildSplitCell(day, Colors.blue.shade900, Colors.blue.shade50, isToday: true);
                },
                
                // 이전달/다음달 날짜 칸 빌더 (정상 작동하므로 유지)
                outsideBuilder: (context, day, focusedDay) {
                  return _buildSplitCell(day, Colors.grey.shade400, Colors.grey.shade50, isOutside: true);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🛠️ 공통적으로 쓰일 2단 분리 가상 셀을 만드는 독립 함수입니다.
  Widget _buildSplitCell(DateTime day, Color textColor, Color barBgColor, {bool isToday = false, bool isOutside = false}) {
    return Container(
      // 개별 칸 전체의 바깥 테두리 선 (바둑판 격자 완성)
      decoration: BoxDecoration(
        color: isOutside ? Colors.grey.shade50 : Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Column(
        children: [
          // 1층: 상단 날짜바 (높이 24로 고정, 배경색 부여)
          Container(
            height: 24,
            width: double.infinity,
            padding: const EdgeInsets.only(left: 6, top: 2),
            decoration: BoxDecoration(
              color: barBgColor,
              // 오늘 날짜면 밑줄을 굵은 파란색으로 포인트를 줌
              border: Border(
                bottom: BorderSide(
                  color: isToday ? Colors.blue.shade400 : Colors.grey.shade300, 
                  width: isToday ? 1.5 : 1.0,
                ),
              ),
            ),
            alignment: Alignment.topLeft,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          
          // 2층: 하단 메모 및 이미지 들어갈 칸 (나머지 모든 남은 공간 차지)
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(2),
              // 💡 [임시 뷰] 지금은 샘플 텍스트지만, 나중에 여기에 데이터(메모/사진)를 매핑하게 됩니다.
              child: const Text(
                '', // 여기에 메모나 이미지가 위치하게 됩니다!
                style: TextStyle(fontSize: 10, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}