import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../models/lesson.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Utility – pure function, no provider dependency
// ─────────────────────────────────────────────────────────────────────────────
String formatDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds.remainder(60);
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Asset-manifest cache (loaded once, shared across the app lifetime)
// ─────────────────────────────────────────────────────────────────────────────
Map<String, dynamic>? _cachedManifest;

Future<Map<String, dynamic>> _getManifest() async {
  if (_cachedManifest != null) return _cachedManifest!;
  try {
    final json = await rootBundle.loadString('AssetManifest.json');
    _cachedManifest = jsonDecode(json) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('AssetManifest load error: $e');
    _cachedManifest = {};
  }
  return _cachedManifest!;
}

// ─────────────────────────────────────────────────────────────────────────────
// AudioProvider
// ─────────────────────────────────────────────────────────────────────────────
class AudioProvider extends ChangeNotifier {
  // Player – lazy-initialised
  late final AudioPlayer _player;
  bool _playerReady = false;

  // Stream subscriptions (cancelled in dispose)
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  // State
  List<AudioFile> _playlist = [];
  int _index = 0;
  int _lesson = 1;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  String? _lastError;

  // Position throttle – only notify UI if position changed by ≥ 500 ms
  Duration _lastNotifiedPosition = Duration.zero;
  static const _posThreshold = Duration(milliseconds: 500);

  static const int totalLessons = 50;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<AudioFile> get currentPlaylist => _playlist;
  int get currentIndex => _index;
  int get currentLesson => _lesson;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  AudioFile? get currentAudio =>
      _playlist.isNotEmpty && _index < _playlist.length
          ? _playlist[_index]
          : null;

  bool get hasNextLesson => _lesson < totalLessons;
  bool get hasPreviousLesson => _lesson > 1;
  bool get isFirstTrack => _index == 0;
  bool get isLastTrack => _index >= _playlist.length - 1;

  // ── Constructor ────────────────────────────────────────────────────────────
  AudioProvider() {
    _initPlayer();
  }

  void _initPlayer() {
    try {
      _player = AudioPlayer();
      _playerReady = true;

      // Position: throttled to avoid 60 Hz full-tree rebuilds
      _posSub = _player.positionStream.listen((pos) {
        _position = pos;
        final delta = pos - _lastNotifiedPosition;
        if (delta.abs() >= _posThreshold || pos == Duration.zero) {
          _lastNotifiedPosition = pos;
          notifyListeners();
        }
      });

      // Duration: notify only on actual change
      _durSub = _player.durationStream.listen((dur) {
        if (dur != null && dur != _duration) {
          _duration = dur;
          notifyListeners();
        }
      });

      // Player state
      _stateSub = _player.playerStateStream.listen((state) {
        final playing = state.playing;
        if (playing != _isPlaying) {
          _isPlaying = playing;
          notifyListeners();
        }
        if (state.processingState == ProcessingState.completed) {
          _onTrackCompleted();
        }
      });
    } catch (e) {
      _lastError = 'Failed to initialise audio player: $e';
      debugPrint(_lastError);
    }
  }

  // ── Playlist management ────────────────────────────────────────────────────
  Future<void> setPlaylist(
      List<AudioFile> files, int startIndex, int lessonNumber) async {
    _playlist = List.from(files);
    _index = startIndex.clamp(0, (files.length - 1).clamp(0, files.length));
    _lesson = lessonNumber;
    // No notifyListeners here — _playCurrentTrack will do it after load
    await _playCurrentTrack();
  }

  Future<void> _playCurrentTrack() async {
    if (!_playerReady ||
        _playlist.isEmpty ||
        _index < 0 ||
        _index >= _playlist.length) return;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final audio = _playlist[_index];
      await _player.setAsset(audio.assetPath);
      _isLoading = false;
      notifyListeners();
      await _player.play();
    } catch (e) {
      _isLoading = false;
      _lastError = 'Could not play track: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  Future<void> _onTrackCompleted() async {
    if (_index < _playlist.length - 1) {
      _index++;
      await _playCurrentTrack();
    } else if (hasNextLesson) {
      await _changeLesson(_lesson + 1);
    } else {
      await _player.seek(Duration.zero);
      await _player.pause();
    }
  }

  Future<void> _changeLesson(int lessonNumber) async {
    final files = await loadLessonFiles(lessonNumber);
    if (files.isNotEmpty) {
      _playlist = files;
      _index = 0;
      _lesson = lessonNumber;
      await _playCurrentTrack();
    }
  }

  // ── Static helpers ─────────────────────────────────────────────────────────

  /// Loads audio files for a lesson using the cached manifest — no per-file
  /// round-trips to rootBundle.
  static Future<List<AudioFile>> loadLessonFiles(int lessonNumber) async {
    try {
      final manifest = await _getManifest();
      final prefix = 'assets/audio/lesson_$lessonNumber/';
      final seen = <String>{};
      final files = <AudioFile>[];

      if (manifest.isNotEmpty) {
        for (final key in manifest.keys) {
          if (key.startsWith(prefix) && key.endsWith('.mp3')) {
            final fileName = key.split('/').last;
            if (seen.add(fileName)) {
              files.add(AudioFile.fromFileName(fileName, lessonNumber));
            }
          }
        }
      }

      // Fallback when manifest is unavailable (e.g., unit tests / simulators)
      if (files.isEmpty) {
        final candidates = [
          'l${lessonNumber}_main.mp3',
          ...List.generate(
              6, (i) => 'l${lessonNumber}_q${i + 1}.mp3'),
        ];
        for (final name in candidates) {
          try {
            await rootBundle.load('$prefix$name');
            files.add(AudioFile.fromFileName(name, lessonNumber));
          } catch (_) {}
        }
      }

      files.sort(AudioFile.sortAudioFiles);
      return files;
    } catch (e) {
      debugPrint('loadLessonFiles error: $e');
      return [];
    }
  }

  // ── Playback controls ──────────────────────────────────────────────────────
  Future<void> togglePlayPause() async {
    if (!_playerReady) return;
    _isPlaying ? await _player.pause() : await _player.play();
  }

  Future<void> playNext() async {
    if (_index < _playlist.length - 1) {
      _index++;
      await _playCurrentTrack();
    } else if (hasNextLesson) {
      await _changeLesson(_lesson + 1);
    }
  }

  Future<void> playPrevious() async {
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_index > 0) {
      _index--;
      await _playCurrentTrack();
    } else if (hasPreviousLesson) {
      await _changeLesson(_lesson - 1);
    }
  }

  Future<void> playNextLesson() async {
    if (hasNextLesson) await _changeLesson(_lesson + 1);
  }

  Future<void> playPreviousLesson() async {
    if (hasPreviousLesson) await _changeLesson(_lesson - 1);
  }

  Future<void> seek(Duration position) async {
    if (!_playerReady) return;
    await _player.seek(position);
  }

  Future<void> seekRelative(Duration offset) async {
    if (!_playerReady) return;
    final newMs =
        (_position + offset).inMilliseconds.clamp(0, _duration.inMilliseconds);
    await _player.seek(Duration(milliseconds: newMs));
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    if (_playerReady) _player.dispose();
    super.dispose();
  }
}
