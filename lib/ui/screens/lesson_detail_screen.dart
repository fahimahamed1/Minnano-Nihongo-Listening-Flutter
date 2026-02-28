import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';
import '../../data/providers/audio_provider.dart';
import 'player_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  List<AudioFile> _audioFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
  }

  Future<void> _loadAudioFiles() async {
    try {
      List<String> fileNames = [];
      
      // Load from asset manifest
      try {
        final manifestJson = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifest = json.decode(manifestJson);
        
        final lessonPath = 'assets/audio/lesson_${widget.lesson.number}';
        
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
      
      // If no files found, use predefined list
      if (fileNames.isEmpty) {
        fileNames = _getPredefinedFiles();
      }
      
      // Convert to AudioFile objects and verify
      final files = <AudioFile>[];
      for (var f in fileNames) {
        final audioFile = AudioFile.fromFileName(f, widget.lesson.number);
        try {
          await rootBundle.load(audioFile.assetPath);
          files.add(audioFile);
        } catch (e) {
          // Skip non-existent files
        }
      }
      
      files.sort(AudioFile.sortAudioFiles);
      
      if (mounted) {
        setState(() {
          _audioFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> _getPredefinedFiles() {
    final lesson = widget.lesson.number;
    return [
      'l${lesson}_main.mp3',
      'l${lesson}_q1.mp3',
      'l${lesson}_q2.mp3',
      'l${lesson}_q3.mp3',
      'l${lesson}_q4.mp3',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCE4EC), Color(0xFFFAFAFA)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading ? _buildLoading() : _buildAudioList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildAudioList() {
    if (_audioFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off_rounded, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('No audio files', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _audioFiles.length,
      itemBuilder: (context, index) {
        return _buildAudioCard(_audioFiles[index], index);
      },
    );
  }

  Widget _buildAudioCard(AudioFile audio, int index) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final isPlaying = audioProvider.currentAudio?.uniqueId == audio.uniqueId &&
            audioProvider.isPlaying;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _playAudio(index),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isPlaying
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isPlaying ? AppColors.primary : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: isPlaying
                            ? const Icon(Icons.pause_rounded, color: Colors.white, size: 24)
                            : Text(audio.emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audio.formattedDisplayName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getAudioDescription(audio.type),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
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

  String _getAudioDescription(AudioType type) {
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

  void _playAudio(int index) {
    HapticFeedback.lightImpact();
    context.read<AudioProvider>().setPlaylist(_audioFiles, index, widget.lesson.number);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerScreen()),
    );
  }
}
