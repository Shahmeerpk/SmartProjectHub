import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    final api = context.read<ApiService>();
    final auth = context.read<AuthService>();

   final newUrl = await api.uploadProfilePicture(pickedFile); // NAYI LINE (.path hata diya)

    if (mounted) {
      setState(() => _isUploading = false);
      if (newUrl != null) {
        auth.updateProfilePicture(newUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload picture.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 🔥 API ka base URL uthao taake DP ka mukammal link ban sakay
    final api = context.read<ApiService>();
    final serverBaseUrl = api.baseUrl.replaceAll('/api', ''); // e.g. http://10.0.2.2:5264
    final fullImageUrl = user.profilePictureUrl != null ? '$serverBaseUrl${user.profilePictureUrl}' : null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4F8), Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // 🖼️ Profile Avatar Section
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : fullImageUrl != null
                              ? Image.network(
                                  fullImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Icon(Icons.person, size: 60, color: AppTheme.textSecondary),
                                )
                              : Icon(Icons.person, size: 60, color: AppTheme.textSecondary),
                    ),
                  ),
                  
                  // Camera Button
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 📝 User Info
              Text(
                user.fullName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryDark, letterSpacing: 1),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 📋 Details Cards
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView(
                    children: [
                      _ProfileDetailRow(icon: Icons.email_outlined, title: 'Email', value: user.email),
                      const SizedBox(height: 16),
                      _ProfileDetailRow(
                        icon: Icons.account_balance_outlined, 
                        title: 'University', 
                        value: user.universityName ?? 'Not Assigned'
                      ),
                      const SizedBox(height: 16),
                      if (user.department != null) ...[
                        _ProfileDetailRow(icon: Icons.domain_outlined, title: 'Department', value: user.department!),
                        const SizedBox(height: 16),
                      ],
                    ],
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

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileDetailRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 10,
      color: Colors.white.withValues(alpha: 0.6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}