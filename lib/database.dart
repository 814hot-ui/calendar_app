import 'dart:io';
import 'dart:convert'; // jsonEncode, jsonDecode를 위해 필요
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


part 'database.g.dart';

// 💡 [감정 리스트 변환기] SQLite는 List<String>을 통째로 못 넣기 때문에, 
// 저장할 때는 JSON 글자(텍스트)로 바꾸고, 가져올 때는 다시 리스트로 변환해 주는 마법의 장치입니다.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  
  @override
  List<String> fromSql(String fromDb) {
    return List<String>.from(jsonDecode(fromDb));
  }
  
  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}

// 1. 🌟 기존 Isar 모델에 있던 모든 필드(이미지, 감정)를 완벽하게 반영한 테이블입니다.
class CalendarEntries extends Table {
  IntColumn get id => integer().autoIncrement()();       // 고유 ID
  DateTimeColumn get date => dateTime()();              // 일정 날짜
  TextColumn get content => text()();                  // 일정 내용 (memo)
  TextColumn get emotions => text().map(const StringListConverter())(); // ⭕ 감정 리스트 추가!
  TextColumn get imagePath => text().nullable()();     // ⭕ 이미지 경로 추가! (비어있을 수 있음)
}

@DriftDatabase(tables: [CalendarEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ===== 🛠️ 앱에서 사용할 확장 데이터 기능들 =====

  // 🔎 1. 특정 날짜의 일정 가져오기
  Future<CalendarEntry?> getEntryByDate(DateTime targetDate) {
    final pureDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return (select(calendarEntries)..where((t) => t.date.equals(pureDate))).getSingleOrNull();
  }

  // 📑 2. 모든 일정 데이터 가져오기 (백업용)
  Future<List<CalendarEntry>> getAllEntries() {
    return select(calendarEntries).get();
  }

  // 💾 3. 일정 저장 및 수정 (이미지, 감정까지 싹 다 저장하도록 업그레이드!)
 Future<void> saveEntry({
  int? id, // ⭕ 1. 맨 위에 id 파라미터를 추가해 줍니다!
  required DateTime targetDate,
  required String text,
  required List<String> emotions,
  String? imagePath,
}) async {
  
  // ⭕ 2. 내부 Drift 테이블(Companion)에 id도 함께 배달하게 조립합니다!
  await into(calendarEntries).insertOnConflictUpdate(
    CalendarEntriesCompanion(
      // 기존에 id: Value(id)가 빠져있었다면 여기에 쏙 넣어줍니다.
      // (만약 기존 일기면 원래 id가 들어가고, 새 일기(0 또는 null)면 Drift가 알아서 새 ID를 발급합니다)
      id: id != null && id != 0 ? Value(id) : const Value.absent(), 
      date: Value(targetDate),
      content: Value(text),
      emotions: Value(emotions),
      imagePath: Value(imagePath),
    ),
  );
}

  // ❌ 4. 일정 삭제 (물리적 사진 파일까지 깔끔하게 지우기!)
  Future<void> deleteEntry(DateTime targetDate) async {
    final pureDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    // ① 삭제 전, 먼저 해당 날짜에 저장된 사진 주소가 있는지 조회합니다.
    final existing = await getEntryByDate(pureDate);
    if (existing != null && existing.imagePath != null && existing.imagePath!.isNotEmpty) {
      try {
        // ② 사진 주소가 있다면, 디바이스 내의 실제 파일도 삭제해 줍니다.
        final file = File(existing.imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print("사진 파일 삭제 실패: $e");
      }
    }

    // ③ 최종적으로 DB에서 데이터를 지웁니다.
    await (delete(calendarEntries)..where((t) => t.date.equals(pureDate))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}