import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class DTalk {
  final String token;
  final String secret;

  DTalk({required this.token, required this.secret});

  Future<void> sendMessage(String message) => _sendMessage(this, message);

  static final Dio _dio = Dio();

  static Future<void> _sendMessage(DTalk dTalk, String message) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final stringToSign = '$timestamp\n${dTalk.secret}';
    final hmac = Hmac(sha256, dTalk.secret.toUTF8());
    final sign = base64.encode(hmac.convert(stringToSign.toUTF8()).bytes);
    final url = 'https://oapi.dingtalk.com/robot/send?access_token=${dTalk.token}&timestamp=$timestamp&sign=$sign';
    final response = await _dio.post(url, data: {
      r'msgtype': 'text',
      r'text': {'content': message}
    });
    if (response.data[r'errcode'] != 0) throw Exception('DTalk error => ${response.data[r'errmsg']}');
  }
}

extension UTF8String on String {
  List<int> toUTF8() => utf8.encode(this);
}
