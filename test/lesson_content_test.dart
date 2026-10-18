import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riazi_yar/core/content/lesson_content.dart';
import 'package:riazi_yar/core/models/models.dart';

void main() {
  group('اعتبارسنجی قالب محتوای درس', () {
    test('درس نمونه معتبر بارگذاری می‌شود', () {
      const raw = '''
      {
        "id": "test_lesson",
        "title": "درس آزمایشی",
        "description": "توضیح",
        "unit": "شمارش",
        "contentVersion": "1.0.0",
        "kind": "regular",
        "teacherReviewed": false,
        "activities": [
          {
            "id": "t_a1",
            "type": "countAndChoose",
            "instruction": "بشمار",
            "difficulty": 1,
            "questions": [
              {
                "id": "t_q1",
                "prompt": "چند سیب؟",
                "itemShape": "apple",
                "itemCount": 3,
                "options": [
                  {"value": 2, "label": "۲"},
                  {"value": 3, "label": "۳"},
                  {"value": 4, "label": "۴"}
                ],
                "correctAnswer": 3,
                "hints": ["بشمار یکی یکی"],
                "feedbackCorrect": "آفرین",
                "feedbackWrong": "دوباره"
              }
            ]
          }
        ]
      }
      ''';
      final lesson = LessonContentLoader.loadFromJsonString(raw, source: 'test');
      expect(lesson.id, 'test_lesson');
      expect(lesson.activities.length, 1);
      expect(lesson.allQuestions.length, 1);
      expect(lesson.teacherReviewed, false);
      expect(lesson.kind, LessonKind.regular);
    });

    test('JSON خراب → خطای کنترل‌شده', () {
      expect(
        () => LessonContentLoader.loadFromJsonString('{bad json', source: 't'),
        throwsA(isA<ContentFormatException>()),
      );
    });

    test('correctAnswer خارج از گزینه‌ها → خطا', () {
      const raw = '''
      {
        "id": "bad1", "title": "t", "contentVersion": "1.0.0",
        "activities": [{
          "id": "a", "type": "countAndChoose", "instruction": "x", "difficulty": 1,
          "questions": [{
            "id": "q", "prompt": "p", "itemShape": "apple", "itemCount": 3,
            "options": [{"value": 2, "label": "۲"}],
            "correctAnswer": 3, "hints": ["h"]
          }]
        }]
      }
      ''';
      expect(
        () => LessonContentLoader.loadFromJsonString(raw, source: 't'),
        throwsA(isA<ContentFormatException>()),
      );
    });

    test('بدون hint → خطا', () {
      const raw = '''
      {
        "id": "bad2", "title": "t", "contentVersion": "1.0.0",
        "activities": [{
          "id": "a", "type": "countAndChoose", "instruction": "x", "difficulty": 1,
          "questions": [{
            "id": "q", "prompt": "p", "itemShape": "apple", "itemCount": 3,
            "options": [{"value": 3, "label": "۳"}],
            "correctAnswer": 3, "hints": []
          }]
        }]
      }
      ''';
      expect(
        () => LessonContentLoader.loadFromJsonString(raw, source: 't'),
        throwsA(isA<ContentFormatException>()),
      );
    });

    test('مغایرت itemCount با correctAnswer در countAndChoose → خطا', () {
      const raw = '''
      {
        "id": "bad3", "title": "t", "contentVersion": "1.0.0",
        "activities": [{
          "id": "a", "type": "countAndChoose", "instruction": "x", "difficulty": 1,
          "questions": [{
            "id": "q", "prompt": "p", "itemShape": "apple", "itemCount": 5,
            "options": [{"value": 3, "label": "۳"}],
            "correctAnswer": 3, "hints": ["h"]
          }]
        }]
      }
      ''';
      final doc = jsonDecode(raw) as Map<String, dynamic>;
      final result = LessonContentLoader.validate(doc);
      expect(result.ok, false);
      expect(result.errors.join(), contains('countAndChoose'));
    });

    test('matchCount با دو دسته درست → خطا (گزینه تکراری)', () {
      const raw = '''
      {
        "id": "bad4", "title": "t", "contentVersion": "1.0.0",
        "activities": [{
          "id": "a", "type": "matchCount", "instruction": "x", "difficulty": 2,
          "questions": [{
            "id": "q", "prompt": "p", "itemShape": "ball", "itemCount": 2,
            "options": [
              {"value": 2, "label": "الف"},
              {"value": 2, "label": "ب"}
            ],
            "correctAnswer": 2, "hints": ["h"]
          }]
        }]
      }
      ''';
      final doc = jsonDecode(raw) as Map<String, dynamic>;
      final result = LessonContentLoader.validate(doc);
      expect(result.ok, false);
    });

    test('roundtrip JSON → Lesson → JSON → Lesson پایدار است', () {
      const raw = '''
      {
        "id": "rt", "title": "t", "contentVersion": "2.1.0", "kind": "quiz",
        "activities": [{
          "id": "a", "type": "countAndChoose", "instruction": "x", "difficulty": 3,
          "questions": [{
            "id": "q", "prompt": "p", "itemShape": "star", "itemCount": 7,
            "options": [{"value": 6, "label": "۶"}, {"value": 7, "label": "۷"}],
            "correctAnswer": 7, "hints": ["h1", "h2"]
          }]
        }]
      }
      ''';
      final l1 = LessonContentLoader.loadFromJsonString(raw, source: 'a');
      final l2 = LessonContentLoader.loadFromJsonString(
        jsonEncode(l1.toJson()),
        source: 'b',
      );
      expect(l2.id, l1.id);
      expect(l2.contentVersion, '2.1.0');
      expect(l2.kind, LessonKind.quiz);
      expect(l2.allQuestions.first.correctAnswer, 7);
    });

    test('محتوای تعبیه‌شده واقعی پروژه (۳ فایل JSON) معتبر است', () {
      for (final path in LessonContentLoader.bundledLessonAssets) {
        final raw = _readAssetFromDisk(path);
        final lesson = LessonContentLoader.loadFromJsonString(raw, source: path);
        expect(lesson.activities, isNotEmpty, reason: path);
        expect(lesson.contentVersion, isNotEmpty, reason: path);
        // طبق سیاست شفافیت، محتوای نمونه باید برچسب بازبینی داشته باشد
        expect(lesson.teacherReviewed, false, reason: '$path باید نیازمند بازبینی معلم بماند');
      }
    });
  });
}

/// خواندن asset ها مستقیم از دیسک (flutter test از ریشه پروژه اجرا می‌شود).
String _readAssetFromDisk(String assetPath) =>
    File(assetPath).readAsStringSync();
