import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/storage/app_launch_store.dart';
import 'features/auth/data/auth_flow_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  await AppLaunchStore.instance.initialize();
  await AuthFlowStore.instance.initialize();
  runApp(const VoiceLiveApp());
}
