import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cell_data.dart';
import '../models/emotion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
// 💡 파일명 연산을 위해 추가

const englishMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

void showEntryDialog({
  required BuildContext context,
  required DateTime date,
  CalendarCellData? existingData,
  required Function(CalendarCellData) onSave,
}) {
  showDialog(
    context: context,
    builder: (context) => _EntryDialogContent(
      date: date,
      existingData: existingData,
      onSave: onSave,
    ),
  );
}

class _EntryDialogContent extends StatefulWidget {
  final DateTime date;
  final CalendarCellData? existingData;
  final Function(CalendarCellData) onSave;

  const _EntryDialogContent({
    required this.date,
    this.existingData,
    required this.onSave,
  });

  @override
  State<_EntryDialogContent> createState() => _EntryDialogContentState();
}

class _EntryDialogContentState extends State<_EntryDialogContent> {
  late final TextEditingController _memoController;
  final ImagePicker _picker = ImagePicker();

  // 💡 사용자가 새로 고른 사진을 담는 변수
  File? _tempImage;
  List<String> _tempEmotions = [];

  // 💡 기존에 저장되어 있던 파일명을 안전하게 추적하기 위한 변수
  String? _initialFileName;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(
      text: widget.existingData?.memo ?? '',
    );

    // 💡 [안전 보완] 데이터의 감정을 소문자로 바꾸고 앞뒤 공백을 싹 제거하여 저장합니다.
    _tempEmotions = (widget.existingData?.emotions ?? [])
        .map((e) => e.toString().toLowerCase().trim())
        .toList();

