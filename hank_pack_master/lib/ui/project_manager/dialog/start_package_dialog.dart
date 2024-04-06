import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:hank_pack_master/comm/toast_util.dart';
import 'package:hank_pack_master/hive/env_group/env_group_operator.dart';
import 'package:hank_pack_master/hive/project_record/project_record_entity.dart';
import 'package:hank_pack_master/hive/project_record/upload_platforms.dart';
import 'package:hank_pack_master/ui/work_shop/work_shop_vm.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';

import '../../../comm/comm_font.dart';
import '../../../comm/gradients.dart';
import '../../../comm/str_const.dart';
import '../../../comm/text_util.dart';
import '../../../comm/ui/form_input.dart';
import '../../../comm/upload_platforms.dart';
import '../../../core/command_util.dart';
import '../../../hive/env_config/env_config_operator.dart';
import '../../../hive/env_group/env_check_result_entity.dart';
import '../../../hive/project_record/package_setting_entity.dart';
import '../../../hive/project_record/project_record_operator.dart';

class StartPackageDialogWidget extends StatefulWidget {
  final WorkShopVm workShopVm;

  final List<String> enableAssembleOrders;
  final ProjectRecordEntity projectRecordEntity;
  final EnvCheckResultEntity javaHome;

  final Function? goToWorkShop;

  const StartPackageDialogWidget({
    super.key,
    required this.projectRecordEntity,
    required this.workShopVm,
    required this.enableAssembleOrders,
    this.goToWorkShop,
    required this.javaHome,
  });

  @override
  State<StartPackageDialogWidget> createState() =>
      _StartPackageDialogWidgetState();
}

class _StartPackageDialogWidgetState extends State<StartPackageDialogWidget> {
  var isValidGitUrlRes = true;

  var textStyle = const TextStyle(fontSize: 18);
  var textMustStyle = TextStyle(fontSize: 18, color: Colors.red);

  var errStyle = TextStyle(fontSize: 16, color: Colors.red);

  final TextEditingController _updateLogController = TextEditingController();
  final TextEditingController _mergeBranchNameController =
      TextEditingController();

  final TextEditingController _apkLocationController = TextEditingController();

  String? _selectedOrder;

  UploadPlatform? _selectedUploadPlatform;

  EnvCheckResultEntity? _jdk; // 当前使用的jdk版本

  String get projectName {
    var gitText = widget.projectRecordEntity.gitUrl;
    var lastSepIndex = gitText.lastIndexOf("/");
    var endIndex = gitText.length - 4;
    assert(endIndex > 0);
    String projectName = gitText.substring(lastSepIndex + 1, endIndex);
    return projectName;
  }

  String get gitBranch {
    return widget.projectRecordEntity.branch;
  }

