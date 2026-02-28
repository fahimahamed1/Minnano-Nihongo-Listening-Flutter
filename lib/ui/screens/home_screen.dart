import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';
import 'lesson_detail_screen.dart';

// Pre-computed colours
const _creditBorder = Color(0x28E91E63);
const _monBorder = Color(0x3CE91E63);
const _headerShadow = Color(0x1EE91E63);
const _badgeShadow = Color(0x50E91E63);
const _cardShadow = Color(0x0A000000);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Lessons computed once at class level (const list in model, no work here)
  static final List<Lesson> _lessons = Lesson.getAllLessons();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: SizedBox.expand(
                child: SafeArea(
                  child: Column(
                    children: [
                      _HomeHeader(),
                      Expanded(child: _LessonList(lessons: _lessons)),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _DeveloperCredit(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: _headerShadow, blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left accent bar
          Container(
            width: 3,
            height: 58,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'みんなの日本語',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Minnano Nihongo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'LISTENING',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  '• 日 • 本 • 語 •',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          // Circular seal badge
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _badgeShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.headphones_rounded,
                color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lesson list — RepaintBoundary keeps it isolated from footer/header repaints
// ─────────────────────────────────────────────────────────────────────────────
class _LessonList extends StatelessWidget {
  final List<Lesson> lessons;
  const _LessonList({required this.lessons});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        cacheExtent: 400,
        itemCount: lessons.length,
        itemBuilder: (context, index) =>
            _LessonCard(lesson: lessons[index]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lesson card
// ─────────────────────────────────────────────────────────────────────────────
class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: _cardShadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _navigate(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                _LessonBadge(number: lesson.number),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.formattedTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(lesson.titleJp,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(context, lessonDetailRoute(lesson));
  }
}

class _LessonBadge extends StatelessWidget {
  final int number;
  const _LessonBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(
            color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Developer credit footer
// ─────────────────────────────────────────────────────────────────────────────
class _DeveloperCredit extends StatefulWidget {
  const _DeveloperCredit();

  @override
  State<_DeveloperCredit> createState() => _DeveloperCreditState();
}

class _DeveloperCreditState extends State<_DeveloperCredit> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'v${packageInfo.version}';
      });
    }
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _creditBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              // Japanese mon circle
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _monBorder, width: 1),
                ),
                child: const Center(
                  child: Text('和',
                      style: TextStyle(
                          fontSize: 9,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    const Text('Crafted with ❤️ by ',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textTertiary)),
                    GestureDetector(
                      onTap: () =>
                          _launch('https://www.facebook.com/fahimahamed4'),
                      child: const Text('Fahim Ahamed',
                          style: TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Text(' & ',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textTertiary)),
                    GestureDetector(
                      onTap: () =>
                          _launch('https://www.facebook.com/fahadahamed4'),
                      child: const Text('Fahad Ahamed',
                          style: TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Text(_version,
                  style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
