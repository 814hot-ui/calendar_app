import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final bool hasImage = data != null && data!.image != null;

    return Container(
      margin: EdgeInsets.zero, // ✨ [수정] 칸 사이의 틈을 완전히 없애서 딱 붙입니다.
      decoration: BoxDecoration(
        color: isToday ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.zero, // ✨ [수정] 모서리를 둥글지 않게, 칼같이 각지게 만듭니다.
        border: Border.all(
          // 두께를 0.5로 슬림하게 해서 칸들이 붙어도 테두리가 두꺼워 보이지 않게 합니다.
          color: isSelected ? Colors.green : Colors.grey.shade200,
          width: isSelected ? 2.0 : 0.5, 
        ),
      ),
      child: Column(
        children: [
          // 1층: 상단 날짜 바
          Container(
            width: double.infinity,
            height: 20, 
            padding: const EdgeInsets.symmetric(horizontal: 4), // 날짜 왼쪽 여백
            decoration: BoxDecoration(
              color: barBgColor,
              borderRadius: BorderRadius.zero, // ✨ [수정] 상단 바 음영 모서리도 각지게!
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // ✨ 날짜 왼쪽 정렬 유지
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
                // 감정 색상 점 3개
                if (data != null && data!.emotions.isNotEmpty) ...[
                  const SizedBox(width: 4), 
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: data!.emotions.map((emotionName) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        width: 4.5,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: getEmotionColor(emotionName),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          // 2층: 하단 내용 영역
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white, 
              padding: const EdgeInsets.all(2),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 📸 사진 레이어
                  if (hasImage)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.zero, // ✨ 사진 모서리도 각지게 맞춤
                        child: Image.file(
                          data!.image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // 📝 메모 레이어
                  if (showMemo && data != null && data!.memo.isNotEmpty)
                    Positioned(
                      bottom: 1,
                      left: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: hasImage ? Colors.white.withValues(alpha: 0.8) : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          data!.memo,
                          style: const TextStyle(
                            fontSize: 9, 
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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
}