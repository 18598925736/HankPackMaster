import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:hive_flutter/adapters.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';

import 'comm/functions.dart';
import 'comm/hwobs/obs_client.dart';
import 'comm/str_const.dart';
import 'hive/env_config/env_config_operator.dart';
import 'hive/project_record/project_record_operator.dart';
import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await EnvConfigOperator.openBox();
  await ProjectRecordOperator.openBox();

  OBSClient.init(
    ak: EnvConfigOperator.searchEnvValue(Const.obsAccessKey),
    sk: EnvConfigOperator.searchEnvValue(Const.obsSecretKey),
    domain: EnvConfigOperator.searchEnvValue(Const.obsEndPoint),
    bucketName: EnvConfigOperator.searchEnvValue(Const.obsBucketName),
  );

  // if it's not on the web, windows or android, load the accent color
  if (!kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }

  if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await flutter_acrylic.Window.hideWindowControls();
    }
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setMinimumSize(const Size(500, 600));
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });
  }

  runApp(const App()); // TEST
}
