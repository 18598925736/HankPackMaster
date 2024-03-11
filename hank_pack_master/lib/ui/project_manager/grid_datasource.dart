import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:hank_pack_master/comm/dialog_util.dart';
import 'package:hank_pack_master/comm/gradients.dart';
import 'package:hank_pack_master/comm/no_scroll_bar_ext.dart';
import 'package:hank_pack_master/ui/project_manager/package_history_card.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../comm/pgy/pgy_entity.dart';
import '../../comm/url_check_util.dart';
import '../../hive/project_record/project_record_entity.dart';
import '../../hive/project_record/project_record_operator.dart';
import 'column_name_const.dart';
import 'dialog/edit_project_record_dialog.dart';

const TextStyle gridTextStyle = TextStyle(
    color: Color(0xff2C473E),
    fontFamily: 'STKAITI',
    fontSize: 16,
    fontWeight: FontWeight.w600);

enum CellType {
  text, // 纯文案显示
  assembleOrders, // 进入打包操作
  statue, // 预检状态标志
  goPreCheck, // 操作入列按钮
  goPackageAction, // 进入打包操作
  recordAction, // 项目操作
}

enum ProjectRecordStatue {
  unchecked, // 未激活
  running, // 执行中
  waiting, // 排队中
  checked, // 已激活
}

class CellValue {
  CellType cellType;
  dynamic value;
  ProjectRecordEntity? entity;

  CellValue({required this.cellType, required this.value, this.entity});
}

/// 数据源解析器
class ProjectEntityDataSource extends DataGridSource {
  List<DataGridRow> _rows = [];

  final List<ProjectRecordEntity> dataList = [];

  BuildContext buildContext;

  Function(ProjectRecordEntity)? funConfirmToActive;
  Function(ProjectRecordEntity)? funcGoPackageAction;
  Function()? funJumpToWorkShop;

  ProjectRecordStatue Function(ProjectRecordEntity)
      funJudgeProjectStatue; // 设定一个函数，判断 工程实体的状态

  Function(ProjectRecordEntity, String)? openFastUploadDialogFunc;

  double runningProcessValue = 0;

  void deleteProjectRecord(ProjectRecordEntity? entity) {
    if (entity == null) {
      return;
    }

    ProjectRecordOperator.delete(entity);
    _refresh();
  }

  bool insertOrUpdateProjectRecord(String gitUrl, String branchName,
      String projectName, String projectDesc) {
    if (gitUrl.isEmpty ||
        branchName.isEmpty ||
        projectName.isEmpty ||
        projectDesc.isEmpty) {
      return false;
    }

    ProjectRecordOperator.insertOrUpdate(
      ProjectRecordEntity(gitUrl, branchName, projectName, projectDesc),
    );

    _refresh();

    return true;
  }

  void init() {
    _refresh();
  }

  void clearAllProjectRecord() async {
    debugPrint("执行删除全部");
    await ProjectRecordOperator.clear();
    _refresh();
  }

  /// 原来表格的刷新必须强制更新 每行组件（`_buildRows`）
  _refresh() {
    dataList.clear();
    dataList.addAll(ProjectRecordOperator.findAll());
    _buildRows();
    notifyListeners();
  }

  ProjectEntityDataSource({
    required this.funConfirmToActive,
    required this.funcGoPackageAction,
    required this.funJumpToWorkShop,
    required this.buildContext,
    required this.openFastUploadDialogFunc,
    required this.funJudgeProjectStatue,
  }) {
    _buildRows();
  }

