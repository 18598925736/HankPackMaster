import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:hank_pack_master/hive/project_record/project_record_operator.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../hive/project_record/project_record_entity.dart';
import 'grid_datasource.dart';

class ProjectManagerPage extends StatefulWidget {
  const ProjectManagerPage({super.key});

  @override
  State<ProjectManagerPage> createState() => _ProjectManagerPageState();
}

class _ProjectManagerPageState extends State<ProjectManagerPage> {
  late GridDataSource _dataSource;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _dataSource = GridDataSource(data: _getProjectRecordEntity);
  }

  List<ProjectRecordEntity> get _getProjectRecordEntity {
    return [
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
      ProjectRecordEntity(
          "${DateTime.now().millisecondsSinceEpoch + Random().nextInt(20000)} ",
          "testBranch"),
    ];
  }

  /// Define list of CommandBarItem
  get simpleCommandBarItems => <CommandBarItem>[
        CommandBarBuilderItem(
          builder: (context, mode, w) => Tooltip(
            message: "新建一个安卓工程",
            child: w,
          ),
          wrappedItem: CommandBarButton(
            icon: const Icon(FluentIcons.add),
            label: const Text('新建'),
            onPressed: () => createAndroidProjectRecord(),
          ),
        ),
        const CommandBarButton(
          icon: Icon(FluentIcons.cancel),
          label: Text('Disabled'),
          onPressed: null,
        ),
      ];

  /// 创建一个新的安卓工程record，并刷新UI
  void createAndroidProjectRecord() {
    ProjectRecordOperator.insertOrUpdate(ProjectRecordEntity(
        "${DateTime.now().millisecondsSinceEpoch}", "testBranch"));
    setState(() {});
  }

  Widget _buildDataPager() {
    debugPrint(
        '_getProjectRecordEntity.length = > ${_getProjectRecordEntity.length / _rowsPerPage}');

    return SfDataPager(
      delegate: _dataSource,
      availableRowsPerPage: const <int>[10, 15, 20],
      pageCount: (_getProjectRecordEntity.length / _rowsPerPage).ceilToDouble(),
      onRowsPerPageChanged: (int? rowsPerPage) {
        setState(() {
          _rowsPerPage = rowsPerPage!;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var grid = Expanded(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: SfDataGrid(
          columnWidthMode: ColumnWidthMode.fill,
          gridLinesVisibility: GridLinesVisibility.none,
          headerGridLinesVisibility: GridLinesVisibility.none,
          rowsPerPage: _rowsPerPage,
          source: _dataSource,
          columns: _getColumn,
        ),
      ),
    );

    var size = _getProjectRecordEntity.length;
    if (size == 0) {
      size = 1;
    }

    return Container(
      color: const Color(0xffAFCF84),
      child: Card(
          backgroundColor: const Color(0xfff2f2e8),
          margin: const EdgeInsets.all(15),
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: CommandBar(
                    overflowBehavior: CommandBarOverflowBehavior.noWrap,
                    primaryItems: [...simpleCommandBarItems])),
            grid,
            _buildDataPager()
          ])),
    );
  }

  List<GridColumn> get _getColumn {
    var bg = Colors.green.withOpacity(.1);

    return <GridColumn>[
      GridColumn(
          columnName: 'gitUrl',
          label: Container(
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius:
                      const BorderRadius.only(topLeft: Radius.circular(10))),
              padding: const EdgeInsets.only(left: 8.0),
              alignment: Alignment.centerLeft,
              child: const Text('gitUrl', style: gridTextStyle))),
      GridColumn(
        columnName: 'branch',
        label: Container(
            decoration: BoxDecoration(
                color: bg,
                borderRadius:
                    const BorderRadius.only(topRight: Radius.circular(10))),
            padding: const EdgeInsets.only(left: 8.0),
            alignment: Alignment.centerLeft,
            child: const Text('branch', style: gridTextStyle)),
      ),
    ];
  }
}
