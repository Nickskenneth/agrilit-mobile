import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/forum_provider.dart';

class ForumCreateScreen extends StatefulWidget {
  const ForumCreateScreen({super.key});

  @override
  State<ForumCreateScreen> createState() => _ForumCreateScreenState();
}

class _ForumCreateScreenState extends State<ForumCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _commodity = 'cabai';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await context.read<ForumProvider>().createPost(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          commodity: _commodity,
        );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Pertanyaan terkirim! Menunggu moderasi sebelum tampil.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Pertanyaan')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Consumer<ForumProvider>(
          builder: (context, provider, _) => Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.info),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pertanyaan akan ditinjau moderator sebelum ditampilkan.',
                          style: TextStyle(fontSize: 12, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Komoditas
                const Text('Komoditas *',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: AppConstants.commodities.map((c) {
                    final selected = _commodity == c;
                    final color = AppColors.commodityColor(c);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _commodity = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? color : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selected ? color : Colors.transparent),
                          ),
                          child: Column(
                            children: [
                              Text(AppConstants.commodityEmoji[c] ?? '',
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(
                                AppConstants.commodityLabel[c] ?? c,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Judul
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul Pertanyaan *',
                    hintText: 'Contoh: Daun cabai saya menguning, kenapa?',
                  ),
                  validator: (v) => v == null || v.trim().length < 10
                      ? 'Judul minimal 10 karakter'
                      : null,
                  maxLength: 200,
                ),
                const SizedBox(height: 4),

                // Konten
                TextFormField(
                  controller: _contentCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Detail Pertanyaan *',
                    hintText: 'Jelaskan kondisi tanaman Anda secara detail: '
                        'umur tanaman, gejala yang terlihat, '
                        'kondisi cuaca, dll.',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.trim().length < 20
                      ? 'Pertanyaan minimal 20 karakter'
                      : null,
                  maxLength: 2000,
                ),
                const SizedBox(height: 24),

                // Submit
                if (provider.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(provider.error!,
                        style: const TextStyle(color: AppColors.error)),
                  ),
                ],

                ElevatedButton(
                  onPressed: provider.isSubmitting ? null : _submit,
                  child: provider.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Kirim Pertanyaan',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
