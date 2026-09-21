import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/settings/app_settings_provider.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.photoPath,
    required this.initialText,
    required this.size,
    required this.fitMode,
  });

  final String? photoPath;
  final String initialText;
  final double size;
  final PersonPhotoFitMode fitMode;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.trim().isNotEmpty;
    final initial = initialText.trim().isNotEmpty
        ? initialText.trim()[0].toUpperCase()
        : '?';

    if (!hasPhoto) {
      return CircleAvatar(
        radius: size / 2,
        child: Text(initial),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.file(
          File(photoPath!),
          fit: fitMode == PersonPhotoFitMode.contain
              ? BoxFit.contain
              : BoxFit.cover,
        ),
      ),
    );
  }
}