  _buildRows() {
    _rows = dataList
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<CellValue>(
                  columnName: ColumnNameConst.projectName,
                  value:
                      CellValue(value: e.projectName, cellType: CellType.text)),
              DataGridCell<CellValue>(
                  columnName: ColumnNameConst.gitUrl,
                  value: CellValue(value: e.gitUrl, cellType: CellType.text)),
              DataGridCell<CellValue>(
                  columnName: ColumnNameConst.branch,
                  value: CellValue(value: e.branch, cellType: CellType.text)),
              DataGridCell<CellValue>(
                  columnName: ColumnNameConst.statue,
                  value: CellValue(value: e, cellType: CellType.statue)),
              if (e.preCheckOk) ...[
                DataGridCell<CellValue>(
                    columnName: ColumnNameConst.jobOperation,
                    value: CellValue(
                      value: e,
                      cellType: CellType.goPackageAction,
                      entity: e,
                    )),
              ] else ...[
                DataGridCell<CellValue>(
                    columnName: ColumnNameConst.jobOperation,
                    value: CellValue(
                      value: "马上激活",
                      cellType: CellType.goPreCheck,
                      entity: e,
                    )),
              ],
              DataGridCell<CellValue>(
                  columnName: ColumnNameConst.assembleOrders,
                  value: CellValue(
                      value: e.assembleOrders,
                      cellType: CellType.assembleOrders)),
              DataGridCell<CellValue>(
                  columnName: ColumnNameConst.recordOperation,
                  value: CellValue(value: e, cellType: CellType.recordAction)),
            ]))
        .toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  double iconSize = 30;

  _queryJobHistoryWidget(CellValue cellValue) {
    return Tooltip(
        message: "查看作业历史",
        child: IconButton(
            icon: Icon(FluentIcons.full_history,
                size: iconSize, color: Colors.green.withOpacity(.8)),
            onPressed: () {
              if (cellValue.value is ProjectRecordEntity) {
                var e = cellValue.value as ProjectRecordEntity;

                var his = e.jobHistory ?? [];

                var content = ListView.builder(
                  itemBuilder: (context, index) {
                    var s = his[index];
                    // 尝试将打包历史字符串转化为 MyAppInfo 对象
                    MyAppInfo myAppInfo;
                    try {
                      myAppInfo = MyAppInfo.fromJsonString(s);
                    } catch (ex) {
                      myAppInfo = MyAppInfo(errMessage: s);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right:10.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: PackageHistoryCard(
                                  myAppInfo: myAppInfo,
                                  doFastUpload: (s) {
                                    openFastUploadDialogFunc?.call(e, s);
                                  })),
                        ],
                      ),
                    );
                  },
                  itemCount: his.length,
                );

                DialogUtil.showCustomDialog(
                    maxHeight: 600,
                    maxWidth: 600,
                    context: buildContext,
                    title: "${e.projectName} 打包历史",
                    content: content);
              } else {
                var e = cellValue.entity!;
                var his = e.jobHistory ?? [];

                DialogUtil.showCustomDialog(
                    maxHeight: 600,
                    maxWidth: 600,
                    context: buildContext,
                    title: "${e.projectName} 激活历史",
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...his.reversed.map((s) {
                            return Row(
                              children: [
                                Expanded(
                                  child: m.Card(
                                    color: Colors.white,
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          gradient: mainPanelGradient),
                                      padding: const EdgeInsets.all(10.0),
                                      child: SelectableText(s),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList()
                        ],
                      ),
                    ).hideScrollbar(buildContext));
              }
            }));
  }

  /// 每行UI的构建逻辑
  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    var rowIndex = rows.indexOf(row);
    Color backgroundColor = Colors.transparent;
    if ((rowIndex % 2) == 1) {
      backgroundColor = Colors.green.withOpacity(.1);
    }

    return DataGridRowAdapter(
        color: backgroundColor,
        cells: row.getCells().map<Widget>((dataGridCell) {
          CellValue cellValue = dataGridCell.value;

          Widget cellWidget;

          switch (cellValue.cellType) {
            case CellType.text:
              cellWidget = Text(
                "${cellValue.value}",
                style: gridTextStyle,
                overflow: TextOverflow.ellipsis,
              );
              break;
            case CellType.statue:
              ProjectRecordEntity entity = cellValue.value;
              Widget statueWidget;
              String toolTip;
              ProjectRecordStatue projectRecordStatue =
                  funJudgeProjectStatue(entity);
              switch (projectRecordStatue) {
                case ProjectRecordStatue.unchecked:
                  toolTip = "未激活";
                  statueWidget = Icon(
                    FluentIcons.unknown,
                    color: Colors.red.withOpacity(.5),
                    size: iconSize,
                  );
                  break;
                case ProjectRecordStatue.running:
                  toolTip = "执行中";
                  statueWidget = GestureDetector(
                    onTap: funJumpToWorkShop,
                    child: _progressRing(runningProcessValue),
                  );
                  break;
                case ProjectRecordStatue.waiting:
                  toolTip = "排队中";
                  statueWidget = Icon(
                    FluentIcons.waitlist_confirm,
                    color: Colors.yellow.darkest,
                    size: iconSize,
                  );
                  break;
                case ProjectRecordStatue.checked:
                  toolTip = "已激活";
                  statueWidget = Icon(
                    FluentIcons.skype_circle_check,
                    color: Colors.green,
                    size: iconSize,
                  );
                  break;
              }
              cellWidget = Tooltip(message: toolTip, child: statueWidget);
              break;
            case CellType.goPreCheck:
              cellWidget = Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: "${cellValue.value}",
                    child: IconButton(
                      icon: Icon(FluentIcons.build_queue_new,
                          size: iconSize, color: Colors.green.withOpacity(.8)),
                      onPressed: () =>
                          funConfirmToActive?.call(cellValue.entity!),
                    ),
                  ),
                  _queryJobHistoryWidget(cellValue)
                ],
              );
              break;
            case CellType.goPackageAction:
              cellWidget = Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: "重置激活状态",
                      child: IconButton(
                        icon: Icon(FluentIcons.reset,
                            size: iconSize,
                            color: Colors.green.withOpacity(.8)),
                        onPressed: () {
                          DialogUtil.showCustomDialog(
                              context: buildContext,
                              title: "警告",
                              content: "此项目会变为非激活状态，所有打包记录将会清除，继续吗？",
                              onConfirm: () {
                                var e = cellValue.entity!;
                                _resetProjectRecord(e);
                              });
                        },
                      ),
                    ),
                    Tooltip(
                      message: "开始打包",
                      child: IconButton(
                        icon: Icon(FluentIcons.packages,
                            size: iconSize,
                            color: Colors.green.withOpacity(.8)),
                        onPressed: () =>
                            funcGoPackageAction?.call(cellValue.entity!),
                      ),
                    ),
                    _queryJobHistoryWidget(cellValue)
                  ]);
              break;
            case CellType.assembleOrders:
              cellWidget = ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [..._assembleOrdersWidget(cellValue.value)],
              );
              break;
            case CellType.recordAction:
              cellWidget = Wrap(
                children: [
                  Tooltip(
                    message: "重新编辑",
                    child: IconButton(
                      icon: Icon(FluentIcons.edit,
                          size: iconSize, color: Colors.green.withOpacity(.8)),
                      onPressed: () {
                        var e = cellValue.value;
                        if (e is ProjectRecordEntity) {
                          editAndroidProjectRecord(e);
                        }
                      },
                    ),
                  ),
                  Tooltip(
                    message: "删除此记录",
                    child: IconButton(
                      icon: Icon(FluentIcons.delete,
                          size: iconSize, color: Colors.green.withOpacity(.8)),
                      onPressed: () {
                        var e = cellValue.value;
                        if (e is ProjectRecordEntity) {
                          DialogUtil.showCustomDialog(
                              context: buildContext,
                              title: "确定删除吗?",
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _cText(
                                    label: '工程名',
                                    content: e.projectName,
                                  ),
                                  _cText(
                                    label: '远程仓库',
                                    content: e.gitUrl,
                                  ),
                                  _cText(
                                    label: '分支名',
                                    content: e.branch,
                                  ),
                                ],
                              ),
                              onConfirm: () {
                                deleteProjectRecord(cellValue.value);
                              });
                        }
                      },
                    ),
                  ),
                ],
              );
              break;
          }

          return Container(
            padding: const EdgeInsets.only(left: 5),
            alignment: Alignment.center,
            child: cellWidget,
          );
        }).toList());
  }

  Widget _progressRing(double progressValue) {
    return AnimatedContainer(
      width: iconSize,
      height: iconSize,
      duration: const Duration(milliseconds: 500),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ProgressRing(
            activeColor: Colors.blue,
            strokeWidth: 4,
          ),
          Center(
            child: Text(
              "${progressValue.round()}%",
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 编辑工程
  void editAndroidProjectRecord(ProjectRecordEntity e) {
    TextEditingController gitUrlTextController = TextEditingController();
    TextEditingController branchNameTextController = TextEditingController();
    TextEditingController projectNameTextController = TextEditingController();
    TextEditingController projectDescTextController = TextEditingController();

    var contentWidget = EditProjectDialogWidget(
      projectNameTextController: projectNameTextController,
      gitUrlTextController: gitUrlTextController,
      branchNameTextController: branchNameTextController,
      projectDescTextController: projectDescTextController,
    );

    gitUrlTextController.text = e.gitUrl;
    branchNameTextController.text = e.branch;
    projectNameTextController.text = e.projectName;
    projectDescTextController.text = e.projectDesc ?? '';

    DialogUtil.showCustomDialog(
        context: buildContext,
        title: '编辑工程',
        content: contentWidget,
        showActions: true,
        confirmText: "确定",
        onConfirm: () {
          if (!isValidGitUrl(gitUrlTextController.text)) {
            return false;
          }
          insertOrUpdateProjectRecord(
            gitUrlTextController.text,
            branchNameTextController.text,
            projectNameTextController.text,
            projectDescTextController.text,
          );
        },
        judgePop: () {
          if (gitUrlTextController.text.isEmpty ||
              branchNameTextController.text.isEmpty ||
              projectNameTextController.text.isEmpty ||
              projectDescTextController.text.isEmpty) {
            return false;
          }
          if (!isValidGitUrl(gitUrlTextController.text)) {
            return false;
          }
          return true;
        });
  }

  Widget _cText({
    required String label,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Text(
        "$label:  $content",
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
    );
  }

  List<Widget> _assembleOrdersWidget(List<String>? orders) {
    if (null == orders) {
      return [const SizedBox()];
    }

    Widget card(e) {
      return Card(
          borderColor: Colors.black,
          borderRadius: BorderRadius.circular(2),
          backgroundColor: Colors.blue.withOpacity(.2),
          margin: const EdgeInsets.all(2),
          child: Text(e.replaceAll("assemble", ''),
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)));
    }

    return orders
        .map((e) => GestureDetector(
              onTap: () {
                DialogUtil.showCustomDialog(
                    showCancel: false,
                    confirmText: "我知道了!",
                    context: buildContext,
                    title: "可用变体",
                    content: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [...orders.map((e) => card(e))],
                        ),
                      ),
                    ));
              },
              child: card(e),
            ))
        .toList();
  }

  void _resetProjectRecord(ProjectRecordEntity e) {
    e.preCheckOk = false;
    e.assembleOrders = [];
    e.jobHistory = [];
    ProjectRecordOperator.insertOrUpdate(e);
    _refresh();
  }
}
