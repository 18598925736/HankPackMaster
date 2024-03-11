import 'package:fluent_ui/fluent_ui.dart';
import 'package:hank_pack_master/comm/toast_util.dart';
import 'package:hank_pack_master/hive/project_record/project_record_entity.dart';
import 'package:hank_pack_master/hive/project_record/project_record_operator.dart';
import 'package:hank_pack_master/hive/project_record/upload_platforms.dart';
import 'package:hank_pack_master/ui/work_shop/work_shop_vm.dart';

import '../../../comm/ui/form_input.dart';
import '../../../comm/upload_platforms.dart';
import '../../../hive/project_record/package_setting_entity.dart';

class FastUploadDialogWidget extends StatefulWidget {
  final WorkShopVm workShopVm;

  final ProjectRecordEntity projectRecordEntity;

  final String apkPath;

  final Function? goToWorkShop;

  const FastUploadDialogWidget({
    super.key,
    required this.projectRecordEntity,
    required this.workShopVm,
    this.goToWorkShop,
    required this.apkPath,
  });

  @override
  State<FastUploadDialogWidget> createState() => _FastUploadDialogWidgetState();
}

class _FastUploadDialogWidgetState extends State<FastUploadDialogWidget> {
  var isValidGitUrlRes = true;

  var textStyle = const TextStyle(fontSize: 18);
  var textMustStyle = TextStyle(fontSize: 18, color: Colors.red);

  var errStyle = TextStyle(fontSize: 16, color: Colors.red);

  final TextEditingController _updateLogController = TextEditingController();

  final TextEditingController _apkLocationController = TextEditingController();

  UploadPlatform? _selectedUploadPlatform;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _apkLocationController.text = widget.apkPath;
      initSetting(widget.projectRecordEntity.fastUploadSetting);
    });
  }

  void initSetting(PackageSetting? fastUploadSetting) {
    if (fastUploadSetting == null) {
      return;
    }
    var selectedUploadPlatform = fastUploadSetting.selectedUploadPlatform;
    if (selectedUploadPlatform == null) {
      return;
    }
    _selectedUploadPlatform = selectedUploadPlatform;
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    var confirmActionBtn = FilledButton(
        child: const Text("确定"),
        onPressed: () {
          // 收集信息,并返回出去
          String appUpdateStr = _updateLogController.text;
          String apkLocation = _apkLocationController.text;
          UploadPlatform? selectedUploadPlatform = _selectedUploadPlatform;

          // 将此任务添加到队列中去
          widget.projectRecordEntity.fastUploadSetting =
              widget.projectRecordEntity.setting = PackageSetting(
            appUpdateLog: appUpdateStr,
            apkLocation: apkLocation,
            selectedUploadPlatform: selectedUploadPlatform,
          );

          ProjectRecordOperator.insertOrUpdate(widget.projectRecordEntity);

          String errMsg =
              widget.projectRecordEntity.setting!.readyOnlyPlatform();
          if (errMsg.isNotEmpty) {
            setState(() => _errMsg = errMsg);
            return;
          }

          widget.projectRecordEntity.apkPath =
              apkLocation; // 如果apkLocation为空，则认为是要快速上传

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
          input("apk位置", "", _apkLocationController, maxLines: 1),
          chooseRadio('上传方式'),
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
}
