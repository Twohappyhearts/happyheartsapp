import 'package:flutter_test/flutter_test.dart';

import 'package:happyhearts/presentation/chat_screen/widgets/ai_assistant_web_stub.dart';
import 'package:happyhearts/services/agent_config.dart';

void main() {
  group('open_url bridge message', () {
    test('data is the link as a string (current dashboard format)', () {
      expect(openUrlLink('tel:911').toString(), 'tel:911');
      expect(openUrlLink('tel:988')?.scheme, 'tel');
      expect(
        openUrlLink(' https://www.cdc.gov/hypertension/ ').toString(),
        'https://www.cdc.gov/hypertension/',
      );
      expect(openUrlLink('mailto:study@example.org')?.scheme, 'mailto');
      expect(openUrlLink('sms:741741')?.scheme, 'sms');
      expect(openUrlLink('http://example.org')?.scheme, 'http');
    });

    test('an object with url is accepted too', () {
      expect(openUrlLink({'url': 'tel:911'}).toString(), 'tel:911');
    });

    test('other schemes and bad data are ignored', () {
      expect(openUrlLink('javascript:alert(1)'), isNull);
      expect(openUrlLink('intent://scan#Intent;end'), isNull);
      expect(openUrlLink('file:///etc/hosts'), isNull);
      expect(openUrlLink('www.cdc.gov'), isNull);
      expect(openUrlLink(''), isNull);
      expect(openUrlLink(null), isNull);
      expect(openUrlLink(42), isNull);
      expect(openUrlLink({'href': 'tel:911'}), isNull);
    });
  });

  test('assistant page carries the app language', () {
    final uri = AgentConfig.pageUriFor('zh-Hant');
    expect(uri.path, '/m/assistant');
    expect(uri.queryParameters['lang'], 'zh-Hant');
  });
}
