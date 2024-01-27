import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:hank_pack_master/comm/dialog_util.dart';
import 'package:provider/provider.dart';

import '../../core/command_util.dart';
import '../comm/theme.dart';
import 'env_param_vm.dart';

///
/// 环境参数检测页面
///
class EnvPage extends StatefulWidget {
  const EnvPage({super.key});

  @override
  State<EnvPage> createState() => _EnvPageState();
}

class _EnvPageState extends State<EnvPage> {
  late AppTheme _appTheme;
  late EnvParamVm _envParamModel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // '${_envParamModel.stageTaskExecuteMaxPeriod}',

      _envParamModel.stageTaskExecuteMaxPeriodController.text =
          '${_envParamModel.stageTaskExecuteMaxPeriod}';
      _envParamModel.stageTaskExecuteMaxRetryTimesController.text =
          '${_envParamModel.stageTaskExecuteMaxRetryTimes}';

      _envParamModel.pgyApiKeyController.text = _envParamModel.pgyApiKey;

      _envParamModel.pgyApiKeyController.addListener(() {
        if(_envParamModel.pgyApiKeyController.text.isNotEmpty) {
          _envParamModel.pgyApiKey = _envParamModel.pgyApiKeyController.text;
        }
      });
    });
  }

  Widget _envChooseWidget(
      {required String title,
      required String Function() init,
      required Function(String r) action}) {
    return _card(
        title,
        [
          if (!_envParamModel.isEnvEmpty(title)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: Text(
                init(),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 29),
              ),
            )
          ],
        ],
        action: action);
  }

  @override
  Widget build(BuildContext context) {
    _envParamModel = context.watch<EnvParamVm>();
    _appTheme = context.watch<AppTheme>();

    return Container(
        color: _appTheme.bgColor,
        padding: const EdgeInsets.all(20),
        child: ScrollConfiguration(
            // 隐藏scrollBar
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text("自动环境检测", style: TextStyle(fontSize: 30)),
                  const EnvGroupCard(order: "java"),
                  const EnvGroupCard(order: "git"),
                  const EnvGroupCard(order: "adb"),
                  const EnvGroupCard(order: "flutter"),
                  const SizedBox(height: 20),
                  _manullySpecifyEnvTitle(),
                  Row(children: [
                    Expanded(child: _workspaceChoose()),
                    Expanded(child: _androidSdkChoose()),
                  ]),
                  Row(children: [Expanded(child: _stageTaskExecuteSetting())]),
                  Row(children: [Expanded(child: _pgySetting())]),
                ]))));
  }

  /// 这是为了解决 context可变的问题
  showMyInfo({
    required String title,
    required String content,
    InfoBarSeverity severity = InfoBarSeverity.success,
  }) {
    DialogUtil.showInfo(
        context: context, title: title, content: content, severity: severity);
  }

  bool _checkAllFoldersExist(String directoryPath, List<String> targetFolders) {
    Directory directory = Directory(directoryPath);

    for (String folder in targetFolders) {
      bool exists = false;
      directory.listSync().forEach((FileSystemEntity entity) {
        if (entity is Directory &&
            entity.path.endsWith('${Platform.pathSeparator}$folder')) {
          exists = true;
        }
      });

      if (!exists) {
        return false;
      }
    }

    return true;
  }

  Future<bool> _checkAndroidSdkEnable(String selectedDirectory) async {
    Directory dir = Directory(selectedDirectory);
    // 路径实际上不存在时
    if (!(await dir.exists())) {
      return false;
    }
    // C:\Users\zwx1245985\AppData\Local\Android\Sdk
    List<String> mustHave = ['build-tools', 'platforms', 'platform-tools'];
    return _checkAllFoldersExist(selectedDirectory, mustHave);
  }

  @override
  void dispose() {
    super.dispose();
    debugPrint("envPage dispose");
  }

  Widget envErrWidget(String title) {
    if (_envParamModel.isEnvEmpty(title)) {
      return Text("${_envParamModel.envGuide[title]}",
          style: TextStyle(fontSize: 20, color: Colors.red));
    } else {
      return const SizedBox();
    }
  }

  Widget _card(String title, List<Widget> muEnv,
      {required Function(String r) action}) {
    return Row(mainAxisSize: MainAxisSize.max, children: [
      Expanded(
          child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(10),
              decoration: _boxBorder(title),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 30),
                        ),
                        Row(
                          children: [
                            FilledButton(
                                child: const Text("更换路径"),
                                onPressed: () async {
                                  String? selectedDirectory = await FilePicker
                                      .platform
                                      .getDirectoryPath();
                                  if (selectedDirectory != null) {
                                    action(selectedDirectory);
                                  }
                                }),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ...muEnv,
                    const SizedBox(height: 5),
                    envErrWidget(title),
                    const SizedBox(height: 5),
                  ])))
    ]);
  }

  BoxDecoration _boxBorder(String title) {
    var boxColor = _appTheme.bgColorErr;
    if (!_envParamModel.isEnvEmpty(title)) {
      boxColor = _appTheme.bgColorSucc;
    }

    return BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[50], width: .5));
  }

  void showCmdResultDialog(String res) {
    DialogUtil.showEnvCheckDialog(
      context: context,
      onConfirm: null,
      content: res,
      title: "测试结果",
    );
  }

  Widget _manullySpecifyEnvTitle() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("手动环境指定", style: TextStyle(fontSize: 30)),
          Row(
            children: [
              FilledButton(
                  child: const Text("设置环境变量A为随机值"),
                  onPressed: () async {
                    var random = Random.secure().nextInt(100);
                    ExecuteResult res = await CommandUtil.getInstance()
                        .setSystemEnvVar("A", "$random");
                    if (res.exitCode == 0) {
                      showMyInfo(
                          title: "提示",
                          content: "设置环境变量A的值为 $random 成功",
                          severity: InfoBarSeverity.success);
                    } else {
                      showMyInfo(
                          title: "提示",
                          content: "设置环境变量A失败",
                          severity: InfoBarSeverity.error);
                    }
                  }),
              const SizedBox(width: 10),
              Button(
                  child: const Text("打开环境变量设置"),
                  onPressed: () async {
                    var res = await CommandUtil.getInstance().openEnvSetting();
                    debugPrint("查询到的A的值为： $res  ");
                  }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workspaceChoose() {
    return _envChooseWidget(
        title: "工作空间",
        init: () => _envParamModel.workSpaceRoot,
        action: (selectedDirectory) {
          DialogUtil.showInfo(
              context: context, title: '选择了路径:', content: selectedDirectory);
          _envParamModel.workSpaceRoot = selectedDirectory;
        });
  }

  Widget _androidSdkChoose() {
    return _envChooseWidget(
        title: "Android SDK",
        init: () => _envParamModel.androidSdkRoot,
        action: (selectedDirectory) async {
          String envKey = "ANDROID_HOME";

          if (_envParamModel.androidSdkRoot == selectedDirectory) {
            // 当前路径相同
            showMyInfo(
              title: "选择的路径与当前路径相同 ",
              content: selectedDirectory,
              severity: InfoBarSeverity.warning,
            );
            return;
          }

          // 选择了 androidSDK之后，
          // 1. 检查SDK的可用性，不可用，终止，可用继续往下
          // 2. 检查 echo %ANDROID_HOME% 的值是不是和当前值相同，不同，设置 环境变量 ANDROID_HOME 为选择的路径，相同，结束
          bool enable = await _checkAndroidSdkEnable(selectedDirectory);
          if (!enable) {
            showMyInfo(
              title: '错误:',
              content: "Android SDK  $selectedDirectory 不可用，缺少必要组件",
              severity: InfoBarSeverity.warning,
            );
            return;
          }

          var executeResult = await CommandUtil.getInstance()
              .setSystemEnvVar(envKey, selectedDirectory);
          if (executeResult.exitCode == 0) {
            _envParamModel.androidSdkRoot = selectedDirectory;
            showMyInfo(
                title: "用户环境变量 $envKey设置成功: ", content: selectedDirectory);

            String echoAndroidHome = await CommandUtil.getInstance().echoCmd(
              order: "%$envKey%",
              action: (s) {},
            );

            debugPrint('echoAndroidHome -> $echoAndroidHome');
          } else {
            showMyInfo(
                title: "错误",
                content: "<3>环境变量设置失败 ${executeResult.res}",
                severity: InfoBarSeverity.warning);
          }
        });
  }

  /// 阶段任务执行设置
  _stageTaskExecuteSetting() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 9),
      borderColor: Colors.transparent,
      backgroundColor: _appTheme.bgColorSucc,
      borderRadius: BorderRadius.circular(5),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("阶段任务执行参数设置", style: _cTextStyle),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text("每次最大可执行时间", style: _cTextStyle),
                  SizedBox(
                    width: 100,
                    child: TextBox(
                      controller:
                          _envParamModel.stageTaskExecuteMaxPeriodController,
                      suffix: Text("秒", style: _cTextStyle),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 19),
                    ),
                  )
                ])),
            const SizedBox(width: 100),
            Expanded(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text("最大可执行次数", style: _cTextStyle),
                  SizedBox(
                    width: 100,
                    child: TextBox(
                      suffix: Text("次", style: _cTextStyle),
                      controller: _envParamModel
                          .stageTaskExecuteMaxRetryTimesController,
                      textAlign: TextAlign.center,
                      style: _cTextStyle,
                    ),
                  ),
                ]))
          ])
        ]))
      ]),
    );
  }

  /// 阶段任务执行设置
  _pgySetting() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 9),
      borderColor: Colors.transparent,
      backgroundColor: _appTheme.bgColorSucc,
      borderRadius: BorderRadius.circular(5),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("蒲公英平台设置", style: _cTextStyle),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text("_api_key", style: _cTextStyle),
                  const SizedBox(width: 200),
                  Expanded(
                    child: TextBox(
                      controller: _envParamModel.pgyApiKeyController,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 19),
                    ),
                  )
                ])),
          ]),
        ]))
      ]),
    );
  }

  final _cTextStyle = const TextStyle(fontSize: 19);
}

