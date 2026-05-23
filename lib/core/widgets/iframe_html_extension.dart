import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Custom HtmlExtension untuk merender <iframe> YouTube sebagai player inline.
///
/// Pendekatan: tampilkan thumbnail YouTube dulu (tidak ada error),
/// saat user klik → YouTube IFrame API load dan video langsung play.
/// Ini menghilangkan error cover "Watch on YouTube / Error 153" yang muncul
/// karena YouTube show error state sebelum user berinteraksi.
class IframeHtmlExtension extends HtmlExtension {
  const IframeHtmlExtension();

  static const _origin = 'https://agrilit.my.id';

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
      // Tampilkan thumbnail + play button dulu.
      // Saat diklik → IFrame API load → video play langsung (autoplay=1).
      // Tidak ada error "Watch on YouTube" karena player baru dibuat setelah klik.
      _controller.loadHtmlString(
        _buildThumbnailHtml(videoId),
        baseUrl: IframeHtmlExtension._origin,
      );
    } else {
      _controller.loadRequest(Uri.parse(widget.src));
    }
  }

  String? _extractYoutubeId(String url) {
    final regex = RegExp(r'youtube\.com/embed/([a-zA-Z0-9_\-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// HTML dengan thumbnail YouTube + tombol play.
  /// Saat diklik, YouTube IFrame API di-load secara dinamis dan video autoplay.
  String _buildThumbnailHtml(String videoId) => '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }

    /* Cover: thumbnail + tombol play */
    #cover {
      position: relative;
      width: 100%;
      height: 100%;
      cursor: pointer;
      background: #000;
    }
    #thumbnail {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }
    #play-btn {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: 64px;
      height: 64px;
      background: rgba(255, 0, 0, 0.85);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 16px rgba(0,0,0,0.5);
    }
    #play-btn svg {
      width: 28px;
      height: 28px;
      fill: white;
      margin-left: 4px;
    }

    /* Player: tersembunyi sampai diklik */
    #player-wrap {
      position: absolute;
      top: 0; left: 0;
      width: 100%;
      height: 100%;
      display: none;
    }
    #player { width: 100%; height: 100%; }
  </style>
</head>
<body>

  <!-- State awal: thumbnail yang bisa diklik -->
  <div id="cover" onclick="startPlayer()">
    <img id="thumbnail"
         src="https://img.youtube.com/vi/$videoId/hqdefault.jpg"
         onerror="this.src='https://img.youtube.com/vi/$videoId/mqdefault.jpg'" />
    <div id="play-btn">
      <svg viewBox="0 0 24 24"><polygon points="5,3 19,12 5,21"/></svg>
    </div>
  </div>

  <!-- Player YouTube: muncul setelah diklik -->
  <div id="player-wrap">
    <div id="player"></div>
  </div>

  <script>
    var playerLoaded = false;

    function startPlayer() {
      if (playerLoaded) return;
      playerLoaded = true;

      // Sembunyikan thumbnail, tampilkan area player
      document.getElementById('cover').style.display = 'none';
      document.getElementById('player-wrap').style.display = 'block';

      // Load YouTube IFrame API secara dinamis
      var tag = document.createElement('script');
      tag.src = 'https://www.youtube.com/iframe_api';
      document.head.appendChild(tag);
    }

    // Dipanggil otomatis oleh YouTube IFrame API saat siap
    function onYouTubeIframeAPIReady() {
      new YT.Player('player', {
        videoId: '$videoId',
        playerVars: {
          'origin': '${IframeHtmlExtension._origin}',
          'autoplay': 1,
          'playsinline': 1,
          'controls': 1,
          'rel': 0,
          'modestbranding': 1,
          'enablejsapi': 1
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
