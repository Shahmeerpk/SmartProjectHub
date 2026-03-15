import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../core/theme.dart';

class AssetViewerScreen extends StatefulWidget {
  final String title;
  final String url;
  final String type; // 'video' ya '3dmodel'

  const AssetViewerScreen({
    super.key,
    required this.title,
    required this.url,
    required this.type,
  });

  @override
  State<AssetViewerScreen> createState() => _AssetViewerScreenState();
}

class _AssetViewerScreenState extends State<AssetViewerScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {}); // Video load hone ke baad UI update karein
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
      ),
      backgroundColor: Colors.white, // Viewer ka background dark acha lagta hai
      body: Center(
        child: widget.type == 'video' ? _buildVideoPlayer() : _build3DViewer(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const CircularProgressIndicator(color: AppTheme.primary);
    }
    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_videoController!),
          VideoProgressIndicator(_videoController!, allowScrubbing: true),
          Align(
            alignment: Alignment.center,
            child: IconButton(
              iconSize: 64,
              color: Colors.white.withValues(alpha: 0.7),
              icon: Icon(
                _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              ),
              onPressed: () {
                setState(() {
                  _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                });
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _build3DViewer() {
    return ModelViewer(
      src: widget.url,
      alt: 'A 3D model of the project',
      ar: true,             // Augmented Reality ka button dega
      autoRotate: true,     // Khud ba khud ghoomega
      cameraControls: true, // Ungli se ghumane ki permission
      backgroundColor: Colors.white, // 3D model white background pe clear dikhta hai
    );
  }
}