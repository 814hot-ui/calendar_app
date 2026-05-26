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
  // ✨ [추가] 텍스트 입력창을 조종할 리모컨
  final TextEditingController _memoController = TextEditingController();

  // ✨ [추가] 달력에서 선택된 날짜들을 기억할 변수 2개
  DateTime _focusedDay = DateTime.now();  // 현재 화면에 보여지는 달(Month) 기준 날짜
  DateTime? _selectedDay;                 // 사용자가 마우스나 손가락으로 콕 집은 날짜

  // ✨ [추가] 날짜(DateTime)를 열쇠로 삼아 데이터(CalendarCellData)를 저장하는 진짜 창고
  Map<DateTime, CalendarCellData> _calendarData = {};

  // ✨ [추가] 시/분/초를 제하고 '년/월/일' 데이터만 남겨주는 함수
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

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
        title: const Text('BiscuitCalendar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0, top: 0.0),
            child: Container(
              // 달력 외곽 테두리
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2099, 12, 31),

                // ✨ [추가] 2. 날짜를 클릭했을 때 일어날 일(이벤트)을 적어줍니다.
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                // ✨ [대폭 개선] 날짜를 '꾹~ 길게 눌렀을 때'만 메모 팝업창이 뜨도록 만듭니다!
                onDayLongPressed: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  
                  // 꾹 눌렀을 때만 팝업창 호출!
                  _showEntryDialog(selectedDay);
                },
                
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
                  dowBuilder: (context, day) {
                    if (day.weekday == 7) {
                      // 🔴 일요일 이름은 빨간색
                      return const Center(
                        child: Text('Sun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      );
                    } else if (day.weekday == 6) {
                      // 🔵 토요일 이름은 파란색
                      return const Center(
                        child: Text('Sat', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      );
                    } else {
                      // ⚪ 평일 이름은 정석 검은색
                      // (기호에 따라 '월', '화' 대신 day.weekday 값을 활용해 영문 등으로도 바꿀 수 있습니다)
                      final text = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'][day.weekday - 1];
                      return Center(
                        child: Text(text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      );
                    }
                  },
                  // 💡 평일, 토요일, 일요일을 이 안에서 직접 계산해서 그리도록 통합했습니다.
                  defaultBuilder: (context, day, focusedDay) {
                    // ✨ [추가] 현재 그리는 날짜가 사용자가 클릭한 '선택된 날짜'인지 확인합니다.
                    bool isSelected = isSameDay(_selectedDay, day);
                    final cellData = _calendarData[_normalizeDate(day)];

                    if (day.weekday == 7) {
                      // 일요일인데 선택까지 되었다면 연한 초록색 배경, 아니면 기존 회색 배경
                      return _buildSplitCell(day, Colors.red.shade700, isSelected ? Colors.green.shade50 : Colors.grey.shade100, isSelected: isSelected, data: cellData);
                    } else if (day.weekday == 6) {
                      // 토요일인데 선택까지 되었다면 연한 초록색 배경, 아니면 기존 회색 배경
                      return _buildSplitCell(day, Colors.blue.shade700, isSelected ? Colors.green.shade50 : Colors.grey.shade100, isSelected: isSelected, data: cellData);
                    } else {
                      // 평일인데 선택까지 되었다면 연한 초록색 배경, 아니면 기존 회색 배경
                      return _buildSplitCell(day, Colors.black87, isSelected ? Colors.green.shade50 : Colors.grey.shade100, isSelected: isSelected, data: cellData);
                    }
                  },
                  
                  // 오늘 날짜용 칸 빌더 (정상 작동하므로 유지)
                  todayBuilder: (context, day, focusedDay) {
                    // ✨ 현재 오늘 날짜가 사용자에 의해 클릭(선택)되었는지 확인합니다.
                    bool isSelected = isSameDay(_selectedDay, day);
                    final cellData = _calendarData[_normalizeDate(day)];

                    if (isSelected) {
                      // 🟢 오늘인데 선택까지 되었다면? -> 다른 날짜와 똑같이 초록색 배경으로 변경!
                      return _buildSplitCell(
                        day, 
                        Colors.blue.shade900, // 글씨는 원래 오늘 테마인 진한 파랑 유지 (또는 취향껏 수정)
                        Colors.green.shade50, // 💡 배경색을 초록색으로 덮어씁니다.
                        isToday: true, 
                        isSelected: true,
                        data: cellData
                      );
                    } else {
                      // 🔵 오늘인데 아직 선택은 안 되었다면? -> 기존의 평소 오늘 스타일 유지
                      return _buildSplitCell(
                        day, 
                        Colors.grey.shade900, 
                        Colors.grey.shade50, 
                        isToday: true, 
                        isSelected: false,
                        data: cellData
                      );
                    }
                  },
                  
                  // 이전달/다음달 날짜 칸 빌더 (정상 작동하므로 유지)
                  outsideBuilder: (context, day, focusedDay) {
                    final cellData = _calendarData[_normalizeDate(day)];
                    return _buildSplitCell(day, Colors.grey.shade400, Colors.grey.shade50, isOutside: true, data: cellData);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🛠️ 공통적으로 쓰일 2단 분리 가상 셀을 만드는 독립 함수입니다.
  Widget _buildSplitCell(DateTime day, Color textColor, Color barBgColor, {bool isToday = false, bool isOutside = false, bool isSelected = false, CalendarCellData? data}) {
    return Container(
      // 개별 칸 전체의 바깥 테두리 선 (바둑판 격자 완성)
      decoration: BoxDecoration(
        color: isOutside ? Colors.grey.shade50 : Colors.white,
        border: Border.all(
        color: isSelected 
            ? Colors.green.shade400 
            : (isToday ? Colors.blue.shade300 : Colors.grey.shade300), 
        width: isSelected || isToday ? 1.2 : 0.5
        ),
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
                  color: isSelected ? Colors.green.shade300 : (isToday ? Colors.blue.shade300 : Colors.grey.shade300),
                  width: isToday ? 1.5 : 1.0,
                ),
              ),
            ),
            alignment: Alignment.topLeft,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          
          // 2층: 하단 메모 및 이미지 들어갈 칸 (나머지 모든 남은 공간 차지)
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(3.0),
              child: data == null
                ? const SizedBox() // 💡 데이터가 아예 없으면 깨끗하게 빈칸으로 둠
                : Stack(
                    children: [
                      // [케이스 1] 이미지가 있다면 배경에 꽉 차게 썸네일 깔아주기
                      if (data.image != null)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2.0),
                            child: Image.file(
                              data.image!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      
                      // [케이스 2] 메모가 있다면 이미지 위에 반투명하게 얹거나 글씨 띄우기
                      if (data.memo.isNotEmpty)
                        Positioned(
                          left: 2,
                          top: 2,
                          right: 2,
                          child: Container(
                            // 💡 이미지가 뒤에 깔려있을 때 글씨가 잘 보이도록 글씨 배경에 살짝 음영을 줍니다.
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: data.image != null ? Colors.black.withValues(alpha: 0.5) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              data.memo,
                              style: TextStyle(
                                fontSize: 10, 
                                // 이미지가 있으면 글씨를 흰색으로, 없으면 검은색으로 가독성 확보!
                                color: data.image != null ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis, // 💡 넘치는 글자는 ... 처리
                            ),
                          ),
                        ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ [추가] 메모와 이미지를 입력받는 팝업창을 띄우는 함수
  void _showEntryDialog(DateTime date) {
    // 1. 이미 저장된 데이터가 있는지 확인 (창고 뒤지기)
    final normalizedDate = _normalizeDate(date);
    final existingData = _calendarData[normalizedDate];

    // 2. 입력창에 기존 메모가 있다면 미리 써두기
    _memoController.text = existingData?.memo ?? "";
    File? tempImage = existingData?.image; // 팝업창 안에서 임시로 보여줄 이미지

    showDialog(
      context: context,
      builder: (context) {
        // 💡 StatefulBuilder는 팝업창 안에서 이미지를 골랐을 때 화면을 즉시 새로고침하기 위해 사용합니다.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${date.month}월 ${date.day}일 기록'),
              content: Column(
                mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 창 크기 조절
                children: [
                  // [입력창 영역]
                  TextField(
                    controller: _memoController,
                    decoration: const InputDecoration(hintText: "오늘의 메모를 적어주세요"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  
                  // [이미지 선택 영역]
                  GestureDetector(
                    onTap: () async {
                      // 💡 이미지 피커로 사진 고르기
                      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setDialogState(() {
                          tempImage = File(pickedFile.path); // 팝업창 내 임시 이미지 업데이트
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: tempImage != null
                          ? Image.file(tempImage!, fit: BoxFit.cover) // 선택한 사진이 있으면 보여줌
                          : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey), // 없으면 아이콘
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                ElevatedButton(
                  onPressed: () {
                    // 3. [저장 버튼] 눌렀을 때 창고(_calendarData)에 데이터 집어넣기!
                    setState(() {
                      _calendarData[normalizedDate] = CalendarCellData(
                        memo: _memoController.text,
                        image: tempImage,
                      );
                    });
                    Navigator.pop(context); // 팝업창 닫기
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
}

class CalendarCellData {
  final String memo;    // 적어둔 메모 글자
  final File? image;    // 선택한 이미지 파일 (없을 수도 있으니 ? 부호 추가)

  CalendarCellData({
    required this.memo,
    this.image,
  });
}