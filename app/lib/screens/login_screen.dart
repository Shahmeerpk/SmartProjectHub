import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController(); 
  
  bool _isLogin = true;
  bool _obscurePassword = true;
  String? _errorMessage;
  int? _universityId;
  bool _roleStudent = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _rollNoController.dispose(); 
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    
    try {
      final ok = _isLogin
          ? await auth.login(
              _emailController.text.trim(),
              _passwordController.text,
            )
          : await _register(auth);

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
      } else if (_isLogin) {
        setState(() => _errorMessage = 'Invalid email or password.');
      }
    } catch (e) {
      // 🔥 YEH HAI WOH NAYI LINE JO SCREEN PAR ERROR DIKHAYEGI 🔥
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

 Future<bool> _register(AuthService auth) async {
    if (_universityId == null) {
      setState(() => _errorMessage = 'Please select a university.');
      return false;
    }
    
    return auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      role: _roleStudent ? 'Student' : 'Teacher',
      universityId: _universityId!,
      // 🔥 YEH RAHI MASTER STROKE LINE 🔥
      // Agar Teacher hai toh "null" mat bhejo, "TEACHER-PASS" bhej do taake C# khush rahay!
      rollNumber: _roleStudent ? _rollNoController.text.trim() : "TEACHER-PASS", 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF134E4A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Smart Academic\nProject Hub',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage projects • AI duplicate check • Progress tracking',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 48),
                  GlassCard(
                    blur: 16,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _TabChip(
                              label: 'Login',
                              selected: _isLogin,
                              onTap: () => setState(() {
                                _isLogin = true;
                                _errorMessage = null;
                              }),
                            ),
                            const SizedBox(width: 12),
                            _TabChip(
                              label: 'Register',
                              selected: !_isLogin,
                              onTap: () => setState(() {
                                _isLogin = false;
                                _errorMessage = null;
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        GlassTextField(
                          label: 'Email',
                          hint: 'you@university.edu',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your email';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 22,
                          ),
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 20),
                          GlassTextField(
                            label: 'Full name',
                            hint: 'Your name',
                            controller: _nameController,
                            validator: (v) {
                              if (!_isLogin && (v == null || v.isEmpty))
                                return 'Enter your name';
                              return null;
                            },
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _UniversityDropdown(
                            universityId: _universityId,
                            onChanged: (id) => setState(() => _universityId = id),
                          ),
                          const SizedBox(height: 20),
                          _RoleSelector(
                            roleStudent: _roleStudent,
                            onChanged: (v) => setState(() => _roleStudent = v),
                          ),
                          if (_roleStudent) ...[
                            const SizedBox(height: 20),
                            GlassTextField(
                              label: 'Roll Number',
                              hint: 'e.g. K21-1234',
                              controller: _rollNoController,
                              validator: (v) {
                                if (!_isLogin && _roleStudent && (v == null || v.isEmpty))
                                  return 'Enter your roll number';
                                return null;
                              },
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 22,
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 20),
                        GlassTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter password';
                            if (!_isLogin && v.length < 6)
                              return 'At least 6 characters';
                            return null;
                          },
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 22,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white70,
                              size: 22,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppTheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppTheme.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: context.watch<AuthService>().isLoading
                              ? null
                              : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: context.watch<AuthService>().isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1E293B),
                                  ),
                                )
                              : Text(_isLogin ? 'Sign in' : 'Create account'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _UniversityDropdown extends StatelessWidget {
  final int? universityId;
  final ValueChanged<int?> onChanged;

  const _UniversityDropdown({
    required this.universityId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<ApiService>().getUniversities(),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (list.isEmpty && snap.connectionState != ConnectionState.waiting) {
          return GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              'No universities. Add some in the database.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'University',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: EdgeInsets.zero,
              blur: 8,
              color: Colors.white.withValues(alpha: 0.1),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: universityId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Select university',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  items: list.map((u) {
                    final id = u['id'] as int;
                    final name = u['name'] as String? ?? 'University $id';
                    return DropdownMenuItem(
                      value: id,
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final bool roleStudent;
  final ValueChanged<bool> onChanged;

  const _RoleSelector({required this.roleStudent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleChip(
            label: 'Student',
            icon: Icons.school_outlined,
            selected: roleStudent,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleChip(
            label: 'Teacher',
            icon: Icons.badge_outlined,
            selected: !roleStudent,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        blur: 8,
        color: selected
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.06),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.white.withValues(alpha: selected ? 1 : 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: selected ? 1 : 0.8),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}