import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happyhearts/l10n/app_localizations.dart';
import 'package:happyhearts/presentation/lesson_detail_screen/widgets/materials_section_widget.dart';
import 'package:happyhearts/services/content_service.dart';

void main() {
  group('LessonAttachment.listFromJson', () {
    test('reads images and PDFs', () {
      final list = LessonAttachment.listFromJson([
        {
          'name': 'Blood pressure chart',
          'url':
              'https://x.supabase.co/storage/v1/object/public/lesson-materials/a.png',
          'kind': 'image',
          'size_bytes': 52000,
        },
        {
          'name': 'Handout',
          'url':
              'https://x.supabase.co/storage/v1/object/public/lesson-materials/b.pdf',
          'kind': 'pdf',
          'size_bytes': 2400000,
        },
      ]);
      expect(list, hasLength(2));
      expect(list[0].isImage, isTrue);
      expect(list[0].sizeBytes, 52000);
      expect(list[1].isPdf, isTrue);
      expect(list[1].name, 'Handout');
    });

    test('skips entries that are not https or of another kind', () {
      final list = LessonAttachment.listFromJson([
        {'name': 'a', 'url': 'http://example.org/a.png', 'kind': 'image'},
        {'name': 'b', 'url': 'https://example.org/b.mp4', 'kind': 'video'},
        'not a map',
        {'url': 'https://example.org/folder/c.pdf', 'kind': 'PDF'},
      ]);
      expect(list, hasLength(1));
      expect(list.single.isPdf, isTrue);
      expect(list.single.name, 'c.pdf'); // falls back to the file name
      expect(list.single.sizeBytes, isNull);
    });

    test('missing or malformed column gives no materials', () {
      expect(LessonAttachment.listFromJson(null), isEmpty);
      expect(LessonAttachment.listFromJson('[]'), isEmpty);
      expect(LessonAttachment.listFromJson(const []), isEmpty);
    });
  });

  test('file sizes', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(MaterialsSectionWidget.fileSize(en, 2400000), '2.3 MB');
    expect(MaterialsSectionWidget.fileSize(en, 52000), '51 KB');
  });
}
