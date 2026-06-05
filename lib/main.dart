import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'models/cell_data.dart';
import 'widgets/calendar_cell.dart';
import 'widgets/entry_dialog.dart';
import 'package:easy_localization/easy_localization.dart'; 
import 'package:screenshot/screenshot.dart'; 
import 'package:gal/gal.dart'; 

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink.shade50,
          brightness: Brightness.light, 
        ),
      ),
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

  final ScreenshotController _screenshotController = ScreenshotController();

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _captureAndSaveAndShowSnackBar() async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100), 
      );

      if (imageBytes != null) {
        await Gal.putImageBytes(imageBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Monthly Image Saved to Gallery!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image.')),
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
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 100, 
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
                      
                      // ✨ [추가] 달력 상단 년/월 헤더를 클릭하면 무조건 오늘 날짜가 있는 달로 복귀!
                      onHeaderTapped: (focusedDay) {
                        setState(() {
                          _focusedDay = DateTime.now();
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
 
                      rowHeight: (() {
                        final double cellWidth = (MediaQuery.of(context).size.width - 24) / 7;
                        final double imageHeight = cellWidth * 1.3;
                        return imageHeight + 20;
                      })(),

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
                            return Center(child: Text('sun'.tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
                          } else if (day.weekday == 6) {
                            return Center(child: Text('sat'.tr(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)));
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
  final VoidCallback onSavePressed; 

  const BottomAlignedAppBar({
    super.key,
    required this.title,
    required this.showMemoWithImage,
    required this.onTogglePressed,
    required this.onSavePressed, 
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
              
              Transform.translate(
                offset: const Offset(0, 1.0),
                child: GestureDetector(
                  onTap: onSavePressed, 
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