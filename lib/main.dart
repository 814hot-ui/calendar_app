import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'models/cell_data.dart';
import 'widgets/calendar_cell.dart';
import 'widgets/entry_dialog.dart';
import 'package:easy_localization/easy_localization.dart'; 
import 'package:screenshot/screenshot.dart'; // ✨ 추가
import 'package:gal/gal.dart'; // ✨ 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      path: 'assets/translations', 
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      title: 'app_title'.tr(),
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

  // ✨ [추가] 스크롤 캡처를 제어할 컨트롤러 선언
  final ScreenshotController _screenshotController = ScreenshotController();

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // ✨ [추가] 전체 스크롤 캡처 및 저장 기능 함수
  Future<void> _captureAndSaveAndShowSnackBar() async {
    try {
      // 1. 화면에 보이지 않는 스크롤 영역까지 통째로 이미지 바이트 데이터로 구워냅니다.
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100), // 안정적인 렌더링을 위한 미세한 대기 시간
      );

      if (imageBytes != null) {
        // 2. 구워낸 바이트 데이터를 스마트폰 갤러리에 저장합니다.
        await Gal.putImageBytes(imageBytes);
        
        // 3. 성공 안내 메시지 띄우기
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📅 달력 이미지가 갤러리에 안전하게 저장되었습니다!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      appBar: BottomAlignedAppBar(
        title: 'app_title'.tr(),
        showMemoWithImage: _showMemoWithImage,
        onTogglePressed: () {
          setState(() {
            _showMemoWithImage = !_showMemoWithImage;
          });
        },
        onSavePressed: _captureAndSaveAndShowSnackBar,
      ),
      
      body: SingleChildScrollView(
        child: SafeArea(
          child: Screenshot(
            controller: _screenshotController,

            child:GestureDetector(
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  // 💡 테두리와 배경색을 주고, 내부 알맹이 크기에 맞춰 늘어나도록 만듭니다.
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  
                  // 💥 [핵심] TableCalendar가 스크롤 안에서 춤추지 못하게 수직 제약(Constraints)을 꽉 잡아줍니다.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 100, // 마이너스 높이 에러 방지용 안전선
                    ),
                    child: TableCalendar(
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
                            setState(() {
                              _calendarData[normalizedDate] = newData;
                            });
                          },
                        );
                      },         
 
                      // 📏 가로 폭 기반 높이 계산 (이건 정상적인 수식입니다!)
                      rowHeight: ((MediaQuery.of(context).size.width - 24) / 7) * 1.5, 
                      daysOfWeekHeight: 30,
                      
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
                        headerPadding: EdgeInsets.symmetric(vertical: 0.0), 
                      ),
                      calendarBuilders: CalendarBuilders(
                        dowBuilder: (context, day) {
                          if (day.weekday == 7) {
                            return Center(child: Text('sun'.tr(), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
                          } else if (day.weekday == 6) {
                            return Center(child: Text('sat'.tr(), style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)));
                          } else {
                            final text = ['mon'.tr(), 'tue'.tr(), 'wed'.tr(), 'thu'.tr(), 'fri'.tr()][day.weekday - 1];
                            return Center(child: Text(text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)));
                          }
                        },
                        defaultBuilder: (context, day, focusedDay) {
                          bool isSelected = isSameDay(_selectedDay, day);
                          return BuildSplitCell(
                            day: day,
                            textColor: day.weekday == 7 ? Colors.red.shade700 : (day.weekday == 6 ? Colors.blue.shade700 : Colors.black87),
                            barBgColor: Colors.grey.shade100,
                            isSelected: isSelected,
                            data: _calendarData[_normalizeDate(day)],
                            showMemo: _showMemoWithImage,
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          bool isSelected = isSameDay(_selectedDay, day);
                          return BuildSplitCell(
                            day: day,
                            textColor: Colors.blue.shade900,
                            barBgColor: isSelected ? Colors.grey.shade100 : Colors.blue.shade50,
                            isToday: true,
                            isSelected: isSelected,
                            data: _calendarData[_normalizeDate(day)],
                            showMemo: _showMemoWithImage,
                          );
                        },
                        outsideBuilder: (context, day, focusedDay) {
                          return BuildSplitCell(
                            day: day,
                            textColor: Colors.grey.shade400,
                            barBgColor: Colors.grey.shade100,
                            isOutside: true,
                            showMemo: _showMemoWithImage,
                            data: _calendarData[_normalizeDate(day)],
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return BuildSplitCell(
                            day: day,
                            textColor: day.weekday == 7 ? Colors.red.shade700 : (day.weekday == 6 ? Colors.blue.shade700 : Colors.black87),
                            barBgColor: Colors.grey.shade100,
                            isSelected: true,
                            isToday: isSameDay(DateTime.now(), day),
                            data: _calendarData[_normalizeDate(day)],
                            showMemo: _showMemoWithImage,
                          );
                        },  
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ),
      ),
    ),
    );
  }
}

class BottomAlignedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showMemoWithImage;
  final VoidCallback onTogglePressed;
  final VoidCallback onSavePressed; // 👈 1. 이 줄이 클래스 내부에 선언되어 있어야 합니다!

  const BottomAlignedAppBar({
    super.key,
    required this.title,
    required this.showMemoWithImage,
    required this.onTogglePressed,
    required this.onSavePressed, // 👈 2. 생성자(Constructor)에도 반드시 필수로 등록해 줘야 합니다!
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 52.0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      actions: const [],
      title: SizedBox(
        height: 52.0,
        child: Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              
              // 📸 3. 실제 저장 기능을 실행할 다운로드 아이콘 버튼 구역
              Transform.translate(
                offset: const Offset(0, 1.0),
                child: GestureDetector(
                  onTap: onSavePressed, // 👈 여기서 위에서 받아온 함수를 실행하게 됩니다.
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.download, 
                      color: Colors.black87,
                      size: 26.0,
                    ),
                  ),
                ),
              ),
              
              // 🎯 기존 토글 버튼 구역
              Transform.translate(
                offset: const Offset(0, 4.0),
                child: GestureDetector(
                  onTap: onTogglePressed,
                  behavior: HitTestBehavior.opaque, 
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 0, left: 8, right: 0), 
                    child: Icon(
                      showMemoWithImage ? Icons.toggle_on : Icons.toggle_off,
                      color: showMemoWithImage ? const Color.fromARGB(255, 77, 79, 82) : Colors.grey,
                      size: 32.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52.0);
}