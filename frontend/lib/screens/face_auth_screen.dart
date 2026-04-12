// lib/screens/face_auth_screen.dart
//
// Web-safe face-auth page:
//   • "Use Camera"  — ImageSource.camera  (opens device camera on mobile web)
//   • "Upload Photo" — ImageSource.gallery (file picker on desktop web)
//   • Shows preview → Confirm → calls POST /auth/face-auth → JWT saved

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class FaceAuthScreen extends StatefulWidget {
  /// Called after successful authentication.
  /// Returning null means the caller should decide navigation.
  final VoidCallback? onAuthenticated;
  final String        title;
  final String        subtitle;

  const FaceAuthScreen({
    super.key,
    this.onAuthenticated,
    this.title    = 'Verify your identity',
    this.subtitle = 'Take a selfie to continue. No password needed.',
  });

  @override
  State<FaceAuthScreen> createState() => _FaceAuthScreenState();
}

class _FaceAuthScreenState extends State<FaceAuthScreen> {
  final _picker = ImagePicker();

  Uint8List? _previewBytes;
  String     _previewName  = 'selfie.jpg';
  bool       _isProcessing = false;
  String?    _errorMsg;

  // ─── Capture ────────────────────────────────────────────────────────────

  Future<void> _captureCamera() async {
    try {
      final xfile = await _picker.pickImage(
        source:       ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      setState(() { _previewBytes = bytes; _previewName = xfile.name; _errorMsg = null; });
    } catch (e) {
      setState(() => _errorMsg = 'Camera not available. Please upload a photo instead.');
    }
  }

  Future<void> _uploadFile() async {
    try {
      final xfile = await _picker.pickImage(
        source:       ImageSource.gallery,
        imageQuality: 90,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      setState(() { _previewBytes = bytes; _previewName = xfile.name; _errorMsg = null; });
    } catch (e) {
      setState(() => _errorMsg = 'Could not open file picker: $e');
    }
  }

  Future<void> _authenticate() async {
    if (_previewBytes == null) return;
    setState(() { _isProcessing = true; _errorMsg = null; });
    try {
      await context.read<AuthProvider>().authenticateWithFace(_previewBytes!, _previewName);
      if (!mounted) return;
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!();
      } else {
        Navigator.of(context).pop(true); // pop with success result
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _retry() => setState(() { _previewBytes = null; _errorMsg = null; });

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.heroGradient),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('GrabPic AI'),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 32),

                // Preview or capture UI
                if (_previewBytes != null)
                  _buildPreview()
                else
                  _buildCapturePanel(),

                const SizedBox(height: 24),

                // Error
                if (_errorMsg != null) _buildError(),

                const SizedBox(height: 8),

                // Action buttons
                if (_previewBytes != null) ...[
                  GradientButton(
                    label:     _isProcessing ? 'Verifying…' : 'Confirm & Continue',
                    icon:      Icons.check_circle_outline_rounded,
                    isLoading: _isProcessing,
                    onTap:     _isProcessing ? null : _authenticate,
                    width:     double.infinity,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _retry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retake Photo'),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                _buildTip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Gradient circle icon
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: AppColors.heroGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: AppColors.purple.withOpacity(0.4), blurRadius: 24),
            ],
          ),
          child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCapturePanel() {
    return GlassCard(
      child: Column(
        children: [
          // Dashed circle placeholder
          Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
              color: AppColors.bg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline_rounded, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text('No photo yet', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Camera button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _captureCamera,
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: const Text('Open Camera'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 12),

          // Gallery button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _uploadFile,
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: const Text('Upload a Photo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return GlassCard(
      child: Column(
        children: [
          // Photo preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _previewBytes!,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Photo ready',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
          GestureDetector(
            onTap: () => setState(() => _errorMsg = null),
            child: const Icon(Icons.close, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTip() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_outlined, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          'Your biometric data never leaves the secure server.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}