import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Custom HtmlExtension untuk merender tag <iframe> sebagai WebView inline.
/// Digunakan untuk embed video YouTube di dalam konten artikel.
/// Hanya aktif di Android/iOS — jangan pakai di web build.
///
/// FIX Error 153: Set User-Agent sebagai Chrome Mobile agar YouTube
/// tidak memblokir embed di Android WebView.
class IframeHtmlExtension extends HtmlExtension {
  const IframeHtmlExtension();

  // User-Agent Chrome Mobile agar YouTube tidak blokir embed
  static const _chromeUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.6099.193 Mobile Safari/537.36';

  @override
  Set<String> get supportedTags => {'iframe'};

  @override
  InlineSpan build(ExtensionContext context) {
    final src = context.attributes['src'];
    if (src == null || src.isEmpty) return const TextSpan(text: '');

    final heightAttr = context.attributes['height'];
    final height = double.tryParse(heightAttr ?? '') ?? 220.0;

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _WebViewIframe(src: src, height: height, userAgent: _chromeUserAgent),
    );
  }
}

class _WebViewIframe extends StatefulWidget {
  final String src;
  final double height;
  final String userAgent;

  const _WebViewIframe({
    required this.src,
    required this.height,
    required this.userAgent,
  });

  @override
  State<_WebViewIframe> createState() => _WebViewIframeState();
}

class _WebViewIframeState extends State<_WebViewIframe> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(widget.userAgent)   // <-- kunci fix error 153
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(widget.src));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 40;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: screenWidth,
          height: widget.height,
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}
