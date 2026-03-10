import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/neumorphic_card.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ProjectDto> _projects = [];
  List<ProjectDto> _pending = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final auth = context.read<AuthService>();
      final projects = await api.getMyProjects();
      final pending = auth.isTeacher
          ? await api.getPendingProjects()
          : <ProjectDto>[];
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _pending = pending;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load projects. Is the API running?';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final approved = _projects.where((p) => p.isApproved).length;
    final rejected = _projects.where((p) => p.isRejected).length;
    final pending = _projects.where((p) => p.isPending).length;

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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user.role,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                                if (user.universityName != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    user.universityName!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text(
                                'Are you sure you want to sign out?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true && context.mounted) {
                            await auth.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shadowColor: Colors.black26,
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total',
                          value: '${_projects.length}',
                          icon: Icons.folder_special_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Pending',
                          value: '$pending',
                          icon: Icons.schedule_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Approved',
                          value: '$approved',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Rejected',
                          value: '$rejected',
                          icon: Icons.cancel_rounded,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (auth.isTeacher && _pending.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      'Pending review',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (auth.isTeacher && _pending.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      child: _ProjectCard(
                        project: _pending[index],
                        isTeacher: true,
                        onReview: () => _reviewProject(_pending[index]),
                        onRefresh: _load,
                      ),
                    ),
                    childCount: _pending.length,
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    auth.isTeacher ? 'All projects' : 'My projects',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: GlassCard(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_projects.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: NeumorphicCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            auth.isStudent ? 'No projects yet' : 'No projects',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          if (auth.isStudent) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to submit your first project',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final p = _projects[index];
                    if (auth.isTeacher && _pending.any((e) => e.id == p.id))
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      child: _ProjectCard(
                        project: p,
                        isTeacher: auth.isTeacher,
                        onRefresh: _load,
                      ),
                    );
                  }, childCount: _projects.length),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: auth.isStudent
          ? FloatingActionButton.extended(
              onPressed: () => _showSubmitProject(context),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New project'),
            )
          : null,
    );
  }

  Future<void> _showSubmitProject(BuildContext context) async {
    final titleController = TextEditingController();
    final abstractController = TextEditingController();
    final api = context.read<ApiService>();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Submit project', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: abstractController,
                decoration: const InputDecoration(
                  labelText: 'Abstract',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final abstract = abstractController.text.trim();
                        if (title.isEmpty || abstract.isEmpty) return;
                        final project = await api.submitProject(
                          title,
                          abstract,
                        );
                        if (ctx.mounted) Navigator.pop(ctx, project != null);
                        if (ctx.mounted && project == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Submission failed. Possibly duplicate (similarity > 70%).',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (submitted == true) _load();
  }

  Future<void> _reviewProject(ProjectDto project) async {
    final approve = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(project.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approve or reject this project?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              project.abstract,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (approve == null) return;
    if (!mounted) return;
    final api = context.read<ApiService>();
    await api.reviewProject(project.id, approve: approve);
    if (mounted) _load();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectDto project;
  final bool isTeacher;
  final VoidCallback? onReview;
  final VoidCallback? onRefresh;

  const _ProjectCard({
    required this.project,
    required this.isTeacher,
    this.onReview,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppTheme.textSecondary;
    if (project.isApproved) statusColor = const Color(0xFF10B981);
    if (project.isRejected) statusColor = AppTheme.error;
    if (project.isPending) statusColor = const Color(0xFFF59E0B);

    return GlassCard(
      blur: 10,
      color: Colors.white.withValues(alpha: 0.7),
      border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  project.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (project.abstract.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              project.abstract,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                '${project.progressPercent.toStringAsFixed(0)}% progress',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isTeacher && project.isPending && onReview != null)
                TextButton(onPressed: onReview, child: const Text('Review')),
            ],
          ),
        ],
      ),
    );
  }
}
