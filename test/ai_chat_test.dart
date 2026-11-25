import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:happyhearts/presentation/ai_chat/agent_reply.dart';
import 'package:happyhearts/presentation/ai_chat/ai_chat_strings.dart';
import 'package:happyhearts/services/agent_messages.dart';

Map<String, dynamic> _j(String s) => jsonDecode(s) as Map<String, dynamic>;

AgentMessage _assemble(List<String> chunks, {AgentMessage? into}) {
  final m = into ?? AgentMessage(id: 'tmp', role: 'assistant', parts: []);
  final a = AgentMessageAssembler(message: m);
  for (final c in chunks) {
    a.apply(_j(c));
  }
  return m;
}

void main() {
  group('reply stream (AI SDK UI message chunks)', () {
    test('search, then text with a sources marker', () {
      String? title;
      final m = AgentMessage(id: 'tmp', role: 'assistant', parts: []);
      final a = AgentMessageAssembler(
        message: m,
        onTitle: (id, t) => title = '$id:$t',
      );
      for (final c in [
        '{"type":"start","messageId":"msg-1"}',
        '{"type":"start-step"}',
        '{"type":"tool-input-start","toolCallId":"c1","toolName":"searchKnowledge"}',
        '{"type":"tool-input-available","toolCallId":"c1","toolName":"searchKnowledge","input":{"query":"q"}}',
        '{"type":"tool-output-available","toolCallId":"c1","output":{"results":[{"ref":1,"title":"Preeclampsia","source":"the National Institutes of Health (NICHD)","documentId":"d1","content":"See https://www.preeclampsia.org/signs."}]}}',
        '{"type":"start-step"}',
        '{"type":"text-start","id":"t1"}',
        '{"type":"text-delta","id":"t1","delta":"Signs include **headache**."}',
        '{"type":"text-delta","id":"t1","delta":"\\n\\n[sources: 1]"}',
        '{"type":"text-end","id":"t1"}',
        '{"type":"finish"}',
        '{"type":"data-conversation-title","data":{"conversationId":"conv-1","title":"Signs"},"transient":true}',
      ]) {
        a.apply(_j(c));
      }
      expect(m.id, 'msg-1');
      expect(title, 'conv-1:Signs');
      final (text, refs) = splitSources(
        m.parts.lastWhere((p) => p.isText).text,
      );
      expect(text, 'Signs include **headache**.');
      expect(refs, [1]);
      final results = collectSearchResults(m);
      expect(results[1]?.documentId, 'd1');
      expect(
        displaySource(results[1]?.source),
        'National Institutes of Health',
      );
      expect(linkableHosts(m), contains('preeclampsia.org'));
      expect(emergencyOf(m), isNull);
    });

    test('a care-team offer in an older reply still marks the emergency', () {
      final m = _assemble([
        '{"type":"start","messageId":"msg-2"}',
        '{"type":"text-start","id":"a"}',
        '{"type":"text-delta","id":"a","delta":"Please contact your healthcare provider."}',
        '{"type":"tool-input-available","toolCallId":"n1","toolName":"notifyCareteam","input":{"situation":"urgent","language":"es","message":"Headache"}}',
        '{"type":"tool-approval-request","approvalId":"ap1","toolCallId":"n1"}',
      ]);
      expect(m.id, 'msg-2');
      expect(fixedReplySituation(replyText(m)), 'personal');
      expect(emergencyOf(m)?.situation, 'urgent');
      expect(emergencyOf(m)?.language, 'es');
    });

    test('reset-step drops the discarded step', () {
      final m = _assemble([
        '{"type":"start-step"}',
        '{"type":"text-start","id":"a"}',
        '{"type":"text-delta","id":"a","delta":"draft"}',
        '{"type":"reset-step"}',
        '{"type":"start-step"}',
        '{"type":"text-start","id":"b"}',
        '{"type":"text-delta","id":"b","delta":"final"}',
      ]);
      expect(m.text, 'final');
    });
  });

  group('safety replies', () {
    test('fixed replies are recognized in every language', () {
      for (final lang in aiChatLanguages) {
        for (final situation in careteamSituations) {
          expect(
            fixedReplySituation('Ok. ${fixedReplies[lang]![situation]}'),
            situation,
            reason: '$lang $situation',
          );
        }
      }
      expect(fixedReplySituation('Call 911 now'), isNull);
    });

    test('Persian digits count as 911', () {
      expect(mentionsNumber('Call ۹۱۱ now', '911'), isTrue);
      expect(mentionsNumber('Call 9110 now', '911'), isFalse);
    });

    test('an emergency reply is detected from its text', () {
      final m = AgentMessage(
        id: 'x',
        role: 'assistant',
        parts: [AgentPart(type: 'text', text: fixedReplies['es']!['crisis']!)],
      );
      expect(emergencyOf(m)?.situation, 'crisis');
    });

    test('language tags', () {
      expect(matchAppLanguage('zh-TW'), 'zh-Hant');
      expect(matchAppLanguage('es-419'), 'es');
      expect(matchAppLanguage('de'), isNull);
    });
  });

  group('history', () {
    test('an older reply that waited for a care-team answer', () {
      final m = AgentMessage.fromJson(
        _j(
          '{"id":"h1","role":"assistant","createdAt":"2026-11-20T10:00:00.000Z","parts":[{"type":"step-start"},{"type":"tool-notifyCareteam","toolCallId":"n9","state":"approval-requested","input":{"situation":"urgent"},"approval":{"id":"ap9"}}]}',
        ),
      );
      expect(m.parts.last.toolName, kOldCareteamTool);
      expect(emergencyOf(m)?.situation, 'urgent');
    });
  });

  group('versions', () {
    test('a message from history carries its versions', () {
      final m = AgentMessage.fromJson(
        _j(
          '{"id":"b","role":"user","parts":[{"type":"text","text":"Hi"}],"siblingIds":["a","b","c"]}',
        ),
      );
      expect(m.siblingIds, ['a', 'b', 'c']);
      expect(m.siblingIds.indexOf(m.id), 1);
    });

    test('a message without versions is its only version', () {
      final m = AgentMessage.fromJson(
        _j('{"id":"x","role":"user","parts":[]}'),
      );
      expect(m.siblingIds, ['x']);
    });
  });

  group('answer ratings', () {
    test('a rating may have one score only (saved as soon as it is picked)', () {
      final r = AgentAnswerRating.fromJson(
        _j(
          '{"messageId":"2f1c9a7e-6b1d-4c1e-9a55-0d2b7c1e8f00","usability":4,"safety":null,"comment":""}',
        ),
      );
      expect(r.usability, 4);
      expect(r.safety, isNull);
      expect(r.comment, '');
    });

    test('only saved answers (server ids) can be rated', () {
      expect(isServerMessageId('2f1c9a7e-6b1d-4c1e-9a55-0d2b7c1e8f00'), isTrue);
      expect(isServerMessageId('reply-1732400000000'), isFalse);
    });
  });

  group('texts', () {
    test('Arabic plural of sources', () {
      final ar = AiChatStrings.of('ar');
      expect(ar.sources(1), 'مصدر واحد');
      expect(ar.sources(5), '5 مصادر');
      expect(ar.sources(12), '12 مصدرًا');
    });

    test('unknown language falls back to English', () {
      expect(AiChatStrings.of('xx').send, 'Send');
    });
  });
}
