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

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('나만의 이미지 달력', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TableCalendar(
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
                      barBgColor: isSelected ? Colors.green.shade50 : Colors.grey.shade100,
                      isSelected: isSelected,
                      data: cellData,
                    );
                  },
                  
                  todayBuilder: (context, day, focusedDay) {
                    bool isSelected = isSameDay(_selectedDay, day);
                    final cellData = _calendarData[_normalizeDate(day)];

                    return BuildSplitCell(
                      day: day,
                      textColor: Colors.blue.shade900,
                      barBgColor: isSelected ? Colors.green.shade50 : Colors.blue.shade50,
                      isToday: true,
                      isSelected: isSelected,
                      data: cellData,
                    );
                  },
                  
                  outsideBuilder: (context, day, focusedDay) {
                    final cellData = _calendarData[_normalizeDate(day)];
                    return BuildSplitCell(
                      day: day,
                      textColor: Colors.grey.shade400,
                      barBgColor: Colors.grey.shade50,
                      isOutside: true,
                      data: cellData,
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