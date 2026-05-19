import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/commodity_chip.dart';
import '../../data/forum_provider.dart';
import '../../data/forum_models.dart';

class ForumListScreen extends StatefulWidget {
  const ForumListScreen({super.key});

  @override
  State<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends State<ForumListScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  String? _commodity;
  String? _filter; // null | 'unanswered' | 'answered'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(refresh: true));
    _scrollCtrl.addListener(_onScroll);
  }

  void _load({bool refresh = false}) {
    context.read<ForumProvider>().fetchPosts(
          commodity: _commodity,
          filter: _filter,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/forum/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Tanya Pakar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
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
                  const Text('💬 Forum Diskusi',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _load(refresh: true),
                    decoration: InputDecoration(
                      hintText: 'Cari pertanyaan...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _load(refresh: true);
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Status filter
                    CommodityChip(
                      label: 'Semua',
                      selected: _filter == null,
                      onTap: () => setState(() {
                        _filter = null;
                        _load(refresh: true);
                      }),
                    ),
                    CommodityChip(
                      label: '❓ Belum Dijawab',
                      selected: _filter == 'unanswered',
                      color: AppColors.warning,
                      onTap: () => setState(() {
                        _filter = 'unanswered';
                        _load(refresh: true);
                      }),
                    ),
                    CommodityChip(
                      label: '✅ Terjawab',
                      selected: _filter == 'answered',
                      color: AppColors.success,
                      onTap: () => setState(() {
                        _filter = 'answered';
                        _load(refresh: true);
                      }),
                    ),
                    const SizedBox(width: 8),
                    // Divider vertikal
                    Container(
                      height: 24,
                      width: 1,
                      color: AppColors.border,
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    // Komoditas filter
                    ...AppConstants.commodities.map((c) => CommodityChip(
                          label:
                              '${AppConstants.commodityEmoji[c]} ${AppConstants.commodityLabel[c]}',
                          selected: _commodity == c,
                          color: AppColors.commodityColor(c),
                          onTap: () => setState(() {
                            _commodity = _commodity == c ? null : c;
                            _load(refresh: true);
                          }),
                        )),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: Consumer<ForumProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.posts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null && provider.posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off,
                              size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text(provider.error!,
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _load(refresh: true),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (provider.posts.isEmpty) {
                    return const Center(
                      child: Text('Belum ada pertanyaan.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchPosts(
                      commodity: _commodity,
                      filter: _filter,
                      refresh: true,
                    ),
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount:
                          provider.posts.length + (provider.hasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == provider.posts.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _ForumCard(
                          post: provider.posts[i],
                          onTap: () =>
                              context.push('/forum/${provider.posts[i].id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumCard extends StatelessWidget {
  final ForumPostModel post;
  final VoidCallback onTap;
  const _ForumCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final commodityColor = AppColors.commodityColor(post.commodity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: post.isAnswered
              ? AppColors.success.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badges
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: commodityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${AppConstants.commodityEmoji[post.commodity] ?? ''} ${AppConstants.commodityLabel[post.commodity] ?? post.commodity}',
                      style: TextStyle(
                          fontSize: 11,
                          color: commodityColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (post.isAnswered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('Terjawab',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Menunggu jawaban',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Judul
              Text(post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),

              // Konten preview
              Text(post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4)),

              // Expert reply preview
              if (post.isAnswered && post.expertReply != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post.expertReply!.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),
              // Meta
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(post.userName ?? 'Petani',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                  const Spacer(),
                  const Icon(Icons.chat_bubble_outline,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('${post.replyCount}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                  const SizedBox(width: 12),
                  const Icon(Icons.remove_red_eye_outlined,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('${post.views}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
