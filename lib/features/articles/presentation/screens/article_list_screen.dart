import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/commodity_chip.dart';
import '../../data/article_provider.dart';
import '../widgets/article_card.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  String? _commodity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(refresh: true));
    _scrollCtrl.addListener(_onScroll);
  }

  void _load({bool refresh = false}) {
    context.read<ArticleProvider>().fetchArticles(
          commodity: _commodity,
          search: _searchCtrl.text.trim(),
          refresh: refresh,
        );
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _load();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📰 Literasi Pertanian',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Search bar
                  TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _load(refresh: true),
                    decoration: InputDecoration(
                      hintText: 'Cari artikel...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _load(refresh: true);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips komoditas
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CommodityChip(
                      label: 'Semua',
                      selected: _commodity == null,
                      onTap: () => setState(() {
                        _commodity = null;
                        _load(refresh: true);
                      }),
                    ),
                    ...AppConstants.commodities.map((c) => CommodityChip(
                          label:
                              '${AppConstants.commodityEmoji[c]} ${AppConstants.commodityLabel[c]}',
                          selected: _commodity == c,
                          color: AppColors.commodityColor(c),
                          onTap: () => setState(() {
                            _commodity = c;
                            _load(refresh: true);
                          }),
                        )),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: Consumer<ArticleProvider>(
                builder: (context, provider, _) {
                  if (provider.isOffline) {
                    return Column(
                      children: [
                        const OfflineBanner(),
                        Expanded(child: _buildList(provider)),
                      ],
                    );
                  }
                  if (provider.isLoading && provider.articles.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null && provider.articles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(provider.error!,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _load(refresh: true),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildList(provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ArticleProvider provider) {
    if (provider.articles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('Tidak ada artikel ditemukan',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchArticles(
        commodity: _commodity,
        search: _searchCtrl.text.trim(),
        refresh: true,
      ),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemCount: provider.articles.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == provider.articles.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final article = provider.articles[i];
          return ArticleCard(
            article: article,
            onTap: () => context.go('/articles/${article.id}'),
          );
        },
      ),
    );
  }
}