  @override
  void initState() {
    super.initState();
    _jdk = widget.javaHome; // 这里必须使用 激活时使用的jdk
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initSetting(widget.projectRecordEntity.packageSetting);

      String projectWorkDir =
          EnvConfigOperator.searchEnvValue(Const.envWorkspaceRootKey) +
              Platform.pathSeparator +
              projectName +
              Platform.pathSeparator +
              Uri.encodeComponent(gitBranch) +
              Platform.pathSeparator +
              projectName +
              Platform.pathSeparator; // 总目录\项目名\分支名\项目名

      debugPrint("命令执行根目录为:$projectWorkDir");

      CommandUtil.getInstance().gitBranchRemote(
        projectWorkDir,
        (s) {
          debugPrint('获取本地分支:$s');
          s.split("\n").forEach((e) {
            _branchList.add(e);
          });

          _branchList.removeWhere((e) =>
          e.contains("origin/HEAD") ||
              Uri.encodeComponent(e.trim()) == Uri.encodeComponent(gitBranch));

          setState(() {});
        },
      );
    });
  }

  void initSetting(PackageSetting? packageSetting) {
    if (packageSetting == null) {
      return;
    }

    StringBuffer sb = StringBuffer();
    packageSetting.mergeBranchList?.forEach((e) {
      sb.writeln(e);
    });

    _mergeBranchNameController.text = sb.toString().trim();
    _selectedOrder = packageSetting.selectedOrder;
    _selectedUploadPlatform = packageSetting.selectedUploadPlatform;
    _apkLocationController.text = packageSetting.apkLocation ?? '';
    _jdk = packageSetting.jdk;

    setState(() {});
  }

  Widget chooseRadio(String title) {
    Widget mustSpace = SizedBox(
        width: 20,
        child: Center(
            child: Text(
          '*',
          style: TextStyle(fontSize: 18, color: Colors.red),
        )));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0),
      child: Row(children: [
        SizedBox(
            width: 100,
            child: Row(children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              mustSpace
            ])),
        Expanded(
          child: Row(
            children: List.generate(uploadPlatforms.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 18.0),
                child: RadioButton(
                    checked: index == _selectedUploadPlatform?.index,
                    content: Text(
                      uploadPlatforms[index].name!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    onChanged: (checked) {
                      if (checked == true) {
                        _selectedUploadPlatform = uploadPlatforms[index];
                        setState(() {});
                      }
                    }),
              );
            }),
          ),
        )
      ]),
    );
  }

  String _errMsg = "";

  final List<String> _branchList = [];
  final List<String> _selectedToMergeBranch = [];

  @override
  Widget build(BuildContext context) {
    Map<String, String> enableAssembleMap = {};
    for (var e in widget.enableAssembleOrders) {
      enableAssembleMap[e] = e;
    }

    var confirmActionBtn = FilledButton(
        child: const Text("确定"),
        onPressed: () {
          // 收集信息,并返回出去
          String appUpdateStr = _updateLogController.text;
          List<String> mergeBranchList = _mergeBranchNameController.text
              .trim()
              .split("\n")
              .map((e) => e.trim())
              .toList();
          mergeBranchList.removeWhere((e) => e.trim().isEmpty);

          String apkLocation = _apkLocationController.text;
          String? selectedOrder = _selectedOrder;
          UploadPlatform? selectedUploadPlatform = _selectedUploadPlatform;

          // 将此任务添加到队列中去
          widget.projectRecordEntity.packageSetting =
              widget.projectRecordEntity.settingToWorkshop = PackageSetting(
            appUpdateLog: appUpdateStr,
            apkLocation: apkLocation,
            selectedOrder: selectedOrder,
            selectedUploadPlatform: selectedUploadPlatform,
            jdk: _jdk,
            mergeBranchList: mergeBranchList,
          );
          ProjectRecordOperator.update(widget.projectRecordEntity);

          String errMsg =
              widget.projectRecordEntity.settingToWorkshop!.readyToPackage();
          if (errMsg.isNotEmpty) {
            setState(() => _errMsg = errMsg);
            return;
          }

          var success = widget.workShopVm.enqueue(widget.projectRecordEntity);
          Navigator.pop(context);
          if (success) {
            widget.goToWorkShop?.call();
          } else {
            ToastUtil.showPrettyToast('打包任务入列失败,发现重复任务');
          }
        });
    var cancelActionBtn = OutlinedButton(
        child: const Text("取消"), onPressed: () => Navigator.pop(context));

    // 弹窗
    var contentWidget = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          input("更新日志", "输入更新日志...", _updateLogController,
              maxLines: 4,
              must: false,
              crossAxisAlignment: CrossAxisAlignment.center),
          _branchMergeWidget(),
          input("合并分支", "输入打包前要合入的其他分支名...", _mergeBranchNameController,
              // 这些分支貌似不应该手动填，而是选择 TODO
              maxLines: 3,
              must: false,
              toolTip: "注意：多个分支换行为分隔",
              crossAxisAlignment: CrossAxisAlignment.center),
          Row(
            children: [
              choose('打包命令', enableAssembleMap, setSelectedOrder: (order) {
                // 命令内容形如：assembleGoogleUat
                // 那就提取出 assemble后面的第一个单词，并将它转化为小写
                var apkChildFolder = extractFirstWordAfterAssemble(order);
                // 同时设置默认的apk路径
                _apkLocationController.text =
                    'app\\build\\outputs\\apk\\$apkChildFolder';
                _selectedOrder = order;
                setState(() {});
              }, selected: _selectedOrder),
            ],
          ),
          const SizedBox(height: 5),
          input("apk路径", "程序会根据此路径检测apk文件", _apkLocationController,
              maxLines: 1),
          chooseRadio('上传方式'),
          javaHomeChoose(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(_errMsg,
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const SizedBox(width: 10),
              confirmActionBtn,
              const SizedBox(width: 10),
              cancelActionBtn,
            ],
          )
        ]);

    return contentWidget;
  }

  Widget javaHomeChoose() {
    List<EnvCheckResultEntity> jdks = []; // 这里的数据应该从

    var find = EnvGroupOperator.find("java");
    if (find != null && find.envValue != null) {
      jdks = find.envValue!.toList();
    }

    Widget mustSpace = SizedBox(
        width: 20,
        child: Center(
            child: Text(
          '*',
          style: TextStyle(fontSize: 18, color: Colors.red),
        )));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 100,
            child: Row(children: [
              const Text("JavaHome",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              mustSpace
            ])),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(jdks.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 18.0, bottom: 10),
                child: RadioButton(
                    checked: _jdk == jdks[index],
                    content: Text(
                      jdks[index].envName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onChanged: (checked) {
                      if (checked == true) {
                        setState(() {
                          _jdk = jdks[index];
                          debugPrint("当前使用的jdk是 ${_jdk?.envPath}");
                        });
                      }
                    }),
              );
            }),
          ),
        )
      ]),
    );
  }

  _branchMergeWidget() {
    TextStyle textStyle = const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, fontFamily: commFontFamily);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Row(children: [Text('合并分支', style: textStyle)])),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 5, right: 2, bottom: 10),
              decoration: BoxDecoration(
                  gradient: mainPanelGradient,
                  borderRadius: const BorderRadius.all(Radius.circular(8))),
              child: MultiSelectDialogField<String>(
                  confirmText: Text('确定', style: textStyle),
                  cancelText: Text('取消', style: textStyle),
                  buttonIcon: const Icon(FluentIcons.add_work),
                  title: Text('选择你需要合并的分支', style: textStyle),
                  buttonText: Text('选择你需要合并的分支', style: textStyle),
                  decoration: const BoxDecoration(border: null),
                  searchable: true,
                  chipDisplay: MultiSelectChipDisplay(),
                  backgroundColor: Colors.white,
                  items: _branchList.map((e) => MultiSelectItem(e, e)).toList(),
                  listType: MultiSelectListType.CHIP,
                  onConfirm: (values) => _selectedToMergeBranch.addAll(values)),
            ),
          ),
        ],
      ),
    );
  }
}
