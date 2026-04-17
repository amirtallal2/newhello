import 'package:flutter/foundation.dart';

final class RoomBackgroundController {
  RoomBackgroundController._();

  static final RoomBackgroundController instance = RoomBackgroundController._();

  static const String defaultBackgroundAsset =
      'assets/images/room_background.png';

  static const List<String> availableBackgroundAssets = [
    'assets/images/room_background_option_1.jpg',
    'assets/images/room_background_option_2.jpg',
    'assets/images/room_background_option_3.jpg',
  ];

  final ValueNotifier<String> selectedBackgroundAsset = ValueNotifier<String>(
    defaultBackgroundAsset,
  );

  void updateBackground(String assetPath) {
    selectedBackgroundAsset.value = assetPath;
  }

  void reset() {
    selectedBackgroundAsset.value = defaultBackgroundAsset;
  }
}
