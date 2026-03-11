import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AuctionImageWidget extends StatelessWidget {
  final String? imagePath;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AuctionImageWidget({
    super.key,
    required this.imagePath,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder();
    }

    final isUrl = imagePath!.startsWith('http://') || imagePath!.startsWith('https://');

    Widget imageWidget;
    if (isUrl) {
      imageWidget = CachedNetworkImage(
        imageUrl: imagePath!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
        fadeInDuration: const Duration(milliseconds: 200),
      );
    } else {
      imageWidget = Image.asset(
        imagePath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[600],
        size: width * 0.3,
      ),
    );
  }
}

// Helper function สำหรับ backward compatibility
Widget buildAuctionImage(String? imagePath, {
  double width = 80,
  double height = 80,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
}) {
  return AuctionImageWidget(
    imagePath: imagePath,
    width: width,
    height: height,
    fit: fit,
    borderRadius: borderRadius,
  );
} 