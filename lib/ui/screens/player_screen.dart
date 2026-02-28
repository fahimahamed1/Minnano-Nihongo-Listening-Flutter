import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/audio_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pre-computed colour constants (avoids Color allocations in build)
// ─────────────────────────────────────────────────────────────────────────────
const _white10 = Color(0x1AFFFFFF);
const _white15 = Color(0x26FFFFFF);
const _white20 = Color(0x33FFFFFF);
const _white60 = Color(0x99FFFFFF);
const _white80 = Color(0xCCFFFFFF);
const _white08 = Color(0x14FFFFFF);
const _vinylRing1 = Color(0x0CFFFFFF);
const _vinylRing2 = Color(0x12FFFFFF);
const _vinylRing3 = Color(0x18FFFFFF);
const _primaryGlow = Color(0x50E91E63);
const _primaryShadow = Color(0x82E91E63);
const _blackShadow = Color(0x50000000);

// ─────────────────────────────────────────────────────────────────────────────
// Route — Spotify-style bottom-sheet slide-up
// ─────────────────────────────────────────────────────────────────────────────
Route<void> playerRoute() => _PlayerRoute();

class _PlayerRoute extends PageRouteBuilder<void> {
  _PlayerRoute()
      : super(
          pageBuilder: (_, __, ___) => const PlayerScreen(),
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 340),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            // Subtle scale+dim on the page underneath
            final bgScale = Tween<double>(begin: 1.0, end: 0.96).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );
            final bgFade = Tween<double>(begin: 0.0, end: 0.3).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return Stack(
              children: [
                ScaleTransition(
                  scale: bgScale,
                  child: child, // placeholder — actual page is below
                ),
                // Dim overlay on previous route
                FadeTransition(
                  opacity: bgFade,
                  child: const ColoredBox(color: Colors.black),
                ),
                SlideTransition(position: slide, child: child),
              ],
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
// PlayerScreen
// ─────────────────────────────────────────────────────────────────────────────
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  // ── Vinyl spin ─────────────────────────────────────────────────────────────
  late final AnimationController _spinCtrl;
  late final Animation<double> _spinAnim;

  // ── Content stagger entry ──────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double> _coverAnim;
  late final Animation<double> _infoAnim;
  late final Animation<double> _controlsAnim;

  // ── Drag-to-dismiss (ValueNotifier avoids setState on every pixel) ─────────
  final _dragY = ValueNotifier<double>(0);
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    // Vinyl
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _spinAnim = Tween<double>(begin: 0, end: 1).animate(_spinCtrl);

    // Entry stagger
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _coverAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.00, 0.60, curve: Curves.easeOutCubic),
    );
    _infoAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.20, 0.75, curve: Curves.easeOutCubic),
    );
    _controlsAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.38, 1.00, curve: Curves.easeOutCubic),
    );

    // Defer to post-frame so spin + entry don't fight the route animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AudioProvider>().isPlaying) _spinCtrl.repeat();
      _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _entryCtrl.dispose();
    _dragY.dispose();
    super.dispose();
  }

  void _syncSpin(bool isPlaying) {
    if (isPlaying) {
      if (!_spinCtrl.isAnimating) _spinCtrl.repeat();
    } else {
      if (_spinCtrl.isAnimating) _spinCtrl.stop();
    }
  }

  // ── Drag gestures ──────────────────────────────────────────────────────────
  void _onDragUpdate(DragUpdateDetails d) {
    if (d.delta.dy > 0 || _dragY.value > 0) {
      _dragY.value = (_dragY.value + d.delta.dy).clamp(0.0, 280.0);
    }
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dismissing) return;
    if (_dragY.value > 110 || (d.primaryVelocity ?? 0) > 650) {
      _dismissing = true;
      Navigator.of(context).pop();
    } else {
      // Spring back
      final target = _dragY.value;
      const steps = 12;
      for (var i = 1; i <= steps; i++) {
        Future.delayed(Duration(milliseconds: i * 18), () {
          if (mounted) _dragY.value = target * (1 - i / steps);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: ValueListenableBuilder<double>(
        valueListenable: _dragY,
        builder: (_, dy, child) => Transform.translate(
          offset: Offset(0, dy),
          child: child,
        ),
        child: Scaffold(
          body: Consumer<AudioProvider>(
            builder: (context, audio, _) {
              _syncSpin(audio.isPlaying);
              return DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppColors.playerGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Column(
                      children: [
                        _DragHandle(dragNotifier: _dragY),
                        const SizedBox(height: 4),
                        _PlayerAppBar(audio: audio),
                        const Spacer(flex: 2),

                        // Cover — scale + fade in
                        FadeTransition(
                          opacity: _coverAnim,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.80, end: 1.0)
                                .animate(_coverAnim),
                            child: RepaintBoundary(
                              child: _CoverArt(spinAnim: _spinAnim),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Track info — slide up + fade
                        FadeTransition(
                          opacity: _infoAnim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.25),
                              end: Offset.zero,
                            ).animate(_infoAnim),
                            child: _TrackInfo(audio: audio),
                          ),
                        ),

                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: _infoAnim,
                          child: _TrackCounter(audio: audio),
                        ),

                        const SizedBox(height: 18),

                        // Controls — slide up + fade last
                        FadeTransition(
                          opacity: _controlsAnim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.35),
                              end: Offset.zero,
                            ).animate(_controlsAnim),
                            child: Column(
                              children: [
                                _SeekBar(audio: audio),
                                const SizedBox(height: 20),
                                _Controls(audio: audio),
                                const SizedBox(height: 14),
                                _LessonNav(audio: audio),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag handle — reacts to drag value without setState
// ─────────────────────────────────────────────────────────────────────────────
class _DragHandle extends StatelessWidget {
  final ValueNotifier<double> dragNotifier;
  const _DragHandle({required this.dragNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: dragNotifier,
      builder: (_, dy, __) => Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: dy > 20 ? 52 : 36,
          height: 4,
          decoration: BoxDecoration(
            color: dy > 20 ? _white60 : _white20,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerAppBar extends StatelessWidget {
  final AudioProvider audio;
  const _PlayerAppBar({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TapScale(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _white15,
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
              const Text(
                'Now Playing',
                style: TextStyle(
                  color: _white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
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
        const SizedBox(width: 48), // balance
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover art — vinyl disc with static rings (no allocation per frame)
// ─────────────────────────────────────────────────────────────────────────────
class _CoverArt extends StatelessWidget {
  final Animation<double> spinAnim;
  const _CoverArt({required this.spinAnim});

  // Static vinyl rings — built once
  static const _rings = [
    _VinylRing(size: 60, color: _vinylRing1),
    _VinylRing(size: 44, color: _vinylRing2),
    _VinylRing(size: 28, color: _vinylRing3),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: spinAnim,
      builder: (_, child) => Transform.rotate(
        angle: spinAnim.value * 2 * math.pi,
        child: child,
      ),
      child: Container(
        width: 210,
        height: 210,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(color: _primaryGlow, blurRadius: 50, spreadRadius: 6),
            BoxShadow(
                color: _blackShadow,
                blurRadius: 30,
                offset: Offset(0, 18)),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 162,
          height: 162,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A2E),
            border: Border.all(color: const Color(0x64E91E63), width: 2.5),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ..._rings,
              const Text('🌸', style: TextStyle(fontSize: 46)),
              // Centre spindle dot
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A2E),
                  border: Border.all(
                    color: const Color(0xB4E91E63),
                    width: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VinylRing extends StatelessWidget {
  final double size;
  final Color color;
  const _VinylRing({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Track info
// ─────────────────────────────────────────────────────────────────────────────
class _TrackInfo extends StatelessWidget {
  final AudioProvider audio;
  const _TrackInfo({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          audio.currentAudio?.formattedDisplayName ?? '—',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _white10,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Lesson ${audio.currentLesson} of ${AudioProvider.totalLessons}',
            style: const TextStyle(color: _white60, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Track counter
// ─────────────────────────────────────────────────────────────────────────────
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
          style: const TextStyle(color: _white60, fontSize: 11),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: _white20,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '${audio.currentPlaylist.length} total',
          style: const TextStyle(color: _white60, fontSize: 11),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seek bar — Selector so position updates only rebuild this widget
// ─────────────────────────────────────────────────────────────────────────────
class _SeekBar extends StatelessWidget {
  final AudioProvider audio;
  const _SeekBar({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Selector<AudioProvider, (Duration, Duration)>(
      selector: (_, a) => (a.position, a.duration),
      builder: (_, data, __) {
        final (pos, dur) = data;
        final maxMs = dur.inMilliseconds.toDouble().clamp(1.0, double.infinity);
        final curMs =
            pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble();

        return Column(
          children: [
            SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: _white20,
                thumbColor: Colors.white,
                overlayColor: _primaryGlow,
              ),
              child: Slider(
                value: curMs,
                max: maxMs,
                onChanged: (v) =>
                    audio.seek(Duration(milliseconds: v.round())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(pos),
                      style: const TextStyle(
                          color: _white60, fontSize: 11)),
                  Text(formatDuration(dur),
                      style: const TextStyle(
                          color: _white60, fontSize: 11)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controls
// ─────────────────────────────────────────────────────────────────────────────
class _Controls extends StatelessWidget {
  final AudioProvider audio;
  const _Controls({required this.audio});

  @override
  Widget build(BuildContext context) {
    final canPrev = !audio.isFirstTrack || audio.hasPreviousLesson;
    final canNext = !audio.isLastTrack || audio.hasNextLesson;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IconBtn(
          icon: Icons.replay_10_rounded,
          size: 22,
          onTap: () {
            HapticFeedback.lightImpact();
            audio.seekRelative(const Duration(seconds: -10));
          },
        ),
        const SizedBox(width: 10),
        _IconBtn(
          icon: Icons.skip_previous_rounded,
          size: 28,
          onTap: canPrev
              ? () {
                  HapticFeedback.lightImpact();
                  audio.playPrevious();
                }
              : null,
        ),
        const SizedBox(width: 10),
        _PlayPauseBtn(audio: audio),
        const SizedBox(width: 10),
        _IconBtn(
          icon: Icons.skip_next_rounded,
          size: 28,
          onTap: canNext
              ? () {
                  HapticFeedback.lightImpact();
                  audio.playNext();
                }
              : null,
        ),
        const SizedBox(width: 10),
        _IconBtn(
          icon: Icons.forward_10_rounded,
          size: 22,
          onTap: () {
            HapticFeedback.lightImpact();
            audio.seekRelative(const Duration(seconds: 10));
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play / Pause button with animated icon swap
// ─────────────────────────────────────────────────────────────────────────────
class _PlayPauseBtn extends StatelessWidget {
  final AudioProvider audio;
  const _PlayPauseBtn({required this.audio});

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      scale: 0.91,
      onTap: () {
        HapticFeedback.mediumImpact();
        audio.togglePlayPause();
      },
      child: Container(
        width: 68,
        height: 68,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: _primaryShadow, blurRadius: 24, spreadRadius: 1),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(audio.isPlaying),
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic icon button with tap-scale and disabled state
// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  const _IconBtn({required this.icon, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      onTap: onTap,
      child: Opacity(
        opacity: onTap != null ? 1.0 : 0.28,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: _white08,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lesson navigation
// ─────────────────────────────────────────────────────────────────────────────
class _LessonNav extends StatelessWidget {
  final AudioProvider audio;
  const _LessonNav({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LessonNavBtn(
          icon: Icons.fast_rewind_rounded,
          label: 'Prev Lesson',
          enabled: audio.hasPreviousLesson,
          onTap: audio.playPreviousLesson,
        ),
        Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            width: 1,
            height: 20,
            color: _white15),
        _LessonNavBtn(
          icon: Icons.fast_forward_rounded,
          label: 'Next Lesson',
          enabled: audio.hasNextLesson,
          onTap: audio.playNextLesson,
        ),
      ],
    );
  }
}

class _LessonNavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _LessonNavBtn(
      {required this.icon,
      required this.label,
      required this.enabled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.28,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _white80, size: 16),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                  color: _white80,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tap-scale wrapper — press shrinks, release springs back
// Uses easeOutBack instead of elasticOut (less overshoot, more professional)
// ─────────────────────────────────────────────────────────────────────────────
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const _TapScale({required this.child, this.onTap, this.scale = 0.88});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _anim = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOutBack, // subtle, professional spring-back
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _ctrl.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _anim, child: widget.child),
    );
  }
}
