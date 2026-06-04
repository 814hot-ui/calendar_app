import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cell_data.dart';
import '../models/emotion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/services.dart';

const englishMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

// ==========================================
// 📄 [1] 메인 다이얼로그 실행 함수 (외부 호출용)
// ==========================================
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

// ==========================================
// 🏛️ [2] 다이얼로그 메인 콘텐츠 위젯 (상태 관리)
// ==========================================
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
  File? _tempImage;
  List<String> _tempEmotions = [];

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.existingData?.memo ?? '');
    _tempImage = widget.existingData?.image;
    _tempEmotions = List<String>.from(widget.existingData?.emotions ?? []);

    // 📱 다이얼로그 진입 시 세로 모드 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // 🔄 다이얼로그 해제 시 화면 회전 잠금 풀기
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _memoController.dispose();
    super.dispose();
  }

  // 감정 선택 토글 로직
  void _toggleEmotion(String emotionName) {
    setState(() {
      if (_tempEmotions.contains(emotionName)) {
        _tempEmotions.remove(emotionName);
      } else {
        if (_tempEmotions.length >= 3) return;
        _tempEmotions.add(emotionName);
      }
    });
  }

  // 📸 비즈니스 로직: 사진 피커 호출 및 상태 갱신
  Future<void> _pickAndCropImage() async {
    final File? selectedFile = await _showPhotoPickerBottomSheet(
      context: context,
      date: widget.date,
      picker: _picker,
    );
    if (selectedFile != null) {
      setState(() {
        _tempImage = selectedFile;
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
              _buildMemoTextField(),      // 📝 1. 메모 입력 필드
              const SizedBox(height: 16),
              _buildEmotionSection(),     // 🎨 2. 감정 선택 영역 (긍정/부정)
              const SizedBox(height: 20),
              _buildPhotoSelectionArea(), // 📸 3. 1:1.3 종횡비 사진 영역
            ],
          ),
        ),
      ),
      actions: _buildActionButtons(),     // 🤝 4. 하단 액션 버튼 영역
    );
  }

  // ==========================================
  // 🛠️ 가독성을 높이기 위해 분리한 세부 UI 위젯들
  // ==========================================

  // 1. 타이틀 영역
  Widget _buildDialogTitle() {
    final titleText = 'date_record_title'.tr(namedArgs: {
      'monthName': context.locale.languageCode == 'en'
          ? englishMonths[widget.date.month - 1]
          : widget.date.month.toString(),
      'month': widget.date.month.toString(),
      'day': widget.date.day.toString(),
    });
    return Text(
      titleText,
      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
    );
  }

  // 2. 메모 입력 필드
  Widget _buildMemoTextField() {
    return TextField(
      controller: _memoController,
      decoration: const InputDecoration(hintText: "Today's Memo..."),
      maxLines: 2,
    );
  }

  // 3. 감정 선택 전체 섹션
  Widget _buildEmotionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'pick_feelings'.tr(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _buildHorizontalEmotionList(positiveEmotions), // 긍정 감정 행
        const SizedBox(height: 16),
        _buildHorizontalEmotionList(negativeEmotions), // 부정 감정 행
      ],
    );
  }

  // 3-1. 감정 리스트용 가로 스크롤 로우
  Widget _buildHorizontalEmotionList(List<EmotionData> emotions) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: emotions.map((e) {
          final index = _tempEmotions.indexOf(e.name);
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: _EmotionButton(
              emotion: e,
              selectIndex: index,
              onTap: () => _toggleEmotion(e.name),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. 사진 선택 영역 (사진 없을 땐 예쁘게 채우고, 있을 땐 1:1.3 비율로!)
  Widget _buildPhotoSelectionArea() {
    return GestureDetector(
      onTap: _pickAndCropImage,
      child: _tempImage != null
          ? AspectRatio(
              aspectRatio: 1 / 1.3, // 📸 사진이 있을 때는 크롭 비율 그대로!
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12), // 라운딩도 살짝 더 부드럽게
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _buildSelectedPhotoStack(),
              ),
            )
          : Container(
              // 📐 사진이 없을 때 다이얼로그를 스크롤 없이 예쁘게 채우는 황금 높이
              height: 145, 
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50], // 살짝 더 밝고 감성적인 배경색
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
              ),
              child: _buildEmptyPhotoIcon(),
            ),
    );
  }

  // 4-1. 선택된 사진이 있을 때 표시되는 스택 (이미지 + 삭제 버튼)
  Widget _buildSelectedPhotoStack() {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_tempImage!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _tempImage = null; // 사진 제거
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

  // 4-2. 사진이 없을 때 표시되는 세로형 감성 아이콘 + 텍스트
  Widget _buildEmptyPhotoIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined, // 조금 더 세련된 사진 추가 아이콘
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 5. 하단 취소 및 저장 버튼 영역
  List<Widget> _buildActionButtons() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('cancel'.tr()),
      ),
      ElevatedButton(
        onPressed: () {
          final newData = CalendarCellData(
            memo: _memoController.text,
            image: _tempImage,
            emotions: _tempEmotions,
          );
          widget.onSave(newData);
          Navigator.pop(context);
        },
        child: Text('save'.tr()),
      ),
    ];
  }
}

// ==========================================
// 🎨 [3] 감정 버튼 컴포넌트 위젯 (UI 단독 분리)
// ==========================================
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
                  color: isSelected ? emotion.color.withValues(alpha: 0.2) : Colors.grey[100],
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
                    decoration: BoxDecoration(color: emotion.color, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '${selectIndex + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            emotion.name,
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

// ==========================================
// 📸 [4] 사진첩 및 크롭 관련 비즈니스 로직 함수들
// ==========================================
Future<List<AssetEntity>> _fetchPhotosByDate(DateTime selectedDate) async {
  await PhotoManager.requestPermissionExtend();

  final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 4, 0, 0);
  final DateTime endTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1, 3, 59, 59);

  final FilterOptionGroup filterOption = FilterOptionGroup(
    imageOption: const FilterOption(sizeConstraint: SizeConstraint(minWidth: 10, minHeight: 10)),
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
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) {
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * (isLandscape ? 0.85 : 0.45),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Today\'s Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null && context.mounted) {
                        final File? cropped = await _cropImage(pickedFile.path);
                        await Future.delayed(Duration.zero);
                        if (cropped != null && context.mounted) Navigator.pop(context, cropped);
                      }
                    },
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('All Photos', style: TextStyle(fontSize: 14)),
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
                              await Future.delayed(Duration.zero);
                              if (cropped != null && context.mounted) Navigator.pop(context, cropped);
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<dynamic>(
                              future: entity.thumbnailDataWithSize(const ThumbnailSize.square(200)),
                              builder: (context, byteSnapshot) {
                                if (byteSnapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }
                                final bytes = byteSnapshot.data;
                                if (bytes == null) return Container(color: Colors.grey[200]);
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
      ),
    ],
  );
  return croppedFile != null ? File(croppedFile.path) : null;
}