import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌐 Easy Localization 임포트!
import '../services/settings_manager.dart';
import 'package:package_info_plus/package_info_plus.dart'; // ⭕ 1. 임포트 추가!
import '../services/backup_service.dart'; //

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'settings.title'.tr(), // 🌐 "설정"
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'settings.section_design'.tr(), // 🌐 "디자인 커스텀"
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 1. 폰트 선택
          ListTile(
            title: Text('settings.font_title'.tr()),
            subtitle: Text(settings.fontFamily),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (modalContext) {
                  // 👈 변수명을 modalContext로 명확히 분리합니다.
                  // ⭕ 핵심: 바텀시트 내부에서도 부모의 settings(Provider)를 정확히 바라보도록 재선언합니다.
                  final currentSettings = Provider.of<SettingsManager>(
                    context,
                    listen: false,
                  );
                  final fonts = SettingsManager.fontList;

                  return ListView.builder(
                    itemCount: fonts.length,
                    itemBuilder: (ctx, index) {
                      final f = fonts[index];
                      final isSelected = currentSettings.fontFamily == f;

                      return ListTile(
                        title: Text(
                          f,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () {
                          // ⭕ 부모 context의 세팅을 변경하여 시스템에 확실하게 전파합니다.
                          currentSettings.setFontFamily(f);
                          Navigator.pop(modalContext);
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          // 2. 격자 색상 선택
          ListTile(
            title: Text('settings.grid_color_title'.tr()), // 🌐 "달력 선 색상 변경"
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: settings.gridLineColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('settings.color_picker_title'.tr()), // 🌐 "색상 선택"
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      // ⚡ BlockPicker를 대형 ColorPicker로 교체!
                      pickerColor: settings.gridLineColor,
                      onColorChanged: (color) {
                        settings.setGridLineColor(color); // 실시간 색상 변경 전파
                      },
                      pickerAreaHeightPercent: 0.8, // 스펙트럼 판의 세로 높이 비율
                      enableAlpha: false, // 투명도 슬라이더 숨기기 (오류 방지용 고정)
                      displayThumbColor: true, // 선택 마커 조절 점 안에 현재 색상 보여주기
                      paletteType: PaletteType.hsv, // 무지개 스펙트럼 + 명도 판 형태
                      labelTypes: const [], // 복잡한 색상 코드 문자열 표기들 숨기기 (UI 깔끔)
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'settings.section_data'.tr(), // 🌐 "데이터 관리"
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 3. 데이터 내보내기 📦
          ListTile(
            leading: const Icon(Icons.file_upload_outlined, color: Colors.blue),
            title: Text('backup_export_title'.tr()), // 🌐 "데이터 내보내기"
            subtitle: Text(
              'backup_export_subtitle'.tr(),
            ), // 🌐 "현재 일기 데이터를 파일로 안전하게 백업합니다."
            onTap: () async {
              // 💡 [핵심] 아이패드/시뮬레이터 대응을 위해 현재 클릭한 버튼의 위치 좌표를 계산합니다.
              final box = context.findRenderObject() as RenderBox?;
              final Rect? sharePositionOrigin = box != null
                  ? box.localToGlobal(Offset.zero) & box.size
                  : null;

              // ⭕ exportBackup 함수에 계산한 좌표(sharePositionOrigin)를 인자로 함께 넘겨줍니다.
              await BackupService.instance.exportBackup(
                (msg) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(msg)));
                },
                sharePositionOrigin: sharePositionOrigin, // 👈 추가된 파라미터!
              );
            },
          ),

          // 4. 데이터 가져오기 📂
          ListTile(
            leading: const Icon(
              Icons.file_download_outlined,
              color: Colors.green,
            ),
            title: Text('backup_import_title'.tr()), // 🌐 "데이터 가져오기"
            subtitle: Text(
              'backup_import_subtitle'.tr(),
            ), // 🌐 "백업된 파일을 가져와 기존 일기 데이터에 덮어씁니다."
            onTap: () async {
              // ⭕ ScaffoldMessenger를 내부에 직접 명시하여 에러를 차단합니다.
              await BackupService.instance.importBackup((msg) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              });
            },
          ),
          // ⭕ [최종 완성본] 데이터 관리 타이틀 레벨과 100% 일치하는 버전 및 Copyright
          const Divider(),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final packageInfo = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(
                    16.0,
                  ), // 👈 대메뉴 타이틀과 정확히 일치하는 여백
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // 👈 왼쪽 라인 칼정렬
                    children: [
                      // 1. 버전 정보
                      Text(
                        'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6), // 💡 버전과 저작권 사이의 자연스러운 간격
                      // 2. 저작권 문구
                      const Text(
                        '© 2026 BiscuitCrumbs. All rights reserved.', // 👈 YourName에 닉네임이나 앱 이름을 적으시면 됩니다!
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize:
                              12, // 💡 저작권은 한 단계 작게 들어가야 UI가 훨씬 세련되게 떨어집니다.
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
