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

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late AnimationController _coverController;
  late Animation<double> _coverAnimation;

  @override
  void initState() {
    super.initState();
    _coverController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _coverAnimation = Tween<double>(begin: 0, end: 1).animate(_coverController);
    
    final audioProvider = context.read<AudioProvider>();
    if (audioProvider.isPlaying) {
      _coverController.repeat();
    }
    
    // Listen for lesson changes
    audioProvider.onLessonChanged = (lessonNumber) {
      HapticFeedback.mediumImpact();
    };
  }

  @override
  void dispose() {
    _coverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          final currentAudio = audioProvider.currentAudio;
          
          // Control animation
          if (audioProvider.isPlaying) {
            if (!_coverController.isAnimating) _coverController.repeat();
          } else {
            if (_coverController.isAnimating) _coverController.stop();
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    _buildAppBar(audioProvider),
                    const Spacer(flex: 2),
                    _buildCoverArt(audioProvider),
                    const SizedBox(height: 32),
                    _buildTrackInfo(currentAudio, audioProvider),
                    const SizedBox(height: 8),
                    _buildTrackProgress(audioProvider),
                    const SizedBox(height: 24),
                    _buildProgressBar(audioProvider),
                    const SizedBox(height: 20),
                    _buildControls(audioProvider),
                    const SizedBox(height: 16),
                    _buildLessonNavigation(audioProvider),
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

  Widget _buildAppBar(AudioProvider audioProvider) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 24),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'Now Playing',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '第${audioProvider.currentLesson}課',
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

  Widget _buildCoverArt(AudioProvider audioProvider) {
    return AnimatedBuilder(
      animation: _coverAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _coverAnimation.value * 2 * 3.14159,
          child: child,
        );
      },
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A2E),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 3,
              ),
            ),
            child: const Center(
              child: Text('🌸', style: TextStyle(fontSize: 44)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(currentAudio, AudioProvider audioProvider) {
    return Column(
      children: [
        Text(
          currentAudio?.formattedDisplayName ?? 'No track',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Lesson ${audioProvider.currentLesson} of ${audioProvider.totalLessons}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackProgress(AudioProvider audioProvider) {
    if (audioProvider.currentPlaylist.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Track ${audioProvider.currentIndex + 1}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '${audioProvider.currentPlaylist.length} total',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AudioProvider audioProvider) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.3),
          ),
          child: Slider(
            value: audioProvider.duration.inMilliseconds > 0
                ? audioProvider.position.inMilliseconds
                    .clamp(0, audioProvider.duration.inMilliseconds)
                    .toDouble()
                : 0,
            max: audioProvider.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
            onChanged: (value) => audioProvider.seek(Duration(milliseconds: value.round())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                audioProvider.formatDuration(audioProvider.position),
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
              Text(
                audioProvider.formatDuration(audioProvider.duration),
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(AudioProvider audioProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.replay_10_rounded,
          size: 22,
          onPressed: () => audioProvider.seekRelative(const Duration(seconds: -10)),
        ),
        const SizedBox(width: 12),
        _buildControlButton(
          icon: Icons.skip_previous_rounded,
          size: 28,
          onPressed: audioProvider.hasPreviousLesson || !audioProvider.isFirstTrack
              ? audioProvider.playPrevious
              : null,
        ),
        const SizedBox(width: 12),
        _buildPlayButton(audioProvider),
        const SizedBox(width: 12),
        _buildControlButton(
          icon: Icons.skip_next_rounded,
          size: 28,
          onPressed: audioProvider.hasNextLesson || !audioProvider.isLastTrack
              ? audioProvider.playNext
              : null,
        ),
        const SizedBox(width: 12),
        _buildControlButton(
          icon: Icons.forward_10_rounded,
          size: 22,
          onPressed: () => audioProvider.seekRelative(const Duration(seconds: 10)),
        ),
      ],
    );
  }

  Widget _buildLessonNavigation(AudioProvider audioProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLessonButton(
            icon: Icons.fast_rewind_rounded,
            label: 'Prev Lesson',
            enabled: audioProvider.hasPreviousLesson,
            onPressed: audioProvider.playPreviousLesson,
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.1),
          ),
          _buildLessonButton(
            icon: Icons.fast_forward_rounded,
            label: 'Next Lesson',
            enabled: audioProvider.hasNextLesson,
            onPressed: audioProvider.playNextLesson,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
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

  Widget _buildPlayButton(AudioProvider audioProvider) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        audioProvider.togglePlayPause();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          audioProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback? onPressed,
  }) {
    return Opacity(
      opacity: onPressed != null ? 1.0 : 0.3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: onPressed != null
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed();
                }
              : null,
          icon: Icon(icon, color: Colors.white, size: size),
          padding: const EdgeInsets.all(10),
        ),
      ),
    );
  }
}
