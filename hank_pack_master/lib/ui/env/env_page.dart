import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:hank_pack_master/utils/toast_util.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../comm/const_colors.dart';
import '../../core/command_util.dart';
import '../../test/info_page.dart';
import '../../test/models.dart';
import '../comm/theme.dart';

///
/// 环境参数检测页面
///
class EnvPage extends StatefulWidget {
  const EnvPage({super.key});

  @override
  State<EnvPage> createState() => _EnvPageState();
}

class _EnvPageState extends State<EnvPage> {
  Map<String, Set<String>> envs = {};

  @override
  void initState() {
    super.initState();
    checkAction();
  }

  Widget envTile(String title, Set<String> content, AppTheme appTheme) {
    List<Widget> muEnv = [];
    for (var value in content) {
      muEnv.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: RadioButton(
              checked: false, onChanged: (value) {}, content: Text(value)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 5),
          ...muEnv
        ],
      ),
    );
  }

  checkAction() async {
    envs = await CommandUtil.getInstance().initEnvParam(action: (r) {
      debugPrint("环境检索的日志输出:$r");
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    debugPrint("appTheme=>$appTheme");

    List<Widget> envWidgets = [];

    envs.forEach((key, value) {
      envWidgets.add(envTile(key, value, appTheme));
    });

    return ChangeNotifierProvider(
      builder: (context, c) {
        return Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...envWidgets,
            ],
          ),
        );
      },
      create: (BuildContext context) => ExecutorModel(),
    );
  }
}

