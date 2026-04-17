import 'package:flutter/material.dart';

import '../controllers/room_background_controller.dart';

class RoomBackgroundView extends StatelessWidget {
  const RoomBackgroundView({super.key, this.fit = BoxFit.cover});

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable:
          RoomBackgroundController.instance.selectedBackgroundAsset,
      builder: (context, assetPath, _) {
        return Image.asset(
          assetPath,
          key: ValueKey(assetPath),
          fit: fit,
          filterQuality: FilterQuality.high,
        );
      },
    );
  }
}
