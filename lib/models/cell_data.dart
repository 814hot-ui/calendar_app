import 'dart:io'; 

// 📅 날짜별로 저장할 메모와 이미지 세트 설계도
class CalendarCellData {
  final String memo;    // 적어둔 메모 글자
  final File? image;    // 선택한 이미지 파일 (없을 수도 있음)

  CalendarCellData({
    required this.memo,
    this.image,
  });
}