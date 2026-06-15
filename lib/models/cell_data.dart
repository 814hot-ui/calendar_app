import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p; // 💡 파일명 추출을 위해 꼭 필요!

part 'cell_data.g.dart';

@collection
class CalendarCellData {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date;

  late String memo;

  // 💡 [개념 대수리] 전체 주소가 아닌, 바뀌지 않는 순수 파일명(ex: diary_12345.jpg)만 저장합니다!
  String? imagePath;

  List<int>? imageBytes;
  List<String> emotions = [];

  CalendarCellData({required this.memo, File? image, required this.emotions}) {
    if (image != null) {
      // 💡 주소가 들어오면 몽땅 잘라버리고 오직 맨 뒤 파일명만 쏙 뺍니다.
      imagePath = p.basename(image.path);
    }
  }

  // 💡 아래 getter와 setter는 UI 패키지 호환성을 위해 유지하되, 내부적으론 파일 이름만 건드립니다.
  @ignore
  File? get image => imagePath != null ? File(imagePath!) : null;

  @ignore
  set image(File? file) {
    if (file != null) {
      imagePath = p.basename(file.path);
    } else {
      imagePath = null;
    }
  }
}
