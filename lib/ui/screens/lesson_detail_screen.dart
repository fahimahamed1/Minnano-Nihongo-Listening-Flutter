import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';
import '../../data/providers/audio_provider.dart';
import 'player_screen.dart';

// Smooth fade+slide route for lesson detail (consistent with player route feel)
Route<void> _lessonDetailRoute(Lesson lesson) => PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => LessonDetailScreen(lesson: lesson),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
            opacity: fade, child: SlideTransition(position: slide, child: child));
      },
    );

// Entry point used by home_screen
Route<void> lessonDetailRoute(Lesson lesson) => _lessonDetailRoute(lesson);

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  List<AudioFile> _audioFiles = [];
  bool _isLoading = true;
  String? _error;

  // Stagger controller for list items
  late final AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadAudioFiles();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAudioFiles() async {
    try {
      final files =
          await AudioProvider.loadLessonFiles(widget.lesson.number);
      if (!mounted) return;
      setState(() {
        _audioFiles = files;
        _isLoading = false;
      });
      _listCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load audio files.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            shadowColor: const Color(0x14000000),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded,
                    size: 22, color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.lesson.formattedTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.lesson.titleJp,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 44, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadAudioFiles();
                },
                child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_audioFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off_rounded,
                size: 44, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('No audio files available',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return RepaintBoundary(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        cacheExtent: 500,
        itemCount: _audioFiles.length,
        itemBuilder: (context, index) {
          // Stagger each item's entry
          final itemAnim = CurvedAnimation(
            parent: _listCtrl,
            curve: Interval(
              (index * 0.08).clamp(0.0, 0.7),
              ((index * 0.08) + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          );
          return FadeTransition(
            opacity: itemAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(itemAnim),
              child: _AudioCard(
                audio: _audioFiles[index],
                onTap: () => _playAudio(index),
              ),
            ),
          );
        },
      ),
    );
  }

  void _playAudio(int index) {
    HapticFeedback.lightImpact();
    context.read<AudioProvider>().setPlaylist(
          _audioFiles,
          index,
          widget.lesson.number,
        );
    Navigator.push(context, playerRoute());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Audio card
// ─────────────────────────────────────────────────────────────────────────────
class _AudioCard extends StatelessWidget {
  final AudioFile audio;
  final VoidCallback onTap;
  const _AudioCard({required this.audio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Selector<AudioProvider, bool>(
      selector: (_, p) =>
          p.currentAudio?.uniqueId == audio.uniqueId && p.isPlaying,
      builder: (context, isActive, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(color: AppColors.primary, width: 1.8)
                : null,
            boxShadow: isActive
                ? [
                    const BoxShadow(
                      color: Color(0x20E91E63),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    )
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    )
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: isActive
                            ? const Icon(Icons.equalizer_rounded,
                                key: ValueKey('eq'),
                                color: Colors.white,
                                size: 22)
                            : Text(audio.typeIcon,
                                key: ValueKey('icon'),
                                style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audio.formattedDisplayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            audio.typeDescription,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0x20E91E63)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