///
/// 单独封装一个带动画特效的环境监测卡片
///
/// 1，执行where命令，找出 所有可执行文件的路径 (Done)
/// 2. 逐个进行java指令的 version执行，看看版本号
/// 3. 将执行的结果动态显示出来
/// 4. 用单选框展示，默认选中第一个
///
class EnvGroupCard extends StatefulWidget {
  final String order;

  const EnvGroupCard({super.key, required this.order});

  @override
  State<EnvGroupCard> createState() => _EnvGroupCardState();
}

class _EnvGroupCardState extends State<EnvGroupCard> {
  late AppTheme _appTheme;
  late EnvParamVm _envParamModel;
  List<String> whereRes = [];

  /// 是否正在加载 环境group
  bool _isEnvGroupLoading = false;

  @override
  Widget build(BuildContext context) {
    _envParamModel = context.watch<EnvParamVm>();
    _appTheme = context.watch<AppTheme>();

    return _createDynamicEnvCheckCard();
  }

  /// 带动态效果的环境监测卡片
  Widget _createDynamicEnvCheckCard() {
    return Row(children: [
      Expanded(
        child: Card(
            backgroundColor: _appTheme.bgColorSucc,
            margin: const EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(5),
            borderColor: Colors.transparent,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildEnvRadioBtn(widget.order, whereRes.toSet()),
                ])),
      )
    ]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((timeStamp) => _doWhereAction());
  }

  /// 可执行文件单选按钮组件
  Widget _buildEnvRadioBtn(String title, Set<String> content) {
    List<Widget> muEnv = [];
    for (var binRoot in content) {
      muEnv.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  borderColor: Colors.transparent,
                  backgroundColor: Colors.green.withOpacity(.15),
                  borderRadius: BorderRadius.circular(5),
                  child: RadioButton(
                      checked: _envParamModel.judgeEnv(title, binRoot),
                      onChanged: (v) => _envParamModel.setEnv(title, binRoot,
                          needToOverride: true),
                      content: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _titleWidget(binRoot),
                            EnvCheckWidget(cmdStr: binRoot, title: title),
                          ],
                        ),
                      )),
                ),
              )
            ],
          ),
        ),
      );
    }

    return _card(title, muEnv);
  }

  Widget _titleWidget(String binRoot) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(binRoot, style: const TextStyle(fontSize: 22)),
    );
  }

  Widget _card(String title, List<Widget> muEnv) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 30)),
      const SizedBox(height: 15),
      if (_isEnvGroupLoading) ...[
        ...muEnv,
        envErrWidget(title),
      ] else ...[
        const ProgressBar(),
      ],
    ]);
  }

  bool hasExecutableExtension(String path) {
    var extensions = ['.exe', '.bat', '.cmd'];

    bool has = false;

    for (var element in extensions) {
      if (path.toLowerCase().endsWith(element)) {
        has = true;
        break;
      }
    }

    return has;
  }

  void appendRes(String e) {
    // 过滤掉 不带可执行后缀的
    // 过滤掉重复的
    if (hasExecutableExtension(e)) {
      whereRes.add(e);
    }
  }

  String getFirstFromResSet() {
    if (whereRes.isNotEmpty) {
      return whereRes[0];
    }
    return "";
  }

  /// 初始化
  void _doWhereAction() async {
    CommandUtil.getInstance().whereCmd(
        order: widget.order,
        action: (s) {
          var sTrim = s.trim();
          if (sTrim.contains("\n")) {
            var split = sTrim.split("\n");
            for (var e in split) {
              appendRes(e);
            }
          } else {
            appendRes(s);
          }
          _isEnvGroupLoading = true;
          _envParamModel.setEnv(widget.order, getFirstFromResSet(),
              needToOverride: false);
          setState(() {});
        });
  }

  void showCmdResultDialog(String res) {
    DialogUtil.showEnvCheckDialog(
      context: context,
      onConfirm: null,
      content: res,
      title: "测试结果",
    );
  }

  Widget envErrWidget(String title) {
    if (_envParamModel.isEnvEmpty(title)) {
      return Text("${_envParamModel.envGuide[title]}",
          style: TextStyle(fontSize: 20, color: Colors.red));
    } else {
      return const SizedBox();
    }
  }
}

class EnvCheckWidget extends StatefulWidget {
  final String cmdStr;
  final String title;

  const EnvCheckWidget({super.key, required this.cmdStr, required this.title});

  @override
  State<EnvCheckWidget> createState() => _EnvCheckWidgetState();
}

class _EnvCheckWidgetState extends State<EnvCheckWidget> {
  String executeRes = "";

  bool get _executing => executeRes.isEmpty;

  void _envTestCheck(String binRoot) async {
    executeRes = await CommandUtil.getInstance().checkVersion(binRoot);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_executing) {
      return const ProgressRing();
    }

    return IconButton(
      icon: const Icon(FluentIcons.show_results, size: 24.0),
      onPressed: () => DialogUtil.showConfirmDialog(
          context: context,
          title: "${widget.title}测试结果",
          content: executeRes,
          showCancel: false),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((timeStamp) => _envTestCheck(widget.cmdStr));
  }
}
