import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'models/cell_data.dart';
import 'widgets/calendar_cell.dart';

// ✨ 우리가 쓸 진짜 파일 경로들만 정확하게 꽂아줍니다.
import 'services/db_service.dart'; // 💡 진짜 DriftDbService가 있는 곳
import 'widgets/entry_dialog.dart'; // 💡 진짜 showEntryDialog 함수가 있는 곳

import 'package:easy_localization/easy_localization.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'services/backup_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart'; // 💡 새로 만든 스플래시 화면이 있는 곳입니다.


void main() async {
  // 1. 플러터 엔진 초기화 (기존 코드)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 다국어 패키지 초기화 (기존 코드)
  await EasyLocalization.ensureInitialized();

  // 3. 💾 Isar 데이터베이스 서랍 열기 (새로 추가된 마법의 한 줄!)
  await DriftDbService.instance.init();

  // 4. 앱 실행 (기존 EasyLocalization 구조 그대로 유지!)
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
      home: const SplashScreen(),
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

  // 💡 데이터베이스 로딩 상태를 관리하는 변수입니다.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllCalendarData(); // 기존에 있던 달력 데이터 불러오기 로직

    // // 🔥 [딱 한 번만 실행할 대청소 코드]
    // // 이 코드가 들어간 상태로 앱을 한 번만 실행(핫 리스타트)하면 사진이 싹 지워집니다!
    // Future.microtask(() async {
    //   try {
    //     final appDir = await getApplicationDocumentsDirectory();
    //     final directory = Directory(appDir.path);
        
    //     if (await directory.exists()) {
    //       // 폴더 안의 모든 파일 목록을 가져옵니다.
    //       final List<FileSystemEntity> files = directory.listSync();
    //       int deleteCount = 0;

    //       for (var file in files) {
    //         // 우리가 저장할 때 파일명을 'diary_xxx.jpg'로 만들었으므로,
    //         // 이름에 'diary_'가 포함된 물리 파일만 조준 사격해서 지웁니다.
    //         if (file is File && file.path.contains('diary_')) {
    //           await file.delete();
    //           deleteCount++;
    //         }
    //       }
    //       debugPrint("🧹 [📸 PHOTO_CLEANER] 총 $deleteCount개의 사진 파일 대청소 완료!");
    //     }
    //   } catch (e) {
    //     debugPrint("🔥 [PHOTO_CLEANER] 청소 중 오류 발생: $e");
    //   }
    // });
  }

  // 💾 Isar 데이터베이스에서 모든 데이터를 긁어와 화면 맵에 매핑하는 함수입니다.
  Future<void> _loadAllCalendarData() async {
    try {
      // 1. DB에서 데이터를 일단 다 긁어옵니다.
      final allData = await DriftDbService.instance.getAllCellData();

      if (mounted) {
        setState(() {
          _calendarData.clear();

          // 2. 데이터가 있다면 화면 맵(_calendarData)에 이쁘게 넣어줍니다.
          if (allData.isNotEmpty) {
            for (var data in allData) {
              final normalizedDate = _normalizeDate(data.date);
              _calendarData[normalizedDate] = data;
            }
          }

          // 3. ✨ 데이터가 있든 없든 다 불러왔으니 로딩을 마칩니다!
          _isLoading = false;
        });
      }
    } catch (e) {
      // 4. 🔥 만에 하나 에러가 나더라도 뱅글뱅글 돌지 않고 화면은 보여주도록 방어!
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save image.')));
      }
    }
  }

  // 💡 아래에서 메뉴 서랍이 스르륵 올라오게 만드는 백업 팝업 함수입니다!
  void _showBackupBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'backup_title'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              
              // 📦 1. 현재 데이터 백업하기 버튼
              ListTile(
                leading: const Icon(Icons.cloud_upload, color: Colors.blue),
                title: Text('backup_export_title'.tr()),
                subtitle: Text('backup_export_subtitle'.tr()),
                onTap: () async {
                  // 💡 백업 메신저도 미리 캡처!
                  final messenger = ScaffoldMessenger.of(context);
                  
                  Navigator.pop(context);
                  
                  await BackupService.instance.exportBackup((message) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  });
                },
              ),
              
              // 📂 2. 백업 파일로 복구하기 버튼
              ListTile(
                leading: const Icon(Icons.cloud_download, color: Colors.green),
                title: Text('backup_import_title'.tr()),
                subtitle: Text('backup_import_subtitle'.tr()),
                onTap: () async {
                  // 💡 [핵심 해결] 팝업창이 닫히기 전, 메인 화면의 스낵바 메신저를 미리 변수에 보관합니다!
                  final messenger = ScaffoldMessenger.of(context);
                  
                  // 메신저를 확보했으니 이제 안심하고 팝업창을 닫습니다.
                  Navigator.pop(context);
                  
                  // 1. 진짜 복구 서비스 호출 (보관해둔 messenger를 활용해 안전하게 출력)
                  await BackupService.instance.importBackup((message) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  });
                  
                  // 2. 복구 완료 후 달력 화면에 새 데이터 반영하기
                  if (mounted) {
                    await _loadAllCalendarData(); 
                  }
                },
              ),


              const SizedBox(height: 12),
            ],
          ),
        );
      }
    );
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
        onBackupPressed: _showBackupBottomSheet,
      ),

      // 💡 데이터베이스에서 일기를 다 불러오기 전까진 로딩 인디케이터를 띄워 튕김을 방지합니다.
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
                            color: Colors.grey.shade400,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),

                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 100),
                          child: TableCalendar(
                            availableGestures:
                                AvailableGestures.horizontalSwipe,
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) async {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                              
                              final normalizedDate = _normalizeDate(selectedDay);
                              
                              showEntryDialog(
                                context: context,
                                date: selectedDay,
                                // 🔥 중요: 해당 날짜에 이미 저장된 데이터가 있다면 ID를 포함해 통째로 넘깁니다.
                                existingData: _calendarData[normalizedDate], 
                                onSave: (newData) async {
                                  // 대소문자 구분 없이 _DELETE_ 신호 확인
                                  bool hasDeleteSignal = newData.emotions.any(
                                    (e) => e.toString().toUpperCase() == '_DELETE_'
                                  );

                                  if (hasDeleteSignal) {
                                    // 길게 눌러 삭제할 때도 id와 date를 둘 다 넘겨주도록 수정합니다!
                                    if (newData.id != 0) {
                                      await DriftDbService.instance.deleteCellData(
                                        newData.id, 
                                        newData.date, // ⭕ 날짜 데이터 추가!
                                      );
                                    }
                                    await _loadAllCalendarData();
                                    return;
                                  }

                                  await DriftDbService.instance.saveCellData(newData);
                                  await _loadAllCalendarData();

                                  await _loadAllCalendarData();
                                },
                              );
                            },

                            // 달력 상단 년/월 헤더를 클릭하면 무조건 오늘 날짜가 있는 달로 복귀!
                            onHeaderTapped: (focusedDay) {
                              setState(() {
                                _focusedDay = DateTime.now();
                              });
                            },

                            onDayLongPressed: (selectedDay, focusedDay) async {
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
                                      await DriftDbService.instance.deleteCellData(
                                        newData.id, 
                                        newData.date, // ⭕ 날짜 데이터 추가!
                                      );
                                    }
                                    await _loadAllCalendarData();
                                    return;
                                  }

                                  await DriftDbService.instance.saveCellData(newData);
                                  await _loadAllCalendarData();

                                  await _loadAllCalendarData();
                                },
                              );
                            },

                            rowHeight: (() {
                              final double cellWidth =
                                  (MediaQuery.of(context).size.width - 24) / 7;
                              final double imageHeight = cellWidth * 1.3;
                              return imageHeight + 20;
                            })(),

                            daysOfWeekHeight: 30,

                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: GoogleFonts.quicksand( // 💡 달력 헤더에도 구글 폰트 적용!
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,       // 너무 두껍지 않고 세련된 두께
                                color: const Color(0xFF2D2D2D),    // 전체 톤과 맞춘 짙은 회색
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: Colors.black,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: Colors.black,
                              ),
                              headerPadding: EdgeInsets.symmetric(
                                vertical: 0.0,
                              ),
                            ),
                            calendarBuilders: CalendarBuilders(
                              dowBuilder: (context, day) {
                                if (day.weekday == 7) {
                                  return Center(
                                    child: Text(
                                      'sun'.tr(),
                                      style: GoogleFonts.quicksand(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                } else if (day.weekday == 6) {
                                  return Center(
                                    child: Text(
                                      'sat'.tr(),
                                      style: GoogleFonts.quicksand(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                } else {
                                  final text = [
                                    'mon'.tr(),
                                    'tue'.tr(),
                                    'wed'.tr(),
                                    'thu'.tr(),
                                    'fri'.tr(),
                                  ][day.weekday - 1];
                                  return Center(
                                    child: Text(
                                      text,
                                      style: GoogleFonts.quicksand(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                              },
                              defaultBuilder: (context, day, focusedDay) {
                                bool isSelected = isSameDay(_selectedDay, day);
                                return BuildSplitCell(
                                  day: day,
                                  textColor: day.weekday == 7
                                      ? Colors.red.shade700
                                      : (day.weekday == 6
                                            ? Colors.blue.shade700
                                            : Colors.black87),
                                  barBgColor: Colors.grey.shade50,
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
                                  barBgColor: isSelected
                                      ? Colors.grey.shade50
                                      : Colors.blue.shade50,
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
                                  barBgColor: Colors.grey.shade50,
                                  isOutside: true,
                                  showMemo: _showMemoWithImage,
                                  data: _calendarData[_normalizeDate(day)],
                                );
                              },
                              selectedBuilder: (context, day, focusedDay) {
                                return BuildSplitCell(
                                  day: day,
                                  textColor: day.weekday == 7
                                      ? Colors.red.shade700
                                      : (day.weekday == 6
                                            ? Colors.blue.shade700
                                            : Colors.black87),
                                  barBgColor: Colors.grey.shade50,
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

class BottomAlignedAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool showMemoWithImage;
  final VoidCallback onTogglePressed;
  final VoidCallback onSavePressed;
  final VoidCallback onBackupPressed;

  const BottomAlignedAppBar({
    super.key,
    required this.title,
    required this.showMemoWithImage,
    required this.onTogglePressed,
    required this.onSavePressed,
    required this.onBackupPressed,
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
                style: GoogleFonts.quicksand( // 💡 상단에 임포트가 되어있어 바로 쓸 수 있습니다!
                  fontSize: 15.0,             // 글자 크기를 살짝 키우면 더 시원해 보입니다.
                  fontWeight: FontWeight.w600, // 이미지 폰트와 가장 흡사한 굵기
                  color: const Color(0xFF2D2D2D), // 세련된 짙은 회색/검은색
                  letterSpacing: -0.2,        // 자간을 아주 미세하게 좁혀 완성도를 높입니다.
                ),
              ),
              const Spacer(),


              Transform.translate(
                offset: const Offset(0, 1.0),
                child: GestureDetector(
                  onTap: onBackupPressed, // 💡 3-1에서 만든 주머니와 연결!
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.cloud_upload_outlined, // 구름 모양 백업 아이콘
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
                    padding: const EdgeInsets.only(
                      bottom: 0,
                      left: 8,
                      right: 0,
                    ),
                    child: Icon(
                      showMemoWithImage ? Icons.toggle_on : Icons.toggle_off,
                      color: showMemoWithImage
                          ? const Color.fromARGB(255, 77, 79, 82)
                          : Colors.grey,
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
