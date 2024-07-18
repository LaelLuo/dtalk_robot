import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class DTalk {
  final String token;
  final String secret;

  DTalk({required this.token, required this.secret});

  Future<void> sendMessage(String message) => _sendMessage(this, message);

  static final HttpClient _client = HttpClient();

  static Future<void> _sendMessage(DTalk dTalk, String message) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final stringToSign = '$timestamp\n${dTalk.secret}';
    final hmac = Hmac(sha256, dTalk.secret.toUTF8());
    final sign = base64.encode(hmac.convert(stringToSign.toUTF8()).bytes);
    final url = 'https://oapi.dingtalk.com/robot/send?access_token=${dTalk.token}&timestamp=$timestamp&sign=$sign';
    final request = await _client.postUrl(Uri.parse(url));
    request.headers.contentType = ContentType.json;
    request.write(json.encode({
      r'msgtype': 'text',
      r'text': {'content': message}
    }));
    final response = await request.close();
    final data = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) throw Exception('DTalk error => $data');
    final jsonData = json.decode(data);
    if (jsonData[r'errcode'] != 0) throw Exception('DTalk error => ${jsonData[r'errmsg']}');
  }
}

extension UTF8String on String {
  List<int> toUTF8() => utf8.encode(this);
}
