import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/article_provider.dart';

class ArticleDetailScreen extends StatefulWidget {
  final int id;
  const ArticleDetailScreen({super.key, required this.id});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArticleProvider>().fetchArticleDetail(widget.id);
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    setState(() => _ttsReady = true);
  }

  Future<void> _toggleTts(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      // Strip HTML tags untuk TTS
      final plainText = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
      await _tts.speak(plainText);
      setState(() => _isSpeaking = true);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ArticleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }

          final article = provider.selected;
          if (article == null) return const SizedBox();

          return CustomScrollView(
            slivers: [
              // App bar dengan thumbnail
              SliverAppBar(
                expandedHeight: article.thumbnailUrl != null ? 200 : 0,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: article.thumbnailUrl != null
                    ? FlexibleSpaceBar(
                        background: Image.network(
                          article.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.primaryLight),
                        ),
                      )
                    : null,
                actions: [
                  // TTS button
                  if (_ttsReady && article.content != null)
                    IconButton(
                      icon: Icon(_isSpeaking
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined),
                      tooltip: _isSpeaking ? 'Stop' : 'Dengarkan',
                      onPressed: () => _toggleTts(article.content!),
                    ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Offline notice
                      if (provider.isOffline)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.offline_bolt,
                                  size: 16, color: AppColors.warning),
                              SizedBox(width: 8),
                              Text('Membaca dari cache offline',
                                  style: TextStyle(
                                      color: AppColors.warning, fontSize: 12)),
                            ],
                          ),
                        ),

                      // Commodity badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.commodityColor(article.commodity)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${AppConstants.commodityEmoji[article.commodity] ?? '🌱'} ${AppConstants.commodityLabel[article.commodity] ?? article.commodity}  •  ${AppConstants.categoryLabel[article.category] ?? article.category}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.commodityColor(article.commodity),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Author & views
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(article.authorName ?? 'Pakar AgriLit',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(width: 16),
                          const Icon(Icons.remove_red_eye_outlined,
                              size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text('${article.views} views',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 32),

                      // HTML content
                      if (article.content != null)
                        Html(
                          data: article.content!,
                          style: {
                            'body': Style(
                              fontSize: FontSize(15),
                              lineHeight: LineHeight(1.7),
                              color: AppColors.textPrimary,
                            ),
                            'h2': Style(
                              fontSize: FontSize(18),
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                              margin: Margins.only(top: 20, bottom: 8),
                            ),
                            'li': Style(
                              margin: Margins.only(bottom: 6),
                            ),
                            'strong': Style(
                              fontWeight: FontWeight.bold,
                            ),
                          },
                        )
                      else
                        const Text('Konten tidak tersedia.',
                            style: TextStyle(color: AppColors.textSecondary)),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
