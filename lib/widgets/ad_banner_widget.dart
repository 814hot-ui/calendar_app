import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // 🌟 [중요] 아직 출시 전이므로 구글이 제공하는 '안전한 테스트 ID'를 사용합니다!
  final String _testAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // 안드로이드 테스트 ID
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS 테스트 ID

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _testAdUnitId, // 👈 테스트 ID 장착
      request: const AdRequest(),
      size: AdSize.banner, // 📊 가장 대중적인 320x50 사이즈
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() { _isLoaded = true; }); // 로드 성공 시 화면 갱신
        },
        onAdFailedToLoad: (ad, err) {
          print('❌ 광고 로드 실패: ${err.message}');
          ad.dispose();
        },
      ),
    )..load(); // 광고 로딩 시작
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // 메모리 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!), // 진짜 구글 광고판
      );
    }
    return const SizedBox.shrink(); // 로드 전엔 숨김
  }
}