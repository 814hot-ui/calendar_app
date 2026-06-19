import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // 💡 실시간 진짜 폴더 조회를 위해 필수!
import '../models/cell_data.dart';
import '../models/emotion.dart';

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
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isToday ? Colors.amber.shade50 : Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        children: [
          // 1층: 날짜 헤더
          Container(
            width: double.infinity,
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: barBgColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
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
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
                if (data != null && data!.emotions.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: data!.emotions.map((emotionName) {
                      // 1. 대소문자 및 공백 세척
                      var cleanId = emotionName.toString().toLowerCase().trim();
                      
                      // 💡 [구조 결함 방어존] 혹시 DB에 영/한이 섞여 "슬픔"이나 "stressed" 등이 그대로 남아있다면 고유 ID 규격으로 강제 맵핑해줍니다.
                      if (cleanId == '슬픔' || cleanId == 'sad') cleanId = 'sad';
                      if (cleanId == '분노' || cleanId == 'angry') cleanId = 'angry';
                      if (cleanId == '스트레스' || cleanId == 'stressed') cleanId = 'stressed';
                      // (프로젝트에 정의된 다른 감정들이 있다면 여기에 추가 가능)

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
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(2),
              child: FutureBuilder<File?>(
                future: _getRealImageFile(),
                builder: (context, snapshot) {
                  final File? imgFile = snapshot.data;
                  final bool displayFile = imgFile != null;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // 📸 실시간 경로가 확인된 진짜 사진 레이어
                      if (displayFile)
                        Align(
                          alignment: Alignment.center,
                          child: AspectRatio(
                            aspectRatio: 1 / 1.3,
                            child: Image.file(
                              imgFile,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),

                      // 📝 메모 레이어 (🔧 괄호 오타 수리 완료!)
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
                              color: displayFile
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              data!.memo,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                height: 1.1, // 💡 두 줄이 되었을 때 줄간격을 살짝 콤팩트하게 조절
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
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
