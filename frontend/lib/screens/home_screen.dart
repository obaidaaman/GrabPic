// lib/screens/home_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/space_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import 'landing_screen.dart';
import 'space_screens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root shell with responsive nav (sidebar on desktop, bottom nav on mobile)
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  final _pages = const [
    _SpacesTab(),
    _UploadTab(),
    _ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpaceProvider>().loadSpaces();
    });
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w >= 900;

    if (isDesktop) return _desktopLayout();
    return _mobileLayout();
  }

  Widget _desktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          _SideNav(selected: _idx, onSelect: (i) => setState(() => _idx = i), onLogout: _logout),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: _pages[_idx]),
        ],
      ),
    );
  }

  Widget _mobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderLight),
          ), child: const Icon(Icons.face_retouching_natural, color: AppColors.textPrimary, size: 14)),
          const SizedBox(width: 8),
          const Text('GrabPic AI'),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout, tooltip: 'Log out'),
        ],
      ),
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.textPrimary,
          unselectedItemColor: AppColors.textMuted,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined),       activeIcon: Icon(Icons.folder),        label: 'Spaces'),
            BottomNavigationBarItem(icon: Icon(Icons.cloud_upload_outlined),  activeIcon: Icon(Icons.cloud_upload),  label: 'Upload'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  const _SideNav({required this.selected, required this.onSelect, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Container(
      width: 220,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ), child: const Icon(Icons.face_retouching_natural, color: AppColors.textPrimary, size: 18)),
              const SizedBox(width: 10),
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'GrabPic ', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                TextSpan(text: 'AI', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 16)),
              ])),
            ]),
          ),
          const SizedBox(height: 32),

          // Nav items
          _navItem(0, Icons.folder_rounded, 'My Spaces'),
          _navItem(1, Icons.cloud_upload_rounded, 'Upload Photos'),
          _navItem(2, Icons.person_rounded, 'Profile'),

          const Spacer(),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // User chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.surfaceLight,
                  border: Border.all(color: AppColors.borderLight),
                ), child: const Icon(Icons.person, color: AppColors.textPrimary, size: 16)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  auth.user?.id.substring(0, 8) ?? '…',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textMuted),
            title: const Text('Log out', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            onTap: onLogout,
            dense: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final active = selected == idx;
    return StatefulBuilder(builder: (ctx, set) {
      return MouseRegion(
        child: GestureDetector(
          onTap: () => onSelect(idx),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.surfaceLight : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? AppColors.borderLight : Colors.transparent),
            ),
            child: Row(children: [
              Icon(icon, size: 18, color: active ? AppColors.textPrimary : AppColors.textMuted),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              )),
            ]),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spaces Tab
// ─────────────────────────────────────────────────────────────────────────────

class _SpacesTab extends StatelessWidget {
  const _SpacesTab();

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SpaceProvider>();
    final w  = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Spaces', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text('${sp.spaces.length} space${sp.spaces.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                )),
                Row(children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const JoinSpaceScreen())),
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text('Join'),
                  ),
                  const SizedBox(width: 10),
                  GradientButton(
                    label: 'Create',
                    icon:  Icons.add_rounded,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CreateSpaceScreen())),
                  ),
                ]),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          // Body
          Expanded(
            child: sp.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sp.spaces.isEmpty
                    ? _EmptySpaces(
                        onCreate: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSpaceScreen())),
                        onJoin:   () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinSpaceScreen())),
                      )
                    : _SpaceGrid(spaces: sp.spaces, isWide: w >= 900),
          ),
        ],
      ),
    );
  }
}

class _SpaceGrid extends StatelessWidget {
  final List<Space> spaces;
  final bool        isWide;
  const _SpaceGrid({required this.spaces, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isWide ? 1.4 : 3.5,
      ),
      itemCount: spaces.length,
      itemBuilder: (_, i) => _SpaceCard(space: spaces[i]),
    );
  }
}

