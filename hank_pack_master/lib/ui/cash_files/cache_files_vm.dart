import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../comm/ui/download_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheFilesVm extends ChangeNotifier {
  // 给定一个依赖下载地址：https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.17.0/ (maven的案例)
  // 换一个：           https://repo1.maven.org/maven2/org/apache/spark/spark-hive_2.13/3.5.1/
  String get host =>
      hostInputController.text; // "https://repo1.maven.org/maven2/";
  String get path =>
      pathInputController.text; // "org/apache/spark/spark-hive_2.13/3.5.1/";
  String get saveFolder => saveFolderInputController.text; // "E:/fileCache/";

  Map<String, DownloadButtonController> listFileMap = {};

  bool? loadingFileList;
  bool? fileListDownloading;

  TextEditingController hostInputController = TextEditingController();
  TextEditingController pathInputController = TextEditingController();
  TextEditingController saveFolderInputController = TextEditingController();

  init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    hostInputController.addListener(() {
      prefs.setString("hostInput", hostInputController.text);
      notifyListeners();
    });
    hostInputController.text = prefs.getString("hostInput") ?? '';

    pathInputController.addListener(() {
      prefs.setString("pathInput", pathInputController.text);
      notifyListeners();
    });
    pathInputController.text = prefs.getString("pathInput") ?? '';

    saveFolderInputController.addListener(() {
      prefs.setString("saveFolder", saveFolderInputController.text);
      notifyListeners();
    });
    saveFolderInputController.text = prefs.getString("saveFolder") ?? '';
  }

  bool get enableDownload {
    if (host.isEmpty) {
      return false;
    }
    if (path.isEmpty) {
      return false;
    }
    if (saveFolder.isEmpty) {
      return false;
    }
    return true;
  }

  List<String> _parseHtmlString(String htmlString) {
    List<String> list = [];

    // 提取所有链接
    RegExp linkRegExp = RegExp(r'href="([^"]+)"');
    // 正则解释一下：
    // r前缀标识了这是一个原始字符串字面量，在Dart中，原始字符串字面量以r开头，它们允许我们在字符串中使用反斜杠而无需对其进行转义。这在处理正则表达式时非常有用，因为正则表达式本身经常包含反斜杠。
    //
    // href="([^"]+)"是实际的正则表达式模式。
    //
    // href=": 这部分简单地匹配了字符串中的“href=”这个文本。
    // ([^"]+): 这是一个用括号括起来的子表达式，
    // 它实际上定义了我们想要匹配的内容。
    // [^"]表示匹配除了双引号之外的任意字符，
    // +表示匹配前面的表达式一次或多次。
    // 因此，([^"]+)表示匹配双引号之间的所有字符（不包括双引号本身）。
    // ": 最后的双引号表示我们要匹配的文本在结束时需要有双引号闭合。
    Iterable<Match> matches = linkRegExp.allMatches(htmlString);

    // 打印链接
    for (Match match in matches) {
      if (match.groupCount > 0) {
        String? fileName = match.group(1);
        if (fileName == null || fileName.isEmpty) {
          continue;
        }
        if (fileName.contains("/")) {
          continue;
        }
        list.add(fileName);
      }
    }

    return list;
  }

  Future fetchFilesList() async {
    fileListDownloading = true;
    loadingFileList = true;
    notifyListeners();

    Dio dio = Dio();
    Response response = await dio.get(host + path);

    if (response.statusCode == 200) {
      List<String> listFile = _parseHtmlString(response.data);

      for (var s in listFile) {
        listFileMap[s] = DownloadButtonController(); // 给每一条下载任务都创建一个下载按钮控制器
      }

      loadingFileList = false;
      notifyListeners();

      if (listFileMap.isNotEmpty) {
        downloadFile();
      }
    } else {
      debugPrint("Failed to fetch files list");
    }
  }

  void downloadFile() async {
    Dio dio = Dio();

    Map<String, bool> downloadTagList = {};

    listFileMap.forEach((fileName, controller) async {
      downloadTagList[fileName] = false;
      Directory directory =
          Directory(saveFolder + Platform.pathSeparator + path);
      if (!directory.existsSync()) {
        directory.create(recursive: true);
      }

      String fileUrl = host + path + fileName;
      String savePath = saveFolder + path + fileName; // 文件保存的本地路径
      controller.startDownload();
      try {
        await dio.download(fileUrl, savePath, onReceiveProgress: (c, t) {
          controller.setProgressValue((100 * c / t).round());
          if (c == t) {
            downloadTagList[fileName] = true;
          }
        });

        /// 先检查数量是不是相等
        bool hasAllTask = downloadTagList.length == listFileMap.length;
        if (hasAllTask) {
          bool hasUncompletedTask = downloadTagList.values
              .toList()
              .where((element) => false)
              .isNotEmpty; // 未完成的任务数量大于0
          fileListDownloading = hasUncompletedTask; // 未完成的任务数量大于0，则认为正在下载
          notifyListeners();
        }

        debugPrint('$fileUrl 下载成功，保存在 $savePath');
      } on DioError catch (e) {
        debugPrint('下载失败: $fileUrl, 错误信息: ${e.message}');
      }
    });
  }
}
