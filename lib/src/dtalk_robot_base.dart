import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class DTalk {
  final String token;
  final String secret;

  DTalk({required this.token, required this.secret});

  Future<void> sendMessage(DTalkMessage message) => _sendMessage(this, message);

  Future<void> sendText(String content, {DTalkAt? at}) =>
      sendMessage(DTalkTextMessage(content: content, at: at));

  static final HttpClient _client = HttpClient();

  static Future<void> _sendMessage(DTalk dTalk, DTalkMessage message) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final stringToSign = '$timestamp\n${dTalk.secret}';
    final hmac = Hmac(sha256, dTalk.secret.toUTF8());
    final sign = base64.encode(hmac.convert(stringToSign.toUTF8()).bytes);
    final url =
        'https://oapi.dingtalk.com/robot/send?access_token=${dTalk.token}&timestamp=$timestamp&sign=$sign';
    final request = await _client.postUrl(Uri.parse(url));
    request.headers.contentType = ContentType.json;
    request.write(json.encode(message.toRequestBody()));
    final response = await request.close();
    final data = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) throw Exception('DTalk error => $data');
    final jsonData = json.decode(data);
    if (jsonData[r'errcode'] != 0) {
      throw Exception('DTalk error => ${jsonData[r'errmsg']}');
    }
  }
}

extension UTF8String on String {
  List<int> toUTF8() => utf8.encode(this);
}

class DTalkAt {
  const DTalkAt({
    this.mobiles = const [],
    this.userIds = const [],
    this.isAtAll = false,
  });

  final List<String> mobiles;
  final List<String> userIds;
  final bool isAtAll;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (mobiles.isNotEmpty) data[r'atMobiles'] = mobiles;
    if (userIds.isNotEmpty) data[r'atUserIds'] = userIds;
    if (isAtAll) data[r'isAtAll'] = true;
    return data;
  }
}

abstract class DTalkMessage {
  DTalkMessage({
    required this.msgType,
    this.at,
    this.supportsAt = false,
  }) {
    if (at != null && !supportsAt) {
      throw ArgumentError('$msgType 消息类型不支持@功能');
    }
  }

  final String msgType;

  final DTalkAt? at;

  final bool supportsAt;

  Map<String, dynamic> buildMessage();

  Map<String, dynamic> toRequestBody() {
    final body = <String, dynamic>{
      r'msgtype': msgType,
      msgType: buildMessage(),
    };
    if (at != null && supportsAt) {
      final atJson = at!.toJson();
      if (atJson.isNotEmpty) {
        body[r'at'] = atJson;
      }
    }
    return body;
  }
}

class DTalkTextMessage extends DTalkMessage {
  DTalkTextMessage({required this.content, super.at})
      : super(msgType: 'text', supportsAt: true);

  final String content;

  @override
  Map<String, dynamic> buildMessage() => {r'content': content};
}

class DTalkLinkMessage extends DTalkMessage {
  DTalkLinkMessage({
    required this.title,
    required this.text,
    required this.messageUrl,
    this.picUrl,
  }) : super(msgType: 'link');

  final String title;
  final String text;
  final String messageUrl;
  final String? picUrl;

  @override
  Map<String, dynamic> buildMessage() {
    final data = <String, dynamic>{
      r'title': title,
      r'text': text,
      r'messageUrl': messageUrl,
    };
    if (picUrl != null && picUrl!.isNotEmpty) {
      data[r'picUrl'] = picUrl;
    }
    return data;
  }
}

class DTalkMarkdownMessage extends DTalkMessage {
  DTalkMarkdownMessage({
    required this.title,
    required this.text,
    super.at,
  }) : super(msgType: 'markdown', supportsAt: true);

  final String title;
  final String text;

  @override
  Map<String, dynamic> buildMessage() => {
        r'title': title,
        r'text': text,
      };
}

class DTalkActionCardButton {
  const DTalkActionCardButton({
    required this.title,
    required this.actionUrl,
  });

  final String title;
  final String actionUrl;

  Map<String, dynamic> toJson() => {
        r'title': title,
        r'actionURL': actionUrl,
      };
}

class DTalkActionCardMessage extends DTalkMessage {
  DTalkActionCardMessage.single({
    required this.title,
    required this.text,
    required String singleTitle,
    required String singleUrl,
    this.btnOrientation,
    super.at,
  })  : single = DTalkActionCardSingle(title: singleTitle, url: singleUrl),
        buttons = null,
        super(msgType: 'actionCard', supportsAt: true);

  DTalkActionCardMessage.multi({
    required this.title,
    required this.text,
    required List<DTalkActionCardButton> buttons,
    this.btnOrientation,
    super.at,
  })  : buttons = List.unmodifiable(buttons),
        single = null,
        super(msgType: 'actionCard', supportsAt: true) {
    if (buttons.isEmpty) {
      throw ArgumentError('actionCard.btns 不能为空');
    }
  }

  final String title;
  final String text;
  final String? btnOrientation;
  final DTalkActionCardSingle? single;
  final List<DTalkActionCardButton>? buttons;

  @override
  Map<String, dynamic> buildMessage() {
    final data = <String, dynamic>{
      r'title': title,
      r'text': text,
    };
    if (btnOrientation != null && btnOrientation!.isNotEmpty) {
      data[r'btnOrientation'] = btnOrientation;
    }
    final singleAction = single;
    if (singleAction != null) {
      data[r'singleTitle'] = singleAction.title;
      data[r'singleURL'] = singleAction.url;
    } else {
      final actionButtons = buttons;
      if (actionButtons != null) {
        data[r'btns'] = actionButtons.map((b) => b.toJson()).toList();
      }
    }
    return data;
  }
}

class DTalkActionCardSingle {
  const DTalkActionCardSingle({required this.title, required this.url});

  final String title;
  final String url;
}

class DTalkFeedCardLink {
  const DTalkFeedCardLink({
    required this.title,
    required this.messageUrl,
    required this.picUrl,
  });

  final String title;
  final String messageUrl;
  final String picUrl;

  Map<String, dynamic> toJson() => {
        r'title': title,
        r'messageURL': messageUrl,
        r'picURL': picUrl,
      };
}

class DTalkFeedCardMessage extends DTalkMessage {
  DTalkFeedCardMessage({required List<DTalkFeedCardLink> links})
      : links = List.unmodifiable(links),
        super(msgType: 'feedCard') {
    if (this.links.isEmpty) {
      throw ArgumentError('feedCard.links 不能为空');
    }
  }

  final List<DTalkFeedCardLink> links;

  @override
  Map<String, dynamic> buildMessage() =>
      {r'links': links.map((link) => link.toJson()).toList()};
}
