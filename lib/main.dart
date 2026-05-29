import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// ✨ 우리가 이사 보낸 파일들을 연결해 줍니다!
import 'models/cell_data.dart';
import 'widgets/calendar_cell.dart';
import 'widgets/entry_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image Calendar',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ImageCalendar(),
    );
  }
}

class ImageCalendar extends StatefulWidget {
  const ImageCalendar({super.key});

  @override
  State<ImageCalendar> createState() => _ImageCalendarState();
}

class _ImageCalendarState extends State<ImageCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, CalendarCellData> _calendarData = {};
  bool _showMemoWithImage = true;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Biscuit Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showMemoWithImage ? Icons.toggle_on : Icons.toggle_off, // 🔄 아이콘 변경
              color: _showMemoWithImage ? Colors.blue : Colors.grey,
            ),
            tooltip: _showMemoWithImage ? '사진+메모 보기 모드' : '사진만 보기 모드',
            onPressed: () {
              setState(() {
                _showMemoWithImage = !_showMemoWithImage; // 누를 때마다 모드 반전
              });
              
              // 폰에서 바로 확인용 토스트/스낵바 띄우기
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_showMemoWithImage ? '📷 사진과 📝 메모를 함께 보여줍니다.' : '📷 사진만 깔끔하게 보여줍니다.'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(

            padding: const EdgeInsets.all(12.0),

            child: Container(
              height: MediaQuery.of(context).orientation == Orientation.portrait ? MediaQuery.of(context).size.height * 0.82 : null,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(8.0),
              ),

              child: TableCalendar(

                // 달력이 가로 제스처(왼쪽/오른쪽 월 이동)만 흡수하게 제한합니다. 
                // 이렇게 하면 세로로 밀 때 스크롤 주머니가 정상 작동합니다!
                availableGestures: AvailableGestures.horizontalSwipe,

                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },

                // 💡 꾹 눌렀을 때 새롭게 만든 분리형 팝업창을 소환합니다.
                onDayLongPressed: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  
                  final normalizedDate = _normalizeDate(selectedDay);
                  
                  showEntryDialog(
                    context: context,
                    date: selectedDay,
                    existingData: _calendarData[normalizedDate],
                    onSave: (newData) {
                      // 팝업창이 던져준 데이터를 받아서 화면을 새로고침합니다.
                      setState(() {
                        _calendarData[normalizedDate] = newData;
                      });
                    },
                  );
                },

                rowHeight: 75,
                daysOfWeekHeight: 30,
                
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
                ),

                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    if (day.weekday == 7) {
                      return const Center(child: Text('일', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
                    } else if (day.weekday == 6) {
                      return const Center(child: Text('토', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)));
                    } else {
                      final text = ['월', '화', '수', '목', '금'][day.weekday - 1];
                      return Center(child: Text(text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)));
                    }
                  },
                  
                  // 💡 아래의 모든 빌더들이 새로 만든 독립형 'BuildSplitCell' 위젯을 사용하도록 교체되었습니다!
                  defaultBuilder: (context, day, focusedDay) {
                    bool isSelected = isSameDay(_selectedDay, day);
                    final cellData = _calendarData[_normalizeDate(day)];

                    return BuildSplitCell(
                      day: day,
                      textColor: day.weekday == 7 ? Colors.red.shade700 : (day.weekday == 6 ? Colors.blue.shade700 : Colors.black87),
                      barBgColor: isSelected ? Colors.grey.shade100 : Colors.grey.shade100,
                      isSelected: isSelected,
                      data: cellData,
                      showMemo: _showMemoWithImage,
                    );
                  },
                  
                  todayBuilder: (context, day, focusedDay) {
                    bool isSelected = isSameDay(_selectedDay, day);
                    final cellData = _calendarData[_normalizeDate(day)];

                    return BuildSplitCell(
                      day: day,
                      textColor: Colors.blue.shade900,
                      barBgColor: isSelected ? Colors.grey.shade100 : Colors.blue.shade50,
                      isToday: true,
                      isSelected: isSelected,
                      data: cellData,
                      showMemo: _showMemoWithImage,
                    );
                  },
                  
                  outsideBuilder: (context, day, focusedDay) {
                    final cellData = _calendarData[_normalizeDate(day)];
                    return BuildSplitCell(
                      day: day,
                      textColor: Colors.grey.shade400,
                      barBgColor: Colors.grey.shade100,
                      isOutside: true,
                      showMemo: _showMemoWithImage,
                      data: cellData,
                    );
                  },

                  selectedBuilder: (context, day, focusedDay) {
                    final cellData = _calendarData[_normalizeDate(day)];
                    
                    // 선택된 날짜도 우리만의 'BuildSplitCell'을 똑같이 쓰되, 
                    // isSelected를 true로 주어 초록색 테두리만 예쁘게 돌리도록 만듭니다!
                    return BuildSplitCell(
                      day: day,
                      textColor: day.weekday == 7 ? Colors.red.shade700 : (day.weekday == 6 ? Colors.blue.shade700 : Colors.black87),
                      barBgColor: Colors.grey.shade100, // 선택된 날짜는 연한 녹색 바탕으로 강조!
                      isSelected: true, // 🟢 테두리 강조 스위치 On!
                      isToday: isSameDay(DateTime.now(), day), // 혹시 오늘 날짜를 선택했을 수도 있으니 체크
                      data: cellData,
                      showMemo: _showMemoWithImage, // 아까 만든 보기 옵션도 같이 넘겨줍니다!
                    );
                  },  
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}