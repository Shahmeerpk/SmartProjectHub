import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import 'asset_viewer_screen.dart'; // 🔥 NAYA IMPORT: Asset Viewer Screen ke liye

class WorkspaceScreen extends StatefulWidget {
  final ProjectDto project;

  const WorkspaceScreen({super.key, required this.project});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  late TextEditingController _linksController;
  bool _isUploading = false;
  double _currentProgress = 0;

  @override
  void initState() {
    super.initState();
    _linksController = TextEditingController(text: widget.project.projectLinks ?? '');
    _currentProgress = widget.project.progressPercent;
  }

  Future<void> _pickAndUpload(String type) async {
    // Sirf allow ki gayi files pick karne dega
    final allowedExtensions = type == 'video' ? ['mp4', 'mov', 'avi'] : ['obj', 'glb', 'gltf'];
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true, // Yeh Web ke liye zaroori hai
    );

    if (result != null && result.files.first.bytes != null) {
      setState(() => _isUploading = true);
      
      final api = context.read<ApiService>();
      final bytes = result.files.first.bytes!;
      final name = result.files.first.name;

      final url = await api.uploadWorkspaceFile(widget.project.id, bytes, name, type);

      setState(() => _isUploading = false);

      if (url != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type.toUpperCase()} uploaded successfully! \nRefresh to see changes.'), backgroundColor: Colors.green),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveLinks() async {
    final api = context.read<ApiService>();
    final success = await api.updateProjectLinks(widget.project.id, _linksController.text);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Links Saved!'), backgroundColor: Colors.green));
    }
  }

  Future<void> _updateProgress() async {
    final api = context.read<ApiService>();
    // final auth = context.read<AuthService>(); // Agar backend ko userId chahiye ho tou use karein
    
    final success = await api.updateProgress(widget.project.id, _currentProgress);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress Updated!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF0F4F8),
      body: _isUploading 
        ? const Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading heavy file... Please wait!', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📌 Project Title
            Text(widget.project.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
            const SizedBox(height: 8),
            Text('Manage your project assets and progress here.', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 30),

            // 📊 Progress Section
            GlassCard(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Project Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${_currentProgress.toInt()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                  Slider(
                    value: _currentProgress,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _currentProgress = val),
                    onChangeEnd: (val) => _updateProgress(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🔗 Links Section
            GlassCard(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Digital Assets (Links)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Paste your GitHub, Figma, or Drive links here:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _linksController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g., GitHub: https://github.com/...',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saveLinks,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save Links'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🎥 Video & 3D Model Upload Section
            Row(
              children: [
                Expanded(
                  child: _UploadBox(
                    title: '2-Min Pitch',
                    subtitle: 'Upload MP4/MOV',
                    icon: Icons.video_camera_back_rounded,
                    color: const Color(0xFF10B981),
                    isUploaded: widget.project.videoUrl != null,
                    onTap: () => _pickAndUpload('video'),
                    onView: () {
                      final api = context.read<ApiService>();
                      final fullUrl = '${api.baseUrl.replaceAll('/api', '')}${widget.project.videoUrl}';
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AssetViewerScreen(title: 'Pitch Video', url: fullUrl, type: 'video')));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _UploadBox(
                    title: '3D Hardware',
                    subtitle: 'Upload .OBJ/.GLB',
                    icon: Icons.view_in_ar_rounded,
                    color: const Color(0xFFF59E0B),
                    isUploaded: widget.project.model3DUrl != null,
                    onTap: () => _pickAndUpload('3dmodel'),
                    onView: () {
                      final api = context.read<ApiService>();
                      final fullUrl = '${api.baseUrl.replaceAll('/api', '')}${widget.project.model3DUrl}';
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AssetViewerScreen(title: '3D Model', url: fullUrl, type: '3dmodel')));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isUploaded;
  final VoidCallback onTap;
  final VoidCallback? onView; // 🔥 NAYA: View karne ka function

  const _UploadBox({
    required this.title, 
    required this.subtitle, 
    required this.icon, 
    required this.color, 
    required this.isUploaded, 
    required this.onTap,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploaded ? onView : onTap, // Agar uploaded hai tou view karega, warna upload karega
      child: GlassCard(
        color: isUploaded ? color.withValues(alpha: 0.1) : Colors.white,
        border: Border.all(color: isUploaded ? color : Colors.transparent, width: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(isUploaded ? Icons.play_circle_fill_rounded : icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(isUploaded ? 'Tap to View' : subtitle, style: TextStyle(fontSize: 11, color: isUploaded ? color : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}