// class LeftSide extends StatefulWidget {
//   const LeftSide({Key? key}) : super(key: key);
//
//   @override
//   State<LeftSide> createState() => _LeftSideState();
// }
//
// class _LeftSideState extends State<LeftSide> {
//   late ExecutorModel executorModel;
//
//   @override
//   void initState() {
//     super.initState();
//     executorModel = context.read<ExecutorModel>();
//   }
//
//   List<Widget> _flutterGroup() {
//     String? rootPath = EnvParams.flutterRoot.firstOrNull;
//
//     if (rootPath == null || rootPath.isEmpty) return [];
//
//     var flutterVersionBtn = _getCmdBtn(
//         btnName: "flutter version",
//         binRoot: rootPath,
//         cmd: "flutter.bat",
//         params: ["--version"],
//         workDir: EnvParams.workRoot,
//         btnColor: Colors.tealAccent);
//
//     var flutterDoctorBtn = _getCmdBtn(
//         btnName: "flutter doctor",
//         binRoot: rootPath,
//         cmd: "flutter.bat",
//         params: ["doctor"],
//         workDir: EnvParams.workRoot,
//         btnColor: Colors.tealAccent);
//
//     var flutterDartBtn = _getCmdBtn(
//         btnName: "dart -version",
//         binRoot: rootPath,
//         cmd: "dart.bat",
//         workDir: EnvParams.workRoot,
//         btnColor: Colors.tealAccent);
//
//     return [flutterVersionBtn, flutterDoctorBtn, flutterDartBtn];
//   }
//
//   List<Widget> _gitGroup() {
//     String? rootPath = EnvParams.gitRoot.firstOrNull;
//     if (rootPath == null || rootPath.isEmpty) return [];
//
//     var gitCloneBtn = _getCmdBtn(
//         btnName: "git clone",
//         workDir: EnvParams.workRoot,
//         cmd: "git",
//         params: ["clone", "git@github.com:18598925736/HankPackMaster.git"],
//         btnColor: Colors.blue);
//
//     var gitVersionBtn = _getCmdBtn(
//         btnName: "git version",
//         workDir: EnvParams.workRoot,
//         cmd: "git",
//         params: ["--version"],
//         btnColor: Colors.blue);
//
//     return [gitCloneBtn, gitVersionBtn];
//   }
//
//   List<Widget> _adbGroup() {
//     String? rootPath = EnvParams.gitRoot.firstOrNull;
//     if (rootPath == null || rootPath.isEmpty) return [];
//     var adbDevicesBtn = _getCmdBtn(
//         workDir: EnvParams.workRoot,
//         btnName: "adb devices",
//         cmd: "adb",
//         params: ["devices"],
//         btnColor: Colors.amber);
//
//     var adbLogcatBtn = _getCmdBtn(
//         btnName: "adb logcat",
//         cmd: "adb",
//         workDir: EnvParams.workRoot,
//         params: ["logcat", "|", "findStr", "com.kbzbank.kpaycustomer.uat"],
//         btnColor: Colors.amber);
//     return [adbDevicesBtn, adbLogcatBtn];
//   }
//
//   List<Widget> _gradlewBtns() {
//     var gradlewVersion = _getCmdBtn(
//         btnName: "gradlew -version",
//         cmd: "gradlew.bat",
//         binRoot: "E:\\MyApplication\\",
//         workDir: "E:\\MyApplication\\",
//         params: ["-version"],
//         btnColor: Colors.greenAccent); // 执行打包命令还必须将工作目录和可执行目录都设置为 工程主目录
//
//     var gradlew = _getCmdBtn(
//         btnName: "gradlew assembleDebug",
//         cmd: "gradlew.bat",
//         binRoot: "E:\\MyApplication\\",
//         workDir: "E:\\MyApplication\\",
//         params: ["clean", "assembleDebug"],
//         btnColor: Colors.greenAccent); // 执行打包命令还必须将工作目录和可执行目录都设置为 工程主目录
//     return [gradlewVersion, gradlew];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var monkeyrunner = _getCmdBtn(
//         btnName: "monkeyrunner",
//         binRoot: "D:\\env\\sdk\\tools\\bin\\",
//         cmd: "monkeyrunner.bat",
//         workDir: EnvParams.workRoot,
//         btnColor: Colors.white60);
//
//     var envInitBtn = Padding(
//       padding: const EdgeInsets.all(8),
//       child: ElevatedButton(
//           onPressed: () async {
//             reset();
//             await CommandUtil.getInstance().initEnvParam(action: addRes);
//             setState(() {});
//           },
//           child: const Text("initEnvParam")),
//     );
//
//     var actionButtons = Column(
//       // mainAxisAlignment: MainAxisAlignment.start,
//       // crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Wrap(children: [
//           envInitBtn,
//           ..._gitGroup(),
//           ..._adbGroup(),
//           ..._gradlewBtns(),
//           ..._flutterGroup(),
//           monkeyrunner,
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child:
//                 ElevatedButton(onPressed: makePack, child: const Text("完整打包")),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: ElevatedButton(
//                 onPressed: () {
//                   CommandUtil.getInstance().stopAllExec();
//                 },
//                 child: const Text("停止所有指令")),
//           ),
//         ]),
//       ],
//     );
//
//     return Container(
//         color: Colors.orange,
//         width: 400,
//         padding: const EdgeInsets.all(20),
//         child: Stack(children: [
//           Column(children: [
//             actionButtons,
//             const SizedBox(height: 20),
//           ]),
//         ]));
//   }
//
//   void addRes(String res) {
//     if (res.trim().isEmpty) return;
//     executorModel.append(
//         "${Jiffy.now().format(pattern: "yyyy-MM-dd HH:mm:ss")} : ${res.trim()}");
//   }
//
//   void reset() {
//     executorModel.reset();
//   }
//
//   ///
//   /// 打包动作
//   ///
//   void makePack() async {
//     reset();
//
//     // clone
//     var gitClone = await CommandUtil.getInstance().execute(
//       workDir: EnvParams.workRoot,
//       cmd: "git",
//       params: ["clone", "git@github.com:18598925736/MyApp20231224.git"],
//       action: addRes,
//     );
//
//     var exitCode = await gitClone?.exitCode;
//     if (0 != exitCode) {
//       String failedStr = "clone 执行失败.$exitCode";
//       ToastUtil.showPrettyToast(failedStr);
//       addRes(failedStr);
//       return;
//     } else {
//       addRes("clone完毕");
//     }
//
//     // assemble
//     var assemble = await CommandUtil.getInstance().execute(
//         cmd: "gradlew.bat",
//         binRoot: "${EnvParams.workRoot}\\MyApp20231224\\",
//         workDir: "${EnvParams.workRoot}\\MyApp20231224\\",
//         params: ["clean", "assembleDebug", "--stacktrace"],
//         action: addRes);
//
//     // 检查打包结果
//     exitCode = await assemble?.exitCode;
//     if (0 != exitCode) {
//       String failedStr = "assemble 执行失败.$exitCode";
//       ToastUtil.showPrettyToast(failedStr);
//       addRes(failedStr);
//       return;
//     } else {
//       addRes("assemble完毕");
//     }
//   }
//
//   _getCmdBtn(
//       {required String btnName,
//       required String cmd,
//       List<String> params = const [],
//       String binRoot = "",
//       required String workDir,
//       Color btnColor = Colors.green}) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: ElevatedButton(
//           style: ButtonStyle(
//               backgroundColor: ButtonStyleButton.allOrNull<Color>(btnColor),
//               foregroundColor:
//                   ButtonStyleButton.allOrNull<Color>(Colors.white)),
//           onPressed: () async {
//             reset();
//             var process = await CommandUtil.getInstance().execute(
//               binRoot: binRoot,
//               cmd: cmd,
//               params: params,
//               workDir: workDir,
//               action: addRes,
//             );
//
//             // 等待命令执行完成
//             var exitCode = await process?.exitCode;
//             ToastUtil.showPrettyToast("$btnName  执行完成，exitCode = $exitCode");
//           },
//           child: Text(btnName)),
//     );
//   }
// }
//
// class RightSide extends StatefulWidget {
//   const RightSide({Key? key}) : super(key: key);
//
//   @override
//   State<RightSide> createState() => _RightSideState();
// }
//
// class _RightSideState extends State<RightSide> {
//   late ExecutorModel executorModel;
//
//   @override
//   void initState() {
//     super.initState();
//     executorModel = context.read<ExecutorModel>();
//   }
//
//   final BoxDecoration bg = const BoxDecoration(
//     gradient: LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [backgroundStartColor, backgroundEndColor],
//         stops: [0.0, 1.0]),
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//         child: Container(
//             decoration: bg,
//             child: Column(children: [
//               Expanded(
//                 child: Consumer<ExecutorModel>(
//                     builder: (context, value, child) => InfoPage(
//                           content: value.getRes,
//                           scrollController: executorModel.scrollController,
//                         )),
//               )
//             ])));
//   }
// }