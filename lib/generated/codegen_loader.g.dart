// DO NOT EDIT. This is code generated via package:easy_localization/generate.dart

// ignore_for_file: prefer_single_quotes, avoid_renaming_method_parameters, constant_identifier_names

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' show AssetLoader;

class CodegenLoader extends AssetLoader{
  const CodegenLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    return Future.value(mapLocales[locale.toString()]);
  }

  static const Map<String,dynamic> _en = {
  "app_title": "BiscuitCalendar",
  "date_record_title": "Record for {monthName} {day}",
  "today": "Today",
  "memo_hint": "Record today's memo...",
  "save": "Save",
  "cancel": "Cancel",
  "gallery_title_filtered": "Photos on this date",
  "gallery_title_all": "All Photos",
  "view_all": "Show All",
  "view_filtered": "Filter Date",
  "crop_title": "Crop Photo",
  "sun": "SUN",
  "mon": "MON",
  "tue": "TUE",
  "wed": "WED",
  "thu": "THU",
  "fri": "FRI",
  "sat": "SAT",
  "happy": "Happy",
  "joy": "Joy",
  "love": "Love",
  "proud": "Proud",
  "calm": "Calm",
  "sad": "Sad",
  "stressed": "Stressed",
  "angry": "Angry",
  "anxious": "Anxious",
  "tired": "Tired",
  "pick_feelings": "Today's Feelings (Max 3)",
  "backup_title": "Data Backup / Restore",
  "backup_export_title": "Export Current Data",
  "backup_export_subtitle": "Bundle diary text and photos into a single file for export.",
  "backup_import_title": "Import Backup File",
  "backup_import_subtitle": "Import a previously backed-up file to restore your data.",
  "backup_preparing": "Preparing backup functionality!",
  "backup_importing": "Importing backup, please wait...",
  "backup_share_text": "My Calendar Diary Backup File ({dataCount} data, {imageCount} photos)",
  "backup_export_success": "Backup export completed successfully!",
  "backup_export_failed": "Backup export failed. Error: {error}",
  "backup_import_success": "Backup file restore completed successfully! (Data: {dataCount}, Photos: {imageCount})",
  "backup_import_failed": "Backup file restore failed. Error: {error}",
  "backup_no_data": "No data available for backup.",
  "backup_import_no_file": "Please select a backup file to restore.",
  "backup_import_invalid_file": "The selected file is not a valid backup file."
};
static const Map<String,dynamic> _ko = {
  "app_title": "비스킷 캘린더",
  "date_record_title": "{month}월 {day}일 기록",
  "today": "오늘",
  "memo_hint": "오늘의 메모를 기록하세요...",
  "save": "저장",
  "cancel": "취소",
  "gallery_title_filtered": "이 날짜에 찍은 사진",
  "gallery_title_all": "전체 사진 보기",
  "view_all": "전체보기",
  "view_filtered": "날짜제한",
  "crop_title": "사진 자르기",
  "sun": "일",
  "mon": "월",
  "tue": "화",
  "wed": "수",
  "thu": "목",
  "fri": "금",
  "sat": "토",
  "happy": "행복",
  "joy": "즐거움",
  "love": "사랑",
  "proud": "뿌듯",
  "calm": "평온",
  "sad": "슬픔",
  "stressed": "스트레스",
  "angry": "화남",
  "anxious": "불안",
  "tired": "피곤",
  "pick_feelings": "오늘의 감정 (최대 3개)",
  "backup_title": "데이터 백업 / 복구",
  "backup_export_title": "현재 데이터 백업하기",
  "backup_export_subtitle": "일기 텍스트와 사진을 하나의 파일로 내보냅니다.",
  "backup_import_title": "백업 파일로 복구하기",
  "backup_import_subtitle": "이전에 백업한 파일을 가져와 데이터를 복원합니다.",
  "backup_preparing": "백업 기능을 준비 중입니다!",
  "backup_importing": "백업 파일을 가져오는 중입니다. 잠시만 기다려주세요...",
  "backup_share_text": "내 달력 일기장 백업 파일 (데이터 {dataCount}건, 사진 {imageCount}장)",
  "backup_export_success": "백업 내보내기가 성공적으로 완료되었습니다!",
  "backup_export_failed": "백업 내보내기에 실패했습니다. 오류: {error}",
  "backup_import_success": "백업 파일 복구가 성공적으로 완료되었습니다! (데이터: {dataCount}건, 사진: {imageCount}장)",
  "backup_import_failed": "백업 파일 복구에 실패했습니다. 오류: {error}",
  "backup_no_data": "백업할 데이터가 없습니다.",
  "backup_import_no_file": "복구할 백업 파일을 선택해주세요.",
  "backup_import_invalid_file": "선택하신 파일은 유효한 백업 파일이 아닙니다."
};
static const Map<String, Map<String,dynamic>> mapLocales = {"en": _en, "ko": _ko};
}
