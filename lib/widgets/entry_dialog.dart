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
import 'package:path/path.dart' as p; // 💡 파일명 연산을 위해 추가

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
    _tempEmotions = List<String>.from(widget.existingData?.emotions ?? []);

    // 만약 기존 데이터에 파일 경로/명이 있다면 파일명만 쏙 발라냅니다.
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
        _buildHorizontalEmotionList(positiveEmotions),
        const SizedBox(height: 16),
        _buildHorizontalEmotionList(negativeEmotions),
      ],
    );
  }

  Widget _buildHorizontalEmotionList(List<EmotionData> emotions) {
    return SizedBox(
      height: 75,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: emotions.map((e) {
            final index = _tempEmotions.indexOf(e.name);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _EmotionButton(
                emotion: e,
                selectIndex: index,
                onTap: () => _toggleEmotion(e.name),
              ),
            );
          }).toList(),
        ),
      ),
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
          File? finalSavedImage;

          // 1. 만약 사용자가 사진을 '새로 골랐다면' 영구 보관소로 복사 이사를 보냅니다.
          if (_tempImage != null) {
            try {
              final appDir = await getApplicationDocumentsDirectory();
              final String timestamp = DateTime.now().millisecondsSinceEpoch
                  .toString();
              final String permanentPath =
                  '${appDir.path}/diary_$timestamp.jpg';

              finalSavedImage = await _tempImage!.copy(permanentPath);
            } catch (e) {
              debugPrint("📸 [DIARY_SAVE] Copy Error: $e");
              finalSavedImage = _tempImage;
            }
          }
          // 2. 사진을 새로 고르지 않았지만, 기존 사진 파일명이 살아있다면 실시간 조립한 경로를 유지합니다.
          else if (_initialFileName != null) {
            final appDir = await getApplicationDocumentsDirectory();
            finalSavedImage = File('${appDir.path}/$_initialFileName');
          }

          final newData = CalendarCellData(
            memo: _memoController.text,
            image: finalSavedImage,
            emotions: _tempEmotions,
          );

          newData.date = DateTime(
            widget.date.year,
            widget.date.month,
            widget.date.day,
          );

          if (widget.existingData != null) {
            newData.id = widget.existingData!.id;
          }

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
                        await Future.delayed(Duration.zero);
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
                              await Future.delayed(Duration.zero);
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
                                if (bytes == null)
                                  return Container(color: Colors.grey[200]);
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
