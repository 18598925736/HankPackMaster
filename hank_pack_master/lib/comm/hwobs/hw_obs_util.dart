import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';

/// 华为OBS对象存储服务核心类
class HwObsUtil {
  ///

  static HwObsUtil? _instance;

  /// 私有的构造函数
  HwObsUtil._();

  static late Dio _dio;

  static late String _ak;
  static late String _sk;
  static late String _endpoint;
  static late String _bucketName;

  // 公共的静态方法获取实例
  static HwObsUtil getInstance() {
    if (_instance == null) {
      _dio = Dio();
      _ak = "WME9RK9W2EA5J7WMG0ZD";
      _sk = "mW2cNSmvCgDBk2WSeqNSdJowr7KlMTe5FxDl9ovB";
      _endpoint = "obs.ap-southeast-1.myhuaweicloud.com";
      _bucketName = "kbzpay-apppackage";
      _instance = HwObsUtil._();
    }
    return _instance!;
  }

  String nowDate() {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('E, dd MMM yyyy HH:mm:ss', 'en_GB');
    String formatted = formatter.format(now.toUtc());
    return "$formatted GMT";
  }

  String getAuthorization(String requestTime) {
    // 1 构造请求字符串（StringToSign）;

    debugPrint("requestTime: $requestTime");

    String contentMD5 = "";
    String contentType = "";
    String canonicalizedHeaders = "";
    String canonicalizedResource = "/$_bucketName/objecttest1";
    debugPrint("canonicalizedResource: $canonicalizedResource");
    String stringToSign =
        "PUT\n$contentMD5\n$contentType\n$requestTime\n$canonicalizedHeaders$canonicalizedResource";
    debugPrint("StringToSign: $stringToSign");

    // 2. 使用SK对StringToSign UTF-8编码之后的结果进行HMAC-SHA1签名计算
    List<int> keyBytes = utf8.encode(_sk);
    List<int> messageBytes =
        utf8.encode(stringToSign); // 对 StringToSign 进行 UTF-8 编码
    Hmac hmacSha1 = Hmac(sha1, keyBytes);
    Digest hmacDigest = hmacSha1.convert(messageBytes);
    String hmacSha1Result = hmacDigest.toString();
    debugPrint("HMAC-SHA1计算的结果是:  $hmacSha1Result");

    // 3. 对第3步的结果进行Base64编码
    String encodedMessage = base64.encode(utf8.encode(hmacSha1Result));
    debugPrint("最终签名: OBS $_ak:$encodedMessage"); // 打印编码后的字符串

    return 'OBS $_ak:$encodedMessage';
  }

  testBaidu() async {
    String url = "https://www.baidu.com";
    debugPrint("请求地址为：$url");
    final response = await _dio.get(url);
    debugPrint('responseCode  =  ${response.statusCode ?? 0}');



  }

  /// 调用 OBS上传，必须关闭XGate，不然网络有问题
  doUpload() async {
    String requestTime = nowDate();
    String authorization = getAuthorization(requestTime);
    String url = "https://$_bucketName.$_endpoint";
    debugPrint("请求地址为：$url");

    // 构建 FormData
    FormData formData = FormData.fromMap(
        {"file": await MultipartFile.fromFile('D:\\OBSobject\\text01.txt')});

    var options = Options(
      headers: {
        'Date': requestTime,
        'Authorization': authorization,
      },
    );

    onSendProgress(int current, int total) {
      double result = (current / total) * 100;
      String formattedResult = result.toStringAsFixed(2);
      debugPrint("请求发送中...$formattedResult%");
    }

    onReceiveProgress(int current, int total) {
      double result = (current / total) * 100;
      String formattedResult = result.toStringAsFixed(2);
      debugPrint("请求接收中...$formattedResult%");
    }

    final response = await _dio.post(url,
        data: formData,
        options: options,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);

    debugPrint('responseCode  =  ${response.statusCode ?? 0}');
  }

// 官方计算的: OBS WME9RK9W2EA5J7WMG0ZD:Ha1fA/9wR0qIxXhGw7mBAJO46xM=
// 本人计算的: OBS WME9RK9W2EA5J7WMG0ZD:MWRhZDVmMDNmZjcwNDc0YTg4YzU3ODQ2YzNiOTgxMDA5M2I4ZWIxMw==
}
