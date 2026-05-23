import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// Custom HtmlExtension untuk merender tag <img> menggunakan CachedNetworkImage.
/// flutter_html 3.0 tidak mendukung CSS max-width:100%, sehingga gambar
/// dari HTML konten tidak muncul. Extension ini menggantikan rendering default
/// dengan CachedNetworkImage yang selalu full-width dan support error state.
class ImgHtmlExtension extends HtmlExtension {
  const ImgHtmlExtension();

  @override
  Set<String> get supportedTags => {'img'};

  @override
  InlineSpan build(ExtensionContext context) {
    final src = context.attributes['src'];
    final alt = context.attributes['alt'] ?? '';

    if (src == null || src.isEmpty) return TextSpan(text: alt);

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _ArticleImage(src: src, alt: alt),
    );
  }
}

class _ArticleImage extends StatelessWidget {
  final String src;
  final String alt;

  const _ArticleImage({required this.src, required this.alt});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 40;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: src,
          width: screenWidth,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: screenWidth,
            height: 180,
            color: const Color(0xFFE8F5E9),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: screenWidth,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_not_supported_outlined,
                    size: 32, color: Colors.grey),
                if (alt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(alt,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
