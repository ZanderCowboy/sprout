
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/settings/application/profile_avatar_service.dart';
import 'package:sprout/features/settings/presentation/widgets/profile_avatar_crop_page.dart';
import 'package:sprout/ui/export.dart';

/// Shows the profile-photo action sheet and runs pick → crop → upload / remove.
Future<void> showProfileAvatarActions(
  BuildContext context, {
  required AuthUser user,
  required ValueChanged<bool> onBusyChanged,
}) async {
  final hasPhoto = user.hasCustomAvatar;
  final choice = await showModalBottomSheet<_AvatarSheetAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text(AppStrings.choosePhoto),
              onTap: () => Navigator.pop(
                sheetContext,
                _AvatarSheetAction.choosePhoto,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text(AppStrings.takePhoto),
              onTap: () =>
                  Navigator.pop(sheetContext, _AvatarSheetAction.takePhoto),
            ),
            if (hasPhoto)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(
                  AppStrings.removePhoto,
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                ),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _AvatarSheetAction.removePhoto,
                ),
              ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text(AppStrings.cancel),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      );
    },
  );

  if (!context.mounted || choice == null) return;

  switch (choice) {
    case _AvatarSheetAction.choosePhoto:
      await _pickCropUpload(
        context,
        source: ImageSource.gallery,
        onBusyChanged: onBusyChanged,
      );
    case _AvatarSheetAction.takePhoto:
      await _pickCropUpload(
        context,
        source: ImageSource.camera,
        onBusyChanged: onBusyChanged,
      );
    case _AvatarSheetAction.removePhoto:
      await _confirmAndRemove(context, onBusyChanged: onBusyChanged);
  }
}

enum _AvatarSheetAction { choosePhoto, takePhoto, removePhoto }

Future<void> _pickCropUpload(
  BuildContext context, {
  required ImageSource source,
  required ValueChanged<bool> onBusyChanged,
}) async {
  final picker = ImagePicker();
  final XFile? picked;
  try {
    picked = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
    );
  } on Object {
    if (!context.mounted) return;
    _showError(context, AppStrings.avatarPermissionDenied);
    return;
  }
  if (picked == null || !context.mounted) return;

  final Uint8List raw;
  try {
    raw = await picked.readAsBytes();
  } on Object {
    if (!context.mounted) return;
    _showError(context, AppStrings.avatarInvalid);
    return;
  }

  if (!context.mounted) return;
  final cropped = await ProfileAvatarCropPage.open(
    context,
    imageBytes: raw,
  );
  if (cropped == null || !context.mounted) return;

  final service = sl<ProfileAvatarService>();
  if (service.isBusy) return;

  onBusyChanged(true);
  try {
    final user = await service.uploadAvatar(cropped);
    if (!context.mounted) return;
    context.read<AuthCubit>().applyUser(user);
  } on AppException catch (e) {
    if (!context.mounted) return;
    _showError(context, e.toFailure().message);
  } on Object catch (e) {
    if (!context.mounted) return;
    _showError(context, e.toString());
  } finally {
    onBusyChanged(false);
  }
}

Future<void> _confirmAndRemove(
  BuildContext context, {
  required ValueChanged<bool> onBusyChanged,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(AppStrings.removePhotoConfirmTitle),
        content: const Text(AppStrings.removePhotoConfirmBody),
        actions: SproutDialogActions.cancelConfirm(
          onCancel: () => Navigator.pop(dialogContext, false),
          onConfirm: () => Navigator.pop(dialogContext, true),
          cancelIdentifier: SemanticsIds.settingsAvatarRemoveDismiss,
          confirmIdentifier: SemanticsIds.settingsAvatarRemoveConfirm,
          confirmLabel: AppStrings.removePhoto,
        ),
      );
    },
  );
  if (confirmed != true || !context.mounted) return;

  final service = sl<ProfileAvatarService>();
  if (service.isBusy) return;

  onBusyChanged(true);
  try {
    final user = await service.removeAvatar();
    if (!context.mounted) return;
    context.read<AuthCubit>().applyUser(user);
  } on AppException catch (e) {
    if (!context.mounted) return;
    _showError(context, e.toFailure().message);
  } on Object catch (e) {
    if (!context.mounted) return;
    _showError(context, e.toString());
  } finally {
    onBusyChanged(false);
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