class _SpaceCard extends StatefulWidget {
  final Space space;
  const _SpaceCard({required this.space});
  @override
  State<_SpaceCard> createState() => _SpaceCardState();
}
class _SpaceCardState extends State<_SpaceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SpaceDetailScreen(space: widget.space))),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? AppColors.borderLight : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.folder_rounded, color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(height: 12),
              Text(widget.space.name,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                widget.space.createdAt != null
                    ? 'Created ${_fmt(widget.space.createdAt!)}'
                    : 'Active',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const Spacer(),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text('View Gallery', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _EmptySpaces extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _EmptySpaces({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.folder_open_rounded, size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text('No spaces yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Create your first event space or join an existing one.', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
            GradientButton(label: 'Create Space', icon: Icons.add_rounded, onTap: onCreate),
            OutlinedButton.icon(onPressed: onJoin, icon: const Icon(Icons.login_rounded, size: 16), label: const Text('Join Space')),
          ]),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Space Detail Screen
// ─────────────────────────────────────────────────────────────────────────────

class SpaceDetailScreen extends StatefulWidget {
  final Space space;
  const SpaceDetailScreen({super.key, required this.space});
  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  List<UserImage> _images     = [];
  bool            _loading    = true;
  String?         _error;

  @override
  void initState() { super.initState(); _loadImages(); }

  Future<void> _loadImages() async {
    final token = StorageService().getJwtToken();
    if (token == null) return;
    try {
      final imgs = await ApiService().getImages(spaceId: widget.space.id, token: token);
      setState(() { _images = imgs; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.space.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GradientButton(
              label: 'Upload Photos',
              icon:  Icons.cloud_upload_rounded,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => UploadScreen(spaceId: widget.space.id, spaceName: widget.space.name))),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrView(msg: _error!, onRetry: _loadImages)
                : _images.isEmpty
                    ? _EmptyGallery(spaceId: widget.space.id, spaceName: widget.space.name)
                    : _GalleryGrid(images: _images, cols: w >= 900 ? 4 : w >= 600 ? 3 : 2),
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  final List<UserImage> images;
  final int             cols;
  const _GalleryGrid({required this.images, required this.cols});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${images.length} photo${images.length == 1 ? '' : 's'} of you',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text('AI found you in these photos.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: images.length,
            itemBuilder: (_, i) => _ImageTile(img: images[i]),
          ),
        ),
      ],
    );
  }
}

class _ImageTile extends StatefulWidget {
  final UserImage img;
  const _ImageTile({required this.img});
  @override
  State<_ImageTile> createState() => _ImageTileState();
}
class _ImageTileState extends State<_ImageTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _showFull(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hovered ? AppColors.borderLight : AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(fit: StackFit.expand, children: [
              Image.network(widget.img.url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.card,
                      child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted))),
              if (_hovered)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Icon(Icons.zoom_in_rounded, color: AppColors.textPrimary, size: 28),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showFull(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Image.network(widget.img.url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  final String spaceId;
  final String spaceName;
  const _EmptyGallery({required this.spaceId, required this.spaceName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text('No photos found', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text("You haven't appeared in any uploaded photos yet, or photos haven't been processed.",
            style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        GradientButton(label: 'Upload Photos', icon: Icons.cloud_upload_rounded,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => UploadScreen(spaceId: spaceId, spaceName: spaceName)))),
      ]),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Upload Tab / Screen
// ─────────────────────────────────────────────────────────────────────────────

class _UploadTab extends StatelessWidget {
  const _UploadTab();
  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SpaceProvider>();
    if (sp.spaces.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_upload_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No spaces to upload to', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Create or join a space first.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            GradientButton(label: 'Create Space', icon: Icons.add_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSpaceScreen()))),
          ]),
        ),
      );
    }
    // Prompt which space to upload to
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Upload Photos', style: Theme.of(context).textTheme.headlineLarge),
          ),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: sp.spaces.length,
              itemBuilder: (_, i) {
                final s = sp.spaces[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(width: 40, height: 40, decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ), child: const Icon(Icons.folder_rounded, color: AppColors.textPrimary, size: 20)),
                    title: Text(s.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tap to upload photos to this space', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.cloud_upload_rounded, color: AppColors.textMuted),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => UploadScreen(spaceId: s.id, spaceName: s.name))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UploadScreen extends StatefulWidget {
  final String spaceId;
  final String spaceName;
  const UploadScreen({super.key, required this.spaceId, required this.spaceName});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _picker    = ImagePicker();
  final _api       = ApiService();
  final _storage   = StorageService();

  List<_PickedFile> _picked    = [];
  bool              _uploading = false;
  String?           _error;
  String?           _success;
  int               _progress  = 0;
 String _getContentType(String name) {
  final ext = name.split('.').last.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    default:
      return 'application/octet-stream';
  }
}
  Future<void> _pickFiles() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    final picked = <_PickedFile>[];
    for (final f in files) {
      final bytes = await f.readAsBytes();
      picked.add(_PickedFile(name: f.name, bytes: bytes));
    }
    setState(() { _picked.addAll(picked); _error = null; _success = null; });
  }

  void _remove(int idx) => setState(() => _picked.removeAt(idx));

  Future<void> _upload() async {
    if (_picked.isEmpty) return;
    final token = _storage.getJwtToken();
    if (token == null) { setState(() => _error = 'Not authenticated'); return; }

    setState(() { _uploading = true; _error = null; _success = null; _progress = 0; });

    try {
      // 1. Get presigned URLs
      final names = _picked.map((f) => f.name).toList();
      final resp  = await _api.getPresignedUrls(fileNames: names, spaceId: widget.spaceId, token: token);

      // 2. Upload to GCS
      for (var i = 0; i < resp.urls.length; i++) {
        await _api.uploadToSignedUrl(signedUrl: resp.urls[i].signedUrl, bytes: _picked[i].bytes, contentType: _getContentType(_picked[i].name));
        setState(() => _progress = i + 1);
      }

      // 3. Trigger embedding
      final paths = resp.urls.map((u) => u.storagePath).toList();
      await _api.triggerEmbedding(storagePaths: paths, spaceId: widget.spaceId, token: token);

      setState(() {
        _success  = 'Uploaded ${_picked.length} photos! Face indexing started in the background.';
        _picked   = [];
        _uploading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Upload to ${widget.spaceName}')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drop zone / pick button
                GestureDetector(
                  onTap: _uploading ? null : _pickFiles,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.cloud_upload_rounded, size: 40, color: AppColors.textPrimary),
                      const SizedBox(height: 12),
                      const Text('Click to select photos', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('JPG, PNG • Multiple files supported', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ]),
                  ),
                ),

                if (_picked.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(children: [
                    Text('${_picked.length} file${_picked.length == 1 ? '' : 's'} selected',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _uploading ? null : () => setState(() => _picked.clear()),
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Clear all'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
                    ),
                    itemCount: _picked.length,
                    itemBuilder: (_, i) => Stack(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_picked[i].bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
                      Positioned(top: 4, right: 4,
                          child: GestureDetector(onTap: () => _remove(i),
                              child: Container(padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12)))),
                    ]),
                  ),
                ],

                if (_uploading) ...[
                  const SizedBox(height: 20),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Uploading $_progress / ${_picked.isEmpty ? _progress : _progress + _picked.length - _progress}…',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      backgroundColor: AppColors.border,
                      color: AppColors.textPrimary,
                      value: _picked.isNotEmpty
                          ? _progress / (_progress + _picked.length)
                          : null,
                    ),
                  ]),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ],

                if (_success != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_success!, style: const TextStyle(color: AppColors.success, fontSize: 13))),
                    ]),
                  ),
                ],

                const SizedBox(height: 24),
                GradientButton(
                  label:     _uploading ? 'Uploading…' : 'Upload ${_picked.isNotEmpty ? '(${_picked.length})' : ''}',
                  icon:      Icons.rocket_launch_rounded,
                  isLoading: _uploading,
                  onTap:     _picked.isEmpty || _uploading ? null : _upload,
                  width:     double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickedFile {
  final String    name;
  final Uint8List bytes;
  const _PickedFile({required this.name, required this.bytes});
}


// ─────────────────────────────────────────────────────────────────────────────
// Profile Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Avatar - Monochromatic
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceLight,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(Icons.face_retouching_natural, color: AppColors.textPrimary, size: 48),
                ),
                const SizedBox(height: 20),
                Text('Face ID User', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'ID: ${user?.id.substring(0, 16) ?? '…'}…',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.success.withOpacity(0.4)),
                  ),
                  child: const Text('Verified', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 40),

                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    _ProfileTile(icon: Icons.fingerprint_rounded, label: 'Auth method', value: 'Face Biometric'),
                    const Divider(height: 1, color: AppColors.border),
                    _ProfileTile(icon: Icons.folder_rounded, label: 'Spaces joined',
                        value: '${context.watch<SpaceProvider>().spaces.length}'),
                    const Divider(height: 1, color: AppColors.border),
                    _ProfileTile(icon: Icons.shield_rounded, label: 'JWT token', value: 'Active'),
                  ]),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder: (_) => const LandingScreen()), (_) => false);
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                    label: const Text('Log Out', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────

class _ErrView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrView({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
    ]));
  }
}
