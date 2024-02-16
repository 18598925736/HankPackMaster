import 'package:fluent_ui/fluent_ui.dart';
import 'package:hank_pack_master/comm/toast_util.dart';

import '../upload_platforms.dart';

/// 输入框
Widget input(
  String title,
  String placeholder,
  TextEditingController controller, {
  Widget? suffix,
  int maxLines = 1,
  int? maxLength,
  bool must = false,
  bool enable = true,
}) {
  Widget mustSpace;

  if (must) {
    mustSpace = SizedBox(
        width: 20,
        child: Center(
            child:
                Text('*', style: TextStyle(fontSize: 18, color: Colors.red))));
  } else {
    mustSpace = const SizedBox(width: 20);
  }

  var textStyle =
      const TextStyle(decoration: TextDecoration.none, fontSize: 16);

  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 18)),
              mustSpace
            ],
          ),
        ),
        Expanded(
          child: TextBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
              unfocusedColor: Colors.transparent,
              highlightColor: Colors.transparent,
              style: textStyle,
              placeholder: placeholder,
              placeholderStyle: textStyle,
              expands: false,
              maxLines: maxLines,
              maxLength: maxLength,
              enabled: enable,
              controller: controller),
        ),
        if (suffix != null) ...[suffix]
      ],
    ),
  );
}

Widget choose(String title, Map<String, String> orderList,
    {bool must = true,
    required Function(String) setSelectedOrder,
    required String? selected}) {
  Widget comboBox;

  Widget mustSpace;

  if (must) {
    mustSpace = SizedBox(
        width: 20,
        child: Center(
            child:
                Text('*', style: TextStyle(fontSize: 18, color: Colors.red))));
  } else {
    mustSpace = const SizedBox(width: 20);
  }

  comboBox = ComboBox<String>(
    value: selected,
    placeholder: const Text('你必须选择一个打包命令'),
    items: orderList.entries
        .map((e) => ComboBoxItem(value: e.key, child: Text(e.key)))
        .toList(),
    onChanged: (order) {
      if (order != null) {
        setSelectedOrder(order);
      } else {
        ToastUtil.showPrettyToast("你必须选择一个打包命令");
      }
    },
  );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0),
    child: Row(children: [
      SizedBox(
        width: 100,
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            mustSpace
          ],
        ),
      ),
      comboBox
    ]),
  );
}

Widget chooseRadio(
  String title, {
  bool must = true,
  required UploadPlatform? selectedUploadPlatform,
  Function? setState,
}) {
  Widget mustSpace;

  if (must) {
    mustSpace = SizedBox(
        width: 20,
        child: Center(
            child:
                Text('*', style: TextStyle(fontSize: 18, color: Colors.red))));
  } else {
    mustSpace = const SizedBox(width: 20);
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0),
    child: Row(children: [
      SizedBox(
          width: 100,
          child: Row(children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            mustSpace
          ])),
      Expanded(
        child: Row(
          children: List.generate(uploadPlatforms.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 18.0),
              child: RadioButton(
                  checked: index == selectedUploadPlatform?.index,
                  content: Text(uploadPlatforms[index].name),
                  onChanged: (checked) {
                    selectedUploadPlatform = uploadPlatforms[index];
                    debugPrint(
                        "uploadPlatforms[index] = ${selectedUploadPlatform?.index}");
                    // setState?.call();
                  }),
            );
          }),
        ),
      )
    ]),
  );
}