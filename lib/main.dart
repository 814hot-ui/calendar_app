// main.dart 수정본
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'models/cell_data.dart';
import 'widgets/calendar_cell.dart';
import 'services/db_service.dart'; 
import 'widgets/entry_dialog.dart'; 

import 'package:easy_localization/easy_localization.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart'; 

// ⭕ 확장 기능 관련 추가 임포트
import 'package:provider/provider.dart';
import 'services/settings_manager.dart';
import 'widgets/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await DriftDbService.instance.init();

  runApp(
    // 1. 최상단에서는 다국어 설정만 깔끔하게 유지합니다.
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
    return ChangeNotifierProvider(
      create: (_) => SettingsManager(),
      child: const MaterialAppWithTheme(), // 👈 공유기 아래에서 진짜 앱을 실행합니다.
    );
  }  
}

// 3. ⭐️ 에러 해결사: 프로바이더의 상태를 안전하게 수신하는 진짜 마켓 위젯입니다.
class MaterialAppWithTheme extends StatelessWidget {
  const MaterialAppWithTheme({super.key});

  @override
  Widget build(BuildContext context) {
    // 이제 이 context는 완벽하게 부모의 SettingsManager를 인식할 수 있습니다! ✨
    final settings = Provider.of<SettingsManager>(context);
    final fontStyle = settings.getGoogleFontStyle();

    // ⭕ [핵심 안전장치] 현재 설정된 폰트 이름이 '기본글꼴'이 아니고, 
    // 동시에 우리가 지정한 fontList에도 실제로 들어있을 때만 구글 테마를 실행합니다!
    final bool isDefaultFont = settings.fontFamily == '기본글꼴';
    final bool isValidGoogleFont = !isDefaultFont && 
                                   SettingsManager.fontList.contains(settings.fontFamily);
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      title: 'app_title'.tr(),
      theme: ThemeData(
        useMaterial3: true,
        // 설정 화면에서 선택한 폰트를 전역으로 꽂아줍니다.
        
        textTheme: !isDefaultFont 
            ? GoogleFonts.getTextTheme(
                settings.getGoogleFontFamilyName(), 
                ThemeData.light().textTheme.merge(
                  TextTheme(
                    bodyLarge: fontStyle,
                    bodyMedium: fontStyle,
                    titleLarge: fontStyle,
                  ),
                ),
              ) 
            : null,
        // ⭕ 여기도 리스트에 있는 정상 폰트일 때만 이름을 지정해 줍니다.
        fontFamily: isValidGoogleFont ? settings.fontFamily : null,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink.shade50,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(), // 💡 스플래시 화면으로 안전하게 진입합니다!
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllCalendarData(); 
  }

  Future<void> _loadAllCalendarData() async {
    try {
      final allData = await DriftDbService.instance.getAllCellData();
      if (mounted) {
        setState(() {
          _calendarData.clear();
          if (allData.isNotEmpty) {
            for (var data in allData) {
              final normalizedDate = _normalizeDate(data.date);
              _calendarData[normalizedDate] = data;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
    // ⭕ 실시간 격자선 색상 감시 및 획득
    final settings = Provider.of<SettingsManager>(context);
    final baseColor = settings.gridLineColor; 

    // 2. ✨ 유저님이 정하신 톤온톤 룰대로 색상 분해 공식 적용!
    final thinGridColor = baseColor.withValues(alpha: 0.4);   // 모든 테두리 (조금 진하게)
    final lightBgColor = baseColor.withValues(alpha: 0.15);  // 날짜칸 배경색 (제일 흐리게)

    

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: BottomAlignedAppBar(
        title: '',
        showMemoWithImage: _showMemoWithImage,
        onTogglePressed: () {
          setState(() {
            _showMemoWithImage = !_showMemoWithImage;
          });
        },
        onSavePressed: _captureAndSaveAndShowSnackBar,
        // ⭕ 구름 아이콘 대신 설정창으로 이동하도록 액션 연결!
        onSettingsPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ).then((_) => _loadAllCalendarData()); // 설정 마치고 돌아왔을 때 데이터 리로드 보장
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          border: Border.all(
                            color: thinGridColor, // ⭕ 설정창 색상 연동
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(1.0),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 100),
                          child: TableCalendar(
                            availableGestures: AvailableGestures.horizontalSwipe,
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) async {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                              final normalizedDate = _normalizeDate(selectedDay);
                              showEntryDialog(
                                context: context,
                                date: selectedDay,
                                existingData: _calendarData[normalizedDate], 
                                onSave: (newData) async {
                                  bool hasDeleteSignal = newData.emotions.any(
                                    (e) => e.toString().toUpperCase() == '_DELETE_'
                                  );
                                  if (hasDeleteSignal) {
                                    if (newData.id != 0) {
                                      await DriftDbService.instance.deleteCellData(newData.id, newData.date);
                                    }
                                    await _loadAllCalendarData();
                                    return;
                                  }
                                  await DriftDbService.instance.saveCellData(newData);
                                  await _loadAllCalendarData();
                                },
                              );
                            },
                            onHeaderTapped: (focusedDay) {
                              setState(() {
                                _focusedDay = DateTime.now();
                              });
                            },
                            rowHeight: (() {
                              final double cellWidth = (MediaQuery.of(context).size.width - 24) / 7;
                              final double imageHeight = cellWidth * 1.3;
                              return imageHeight + 20;
                            })(),
                            daysOfWeekHeight: 30,
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D2D2D),
                              ).merge(settings.getGoogleFontStyle()), // 👈 구글 폰트 결합!
                              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black),
                              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.black),
                              headerPadding: EdgeInsets.zero,
                            ),
                            calendarBuilders: CalendarBuilders(
                              dowBuilder: (context, day) {
                                final textStyle = TextStyle(
                                  fontWeight: FontWeight.bold,
                                ).merge(settings.getGoogleFontStyle()); // 👈 구글 폰트 결합!
                                if (day.weekday == 7) {
                                  return Center(child: Text('sun'.tr(), style: textStyle.copyWith(color: Colors.red)));
                                } else if (day.weekday == 6) {
                                  return Center(child: Text('sat'.tr(), style: textStyle.copyWith(color: Colors.blue)));
                                } else {
                                  final text = ['mon'.tr(), 'tue'.tr(), 'wed'.tr(), 'thu'.tr(), 'fri'.tr()][day.weekday - 1];
                                  return Center(child: Text(text, style: textStyle.copyWith(color: Colors.black87)));
                                }
                              },
                              defaultBuilder: (context, day, focusedDay) {
                                return BuildSplitCell(
                                  day: day,
                                  textColor: day.weekday == 7 ? Colors.red.shade700 : (day.weekday == 6 ? Colors.blue.shade700 : Colors.black87),
                                  barBgColor: lightBgColor,
                                  isSelected: isSameDay(_selectedDay, day),
                                  data: _calendarData[_normalizeDate(day)],
                                  showMemo: _showMemoWithImage,
                                );
                              },
                              todayBuilder: (context, day, focusedDay) {
                                bool isSelected = isSameDay(_selectedDay, day);
                                return BuildSplitCell(
                                  day: day,
                                  textColor: Colors.blue.shade900,
                                  barBgColor: lightBgColor,
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
                                  barBgColor: lightBgColor,
                                  isOutside: true,
                                  showMemo: _showMemoWithImage,
                                  data: _calendarData[_normalizeDate(day)],
                                );
                              },
                              selectedBuilder: (context, day, focusedDay) {
                                return BuildSplitCell(
                                  day: day,
                                  textColor: day.weekday == 7 ? Colors.red.shade700 : (day.weekday == 6 ? Colors.blue.shade700 : Colors.black87),
                                  barBgColor: lightBgColor,
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
  final VoidCallback onSettingsPressed; // ⭕ 주머니 명칭 변경

  const BottomAlignedAppBar({
    super.key,
    required this.title,
    required this.showMemoWithImage,
    required this.onTogglePressed,
    required this.onSavePressed,
    required this.onSettingsPressed, // ⭕ 파라미터 변경
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsManager>(context, listen: false);

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
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D2D2D),
                  letterSpacing: -0.2,
                ).merge(settings.getGoogleFontStyle()),
              ),
              const Spacer(),
              Transform.translate(
                offset: const Offset(0, 1.0),
                child: GestureDetector(
                  onTap: onSettingsPressed, // ⭕ 톱니바퀴 버튼 매핑
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.settings_outlined, // ⭕ 톱니바퀴 디자인으로 대전환!
                      color: Colors.black87,
                      size: 20.0,
                    ),
                  ),
                ),
              ),
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
                      size: 20.0,
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
                      size: 25.0,
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