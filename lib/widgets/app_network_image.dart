import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? _defaultPlaceholder();
    }

    // 1. Base64 Data URI
    if (imageUrl.startsWith('data:image') || _isLikelyBase64(imageUrl)) {
      try {
        final cleanBase64 = imageUrl.contains(',')
            ? imageUrl.split(',').last
            : imageUrl;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _defaultPlaceholder(),
        );
      } catch (e) {
        return errorWidget ?? _defaultPlaceholder();
      }
    }

    // 2. Local File
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _defaultPlaceholder(),
        );
      }
    }

    // 3. Network URL
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: AppTheme.borderLight,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ?? _defaultPlaceholder(),
    );
  }

  bool _isLikelyBase64(String str) {
    return str.length > 100 && !str.contains(' ') && !str.startsWith('http');
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.borderLight,
      child: const Center(
        child: Icon(
          Icons.apartment_rounded,
          color: AppTheme.textMuted,
          size: 32,
        ),
      ),
    );
  }
}
