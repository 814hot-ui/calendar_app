import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/cell_data.dart';

class IsarDbService {
  // 💡 앱 전체에서 단 하나의 창구만 쓰도록 싱글톤(Singleton) 구조 유지
  static final IsarDbService instance = IsarDbService._internal();
  factory IsarDbService() => instance;
  IsarDbService._internal();

  late Isar _isar;

  // 1. 데이터베이스 초기화 (Isar 3버전은 'schema' 단수형을 사용합니다)
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    // 💡 Isar 3버전은 매개변수 이름 없이 대괄호 안이나 함수 안에 바로 스키마를 꽂아줍니다!
    _isar = await Isar.open(
      [CalendarCellDataSchema], // 👈 schema: 나 schemas: 를 과감히 지우고 이것만 남기세요!
      directory: dir.path,
    );
  }

  // 2. 일기 저장 또는 수정 (3버전은 writeTxn 비동기 트랜잭션을 사용합니다)
  Future<void> saveCellData(CalendarCellData data) async {
    await _isar.writeTxn(() async {
      await _isar.calendarCellDatas.put(data);
    });
  }

  // 3. 특정 날짜의 일기 하나만 가져오기 (3버전은 조회도 비동기로 처리합니다)
  Future<CalendarCellData?> getCellDataByDate(DateTime date) async {
    final targetDate = DateTime(date.year, date.month, date.day);

    return await _isar.calendarCellDatas
        .where()
        .dateEqualTo(targetDate)
        .findFirst();
  }

  // 4. 모든 일기 데이터 가져오기 (비동기로 전체 리스트를 반환합니다)
  Future<List<CalendarCellData>> getAllCellData() async {
    return await _isar.calendarCellDatas.where().findAll();
  }

  // 5. 일기 삭제 (저장과 마찬가지로 writeTxn으로 안전하게 지웁니다)
  Future<void> deleteCellData(int id) async {
    await _isar.writeTxn(() async {
      await _isar.calendarCellDatas.delete(id);
    });
  }
}
