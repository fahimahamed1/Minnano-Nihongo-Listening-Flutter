import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/audio_provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  late final Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _spinAnimation = Tween<double>(begin: 0, end: 1).animate(_spinController);

    if (context.read<AudioProvider>().isPlaying) {
      _spinController.repeat();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _syncAnimation(bool isPlaying) {
    if (isPlaying) {
      if (!_spinController.isAnimating) _spinController.repeat();
    } else {
      if (_spinController.isAnimating) _spinController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AudioProvider>(
        builder: (context, audio, _) {
          _syncAnimation(audio.isPlaying);
          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.playerGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    _PlayerAppBar(audio: audio),
                    const Spacer(flex: 2),
                    _CoverArt(animation: _spinAnimation),
                    const SizedBox(height: 32),
                    _TrackInfo(audio: audio),
                    const SizedBox(height: 8),
                    _TrackCounter(audio: audio),
                    const SizedBox(height: 20),
                    _SeekBar(audio: audio),
                    const SizedBox(height: 20),
                    _Controls(audio: audio),
                    const SizedBox(height: 16),
                    _LessonNav(audio: audio),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerAppBar extends StatelessWidget {
  final AudioProvider audio;
  const _PlayerAppBar({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'Now Playing',
                style: TextStyle(
                  color: Colors.white.withAlpha(153),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '第${audio.currentLesson}課',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _CoverArt extends StatelessWidget {
  final Animation<double> animation;
  const _CoverArt({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Transform.rotate(
        angle: animation.value * 2 * 3.14159,
        child: child,
      ),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(102),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A2E),
            border: Border.all(
              color: AppColors.primary.withAlpha(128),
              width: 3,
            ),
          ),
          alignment: Alignment.center,
          child: const Text('🌸', style: TextStyle(fontSize: 44)),
        ),
      ),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  final AudioProvider audio;
  const _TrackInfo({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          audio.currentAudio?.formattedDisplayName ?? 'No track',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Lesson ${audio.currentLesson} of ${AudioProvider.totalLessons}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _TrackCounter extends StatelessWidget {
  final AudioProvider audio;
  const _TrackCounter({required this.audio});

  @override
  Widget build(BuildContext context) {
    if (audio.currentPlaylist.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Track ${audio.currentIndex + 1}',
          style: TextStyle(
            color: Colors.white.withAlpha(128),
            fontSize: 11,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(76),
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '${audio.currentPlaylist.length} total',
          style: TextStyle(
            color: Colors.white.withAlpha(128),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SeekBar extends StatelessWidget {
  final AudioProvider audio;
  const _SeekBar({required this.audio});

  @override
  Widget build(BuildContext context) {
    final maxMs = audio.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);
    final currentMs = audio.position.inMilliseconds
        .clamp(0, audio.duration.inMilliseconds)
        .toDouble();

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white.withAlpha(51),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withAlpha(76),
          ),
          child: Slider(
            value: currentMs,
            max: maxMs,
            onChanged: (v) => audio.seek(Duration(milliseconds: v.round())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                audio.formatDuration(audio.position),
                style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 11),
              ),
              Text(
                audio.formatDuration(audio.duration),
                style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  final AudioProvider audio;
  const _Controls({required this.audio});

  @override
  Widget build(BuildContext context) {
    final canGoPrev = !audio.isFirstTrack || audio.hasPreviousLesson;
    final canGoNext = !audio.isLastTrack || audio.hasNextLesson;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.replay_10_rounded,
          size: 22,
          onPressed: () => audio.seekRelative(const Duration(seconds: -10)),
        ),
        const SizedBox(width: 12),
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          size: 28,
          onPressed: canGoPrev ? audio.playPrevious : null,
        ),
        const SizedBox(width: 12),
        _PlayButton(audio: audio),
        const SizedBox(width: 12),
        _ControlButton(
          icon: Icons.skip_next_rounded,
          size: 28,
          onPressed: canGoNext ? audio.playNext : null,
        ),
        const SizedBox(width: 12),
        _ControlButton(
          icon: Icons.forward_10_rounded,
          size: 22,
          onPressed: () => audio.seekRelative(const Duration(seconds: 10)),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final AudioProvider audio;
  const _PlayButton({required this.audio});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        audio.togglePlayPause();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(128),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed != null ? 1.0 : 0.3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: onPressed != null
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          icon: Icon(icon, color: Colors.white, size: size),
          padding: const EdgeInsets.all(10),
        ),
      ),
    );
  }
}

class _LessonNav extends StatelessWidget {
  final AudioProvider audio;
  const _LessonNav({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LessonNavButton(
            icon: Icons.fast_rewind_rounded,
            label: 'Prev Lesson',
            enabled: audio.hasPreviousLesson,
            onPressed: audio.playPreviousLesson,
          ),
          Container(width: 1, height: 24, color: Colors.white.withAlpha(25)),
          _LessonNavButton(
            icon: Icons.fast_forward_rounded,
            label: 'Next Lesson',
            enabled: audio.hasNextLesson,
            onPressed: audio.playNextLesson,
          ),
        ],
      ),
    );
  }
}

class _LessonNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _LessonNavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
