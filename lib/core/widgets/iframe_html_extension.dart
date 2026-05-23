import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Custom HtmlExtension untuk merender tag <iframe> YouTube sebagai player inline.
///
/// SOLUSI error 153 "Video player configuration error":
/// YouTube memblokir loading youtube.com/embed/ID langsung di Android WebView.
/// Fix: Generate HTML lokal yang memanggil YouTube IFrame JavaScript API —
/// cara ini yang diizinkan YouTube dan dipakai semua website/app profesional.
class IframeHtmlExtension extends HtmlExtension {
  const IframeHtmlExtension();

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
      child: _YoutubeWebView(src: src, height: height),
    );
  }
}

class _YoutubeWebView extends StatefulWidget {
  final String src;
  final double height;

  const _YoutubeWebView({required this.src, required this.height});

  @override
  State<_YoutubeWebView> createState() => _YoutubeWebViewState();
}

class _YoutubeWebViewState extends State<_YoutubeWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final videoId = _extractYoutubeId(widget.src);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    if (videoId != null) {
      // Muat HTML lokal yang pakai YouTube IFrame JavaScript API
      // YouTube mengizinkan cara ini — tidak di-block seperti direct embed URL
      _controller.loadHtmlString(_buildYoutubeHtml(videoId));
    } else {
      // Bukan YouTube, load URL biasa
      _controller.loadRequest(Uri.parse(widget.src));
    }
  }

  /// Ekstrak video ID dari berbagai format YouTube URL:
  /// - https://www.youtube.com/embed/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID?...
  String? _extractYoutubeId(String url) {
    final regex = RegExp(r'youtube\.com/embed/([a-zA-Z0-9_\-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Generate HTML lokal yang embed video via YouTube IFrame JavaScript API.
  /// Ini cara yang direkomendasikan YouTube — bukan direct URL embed.
  String _buildYoutubeHtml(String videoId) => '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    #player { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="player"></div>
  <script src="https://www.youtube.com/iframe_api"></script>
  <script>
    var player;
    function onYouTubeIframeAPIReady() {
      player = new YT.Player('player', {
        videoId: '$videoId',
        playerVars: {
          'playsinline': 1,
          'controls': 1,
          'rel': 0,
          'modestbranding': 1,
          'fs': 1
        },
        events: {
          'onReady': function(event) {
            // Player siap, tidak autoplay
          }
        }
      });
    }
  </script>
</body>
</html>
''';

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
