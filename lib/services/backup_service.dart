import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';

// 우리가 만든 DB 서비스와 데이터 모델을 가져옵니다.
import 'db_service.dart';
import '../models/cell_data.dart';

class BackupService {
  // 싱글톤 패턴으로 어디서든 편하게 부를 수 있게 만듭니다.
  static final BackupService instance = BackupService._init();
  BackupService._init();

  /// 📦 1. 데이터 백업 (Export) 함수
  Future<void> exportBackup(void Function(String message) showMessage) async {
    try {
      showMessage('backup_preparing'.tr()); // "백업 기능을 준비 중입니다!" 또는 커스텀 메시지

      // 1. Isar DB에서 모든 일기 데이터 가져오기
      final allCells = await DriftDbService.instance.getAllCellData();
      if (allCells.isEmpty) {
        showMessage('backup_no_data'.tr());
        return;
      }

      // 2. 데이터를 JSON 문자열로 변환하기
      final List<Map<String, dynamic>> jsonList = allCells.map((cell) {
        return {
          'id': cell.id,
          'date': cell.date.toIso8601String(), // 날짜는 글자 형태로 안전하게 변환
          'memo': cell.memo,                   // 일기 내용 (memo)
          'imagePath': cell.imagePath,         // 사진 파일명
          'emotions': cell.emotions,           // 감정 리스트
        };
      }).toList();
      final String jsonString = jsonEncode(jsonList);

      // 3. 사진들이 저장되어 있는 앱의 영구 폴더 경로 찾기
      final docDir = await getApplicationDocumentsDirectory();
      
      // 4. 압축 파일(ZIP)을 임시로 만들어줄 메모리 주머니(Archive) 생성
      final encoder = ZipFileEncoder();
      final tempDir = await getTemporaryDirectory();
      final String zipPath = '${tempDir.path}/diary_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      
      // 압축 파일 만들기 시작!
      encoder.create(zipPath);

      // 5. 메모리 공간에 JSON 텍스트 파일을 가상으로 만들어 ZIP 안에 쏙 넣어주기
      final List<int> jsonBytes = utf8.encode(jsonString);
      encoder.addArchiveFile(ArchiveFile('diary_backup.json', jsonBytes.length, jsonBytes));

      // 6. 영구 폴더 뒤져서 실제 사진 파일들(.jpg)도 ZIP 안에 쏙쏙 넣어주기
      final directoryList = docDir.listSync();
      int imageCount = 0;
      
      for (var entity in directoryList) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          // 파일명만 순수하게 추출 (예: path/2026-06-16.jpg -> 2026-06-16.jpg)
          final String fileName = entity.path.split('/').last;
          encoder.addFile(entity, fileName);
          imageCount++;
        }
      }

      // 압축 주머니 닫기 (완성!)
      encoder.close();

      // 7. 🎉 대망의 공유 창(Share Sheet) 띄우기!
      // 유저가 카톡, 메일, 드라이브 등 원하는 곳으로 압축파일을 보낼 수 있게 만듭니다.
      final XFile xFile = XFile(zipPath);
      await Share.shareXFiles(
        [xFile],
        text: 'backup_share_text'.tr(namedArgs: {
          'dataCount': jsonList.length.toString(),
          'imageCount': imageCount.toString(),
        }), // "내 달력 일기장 백업 파일 (데이터 {dataCount}건, 사진 {imageCount}장)"
      );

      // 💡 [변경] 한글 메시지 로컬라이제이션 적용 완료
      showMessage('backup_export_success'.tr());
    } catch (e) {
      // 💡 [변경] 에러 메시지 템플릿 로컬라이제이션 적용 완료
      showMessage('backup_export_failed'.tr(namedArgs: {'error': e.toString()}));
    }
  }

  /// 📂 2. 데이터 복구 (Import) 함수
  Future<void> importBackup(void Function(String message) showMessage) async {
    try {
      // 1. 유저에게 파일 선택창을 띄워 .zip 파일 고르게 하기
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'], // 오직 zip 파일만 선택 가능
      );

      if (result == null || result.files.single.path == null) {
        // 💡 [변경] 한글 메시지 로컬라이제이션 적용 완료
        showMessage('backup_import_no_file'.tr());
        return;
      }

      showMessage('backup_importing'.tr());

      // 2. 선택된 압축 파일 읽기
      final File zipFile = File(result.files.single.path!);
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 3. 앱의 영구 저장 폴더 경로 디렉토리 찾기
      final docDir = await getApplicationDocumentsDirectory();
      
      String? jsonContent;
      int imageCount = 0;

      // 4. 압축 파일 내부를 하나씩 순회하며 풀기
      for (final file in archive) {
        if (file.isFile) {
          if (file.name == 'diary_backup.json') {
            // 가상으로 저장된 JSON 텍스트 추출
            jsonContent = utf8.decode(file.content as List<int>);
          } else if (file.name.endsWith('.jpg')) {
            // 사진 파일은 앱의 영구 폴더에 진짜 파일로 복원 저장
            final File imgFile = File('${docDir.path}/${file.name}');
            imgFile.writeAsBytesSync(file.content as List<int>);
            imageCount++;
          }
        }
      }

      // 5. 만약 핵심 데이터인 JSON 파일이 없다면 복구 중단
      if (jsonContent == null) {
        // 💡 [변경] 한글 메시지 로컬라이제이션 적용 완료
        showMessage('backup_import_invalid_file'.tr());
        return;
      }

      // 6. JSON 텍스트를 다시 맵 리스트로 복원 파싱
      final List<dynamic> decodedList = jsonDecode(jsonContent);
      
      // 7. 파싱된 데이터를 바탕으로 하나씩 Isar DB용 모델 인스턴스로 복원
      final List<CalendarCellData> cellsToRestore = decodedList.map((item) {
        // 💡 [안전 필터 강화] 복구 시점에 공백 제거 및 소문자 치환을 무조건 거치게 만듭니다.
        final List<String> rawEmotions = List<String>.from(item['emotions'] as List);
        final List<String> cleanEmotions = rawEmotions
            .map((e) => e.toString().toLowerCase().trim())
            .where((e) => e.isNotEmpty)
            .toList();

        // 괄호 안에 id, date, memo, emotions, imagePath를 정렬하여 한 번에 넣어줍니다!
        final cell = CalendarCellData(
          id: item['id'] as int,
          date: DateTime.parse(item['date'] as String),
          memo: item['memo'] as String,
          emotions: cleanEmotions,
          imagePath: item['imagePath'] as String?,
        );
        
        return cell; //
      }).toList(); //

      // 8. 💾 🎉 대망의 Isar DB 일괄 저장 (기존 id가 있으면 자동 덮어쓰기 처리)
      for (var cell in cellsToRestore) {
        await DriftDbService.instance.saveCellData(cell); 
      }

      // 💡 [변경] 복구 완료 메시지 변수 매핑(namedArgs) 로컬라이제이션 적용 완료
      showMessage('backup_import_success'.tr(namedArgs: {
        'dataCount': cellsToRestore.length.toString(),
        'imageCount': imageCount.toString(),
      }));
    } catch (e) {
      // 💡 [변경] 에러 메시지 템플릿 로컬라이제이션 적용 완료
      showMessage('backup_import_failed'.tr(namedArgs: {'error': e.toString()}));
    }
  }
}