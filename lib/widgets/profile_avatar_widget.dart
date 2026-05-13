import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'luxury_form_widgets.dart';

/// Reusable tappable profile avatar.
/// Shows the user's photo if uploaded, otherwise shows initials.
/// Tapping opens a bottom sheet to pick a new photo.
class ProfileAvatarWidget extends StatefulWidget {
  final String name;
  final String uid;
  final double size;

  const ProfileAvatarWidget({
    super.key,
    required this.name,
    required this.uid,
    this.size = 90,
  });

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  bool _uploading = false;

  String get _initials {
    final n = widget.name.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final file = File(picked.path);
      final ext  = picked.path.split('.').last.toLowerCase();

      // Upload to Firebase Storage: profile_pictures/{uid}.jpg
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${widget.uid}.$ext');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      // Save URL to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'photoUrl': url});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo updated'),
            backgroundColor: LuxuryTheme.purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: LuxuryTheme.card,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)),
          border: Border.all(
              color: LuxuryTheme.purple.withAlpha(60)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: LuxuryTheme.purple.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [LuxuryTheme.goldLight, LuxuryTheme.purpleLight],
              ).createShader(b),
              child: const Text('Update Profile Photo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _sheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: () => _pickAndUpload(ImageSource.gallery),
              )),
              const SizedBox(width: 12),
              Expanded(child: _sheetOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: () => _pickAndUpload(ImageSource.camera),
              )),
            ]),
            const SizedBox(height: 12),
            // Remove photo option
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.uid)
                  .snapshots(),
              builder: (ctx, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final hasPhoto = (data?['photoUrl'] as String?)?.isNotEmpty == true;
                if (!hasPhoto) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.uid)
                        .update({'photoUrl': FieldValue.delete()});
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.redAccent.withAlpha(80)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Remove Photo',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: LuxuryTheme.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: LuxuryTheme.purpleLight.withAlpha(80)),
        ),
        child: Column(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: LuxuryTheme.purple.withAlpha(40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: LuxuryTheme.purpleLight, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return GestureDetector(
      onTap: _uploading ? null : _showPickerSheet,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final photoUrl = data?['photoUrl'] as String?;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: s + 20,
                height: s + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    LuxuryTheme.purple.withAlpha(60),
                    Colors.transparent,
                  ]),
                ),
              ),

              // Avatar circle
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: photoUrl == null
                      ? const LinearGradient(
                          colors: [
                            LuxuryTheme.purple,
                            LuxuryTheme.purpleLight
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: photoUrl != null ? LuxuryTheme.card : null,
                  boxShadow: [
                    BoxShadow(
                      color: LuxuryTheme.purple.withAlpha(100),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _uploading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: LuxuryTheme.purpleLight,
                              strokeWidth: 2))
                      : photoUrl != null && photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              width: s,
                              height: s,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                    color: LuxuryTheme.purpleLight,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(_initials,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: s * 0.3,
                                        fontWeight: FontWeight.w800)),
                              ),
                            )
                          : Center(
                              child: Text(_initials,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: s * 0.3,
                                      fontWeight: FontWeight.w800)),
                            ),
                ),
              ),

              // Camera edit badge
              if (!_uploading)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          LuxuryTheme.purple,
                          LuxuryTheme.purpleLight
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: LuxuryTheme.black, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: LuxuryTheme.purple.withAlpha(120),
                            blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 13),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
