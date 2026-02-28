import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
  
  // Lesson navigation
  static const int _totalLessons = 50;
  Function(int lessonNumber)? onLessonChanged;
  
  // Getters
  AudioPlayer get player => _player;
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

  double get progress => 
      _duration.inMilliseconds > 0 
          ? _position.inMilliseconds / _duration.inMilliseconds 
          : 0;

  // Lesson navigation getters
  bool get hasNextLesson => _currentLesson < _totalLessons;
  bool get hasPreviousLesson => _currentLesson > 1;
  bool get isFirstTrack => _currentIndex == 0;
  bool get isLastTrack => _currentIndex >= _currentPlaylist.length - 1;
  int get totalLessons => _totalLessons;

  AudioProvider() {
    _initPlayer();
  }

  void _initPlayer() {
    _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
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
    await playCurrentTrack();
  }

  Future<void> playCurrentTrack() async {
    if (_currentPlaylist.isEmpty || _currentIndex < 0 || _currentIndex >= _currentPlaylist.length) {
      return;
    }

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
    // Auto-play next track
    if (_currentIndex < _currentPlaylist.length - 1) {
      _currentIndex++;
      await playCurrentTrack();
    } else {
      // End of lesson - auto go to next lesson
      if (hasNextLesson) {
        await _loadAndPlayNextLesson();
      } else {
        // Last lesson completed - stop
        await _player.seek(Duration.zero);
        await _player.pause();
        notifyListeners();
      }
    }
  }

  Future<void> _loadAndPlayNextLesson() async {
    final nextLesson = _currentLesson + 1;
    final files = await _loadLessonFiles(nextLesson);
    
    if (files.isNotEmpty) {
      _currentPlaylist = files;
      _currentIndex = 0;
      _currentLesson = nextLesson;
      notifyListeners();
      
      // Notify UI about lesson change
      onLessonChanged?.call(nextLesson);
      
      await playCurrentTrack();
    }
  }

  Future<void> _loadAndPlayPreviousLesson() async {
    final prevLesson = _currentLesson - 1;
    final files = await _loadLessonFiles(prevLesson);
    
    if (files.isNotEmpty) {
      _currentPlaylist = files;
      _currentIndex = 0;
      _currentLesson = prevLesson;
      notifyListeners();
      
      // Notify UI about lesson change
      onLessonChanged?.call(prevLesson);
      
      await playCurrentTrack();
    }
  }

  Future<List<AudioFile>> _loadLessonFiles(int lessonNumber) async {
    try {
      List<String> fileNames = [];
      
      // Try loading from asset manifest
      try {
        final manifestJson = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifest = json.decode(manifestJson);
        
        final lessonPath = 'assets/audio/lesson_$lessonNumber';
        
        for (var key in manifest.keys) {
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
      
      // Fallback to predefined files
      if (fileNames.isEmpty) {
        fileNames = [
          'l${lessonNumber}_main.mp3',
          'l${lessonNumber}_q1.mp3',
          'l${lessonNumber}_q2.mp3',
          'l${lessonNumber}_q3.mp3',
          'l${lessonNumber}_q4.mp3',
        ];
      }
      
      // Convert to AudioFile objects
      final files = <AudioFile>[];
      for (var f in fileNames) {
        final audioFile = AudioFile.fromFileName(f, lessonNumber);
        try {
          await rootBundle.load(audioFile.assetPath);
          files.add(audioFile);
        } catch (e) {
          // Skip non-existent files
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
  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  
  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  Future<void> playNext() async {
    if (_currentIndex < _currentPlaylist.length - 1) {
      _currentIndex++;
      await playCurrentTrack();
    } else if (hasNextLesson) {
      await _loadAndPlayNextLesson();
    }
  }

  Future<void> playPrevious() async {
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await playCurrentTrack();
    } else if (hasPreviousLesson) {
      await _loadAndPlayPreviousLesson();
    }
  }

  // Lesson navigation
  Future<void> playNextLesson() async {
    if (hasNextLesson) {
      await _loadAndPlayNextLesson();
    }
  }

  Future<void> playPreviousLesson() async {
    if (hasPreviousLesson) {
      await _loadAndPlayPreviousLesson();
    }
  }

  Future<void> seek(Duration position) async => await _player.seek(position);
  
  Future<void> seekRelative(Duration offset) async {
    final newPosition = _position + offset;
    final clampedPosition = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    await _player.seek(clampedPosition);
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

class LessonProvider extends ChangeNotifier {
  List<Lesson> _lessons = [];
  
  List<Lesson> get lessons => _lessons;

  LessonProvider() {
    loadLessons();
  }

  void loadLessons() {
    _lessons = Lesson.getAllLessons();
    notifyListeners();
  }

  Lesson getLesson(int index) => _lessons[index];
  Lesson getLessonByNumber(int number) => 
      _lessons.firstWhere((l) => l.number == number, orElse: () => _lessons.first);
}
