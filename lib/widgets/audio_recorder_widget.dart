import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:bhart/theme/app_theme.dart';

/// Port of AudioRecorder.tsx. `record` handles mic permission + native
/// recording uniformly, so this is simpler than the original's
/// Capacitor-native vs. MediaRecorder-web branching.
///
/// Two real platform differences remain, both handled below:
/// 1. No filesystem on web — `stop()` returns a blob URL instead of a file
///    path (see note on `onAudioRecorded` below).
/// 2. Browsers' MediaRecorder doesn't support AAC — web recording only
///    works with `opus` (or `pcm16bits`), so the encoder + file extension
///    are chosen per-platform.
class AudioRecorderWidget extends StatefulWidget {
  final void Function(String filePath) onAudioRecorded;

  const AudioRecorderWidget({super.key, required this.onAudioRecorded});

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final path = await _buildRecordingPath();
        final config = RecordConfig(encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc);
        await _recorder.start(config, path: path);
        setState(() => _isRecording = true);
      } else {
        // hasPermission() returning false (permission denied) is not an
        // exception, so this used to fall through silently — the user tapped
        // the button and nothing visibly happened.
        _showPermissionError();
      }
    } catch (e) {
      debugPrint('Recording start failed: $e');
      _showPermissionError();
    }
  }

  /// `path_provider` has no web implementation — `getTemporaryDirectory()`
  /// throws a MissingPluginException there. Web doesn't need a real path
  /// since `record` keeps the audio in memory and hands back a blob URL from
  /// `stop()` instead. Extension matches whichever encoder `_startRecording`
  /// picks for the current platform.
  Future<String> _buildRecordingPath() async {
    final ext = kIsWeb ? 'webm' : 'm4a';
    final fileName = 'bhart_voice_edit_${DateTime.now().millisecondsSinceEpoch}.$ext';
    if (kIsWeb) return fileName;
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$fileName';
  }

  void _showPermissionError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microphone access is required to use this feature.')),
    );
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) widget.onAudioRecorded(path);
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 300px was also a fixed-width overflow risk on the narrowest phones
        // (~320-360dp wide) once screen padding is subtracted. Shrink to fit
        // when the available width is tighter than 300, otherwise stay 300.
        final size = constraints.maxWidth < 300 ? constraints.maxWidth : 300.0;
        return Material(
          color: _isRecording ? Colors.red : AppColors.terracotta,
          borderRadius: BorderRadius.circular(48),
          child: InkWell(
            borderRadius: BorderRadius.circular(48),
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isRecording ? Icons.stop : Icons.mic, size: 96, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(_isRecording ? 'रोकें' : 'बोलें',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(_isRecording ? '(Tap to Stop)' : '(Tap to Speak)',
                      style: const TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}