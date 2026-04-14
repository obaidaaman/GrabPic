// lib/screens/create_space_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/space_provider.dart';
import '../utils/app_theme.dart';
import 'face_auth_screen.dart';
import 'home_screen.dart';

class CreateSpaceScreen extends StatefulWidget {
  const CreateSpaceScreen({super.key});
  @override
  State<CreateSpaceScreen> createState() => _CreateSpaceScreenState();
}

class _CreateSpaceScreenState extends State<CreateSpaceScreen> {
  final _form              = GlobalKey<FormState>();
  final _nameCtrl          = TextEditingController();
  final _passCtrl          = TextEditingController();
  final _confirmCtrl       = TextEditingController();
  bool   _obscure          = true;
  bool   _isLoading        = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  /// If not authed, show face-auth first, then come back here.
  Future<bool> _ensureAuthenticated() async {
    if (context.read<AuthProvider>().isAuthenticated) return true;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FaceAuthScreen(
        title:    'Authenticate to create a space',
        subtitle: 'We need to verify your identity first.',
      )),
    );
    return ok == true;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    final authed = await _ensureAuthenticated();
    if (!authed || !mounted) return;

    setState(() { _isLoading = true; _error = null; });
    try {
      await context.read<SpaceProvider>().createSpace(
        spaceName:     _nameCtrl.text.trim(),
        spacePassword: _passCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Space created!'), backgroundColor: AppColors.success),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('Create Space'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _SpaceFormHeader(
                  icon: Icons.add_box_rounded,
                  color: AppColors.textPrimary,
                  title: 'New Event Space',
                  desc: 'Create a private space for your event. Share the name & password with attendees.',
                ),
                const SizedBox(height: 32),

                if (_error != null) _ErrorBanner(msg: _error!, onDismiss: () => setState(() => _error = null)),

                GlassCard(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(
                          ctrl: _nameCtrl,
                          label: 'Space Name',
                          hint: 'e.g. Tech Summit 2025',
                          icon: Icons.folder_rounded,
                          validator: (v) => v == null || v.trim().length < 3 ? 'At least 3 characters' : null,
                        ),
                        const SizedBox(height: 16),
                        _field(
                          ctrl: _passCtrl,
                          label: 'Space Password',
                          hint: 'Choose a strong password',
                          icon: Icons.lock_rounded,
                          obscure: _obscure,
                          suffix: _eyeIcon(),
                          validator: (v) => v == null || v.length < 4 ? 'At least 4 characters' : null,
                        ),
                        const SizedBox(height: 16),
                        _field(
                          ctrl: _confirmCtrl,
                          label: 'Confirm Password',
                          hint: 'Re-enter password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          suffix: _eyeIcon(),
                          validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 28),
                        GradientButton(
                          label:     _isLoading ? 'Creating…' : 'Create Space',
                          icon:      Icons.add_rounded,
                          isLoading: _isLoading,
                          onTap:     _isLoading ? null : _submit,
                          width:     double.infinity,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _InfoTip(text: 'You must authenticate with your face to create a space. This ensures only real people organise events.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:  ctrl,
      obscureText: obscure,
      decoration:  InputDecoration(
        labelText:    label,
        hintText:     hint,
        prefixIcon:   Icon(icon, size: 18),
        suffixIcon:   suffix,
      ),
      validator: validator,
    );
  }

  Widget _eyeIcon() => IconButton(
    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppColors.textMuted),
    onPressed: () => setState(() => _obscure = !_obscure),
  );
}


// ─────────────────────────────────────────────────────────────────────────────
// Join Space Screen
// ─────────────────────────────────────────────────────────────────────────────

class JoinSpaceScreen extends StatefulWidget {
  const JoinSpaceScreen({super.key});
  @override
  State<JoinSpaceScreen> createState() => _JoinSpaceScreenState();
}

class _JoinSpaceScreenState extends State<JoinSpaceScreen> {
  final _form    = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool  _obscure  = true;
  bool  _isLoading = false;
  String? _error;

  @override
  void dispose() { _nameCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<bool> _ensureAuthenticated() async {
    if (context.read<AuthProvider>().isAuthenticated) return true;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FaceAuthScreen(
        title:    'Authenticate to join',
        subtitle: 'Take a selfie to verify your identity before joining.',
      )),
    );
    return ok == true;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final authed = await _ensureAuthenticated();
    if (!authed || !mounted) return;

    setState(() { _isLoading = true; _error = null; });
    try {
      await context.read<SpaceProvider>().joinSpace(
        spaceName:     _nameCtrl.text.trim(),
        spacePassword: _passCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('Join Space'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SpaceFormHeader(
                  icon: Icons.login_rounded,
                  color: AppColors.textPrimary,
                  title: 'Join an Event Space',
                  desc: 'Enter the space name and password given to you by the event organiser.',
                ),
                const SizedBox(height: 32),

                if (_error != null) _ErrorBanner(msg: _error!, onDismiss: () => setState(() => _error = null)),

                GlassCard(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Space Name',
                            hintText: 'e.g. Tech Summit 2025',
                            prefixIcon: Icon(Icons.folder_rounded, size: 18),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Space Password',
                            hintText: 'Password from the organiser',
                            prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppColors.textMuted),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 28),
                        GradientButton(
                          label:     _isLoading ? 'Joining…' : 'Join Space',
                          icon:      Icons.login_rounded,
                          isLoading: _isLoading,
                          onTap:     _isLoading ? null : _submit,
                          width:     double.infinity,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _InfoTip(text: 'You must verify your face before joining. This ensures attendees are real people and only retrieve their own photos.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SpaceFormHeader extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   desc;

  const _SpaceFormHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 32),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(desc, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5), textAlign: TextAlign.center),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.msg, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: AppColors.error, fontSize: 13))),
        GestureDetector(onTap: onDismiss, child: const Icon(Icons.close, color: AppColors.error, size: 16)),
      ]),
    );
  }
}

class _InfoTip extends StatelessWidget {
  final String text;
  const _InfoTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5))),
        ],
      ),
    );
  }
}
