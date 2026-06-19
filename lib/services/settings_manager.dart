import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsManager with ChangeNotifier {
  // 1. 기본값 세팅 (처음 앱을 깔았을 때 기준)
  String _fontFamily = '기본글꼴';
  Color _gridLineColor = const Color(0xFFF2F2F2); // 기본 회색 선

  String get fontFamily => _fontFamily;
  Color get gridLineColor => _gridLineColor;

  // ⭕ [중앙 관리 핵심] 이제 설정 창과 매니저가 공유할 단 하나의 폰트 리스트입니다!
  static const List<String> fontList = [
    '기본글꼴', 
    '나눔고딕', 
    '나눔명조', 
    '나눔손글씨 붓', 
    '주아', 
    '도현', 
    '동글', 
    '고운돋움',
    'Quicksand',
    'Roboto',
    'Lato',
    'Montserrat',
    'Nunito',
    'Noto Sans',
    'Anton',
    'Space Grotesk',
    'Oswald',
    'Poppins',
  ];

  // 2. 클래스가 생성될 때 자동으로 저장된 데이터를 불러옵니다.
  SettingsManager() {
    _loadSettings();
  }

  // ⭕ 단일화된 폰트 매핑 함수
  TextStyle getGoogleFontStyle() {
    switch (_fontFamily) {
      case '나눔고딕': return GoogleFonts.nanumGothic();
      case '나눔명조': return GoogleFonts.nanumMyeongjo();
      case '나눔손글씨 붓': return GoogleFonts.nanumBrushScript();
      case '주아': return GoogleFonts.jua();
      case '도현': return GoogleFonts.doHyeon();
      case '동글': return GoogleFonts.dongle();
      case '고운돋움': return GoogleFonts.gowunDodum();
      case 'Quicksand': return GoogleFonts.quicksand();
      case 'Roboto': return GoogleFonts.roboto();
      case 'Lato': return GoogleFonts.lato();
      case 'Montserrat': return GoogleFonts.montserrat();
      case 'Nunito': return GoogleFonts.nunito();
      case 'Noto Sans': return GoogleFonts.notoSans();  
      case 'Anton': return GoogleFonts.anton();
      case 'Space Grotesk': return GoogleFonts.spaceGrotesk();
      case 'Oswald': return GoogleFonts.oswald();
      case 'Poppins': return GoogleFonts.poppins();
      
      default: return const TextStyle(); 
    }
  }

  // 3️⃣ [통합 관리] main.dart의 전체 테마(getTextTheme)용 공식 구글 영문명 변환기
  String getGoogleFontFamilyName() {
    switch (_fontFamily) {
      case '나눔고딕': return 'Nanum Gothic';
      case '나눔명조': return 'Nanum Myeongjo';
      case '나눔손글씨 붓': return 'Nanum Brush Script';
      case '주아': return 'Jua';
      case '도현': return 'Do Hyeon';
      case '동글': return 'Dongle';
      case '고운돋움': return 'Gowun Dodum';
      default: return _fontFamily; // 영문 폰트는 문자열 그대로 사용 가능
    }
  }

  // 📥 폰 기기 내부에서 저장된 설정 값 읽어오기
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 저장된 폰트 가져오기 (없으면 '기본글꼴')
    _fontFamily = prefs.getString('fontFamily') ?? '기본글꼴';
    
    // 저장된 색상 코드(정수형) 가져오기 (없으면 기본 회색 코드)
    final colorValue = prefs.getInt('gridLineColor');
    if (colorValue != null) {
      _gridLineColor = Color(colorValue);
    }
    
    notifyListeners(); // 📣 달력 화면에 "저장된 값으로 다 갱신해!"라고 알림
  }

  // 💾 폰트 변경 및 영구 저장
  Future<void> setFontFamily(String font) async {
    _fontFamily = font;
    notifyListeners(); // 실시간 반영
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', font); // 폰 기기에 영구 박제 🔒
  }

  // 💾 색상 변경 및 영구 저장
  Future<void> setGridLineColor(Color color) async {
    _gridLineColor = color;
    notifyListeners(); // 실시간 반영
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gridLineColor', color.toARGB32());
  }
}