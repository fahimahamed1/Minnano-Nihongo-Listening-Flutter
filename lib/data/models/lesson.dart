import 'package:flutter/foundation.dart';

class Lesson {
  final int number;
  final String titleJp;
  final String titleEn;

  const Lesson({
    required this.number,
    required this.titleJp,
    required this.titleEn,
  });

  String get formattedTitle => '第$number課';

  static List<Lesson> getAllLessons() {
    return const [
      Lesson(number: 1, titleJp: 'はじめまして', titleEn: 'Nice to meet you'),
      Lesson(number: 2, titleJp: 'これは何ですか', titleEn: 'What is this?'),
      Lesson(number: 3, titleJp: 'ここはデパートです', titleEn: 'This is a department store'),
      Lesson(number: 4, titleJp: '今何時ですか', titleEn: 'What time is it?'),
      Lesson(number: 5, titleJp: '甲子園へ行きますか', titleEn: 'Do you go to Koshien?'),
      Lesson(number: 6, titleJp: 'いっしょに行きませんか', titleEn: "Won't you go together?"),
      Lesson(number: 7, titleJp: 'いらっしゃいませ', titleEn: 'Welcome'),
      Lesson(number: 8, titleJp: 'そろそろ失礼します', titleEn: 'I should be leaving'),
      Lesson(number: 9, titleJp: '残念ですが', titleEn: 'Unfortunately...'),
      Lesson(number: 10, titleJp: 'あります', titleEn: 'There is/are'),
      Lesson(number: 11, titleJp: 'いくつありますか', titleEn: 'How many are there?'),
      Lesson(number: 12, titleJp: 'お祭りはどうでしたか', titleEn: 'How was the festival?'),
      Lesson(number: 13, titleJp: '別々にお願いします', titleEn: 'Separately please'),
      Lesson(number: 14, titleJp: 'みどり町までお願いします', titleEn: 'To Midori town please'),
      Lesson(number: 15, titleJp: 'ご家族は', titleEn: 'Your family?'),
      Lesson(number: 16, titleJp: '使い方を教えてください', titleEn: 'Please teach me how to use'),
      Lesson(number: 17, titleJp: 'どうしましたか', titleEn: 'What happened?'),
      Lesson(number: 18, titleJp: '趣味は何ですか', titleEn: 'What are your hobbies?'),
      Lesson(number: 19, titleJp: 'ダイエットは明日から', titleEn: 'Diet starts tomorrow'),
      Lesson(number: 20, titleJp: '夏休みはどうでしたか', titleEn: 'How was summer vacation?'),
      Lesson(number: 21, titleJp: 'わたしもそう思います', titleEn: 'I think so too'),
      Lesson(number: 22, titleJp: 'どんなアパートがいいですか', titleEn: 'What kind of apartment?'),
      Lesson(number: 23, titleJp: 'どうやって行きますか', titleEn: 'How do you get there?'),
      Lesson(number: 24, titleJp: '手伝ってくれませんか', titleEn: 'Would you help me?'),
      Lesson(number: 25, titleJp: 'いろいろお世話になりました', titleEn: 'Thank you for everything'),
      Lesson(number: 26, titleJp: 'どこかで会ったことが', titleEn: 'Have we met somewhere?'),
      Lesson(number: 27, titleJp: '何でも相談してください', titleEn: 'Please consult me'),
      Lesson(number: 28, titleJp: '最近どうですか', titleEn: 'How are things lately?'),
      Lesson(number: 29, titleJp: '夢がかなう', titleEn: 'Dreams come true'),
      Lesson(number: 30, titleJp: 'せっかくですから', titleEn: "Since we've come this far"),
      Lesson(number: 31, titleJp: 'このごろすごく元気ですね', titleEn: "You're very energetic lately"),
      Lesson(number: 32, titleJp: '味はどうですか', titleEn: "How's the taste?"),
      Lesson(number: 33, titleJp: '何をしているんですか', titleEn: 'What are you doing?'),
      Lesson(number: 34, titleJp: '旅行はいかがでしたか', titleEn: 'How was your trip?'),
      Lesson(number: 35, titleJp: 'とにかく急いで', titleEn: 'Anyway, hurry!'),
      Lesson(number: 36, titleJp: '地震です', titleEn: "It's an earthquake!"),
      Lesson(number: 37, titleJp: 'いつできますか', titleEn: 'When will it be ready?'),
      Lesson(number: 38, titleJp: '直しておいてください', titleEn: 'Please fix it'),
      Lesson(number: 39, titleJp: '残業で遅くなりました', titleEn: 'Late due to overtime'),
      Lesson(number: 40, titleJp: 'サービスはいかがですか', titleEn: 'How about the service?'),
      Lesson(number: 41, titleJp: 'とてもきれいですね', titleEn: "It's very beautiful"),
      Lesson(number: 42, titleJp: 'いただいた荷物', titleEn: 'The package I received'),
      Lesson(number: 43, titleJp: 'お元気で', titleEn: 'Take care'),
      Lesson(number: 44, titleJp: 'ニュースを見ましたか', titleEn: 'Did you watch the news?'),
      Lesson(number: 45, titleJp: 'ぶつかったらどうしますか', titleEn: 'What if we collide?'),
      Lesson(number: 46, titleJp: '来てください', titleEn: 'Please come'),
      Lesson(number: 47, titleJp: '女の人はどなたですか', titleEn: 'Who is the woman?'),
      Lesson(number: 48, titleJp: 'やりがいがあります', titleEn: "It's rewarding"),
      Lesson(number: 49, titleJp: '帰りたいですね', titleEn: 'I want to go home'),
      Lesson(number: 50, titleJp: '心から感謝します', titleEn: 'Grateful from the heart'),
    ];
  }
}

