import 'package:fluent_ui/fluent_ui.dart';

import '../../../comm/url_check_util.dart';

class CreateProjectDialogWidget extends StatefulWidget {
  final TextEditingController gitUrlTextController;

  final TextEditingController branchNameTextController;

  final TextEditingController projectNameTextController;

  final TextEditingController projectDescTextController;

  final String defaultBranch;

  const CreateProjectDialogWidget({
    super.key,
    required this.gitUrlTextController,
    required this.branchNameTextController,
    required this.projectNameTextController,
    required this.projectDescTextController,
    required this.defaultBranch,
  });

  @override
  State<CreateProjectDialogWidget> createState() =>
      _CreateProjectDialogWidgetState();
}

class _CreateProjectDialogWidgetState extends State<CreateProjectDialogWidget> {
  var isValidGitUrlRes = true;

  var textStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  var textMustStyle = TextStyle(fontSize: 18, color: Colors.red);

  var errStyle = TextStyle(fontSize: 16, color: Colors.red);

  @override
  void initState() {
    super.initState();
    widget.gitUrlTextController.addListener(() {
      if (widget.gitUrlTextController.text.isEmpty) {
        isValidGitUrlRes = true;
      } else {
        isValidGitUrlRes = isValidGitUrl(widget.gitUrlTextController.text);
      }
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.branchNameTextController.text = widget.defaultBranch;
    });
  }

  @override
  Widget build(BuildContext context) {
    var projectNameLabel =
        SizedBox(width: 100, child: Text('项目名', style: textStyle));
    var projectDescLabel =
        SizedBox(width: 100, child: Text('项目描述', style: textStyle));
    var gitUrlLabel =
        SizedBox(width: 100, child: Text('git依赖', style: textStyle));
    var mustLabel = SizedBox(width: 20, child: Text("*", style: textMustStyle));
    var isValidGitUrlTip = Visibility(
      visible: !isValidGitUrlRes,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text("这不是一个正确的git地址", style: errStyle),
      ),
    );
    var branchNameLabel =
        SizedBox(width: 100, child: Text('分支名称', style: textStyle));

    var projectDescTextBox = Expanded(
      child: TextBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.green.withOpacity(.1)),
          unfocusedColor: Colors.transparent,
          highlightColor: Colors.transparent,
          expands: false,
          maxLines: 4,
          style: textStyle,
          controller: widget.projectDescTextController),
    );

    var projectNameTextBox = Expanded(
      child: TextBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.green.withOpacity(.1)),
          unfocusedColor: Colors.transparent,
          highlightColor: Colors.transparent,
          expands: false,
          maxLines: 1,
          style: textStyle,
          controller: widget.projectNameTextController),
    );

    var gitUrlTextBox = Expanded(
      child: TextBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.green.withOpacity(.1)),
          unfocusedColor: Colors.transparent,
          highlightColor: Colors.transparent,
          expands: false,
          maxLines: 1,
          style: textStyle,
          controller: widget.gitUrlTextController),
    );
    var branchNameTextBox = Expanded(
      child: TextBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.green.withOpacity(.1)),
          unfocusedColor: Colors.transparent,
          highlightColor: Colors.transparent,
          expands: false,
          maxLines: 1,
          style: textStyle,
          controller: widget.branchNameTextController),
    );
    var gitUrlRow = Row(children: [
      gitUrlLabel,
      mustLabel,
      gitUrlTextBox,
    ]);
    var branchNameRow = Row(children: [
      branchNameLabel,
      mustLabel,
      branchNameTextBox,
    ]);

    var projectName = Row(children: [
      projectNameLabel,
      mustLabel,
      projectNameTextBox,
    ]);

    var projectDesc = Row(children: [
      projectDescLabel,
      mustLabel,
      projectDescTextBox,
    ]);

    // 弹窗
    var contentWidget = Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 5),
      projectName,
      const SizedBox(height: 10),
      projectDesc,
      const SizedBox(height: 10),
      gitUrlRow,
      isValidGitUrlTip,
      const SizedBox(height: 10),
      branchNameRow,
    ]);

    return contentWidget;
  }
}
