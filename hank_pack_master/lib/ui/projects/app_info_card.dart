import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;

import '../../comm/pgy/pgy_entity.dart';

/// 流水线最终成果展示卡片
class AppInfoCard extends StatelessWidget {
  final MyAppInfo appInfo;

  const AppInfoCard({super.key, required this.appInfo});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('App名称', "${appInfo.buildName}"),
          _line('App版本', "${appInfo.buildVersion}"),
          _line('编译版本号', "${appInfo.buildVersionNo}"),
          _line('上传批次', "${appInfo.buildBuildVersion}"),
          _line('App包名', "${appInfo.buildIdentifier}"),
          _line('应用描述', "${appInfo.buildDescription}"),
          _line('更新日志', "${appInfo.buildUpdateDescription}"),
          _line('更新时间', "${appInfo.buildUpdated}"),
          Center(
            child: CachedNetworkImage(
              imageUrl: "${appInfo.buildQRCodeURL}",
              placeholder: (context, url) => const m.CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(m.Icons.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String title, String value) {
    var fontSize = 15.0;

    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: fontSize,
                color: Colors.black,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 5),
          Text(":", style: TextStyle(fontSize: fontSize, color: Colors.black)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
