import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // 💡 실시간 진짜 폴더 조회를 위해 필수!
import '../models/cell_data.dart';
import '../models/emotion.dart';
import 'package:provider/provider.dart';
import '../services/settings_manager.dart';

class BuildSplitCell extends StatelessWidget {
  final DateTime day;
  final Color textColor;
  final Color barBgColor;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;
  final CalendarCellData? data;
  final bool showMemo;

  const BuildSplitCell({
    super.key,
    required this.day,
    required this.textColor,
    required this.barBgColor,
    this.isSelected = false,
    this.isToday = false,
    this.isOutside = false,
    this.data,
    required this.showMemo,
  });

  // 💡 [실시간 주소 조립 나침반] Isar에 저장된 파일 이름과 현재 iOS가 실시간 발급한 진짜 방 주소를 합쳐서 파일을 낚아옵니다.
  Future<File?> _getRealImageFile() async {
    if (data == null || data!.imagePath == null || data!.imagePath!.isEmpty) {
      return null;
    }

    try {
      final String pureFileName = data!.imagePath!.split('/').last;
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/$pureFileName');

      // 💡 [핵심 보완] 주소만 맞다고 던지지 말고, 진짜 기기에 파일이 살아있는지 최종 확인!
      if (await file.exists()) {
        return file;
      } else {
        // debugPrint("⚠️ [CALENDAR_CELL] DB엔 경로가 있지만 물리 파일이 유실됨: $pureFileName");
        return null; // 파일이 없으면 null을 주어 사진 없는 날 처리
      }
    } catch (e) {
      // debugPrint("🔥 [CALENDAR_CELL] 파일 조회 중 오류 발생: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsManager>(context);

    // 🎨 사용자가 선택한 원본 색상 바탕으로 테두리색 재추출
    final baseColor = settings.gridLineColor;
    final thinGridColor = baseColor.withValues(alpha: 0.2); // ⭕ 달력 모든 테두리용 선 색상
    final todayPointColor = baseColor.withValues(
      alpha: 0.6,
    ); // ⭕ 오늘 날짜 강조용 진한 색상

    // ⭕ [추가] 오늘이면서 선택되지 않았을 때만 오늘 강조를 켭니다!
    final bool showTodayHighlight = isToday && !isSelected;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        // ⭕ 오늘 날짜면 전체 칸을 테두리색과 유사한 진한 색으로, 선택된 날은 원래 칸 배경과 같게 흰색 베이스 유지
        color: showTodayHighlight ? todayPointColor : Colors.white,
        border: Border.all(color: thinGridColor, width: 0.5),
      ),
      child: Column(
        children: [
          // 1층: 날짜 헤더
          Container(
            width: double.infinity,
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: showTodayHighlight ? todayPointColor : barBgColor,
              border: Border(
                bottom: BorderSide(color: thinGridColor, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.normal,
                    fontSize: 11,
                  ).merge(settings.getGoogleFontStyle()), // ⭕ 구글 폰트 속성 강제 합성!
                ),
                if (!isOutside &&
                    data != null &&
                    data!.emotions.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: data!.emotions.map((emotionName) {
                      // 1. 대소문자 및 공백 세척
                      var cleanId = emotionName.toString().toLowerCase().trim();

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        width: 6.5,
                        height: 6.5,
                        decoration: BoxDecoration(
                          // 정제된 고유 ID를 던져 정확한 색상을 찾아옵니다.
                          color: getEmotionColor(cleanId),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // 2층: 일기 내용 및 사진 영역
          // 📝 calendar_cell.dart의 2층 Expanded 내부 FutureBuilder 부분을 아래와 같이 교체해 주세요.
          // 📝 calendar_cell.dart 파일의 2층 Expanded 내부를 아래 코드로 교체해 주세요!
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(2),
              child: FutureBuilder<File?>(
                future: _getRealImageFile(),
                builder: (context, snapshot) {
                  final File? imgFile = snapshot.data;

                  // 🌟 [핵심 수술 부위] 사진 파일이 존재하더라도, 이번 달 바깥의 날짜(isOutside)라면 사진이 없는 날로 강제 취급합니다!
                  final bool displayFile = imgFile != null && !isOutside;

                  // 1. 사진이 없는 날 (or 이번 달이 아닌 날) ➡️ 메모만 깔끔하게 중앙 표시
                  if (!displayFile) {
                    return Center(
                      child:
                          (!isOutside &&
                              showMemo &&
                              data != null &&
                              data!.memo.isNotEmpty)
                          ? Text(
                              data!.memo,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black87,
                              ).merge(settings.getGoogleFontStyle()),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            )
                          : const SizedBox.shrink(),
                    );
                  }

                  // 2. 📸 사진이 있는 날 (이번 달 내부이면서 데이터가 완벽할 때만 진입)
                  return Center(
                    child: AspectRatio(
                      aspectRatio: 1 / 1.3, // 고정된 사진 비율
                      child: Stack(
                        fit: StackFit.expand, // 스택 내부 요소들이 사진 크기와 100% 일치하도록 강제
                        children: [
                          // 1. 밑바탕 사진 (displayFile이 참이므로 isOutside 체크는 이미 통과 완료)
                          Image.file(
                            imgFile,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),

                          // 2. 사진 몸통 안에 딱 갇히는 메모 레이어
                          if (showMemo && data != null && data!.memo.isNotEmpty)
                            Positioned(
                              bottom: 1,
                              left: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 0.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  data!.memo,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    height: 1.1,
                                  ).merge(settings.getGoogleFontStyle()),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
