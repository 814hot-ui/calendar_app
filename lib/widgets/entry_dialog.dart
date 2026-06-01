import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cell_data.dart';
import '../models/emotion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_cropper/image_cropper.dart';

const englishMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

// 📸 1. 선택한 날짜(새벽 4시 기준)에 촬영된 사진첩 사진들을 필터링해서 가져오는 함수
Future<List<AssetEntity>> _fetchPhotosByDate(DateTime selectedDate) async {
  // 💡 권한 상태 확인용 로그 추가
  final PermissionState ps = await PhotoManager.requestPermissionExtend();


  final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 4, 0, 0);
  final DateTime endTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1, 3, 59, 59);

  final FilterOptionGroup filterOption = FilterOptionGroup(
    imageOption: const FilterOption(
      sizeConstraint: SizeConstraint(minWidth: 10, minHeight: 10),
    ),
    createTimeCond: DateTimeCond(
      min: startTime,
      max: endTime,
    ),
    orders: [
      const OrderOption(type: OrderOptionType.createDate, asc: false),
    ],
  );

  final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    filterOption: filterOption,
  );

  if (albums.isEmpty) return [];

  final List<AssetEntity> photos = await albums[0].getAssetListRange(start: 0, end: 100);
  return photos;
}

// 📱 2. 그날 찍은 사진 목록과 '전체 사진 보기' 버튼이 있는 하단 팝업창 (위치 수정 완료!)
// 📱 가로/세로 모드 모두에서 에러 없이 유연하게 작동하는 하단 팝업창
Future<File?> _showPhotoPickerBottomSheet({
  required BuildContext context,
  required DateTime date,
  required ImagePicker picker,
}) {
  return showModalBottomSheet<File?>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true, // ⭕ 중요: 이 옵션이 true여야 가로 모드에서 높이를 유연하게 가져갑니다.
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      // 💡 기기의 화면 높이에 따라 팝업창의 최대 높이를 유연하게 조절합니다.
      // 세로 모드일 때는 적당히, 가로 모드일 때는 화면의 80% 정도를 쓰도록 유도합니다.
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            // 가로 모드일 때는 최대 화면 높이의 85%, 세로 모드일 때는 45% 정도로 제한
            maxHeight: MediaQuery.of(context).size.height * (isLandscape ? 0.85 : 0.45),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내부 콘텐츠 크기만큼만 차지하도록 설정
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 타이틀 및 전체사진 버튼 구역 (그대로 유지)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '그날의 추천 사진',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null && context.mounted) {
                        final File? cropped = await _cropImage(pickedFile.path);
                        if (cropped != null && context.mounted) {
                          Navigator.pop(context, cropped);
                        }
                      }
                    },
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('전체 사진 보기'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 2. 사진 리스트 구역 (Expanded로 감싸 남은 공간을 채우고 오버플로우 방지)
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
                    
                    // ⭕ 고정 SizedBox를 없애고 GridView가 남은 공간 안에서만 가로 스크롤 되도록 유도!
                    return GridView.builder(
                      scrollDirection: Axis.vertical,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        // 가로 모드일 때는 공간이 좁으므로 1줄로, 세로 모드일 때는 원래대로 2줄로 유연하게 변경!
                        crossAxisCount: isLandscape ? 8 : 4, 
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.0, // 1:1 비율 유지
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
                                if (bytes == null) {
                                  return Container(color: Colors.grey[200]);
                                }
                                return Image.memory(
                                  bytes,
                                  fit: BoxFit.cover,
                                );
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

// ✂️ 원본 사진을 1:1 정사각형 비율로 예쁘게 잘라주는 함수
Future<File?> _cropImage(String sourcePath) async {
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1.3), // 크롭 비율을 1:1.3으로 설정 (원하는 비율로 조정 가능)
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Cropping Photo',
        toolbarColor: Colors.white,
        toolbarWidgetColor: Colors.black,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: true, // 비율 고정 해제 불가하게 설정
      ),
      IOSUiSettings(
        title: 'Cropping Photo',
        aspectRatioLockEnabled: true, // iOS도 1:1 고정
        resetAspectRatioEnabled: false,
      ),
    ],
  );

  // 크롭을 완료하면 File 객체로 변환해서 돌려주고, 취소하면 null을 반환합니다.
  return croppedFile != null ? File(croppedFile.path) : null;
}

// 💬 3. 메인 다이얼로그 실행 함수
void showEntryDialog({
  required BuildContext context,
  required DateTime date,
  CalendarCellData? existingData,
  required Function(CalendarCellData) onSave,
}) {
  final memoController = TextEditingController(text: existingData?.memo ?? '');
  final ImagePicker picker = ImagePicker();
  File? tempImage = existingData?.image;
  List<String> tempEmotions = List<String>.from(existingData?.emotions ?? []);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          
          void toggleEmotion(String emotionName) {
            setDialogState(() {
              if (tempEmotions.contains(emotionName)) {
                tempEmotions.remove(emotionName);
              } else {
                if (tempEmotions.length >= 3) return;
                tempEmotions.add(emotionName);
              }
            });
          }

          Widget buildEmotionButton(EmotionData emotion) {
            final int selectIndex = tempEmotions.indexOf(emotion.name);
            final bool isSelected = selectIndex != -1;

            return GestureDetector(
              onTap: () => toggleEmotion(emotion.name),
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
                          child: Image.asset(
                            emotion.imagePath,
                            fit: BoxFit.contain,
                          ),
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

          return AlertDialog(
            title: Text(
              'date_record_title'.tr(namedArgs: {
                'monthName': context.locale.languageCode == 'en' 
                ? englishMonths[date.month - 1] 
                : date.month.toString(),
                'month': date.month.toString(),
                'day': date.day.toString(),
              }),
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.6,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: memoController,
                      decoration: const InputDecoration(hintText: "Today's Memo..."),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Text('pick_feelings'.tr(), 
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: positiveEmotions.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: buildEmotionButton(e),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: negativeEmotions.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: buildEmotionButton(e),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 📸 사진 업로드 영역 (바텀시트 호출부 에러 완전 해결!)
                    // 📸 사진 업로드 및 삭제 영역
                    GestureDetector(
                      onTap: tempImage != null 
                          ? null // 💡 사진이 이미 있을 때는 영역 터치로 사진첩이 다시 열리지 않도록 방지 (X 버튼으로만 지우게)
                          : () async {
                              final File? selectedFile = await _showPhotoPickerBottomSheet(
                                context: context,
                                date: date,
                                picker: picker,
                              );
                              
                              if (selectedFile != null) {
                                setDialogState(() {
                                  tempImage = selectedFile;
                                });
                              }
                            },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: tempImage != null
                            ? Stack(
                                children: [
                                  // 1. 선택된 크롭 이미지 (꽉 차게 표시)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(tempImage!, fit: BoxFit.cover),
                                    ),
                                  ),
                                  // 2. ❌ 우측 상단 사진 삭제 버튼
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          tempImage = null; // 🗑️ 사진 데이터 초기화!
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5), // 배경을 살짝 어둡게 해서 잘 보이도록
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Icon(Icons.add_a_photo, size: 30, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: Text('cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () {
                  final newData = CalendarCellData(
                    memo: memoController.text,
                    image: tempImage,
                    emotions: tempEmotions, 
                  );
                  onSave(newData);
                  Navigator.pop(context);
                },
                child: Text('save'.tr()),
              ),
            ],
          );
        },
      );
    },
  );
}