enum AudioType {
  main,
  question,
  practice,
  vocabulary,
  grammar,
  other,
}

@immutable
class AudioFile {
  final String fileName;
  final String displayName;
  final String assetPath;
  final AudioType type;
  final String? questionNumber;
  final int lessonNumber;

  const AudioFile({
    required this.fileName,
    required this.displayName,
    required this.assetPath,
    required this.type,
    required this.lessonNumber,
    this.questionNumber,
  });

  String get formattedDisplayName {
    switch (type) {
      case AudioType.main:
        return '会話 (Kaiwa)';
      case AudioType.question:
        return '問題$questionNumber (Mondai $questionNumber)';
      case AudioType.practice:
        return '練習 (Renshuu)';
      case AudioType.vocabulary:
        return '単語 (Tango)';
      case AudioType.grammar:
        return '文法 (Bunpou)';
      case AudioType.other:
        return displayName.toUpperCase();
    }
  }

  String get typeIcon {
    switch (type) {
      case AudioType.main:
        return '🎵';
      case AudioType.question:
        return '❓';
      case AudioType.practice:
        return '📝';
      case AudioType.vocabulary:
        return '📖';
      case AudioType.grammar:
        return '📚';
      case AudioType.other:
        return '🎶';
    }
  }

  String get typeDescription {
    switch (type) {
      case AudioType.main:
        return 'Main dialogue';
      case AudioType.question:
        return 'Listening question';
      case AudioType.practice:
        return 'Practice';
      case AudioType.vocabulary:
        return 'Vocabulary';
      case AudioType.grammar:
        return 'Grammar';
      case AudioType.other:
        return 'Audio';
    }
  }

  String get uniqueId => 'lesson_${lessonNumber}_$fileName';

  static AudioFile fromFileName(String fileName, int lessonNumber) {
    final assetPath = 'assets/audio/lesson_$lessonNumber/$fileName';
    final displayName = fileName.replaceAll('.mp3', '');

    AudioType type = AudioType.other;
    String? questionNumber;

    if (displayName.contains('main')) {
      type = AudioType.main;
    } else if (displayName.contains('_q')) {
      type = AudioType.question;
      final match = RegExp(r'_q(\d+)').firstMatch(displayName);
      if (match != null) {
        questionNumber = match.group(1);
      }
    } else if (displayName.contains('renshu') || displayName.contains('practice')) {
      type = AudioType.practice;
    } else if (displayName.contains('vocab') || displayName.contains('tango')) {
      type = AudioType.vocabulary;
    } else if (displayName.contains('bunpou') || displayName.contains('grammar')) {
      type = AudioType.grammar;
    }

    return AudioFile(
      fileName: fileName,
      displayName: displayName,
      assetPath: assetPath,
      type: type,
      lessonNumber: lessonNumber,
      questionNumber: questionNumber,
    );
  }

  static int sortAudioFiles(AudioFile a, AudioFile b) {
    if (a.type == AudioType.main && b.type != AudioType.main) return -1;
    if (b.type == AudioType.main && a.type != AudioType.main) return 1;
    if (a.type == AudioType.question && b.type == AudioType.question) {
      final aNum = int.tryParse(a.questionNumber ?? '0') ?? 0;
      final bNum = int.tryParse(b.questionNumber ?? '0') ?? 0;
      return aNum.compareTo(bNum);
    }
    return a.displayName.compareTo(b.displayName);
  }
}