    if (widget.existingData != null && widget.existingData!.imagePath != null) {
      _initialFileName = widget.existingData!.imagePath!.split('/').last;
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // 💡 [달력과 동일한 실시간 주소 조립기] 팝업창이 열릴 때 기존 사진을 올바른 경로로 불러옵니다.
  Future<File?> _getInitialImageFile() async {
    if (_initialFileName == null || _initialFileName!.isEmpty) return null;
    final Directory appDir = await getApplicationDocumentsDirectory();
    final File file = File('${appDir.path}/$_initialFileName');
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _memoController.dispose();
    super.dispose();
  }

  void _toggleEmotion(String emotionId) {
    // 💡 인자를 name 대신 id로 받음
    setState(() {
      if (_tempEmotions.contains(emotionId)) {
        _tempEmotions.remove(emotionId); // 이미 있으면 제거
      } else {
        _tempEmotions.add(emotionId); // 없으면 id 추가
      }
    });
  }

  Future<void> _pickAndCropImage() async {
    final File? selectedFile = await _showPhotoPickerBottomSheet(
      context: context,
      date: widget.date,
      picker: _picker,
    );
    if (selectedFile != null) {
      setState(() {
        _tempImage = selectedFile; // 새로 사진을 고르면 여기에 담김
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _buildDialogTitle(),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMemoTextField(),
              const SizedBox(height: 16),
              _buildEmotionSection(),
              const SizedBox(height: 20),
              _buildPhotoSelectionArea(),
            ],
          ),
        ),
      ),
      actions: _buildActionButtons(),
    );
  }

  Widget _buildDialogTitle() {
    final titleText = 'date_record_title'.tr(
      namedArgs: {
        'monthName': context.locale.languageCode == 'en'
            ? englishMonths[widget.date.month - 1]
            : widget.date.month.toString(),
        'month': widget.date.month.toString(),
        'day': widget.date.day.toString(),
      },
    );
    return Text(
      titleText,
      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMemoTextField() {
    return TextField(
      controller: _memoController,
      decoration: const InputDecoration(hintText: "Today's Memo..."),
      maxLines: 2,
    );
  }

  Widget _buildEmotionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'pick_feelings'.tr(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        _buildEmotionGridList(positiveEmotions),
        const SizedBox(height: 16),
        _buildEmotionGridList(negativeEmotions),
      ],
    );
  }

  Widget _buildEmotionGridList(List<EmotionData> emotions) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: emotions.map((e) {
        // 💡 [안전 보완] DB에서 온 데이터와 현재 고유 id의 대소문자/공백 차이를 완벽히 방어하며 인덱스를 찾습니다.
        final targetId = e.id.toString().toLowerCase().trim();
        final index = _tempEmotions.indexWhere(
          (savedId) => savedId.toString().toLowerCase().trim() == targetId,
        );

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _EmotionButton(
              emotion: e,
              selectIndex: index,
              onTap: () => _toggleEmotion(targetId), // 소문자 정제된 id 전송
            ),
          ),
        );
      }).toList(),
    );
  }

  // 💡 [수리 핵심 부위] 새로 고른 사진이 있으면 그걸 보여주고, 없으면 기존 사진을 실시간 조립해서 띄웁니다!
  Widget _buildPhotoSelectionArea() {
    if (_tempImage != null) {
      // 1. 방금 갤러리에서 새로 고르고 크롭한 사진이 있을 때
      return GestureDetector(
        onTap: _pickAndCropImage,
        child: AspectRatio(
          aspectRatio: 1 / 1.3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildSelectedPhotoStack(_tempImage!),
          ),
        ),
      );
    } else {
      // 2. 새로 고른 사진이 없을 때 -> 기존에 저장된 사진이 있는지 실시간 체크
      return FutureBuilder<File?>(
        future: _getInitialImageFile(),
        builder: (context, snapshot) {
          final File? savedFile = snapshot.data;

          if (savedFile != null) {
            return GestureDetector(
              onTap: _pickAndCropImage,
              child: AspectRatio(
                aspectRatio: 1 / 1.3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildSelectedPhotoStack(savedFile),
                ),
              ),
            );
          }

          // 3. 사진이 아예 등록되지 않은 상태일 때 (기본 빈 화면)
          return GestureDetector(
            onTap: _pickAndCropImage,
            child: Container(
              height: 145,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _buildEmptyPhotoIcon(),
            ),
          );
        },
      );
    }
  }

  Widget _buildSelectedPhotoStack(File targetFile) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(targetFile, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _tempImage = null;
                _initialFileName = null; // 기존 사진도 날림 처리
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPhotoIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 32,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 10),
        Text(
          'Select Photo',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('cancel'.tr()),
      ),
      ElevatedButton(
        onPressed: () async {
          // 📝 [로그 1] 세이브 버튼이 눌렸을 때 현재 상태 파악
          // debugPrint("📱 [DIARY_SAVE_START] ===== 저장 프로세스 시작 =====");
          // debugPrint("📱 [DIARY_SAVE_START] 기존 데이터 존재 여부: ${widget.existingData != null}");
          // if (widget.existingData != null) {
          //   debugPrint("📱 [DIARY_SAVE_START] 기존 DB ID: ${widget.existingData!.id}");
          //   debugPrint("📱 [DIARY_SAVE_START] 기존 DB 저장된 사진경로: ${widget.existingData!.imagePath}");
          // }
          // debugPrint("📱 [DIARY_SAVE_START] 현재 선택된 임시사진(_tempImage) 존재여부: ${_tempImage != null}");
          // debugPrint("📱 [DIARY_SAVE_START] 현재 유지중인 파일명(_initialFileName): $_initialFileName");

          final List<String> realUserEmotions = _tempEmotions
              .where((e) => e.toString().toLowerCase().trim() != '_delete_')
              .toList();

          final bool isMemoEmpty = _memoController.text.trim().isEmpty;
          final bool isEmotionEmpty = realUserEmotions.isEmpty;
          final bool isImageEmpty =
              (_tempImage == null && _initialFileName == null);

          // debugPrint("📱 [DIARY_CONDITIONS] 빈값 검사 결과 -> 메모 빔: $isMemoEmpty, 감정 빔: $isEmotionEmpty, 사진 빔: $isImageEmpty");

          // -------------------------------------------------------------
          // 1. 🗑️ [케이스 A] 그 날짜 데이터 전체를 완전히 지우는 경우 (메모, 감정, 사진 모두 전멸)
          // -------------------------------------------------------------
          if (isMemoEmpty && isEmotionEmpty && isImageEmpty) {
            // debugPrint("🚨 [DIARY_BRANCH] 👉 [케이스 A] 전체 삭제 조건문 진입!");
            if (widget.existingData != null) {
              if (widget.existingData!.imagePath != null &&
                  widget.existingData!.imagePath!.isNotEmpty) {
                try {
                  final oldFile = File(widget.existingData!.imagePath!);
                  final bool exists = await oldFile.exists();
                  // debugPrint("🚨 [물리삭제_A] 실제 파일이 기기에 존재하나요?: $exists");

                  if (exists) {
                    await oldFile.delete();
                    // debugPrint("🗑️ [물리삭제_A] 성공! 기기 내부 그림 파일 삭제 완료: ${widget.existingData!.imagePath}");
                  }
                } catch (e) {
                  // debugPrint("🔥 [물리삭제_A] 파일 에러 발생: $e");
                }
              }

              final deleteSignalData = CalendarCellData(
                id: widget.existingData!.id, // ⭕ 괄호 안으로 이동
                date: widget.existingData!.date, // ⭕ 괄호 안으로 이동
                memo: '',
                emotions: ['_DELETE_'],
                imagePath: null, // ⭕ 필수값 추가
              );

              widget.onSave(deleteSignalData);
            } else {
              // debugPrint("🚨 [DIARY_BRANCH] 기존 데이터가 없던 날이라 삭제신호 없이 종료");
              if (context.mounted) Navigator.pop(context);
              return;
            }
            if (context.mounted) Navigator.pop(context);
            return;
          }

          // -------------------------------------------------------------
          // 2. 📸 [케이스 B] 일기(글/감정)는 놔두고 "사진만" 쏙 지우고 저장한 경우
          // -------------------------------------------------------------
          // debugPrint("📱 [DIARY_BRANCH] 케이스 B 진입 전 검증 조건문 작동중...");
          if (widget.existingData != null &&
              widget.existingData!.imagePath != null &&
              widget.existingData!.imagePath!.isNotEmpty &&
              _tempImage == null &&
              _initialFileName == null) {
            // debugPrint("🚨 [DIARY_BRANCH] 👉 [케이스 B] 사진만 삭제 조건문 충족되어 진입!");
            try {
              final oldFile = File(widget.existingData!.imagePath!);
              final bool exists = await oldFile.exists();
              // debugPrint("🚨 [물리삭제_B] 실제 파일이 기기에 존재하나요?: $exists");

              if (exists) {
                await oldFile.delete();
                // debugPrint("🗑️ [물리삭제_B] 성공! widget.existingData 경로로 물리 파일 파쇄 완료: ${widget.existingData!.imagePath}");
              } else {
                // debugPrint("⚠️ [물리삭제_B] 경로 텍스트는 있는데, 실제 기기 폴더 안에 파일이 실종된 상태입니다.");
              }
            } catch (e) {
              // debugPrint("🔥 [물리삭제_B] 파일 오류: $e");
            }
          } else {
            // debugPrint("📱 [DIARY_BRANCH] 케이스 B 조건 미충족 (사진만 삭제한 게 아님)");
          }

          // -------------------------------------------------------------
          // 🟢 3. 정상 저장 및 수정 로직 진행
          // -------------------------------------------------------------
          // debugPrint("📱 [DIARY_BRANCH] 👉 [일반 저장/수정] 프로세스로 진입합니다.");
          File? finalSavedImage;

          if (_tempImage != null) {
            try {
              final appDir = await getApplicationDocumentsDirectory();

              // 1. 🌟 [핵심 변경] 저장 시점의 시간이 아니라, 일기가 지정된 날짜를 파일명으로 사용합니다!
              // 예: widget.day가 2026년 5월 31일이라면 -> 'diary_20260531.jpg'가 됩니다.
              final String dateStr =
                  "${widget.date.year}${widget.date.month.toString().padLeft(2, '0')}${widget.date.day.toString().padLeft(2, '0')}";
              final String permanentPath = '${appDir.path}/diary_$dateStr.jpg';
              final newFile = File(permanentPath);

              // 2. 🛡️ [충돌 방지 방어 코드] 만약 해당 날짜로 이미 저장된 옛날 사진 파일이 '폴더에 물리적으로 존재'한다면 먼저 싹 지워줍니다.
              if (await newFile.exists()) {
                await newFile.delete();
                // debugPrint("🔄 [동일날짜교체] 기존 날짜 파일이 존재하여 덮어쓰기 전 파쇄 완료");
              }

              // 3. 🛡️ [기존 파일 삭제] 만약 기존 데이터의 경로가 새로 지정할 경로(permanentPath)와 다르고, 물리적으로 존재한다면 지워줍니다.
              if (widget.existingData != null &&
                  widget.existingData!.imagePath != null &&
                  widget.existingData!.imagePath!.isNotEmpty) {
                final oldFile = File(widget.existingData!.imagePath!);
                // 새로 만들 파일(newFile)과 기존 파일(oldFile)의 경로가 다를 때만 안전하게 지워줍니다.
                if (oldFile.path != newFile.path && await oldFile.exists()) {
                  await oldFile.delete();
                  // debugPrint("🔄 [사진교체] 옛날 다른 경로의 물리 사진 파쇄 완료");
                }
              }

              // 4. 새 사진을 지정된 날짜 이름의 경로로 복사합니다.
              finalSavedImage = await _tempImage!.copy(permanentPath);
              _initialFileName =
                  null; // 🌟 [버그 수정 핵심] 새 사진 복사가 완벽히 완료되었으므로, 옛날 사진 이름 찌꺼기를 완전히 파쇄하여 교체 타이밍이 밀리는 현상을 원천 차단합니다!
              // debugPrint("📸 [사진복사] 날짜 이름으로 영구 저장 완료: $permanentPath");
            } catch (e) {
              // debugPrint("📸 [DIARY_SAVE] Copy Error: $e");
              finalSavedImage = _tempImage;
            }
          } else if (_initialFileName != null) {
            final appDir = await getApplicationDocumentsDirectory();
            finalSavedImage = File('${appDir.path}/$_initialFileName');
            // debugPrint("📸 [사진유지] 기존 사진을 그대로 유지합니다: ${finalSavedImage.path}");
          }

          final newData = CalendarCellData(
            id: widget.existingData?.id ?? 0, // ⭕ 추가
            date: DateTime(
              widget.date.year,
              widget.date.month,
              widget.date.day,
            ), // ⭕ 추가
            memo: _memoController.text,
            emotions: realUserEmotions,
            imagePath:
                finalSavedImage?.path, // ⭕ 'image: finalSavedImage'를 이렇게 변경!
          );

          // debugPrint("📱 [DIARY_SAVE_END] 최종 전달 데이터 -> ID: ${newData.id}, 메모: ${newData.memo}, 감정: ${newData.emotions}, 사진경로: ${newData.imagePath}");
          widget.onSave(newData);
          if (context.mounted) Navigator.pop(context);
        },
        child: Text('save'.tr()),
      ),
    ];
  }
}

