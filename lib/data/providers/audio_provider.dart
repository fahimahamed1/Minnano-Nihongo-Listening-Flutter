import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../models/lesson.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  List<AudioFile> _currentPlaylist = [];
  int _currentIndex = 0;
  int _currentLesson = 1;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  static const int totalLessons = 50;

  // Getters
  List<AudioFile> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  int get currentLesson => _currentLesson;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;

  AudioFile? get currentAudio =>
      _currentPlaylist.isNotEmpty && _currentIndex < _currentPlaylist.length
          ? _currentPlaylist[_currentIndex]
          : null;

  bool get hasNextLesson => _currentLesson < totalLessons;
  bool get hasPreviousLesson => _currentLesson > 1;
  bool get isFirstTrack => _currentIndex == 0;
  bool get isLastTrack => _currentIndex >= _currentPlaylist.length - 1;

  AudioProvider() {
    _initPlayer();
  }

  void _initPlayer() {
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }

  Future<void> setPlaylist(List<AudioFile> files, int startIndex, int lessonNumber) async {
    _currentPlaylist = List.from(files);
    _currentIndex = startIndex.clamp(0, files.length - 1);
    _currentLesson = lessonNumber;
    notifyListeners();
    await _playCurrentTrack();
  }

  Future<void> _playCurrentTrack() async {
    if (_currentPlaylist.isEmpty ||
        _currentIndex < 0 ||
        _currentIndex >= _currentPlaylist.length) return;

    try {
      final audio = _currentPlaylist[_currentIndex];
      await _player.setAsset(audio.assetPath);
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  Future<void> _onTrackCompleted() async {
    if (_currentIndex < _currentPlaylist.length - 1) {
      _currentIndex++;
      await _playCurrentTrack();
    } else if (hasNextLesson) {
      await _changeLesson(_currentLesson + 1);
    } else {
      await _player.seek(Duration.zero);
      await _player.pause();
      notifyListeners();
    }
  }

  Future<void> _changeLesson(int lessonNumber) async {
    final files = await loadLessonFiles(lessonNumber);
    if (files.isNotEmpty) {
      _currentPlaylist = files;
      _currentIndex = 0;
      _currentLesson = lessonNumber;
      notifyListeners();
      await _playCurrentTrack();
    }
  }

  /// Loads and validates audio files for a given lesson number.
  static Future<List<AudioFile>> loadLessonFiles(int lessonNumber) async {
    try {
      final fileNames = <String>[];

      try {
        final manifestJson = await rootBundle.loadString('AssetManifest.json');
        final manifest = json.decode(manifestJson) as Map<String, dynamic>;
        final lessonPath = 'assets/audio/lesson_$lessonNumber';

        for (final key in manifest.keys) {
          if (key.contains(lessonPath) && key.endsWith('.mp3')) {
            final fileName = key.split('/').last;
            if (!fileNames.contains(fileName)) {
              fileNames.add(fileName);
            }
          }
        }
      } catch (e) {
        debugPrint('Could not load asset manifest: $e');
      }

      // Fallback to predefined file names if manifest is empty
      if (fileNames.isEmpty) {
        fileNames.addAll([
          'l${lessonNumber}_main.mp3',
          'l${lessonNumber}_q1.mp3',
          'l${lessonNumber}_q2.mp3',
          'l${lessonNumber}_q3.mp3',
          'l${lessonNumber}_q4.mp3',
        ]);
      }

      final files = <AudioFile>[];
      for (final f in fileNames) {
        final audioFile = AudioFile.fromFileName(f, lessonNumber);
        try {
          await rootBundle.load(audioFile.assetPath);
          files.add(audioFile);
        } catch (_) {
          // Skip non-existent files silently
        }
      }

      files.sort(AudioFile.sortAudioFiles);
      return files;
    } catch (e) {
      debugPrint('Error loading lesson files: $e');
      return [];
    }
  }

  // Playback controls
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> playNext() async {
    if (_currentIndex < _currentPlaylist.length - 1) {
      _currentIndex++;
      await _playCurrentTrack();
    } else if (hasNextLesson) {
      await _changeLesson(_currentLesson + 1);
    }
  }

  Future<void> playPrevious() async {
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await _playCurrentTrack();
    } else if (hasPreviousLesson) {
      await _changeLesson(_currentLesson - 1);
    }
  }

  Future<void> playNextLesson() async {
    if (hasNextLesson) await _changeLesson(_currentLesson + 1);
  }

  Future<void> playPreviousLesson() async {
    if (hasPreviousLesson) await _changeLesson(_currentLesson - 1);
  }

  Future<void> seek(Duration position) async => _player.seek(position);

  Future<void> seekRelative(Duration offset) async {
    final newMs = (_position + offset).inMilliseconds
        .clamp(0, _duration.inMilliseconds);
    await _player.seek(Duration(milliseconds: newMs));
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
