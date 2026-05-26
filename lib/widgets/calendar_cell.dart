import 'dart:io';
import 'package:flutter/material.dart';
import '../models/cell_data.dart'; // 방금 만든 데이터 모델 가져오기

class BuildSplitCell extends StatelessWidget {
  final DateTime day;
  final Color textColor;
  final Color barBgColor;
  final bool isToday;
  final bool isOutside;
  final bool isSelected;
  final CalendarCellData? data;

  const BuildSplitCell({
    super.key,
    required this.day,
    required this.textColor,
    required this.barBgColor,
    this.isToday = false,
    this.isOutside = false,
    this.isSelected = false,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isOutside ? Colors.grey.shade50 : Colors.white,
        border: Border.all(
          color: isSelected 
              ? Colors.green.shade400 
              : (isToday ? Colors.blue.shade300 : Colors.grey.shade300), 
          width: isSelected || isToday ? 1.2 : 0.5,
        ),
      ),
      child: Column(
        children: [
          // 1층: 상단 날짜바
          Container(
            height: 24,
            width: double.infinity,
            padding: const EdgeInsets.only(left: 6, top: 2),
            decoration: BoxDecoration(
              color: barBgColor,
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? Colors.green.shade300 : (isToday ? Colors.blue.shade300 : Colors.grey.shade300),
                  width: isSelected || isToday ? 1.5 : 1.0,
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
          
          // 2층: 하단 메모 및 이미지 들어갈 칸
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(3.0),
              child: data == null
                  ? const SizedBox()
                  : Stack(
                      children: [
                        // [케이스 1] 이미지가 있다면 배경에 꽉 차게 썸네일 깔기
                        if (data!.image != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2.0),
                              child: Image.file(
                                data!.image!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        
                        // [케이스 2] 메모가 있다면 이미지 위에 얹기
                        if (data!.memo.isNotEmpty)
                          Positioned(
                            left: 2,
                            top: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: data!.image != null ? Colors.black.withValues(alpha: 0.5) : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                data!.memo,
                                style: TextStyle(
                                  fontSize: 10, 
                                  color: data!.image != null ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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