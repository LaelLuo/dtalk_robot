import 'package:dtalk_robot/dtalk_robot.dart';

Future<void> main() async {
  final dTalk = DTalk(token: r'token', secret: r'secret');
  await dTalk.sendText('test');
}
