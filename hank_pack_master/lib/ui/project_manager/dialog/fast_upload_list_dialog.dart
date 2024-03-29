import 'package:fluent_ui/fluent_ui.dart';
import 'package:hank_pack_master/ui/work_shop/work_shop_vm.dart';

import '../../../comm/ui/history_card.dart';
import '../../../hive/project_record/project_record_entity.dart';
import '../../../hive/project_record/project_record_operator.dart';

/// 快速上传列表弹窗
class FastUploadListDialog extends StatelessWidget {
  final double maxHeight;
  final WorkShopVm workShopVm;

  const FastUploadListDialog({
    super.key,
    required this.maxHeight,
    required this.workShopVm,
  });

  @override
  Widget build(BuildContext context) {
    var jobHistoryList = ProjectRecordOperator.findFastUploadTaskList();

    // 待上传列表中，相同的项目只保留最新的那条记录 TODO

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) {
              var e = jobHistoryList[index];
              return HistoryCard(
                historyEntity: e,
                maxHeight: maxHeight,
                projectRecordEntity: e.parentRecord,
              );
            },
            itemCount: jobHistoryList.length,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Visibility(
                visible: jobHistoryList.isNotEmpty,
                child: FilledButton(
                    child: Text("一键上传", style: _textStyle),
                    onPressed: () {
                      Navigator.pop(context);
                      for (var jobHistory in jobHistoryList) {
                        var projectRecordEntity = jobHistory.parentRecord; // 这里不能这么拼接
                        projectRecordEntity.settingToWorkshop = jobHistory.jobSetting;
                        projectRecordEntity.apkPath = jobHistory.jobResultEntity.apkPath; // 这里没有赋值
                        workShopVm.enqueue(projectRecordEntity); // 这里入列如的有问题
                      }
                    }),
              ),
              const SizedBox(width: 20),
              OutlinedButton(
                  child: Text("关闭", style: _textStyle),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ],
          ),
        )
      ],
    );
  }

  final _textStyle = const TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
}
