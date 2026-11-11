import 'package:flutter_test/flutter_test.dart';

import 'package:happyhearts/services/message_language.dart';

void main() {
  group('detectMessageLanguage', () {
    test('fewer than 4 letters are not checked', () {
      expect(detectMessageLanguage(''), isNull);
      expect(detectMessageLanguage('ok'), isNull);
      expect(detectMessageLanguage('Sí!'), isNull);
      expect(detectMessageLanguage('谢谢'), isNull);
      expect(detectMessageLanguage('👍 123 ?!'), isNull);
      expect(detectMessageLanguage('yes'), isNull);
      expect(detectMessageLanguage('help'), 'en');
    });

    test('English', () {
      expect(
        detectMessageLanguage('I have a question about my blood pressure'),
        'en',
      );
      expect(
        detectMessageLanguage('The video in Session 3 will not play'),
        'en',
      );
      expect(detectMessageLanguage('Thanks!'), 'en');
    });

    test('Spanish', () {
      expect(detectMessageLanguage('¿Puedo tomar ibuprofeno?'), 'es');
      expect(detectMessageLanguage('Tengo una pregunta sobre mi bebé'), 'es');
      expect(detectMessageLanguage('necesito ayuda con el video'), 'es');
      expect(detectMessageLanguage('Mañana no puedo'), 'es');
    });

    test('Vietnamese', () {
      expect(detectMessageLanguage('Tôi có câu hỏi về thuốc'), 'vi');
      expect(detectMessageLanguage('Video không phát được'), 'vi');
    });

    test('Korean and Chinese', () {
      expect(detectMessageLanguage('약에 대해 질문이 있어요'), 'ko');
      expect(detectMessageLanguage('我对我的药物有疑问'), 'zh');
      expect(detectMessageLanguage('我對我的藥物有疑問'), 'zh');
      // Mostly Chinese with a few Latin letters.
      expect(detectMessageLanguage('第3节课的video无法播放了'), 'zh');
    });

    test('Farsi and Arabic', () {
      expect(detectMessageLanguage('دربارهٔ داروی خودم سؤال دارم'), 'fa');
      expect(detectMessageLanguage('چطور فشار خونم را اندازه بگیرم'), 'fa');
      expect(detectMessageLanguage('لدي سؤال عن دوائي'), 'ar');
      expect(detectMessageLanguage('فيديو الجلسة الثالثة لا يعمل'), 'ar');
    });

    test('other writing systems are unknown', () {
      expect(detectMessageLanguage('У меня есть вопрос'), unknownLanguage);
      expect(detectMessageLanguage('くすりについてしつもんがあります'), unknownLanguage);
    });
  });

  group('isMessageLanguageAccepted', () {
    test('default list', () {
      const accepted = ['en', 'es'];
      expect(isMessageLanguageAccepted('en', accepted), isTrue);
      expect(isMessageLanguageAccepted('es', accepted), isTrue);
      expect(isMessageLanguageAccepted('vi', accepted), isFalse);
      expect(isMessageLanguageAccepted('zh', accepted), isFalse);
      expect(isMessageLanguageAccepted(unknownLanguage, accepted), isFalse);
    });

    test('either Chinese script accepts any Chinese text', () {
      expect(isMessageLanguageAccepted('zh', ['en', 'zh-Hans']), isTrue);
      expect(isMessageLanguageAccepted('zh', ['zh-Hant']), isTrue);
      expect(isMessageLanguageAccepted('ko', ['zh-Hant']), isFalse);
    });
  });

  test('normalizeAcceptedLanguages keeps known codes in order, once', () {
    const known = {'en', 'es', 'vi', 'ko', 'zh-Hans', 'zh-Hant', 'fa', 'ar'};
    expect(
      normalizeAcceptedLanguages([
        'es',
        'en',
        'es',
        'zh',
        'zh-Hant',
        3,
      ], known: known),
      ['es', 'en', 'zh-Hant'],
    );
    expect(normalizeAcceptedLanguages('en', known: known), isEmpty);
    expect(normalizeAcceptedLanguages(null, known: known), isEmpty);
  });
}
