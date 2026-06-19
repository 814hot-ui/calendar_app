import '../database.dart'; // 방금 만든 새로운 데이터베이스 설계도를 가져옵니다.
import '../models/cell_data.dart'; // 기존의 데이터 전달 클래스

class DriftDbService {
  // 💡 다른 화면 코드(main, dialog 등)를 안 건드리게 하기 위해, 기존 이름 'DriftDbService'와 'instance'를 그대로 유지합니다!
  static final DriftDbService instance = DriftDbService._internal();
  factory DriftDbService() => instance;
  DriftDbService._internal();

  // 진짜 데이터베이스 인스턴스 보관함
  late AppDatabase _db;

  // 1. 데이터베이스 문 열기 (초기화)
  Future<void> init() async {
    _db = AppDatabase();
  }

  // 💡 [_convertToCellData] Drift가 반환한 DB 전용 클래스(CalendarEntry)를 
  // 기존 화면 코드들이 이해할 수 있는 클래스(CalendarCellData)로 바꿔주는 통역기입니다.
  CalendarCellData _convertToCellData(CalendarEntry entry) {
    return CalendarCellData(
      id: entry.id,
      date: entry.date,
      memo: entry.content,
      emotions: entry.emotions,
      imagePath: entry.imagePath,
    );
  }

  // 2. 일기 저장 또는 수정
  Future<void> saveCellData(CalendarCellData data) async {
    await _db.saveEntry(
      id: data.id, // ⭕ 드디어 끊어졌던 ID 파이프라인을 확실하게 연결해 줍니다!
      targetDate: data.date,
      text: data.memo,
      emotions: data.emotions,
      imagePath: data.imagePath,
    );
  }

  // 3. 특정 날짜의 일기 하나만 가져오기
  Future<CalendarCellData?> getCellDataByDate(DateTime date) async {
    final entry = await _db.getEntryByDate(date);
    if (entry == null) return null;
    return _convertToCellData(entry);
  }

  // 4. 모든 일기 데이터 가져오기 (백업용 기능)
  Future<List<CalendarCellData>> getAllCellData() async {
    final entries = await _db.getAllEntries();
    return entries.map((e) => _convertToCellData(e)).toList();
  }

  // 5. 일기 삭제 (특정 날짜 기준으로 안전하게 삭제)
  Future<void> deleteCellData(int id, DateTime date) async {
    // 기존에 id만 받던 것에서 date도 안전하게 받아서 처리하도록 보완합니다.
    await _db.deleteEntry(date);
  }
}