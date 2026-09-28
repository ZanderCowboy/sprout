import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/ui/export.dart';

/// Full-screen circular crop matching [CircleAvatar].
///
/// Pops with cropped [Uint8List] JPEG/PNG bytes on success, or null on cancel.
class ProfileAvatarCropPage extends StatefulWidget {
  const ProfileAvatarCropPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  static Future<Uint8List?> open(
    BuildContext context, {
    required Uint8List imageBytes,
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ProfileAvatarCropPage(imageBytes: imageBytes),
      ),
    );
  }

  @override
  State<ProfileAvatarCropPage> createState() => _ProfileAvatarCropPageState();
}

class _ProfileAvatarCropPageState extends State<ProfileAvatarCropPage> {
  final _controller = CropController();
  var _cropping = false;

  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.pop(context, croppedImage);
      case CropFailure():
        setState(() => _cropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.avatarInvalid)),
        );
    }
  }

  void _usePhoto() {
    if (_cropping) return;
    setState(() => _cropping = true);
    _controller.cropCircle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cropPhoto),
        leading: SproutIconButton(
          identifier: SemanticsIds.settingsAvatarCropCancel,
          label: AppStrings.cancel,
          onPressed: _cropping ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          SproutTextButton(
            identifier: SemanticsIds.settingsAvatarCropUse,
            label: AppStrings.usePhoto,
            onPressed: _cropping ? null : _usePhoto,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Crop(
            image: widget.imageBytes,
            controller: _controller,
            withCircleUi: true,
            baseColor: Theme.of(context).colorScheme.surface,
            maskColor: Colors.black.withValues(alpha: 0.55),
            onCropped: _onCropped,
            progressIndicator: const Center(child: CircularProgressIndicator()),
          ),
          if (_cropping)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
