import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/forum_provider.dart';
import '../../data/forum_models.dart';

class ForumDetailScreen extends StatefulWidget {
  final int id;
  const ForumDetailScreen({super.key, required this.id});

  @override
  State<ForumDetailScreen> createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends State<ForumDetailScreen> {
  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumProvider>().fetchPostDetail(widget.id);
    });
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final content = _replyCtrl.text.trim();
    if (content.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balasan minimal 10 karakter.')),
      );
      return;
    }

    final ok =
        await context.read<ForumProvider>().replyPost(widget.id, content);

    if (ok && mounted) {
      _replyCtrl.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balasan berhasil dikirim.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Diskusi')),
      body: Consumer<ForumProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }
          final post = provider.selected;
          if (post == null) return const SizedBox();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Pertanyaan utama
                    _buildQuestion(post),
                    const SizedBox(height: 16),

                    // Label jumlah balasan
                    Text(
                      '${post.replies.length} Balasan',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Replies
                    ...post.replies.map((reply) =>
                        _buildReply(context, reply, provider, post.id)),

                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Reply input
              _buildReplyInput(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestion(ForumPostModel post) {
    final color = AppColors.commodityColor(post.commodity);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            const Border(left: BorderSide(color: AppColors.primary, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Komoditas badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${AppConstants.commodityEmoji[post.commodity] ?? ''} ${AppConstants.commodityLabel[post.commodity] ?? post.commodity}',
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),

          Text(post.title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3)),
          const SizedBox(height: 10),

          Text(post.content,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.6)),

          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(post.userName ?? 'Petani',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReply(
    BuildContext context,
    ForumReplyModel reply,
    ForumProvider provider,
    int postId,
  ) {
    final isExpert = reply.isExpertAnswer;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isExpert ? AppColors.primary.withOpacity(0.4) : AppColors.border,
        ),
        boxShadow: isExpert
            ? [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expert badge header
          if (isExpert)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('Jawaban Pakar',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reply.content,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      reply.userName ?? 'Pengguna',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isExpert ? AppColors.primary : AppColors.textHint,
                        fontWeight:
                            isExpert ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    // Upvote button
                    GestureDetector(
                      onTap: reply.id != null
                          ? () => provider.upvoteReply(reply.id!, postId)
                          : null,
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up_outlined,
                              size: 14,
                              color: isExpert
                                  ? AppColors.primary
                                  : AppColors.textHint),
                          const SizedBox(width: 4),
                          Text('${reply.upvotes}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isExpert
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput(ForumProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyCtrl,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Tulis balasan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          provider.isSubmitting
              ? const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  onPressed: _submitReply,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(10),
                  ),
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
        ],
      ),
    );
  }
}
