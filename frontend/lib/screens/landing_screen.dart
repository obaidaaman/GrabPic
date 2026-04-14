// lib/screens/landing_screen.dart
//
// Indie product landing page - Monochromatic theme.

import 'package:flutter/material.dart';
import 'package:grabpic_frontend/screens/space_screens.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/space_provider.dart';
import '../utils/app_theme.dart';
import 'face_auth_screen.dart';
import 'home_screen.dart';


class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {

  // ─── Auth Gate ────────────────────────────────────────────────────────────
  /// If user is authenticated, run [action] immediately.
  /// Otherwise, navigate to FaceAuthScreen first; on success, run [action].
  Future<void> _authGate(VoidCallback action) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      action();
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceAuthScreen(
          title:    'Quick identity check',
          subtitle: 'Take a selfie to continue — no password needed.',
        ),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      // Load spaces then run action
      await context.read<SpaceProvider>().loadSpaces();
      action();
    }
  }

  void _goCreateSpace() {
    _authGate(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateSpaceScreen()),
      ).then((_) {
        if (context.read<AuthProvider>().isAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    });
  }

  void _goJoinSpace() {
    _authGate(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const JoinSpaceScreen()),
      ).then((_) {
        if (context.read<AuthProvider>().isAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    });
  }

  void _goFaceLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaceAuthScreen(
        title:    'Welcome back',
        subtitle: 'Take a selfie to sign in or register automatically.',
        onAuthenticated: () {
          context.read<SpaceProvider>().loadSpaces();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
      )),
    );
  }



  @override
  Widget build(BuildContext context) {
    final size      = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 960;
    final isTablet  = size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
      
          SliverToBoxAdapter(child: _buildNavBar(isDesktop)),

          SliverToBoxAdapter(
            child: isDesktop
                ? _buildHeroDesktop()
                : _buildHeroMobile(),
          ),

         
          SliverToBoxAdapter(child: _buildFeatures(isDesktop)),

          
          SliverToBoxAdapter(child: _buildHowItWorks(isTablet)),

      
          SliverToBoxAdapter(child: _buildBottomCta()),

        
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }


  Widget _buildNavBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Logo
          _Logo(),
          const Spacer(),

          // Nav actions
          if (isDesktop) ...[
            TextButton(
              onPressed: _goJoinSpace,
              child: const Text('Join Space'),
            ),
            const SizedBox(width: 8),
            _NavButton(label: 'Create Space', icon: Icons.add_rounded, onTap: _goCreateSpace),
            const SizedBox(width: 12),
          ],

          // Face login
          GradientButton(label: 'Login', icon: Icons.face_rounded, onTap: _goFaceLogin),

          // Hamburger on mobile
          if (!isDesktop) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'create', child: Text('Create Space')),
                const PopupMenuItem(value: 'join',   child: Text('Join Space')),
              ],
              onSelected: (v) {
                if (v == 'create') _goCreateSpace();
                if (v == 'join')   _goJoinSpace();
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── Hero Desktop ──────────────────────────────────────────────────────────
  Widget _buildHeroDesktop() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _heroText()),
          const SizedBox(width: 80),
          _heroVisual(),
        ],
      ),
    );
  }

  Widget _buildHeroMobile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        children: [
          _heroText(),
          const SizedBox(height: 48),
          _heroVisual(),
        ],
      ),
    );
  }

  Widget _heroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge - Monochromatic
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent)),
              const SizedBox(width: 8),
              Text('AI-Powered Face Recognition', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Headline - Clean white text
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -2, height: 1.1),
            children:  [
              TextSpan(text: 'Your Face.\n'),
              TextSpan(text: 'Your Photos.\n'),
              TextSpan(text: 'Instantly.'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'GrabPic uses face recognition to automatically find every photo you appear in — across events, conferences, weddings and more.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.6),
        ),
        const SizedBox(height: 40),

        // CTA Buttons
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            GradientButton(
              label: 'Create a Space',
              icon:  Icons.add_rounded,
              onTap: _goCreateSpace,
            ),
            OutlinedButton.icon(
              onPressed: _goJoinSpace,
              icon:  const Icon(Icons.login_rounded, size: 18),
              label: const Text('Join a Space'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        Row(
          children: [
            _AvatarStack(),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: AppColors.textSecondary, size: 16))),
                const SizedBox(height: 2),
                Text('Trusted at 200+ events worldwide', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroVisual() {
    return Container(
      width: 380,
      height: 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Grid pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          // Center icon - Monochromatic
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceLight,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(Icons.face_retouching_natural, color: AppColors.textPrimary, size: 56),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.success.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Text('Face Verified', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500, fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 20),
                Text('3 photos found in "Summit 2025"', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          // Floating cards - Monochromatic
          Positioned(
            top: 20, right: -20,
            child: _FloatingCard(icon: Icons.photo_library_rounded, label: '128 Photos'),
          ),
          Positioned(
            bottom: 40, left: -20,
            child: _FloatingCard(icon: Icons.group_rounded, label: '12 Matches'),
          ),
        ],
      ),
    );
  }

  // ── Features ──────────────────────────────────────────────────────────────
  Widget _buildFeatures(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: 80,
      ),
      color: AppColors.surface,
      child: Column(
        children: [
          Text('Everything you need', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Built for event organisers and attendees.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 48),
          _FeatureGrid(isDesktop: isDesktop),
        ],
      ),
    );
  }

  // ── How it works ──────────────────────────────────────────────────────────
  Widget _buildHowItWorks(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : 24, vertical: 80),
      child: Column(
        children: [
          Text(
            'How it works',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 48),
          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Step(n: '01', title: 'Create a Space', desc: 'Organise your event with a unique, password-protected space for photos.', icon: Icons.add_box_rounded)),
                _StepArrow(),
                Expanded(child: _Step(n: '02', title: 'Upload Photos', desc: 'Upload all event photos. Our AI indexes every face automatically.', icon: Icons.cloud_upload_rounded)),
                _StepArrow(),
                Expanded(child: _Step(n: '03', title: 'Take a Selfie', desc: 'Attendees scan their face once to retrieve every photo they appear in.', icon: Icons.face_retouching_natural)),
              ],
            )
          else
            Column(
              children: [
                _Step(n: '01', title: 'Create a Space', desc: 'Organise your event with a unique, password-protected space for photos.', icon: Icons.add_box_rounded),
                const SizedBox(height: 24),
                _Step(n: '02', title: 'Upload Photos', desc: 'Upload all event photos. Our AI indexes every face automatically.', icon: Icons.cloud_upload_rounded),
                const SizedBox(height: 24),
                _Step(n: '03', title: 'Take a Selfie', desc: 'Attendees scan their face once to retrieve every photo they appear in.', icon: Icons.face_retouching_natural),
              ],
            ),
        ],
      ),
    );
  }

  // ── Bottom CTA ────────────────────────────────────────────────────────────
  Widget _buildBottomCta() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text('Ready to get started?', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('No account setup needed. Your face is your identity.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16, runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              GradientButton(label: 'Create a Space', icon: Icons.add_rounded, onTap: _goCreateSpace),
              OutlinedButton.icon(
                onPressed: _goJoinSpace,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Join a Space'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Logo(small: true),
          const Spacer(),
          Text('© 2025 GrabPic AI. All rights reserved.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final bool small;
  const _Logo({this.small = false});

  @override
  Widget build(BuildContext context) {
    final sz = small ? 24.0 : 32.0;
    return Row(
      children: [
        Container(
          width: sz, height: sz,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Icon(Icons.face_retouching_natural, color: AppColors.textPrimary, size: sz * 0.6),
        ),
        const SizedBox(width: 10),
        Text('GrabPic', style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: small ? 14 : 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        )),
        Text(' AI', style: TextStyle(
          fontSize: small ? 14 : 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.textSecondary,
        )),
      ],
    );
  }
}

class _NavButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}
class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hovered ? AppColors.border : Colors.transparent),
          ),
          child: Row(children: [
            Icon(widget.icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(widget.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, height: 32,
      child: Stack(
        children: List.generate(4, (i) => Positioned(
          left: i * 18.0,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: [
                AppColors.surfaceLight,
                AppColors.card,
                AppColors.surface,
                AppColors.surfaceLight,
              ][i],
              border: Border.all(color: AppColors.bg, width: 2),
            ),
            child: const Icon(Icons.person, color: AppColors.textSecondary, size: 14),
          ),
        )),
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FloatingCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final bool isDesktop;
  const _FeatureGrid({required this.isDesktop});

  static const List<Map<String, dynamic>> features = [
    {'icon': Icons.face_retouching_natural, 'title': 'Biometric Login',      'desc': 'Selfie-based authentication — no email or password. Instant & frictionless.',      'color': AppColors.textSecondary},
    {'icon': Icons.folder_special_rounded,  'title': 'Private Spaces',       'desc': 'Each event gets an isolated, password-protected space. Full control for organisers.', 'color': AppColors.textSecondary},
    {'icon': Icons.photo_library_rounded,   'title': 'AI Photo Retrieval',   'desc': 'Upload thousands of photos. Attendees find only theirs in seconds.',                 'color': AppColors.textSecondary},
    {'icon': Icons.cloud_upload_rounded,    'title': 'Bulk Photo Upload',    'desc': 'Upload event galleries in one go. Background AI processing handles the indexing.',    'color': AppColors.textSecondary},
    {'icon': Icons.lock_rounded,            'title': 'Secure by Default',    'desc': 'JWT tokens, signed storage URLs, and role-based access baked in from day one.',      'color': AppColors.textSecondary},
    {'icon': Icons.bolt_rounded,            'title': 'Fast Processing',      'desc': 'Redis-backed job queue ensures face embeddings finish in the background, not blocking your users.',                  'color': AppColors.textSecondary},
  ];

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return GridView.builder(
        shrinkWrap:  true,
        physics:     const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.1,
        ),
        itemCount: features.length,
        itemBuilder: (_, i) => _FeatureCard(f: features[i]),
      );
    }
    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _FeatureCard(f: f),
      )).toList(),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final Map<String, dynamic> f;
  const _FeatureCard({required this.f});
  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}
class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.card : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? AppColors.borderLight : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(widget.f['icon'] as IconData, color: AppColors.textPrimary, size: 22),
            ),
            const SizedBox(height: 16),
            Text(widget.f['title'] as String, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Text(widget.f['desc'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n, title, desc;
  final IconData icon;
  const _Step({required this.n, required this.title, required this.desc, required this.icon});

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
          child: Icon(icon, color: AppColors.textPrimary, size: 30),
        ),
        const SizedBox(height: 16),
        Text(n, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
      ],
    );
  }
}

class _StepArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
    );
  }
}

// Grid background painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.3)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