class _EmotionButton extends StatelessWidget {
  final EmotionData emotion;
  final int selectIndex;
  final VoidCallback onTap;

  const _EmotionButton({
    required this.emotion,
    required this.selectIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectIndex != -1;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? emotion.color.withValues(alpha: 0.2)
                      : Colors.grey[100],
                  border: Border.all(
                    color: isSelected ? emotion.color : Colors.grey.shade300,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(emotion.imagePath, fit: BoxFit.contain),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: emotion.color,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${selectIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // 💡 [수정] 위젯 레벨에서 새로 개편한 translationKey에 직접 .tr()을 붙여 번역을 강제합니다!
          Text(
            emotion.translationKey.tr(),
            maxLines: 1, // 무조건 한 줄로만 나오게 제한
            softWrap: false, // 자동 줄바꿈 금지
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<AssetEntity>> _fetchPhotosByDate(DateTime selectedDate) async {
  await PhotoManager.requestPermissionExtend();

  final DateTime startTime = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    4,
    0,
    0,
  );
  final DateTime endTime = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day + 1,
    3,
    59,
    59,
  );

  final FilterOptionGroup filterOption = FilterOptionGroup(
    imageOption: const FilterOption(
      sizeConstraint: SizeConstraint(minWidth: 10, minHeight: 10),
    ),
    createTimeCond: DateTimeCond(min: startTime, max: endTime),
    orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
  );

  final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    filterOption: filterOption,
  );

  if (albums.isEmpty) return [];
  return await albums[0].getAssetListRange(start: 0, end: 100);
}

Future<File?> _showPhotoPickerBottomSheet({
  required BuildContext context,
  required DateTime date,
  required ImagePicker picker,
}) {
  return showModalBottomSheet<File?>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;

      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height *
                (isLandscape ? 0.85 : 0.45),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Photos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final XFile? pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (pickedFile != null && context.mounted) {
                        final File? cropped = await _cropImage(pickedFile.path);

                        if (cropped != null && context.mounted) {
                          Navigator.pop(context, cropped);
                        }
                      }
                    },
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text(
                      'All Photos',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<AssetEntity>>(
                  future: _fetchPhotosByDate(date),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final photos = snapshot.data ?? [];
                    if (photos.isEmpty) {
                      return const Center(
                        child: Text(
                          'No photos taken on this day. \nPlease use the [All Photos] button to view your gallery.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      );
                    }
                    return GridView.builder(
                      scrollDirection: Axis.vertical,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isLandscape ? 8 : 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final entity = photos[index];
                        return GestureDetector(
                          onTap: () async {
                            final File? file = await entity.file;
                            if (file != null && context.mounted) {
                              final File? cropped = await _cropImage(file.path);

                              if (cropped != null && context.mounted) {
                                Navigator.pop(context, cropped);
                              }
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<dynamic>(
                              future: entity.thumbnailDataWithSize(
                                const ThumbnailSize.square(200),
                              ),
                              builder: (context, byteSnapshot) {
                                if (byteSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final bytes = byteSnapshot.data;
                                if (bytes == null) {
                                  return Container(color: Colors.grey[200]);
                                }
                                return Image.memory(bytes, fit: BoxFit.cover);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<File?> _cropImage(String sourcePath) async {
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    maxWidth: 1080, // 가로 최대 1080px
    maxHeight: 1404, // 세로 최대 1404px (1:1.3 비율을 고려한 해상도)
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1.3),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Cropping Photo',
        toolbarColor: Colors.white,
        toolbarWidgetColor: Colors.black,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: true,
      ),
      IOSUiSettings(
        title: 'Cropping Photo',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        hidesNavigationBar: false,
        aspectRatioPickerButtonHidden: false, 
        showActivitySheetOnDone: false,
      ),
    ],
  );
  return croppedFile != null ? File(croppedFile.path) : null;
}
