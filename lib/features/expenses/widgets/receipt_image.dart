import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ReceiptImage extends StatelessWidget {
  const ReceiptImage({
    super.key,
    required this.path,
    this.height = 210,
    this.onTap,
  });

  final String path;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Material(
      color: const Color(0xFFEDF1FF),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const _MissingReceipt(),
          ),
        ),
      ),
    ),
  );
}

class _MissingReceipt extends StatelessWidget {
  const _MissingReceipt();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, color: AppColors.muted, size: 36),
        SizedBox(height: 8),
        Text(
          'Receipt image unavailable',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}

Future<void> showReceiptImage(BuildContext context, String path) =>
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const _MissingReceipt(),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: 'Close image',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
