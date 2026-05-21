import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/disease_scan_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  String _commodity = 'cabai';
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiseaseScanProvider>().loadUnsyncedCount();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _scan() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto daun terlebih dahulu.')),
      );
      return;
    }

    // Log komoditas yang dipilih
    debugPrint('=== SCAN INITIATED ===');
    debugPrint('Selected commodity: $_commodity');
    debugPrint('Image path: ${_selectedImage!.path}');

    final provider = context.read<DiseaseScanProvider>();
    final ok = await provider.scanImage(
      imageFile: _selectedImage!,
      commodity: _commodity, // ← Pastikan ini terkirim
    );

    if (!mounted) return;

    if (ok && provider.lastResult != null) {
      // Log hasil
      debugPrint('=== SCAN RESULT ===');
      debugPrint('Label: ${provider.lastResult!.resultLabel}');
      debugPrint('Label ID: ${provider.lastResult!.resultLabelId}');
      debugPrint('Commodity: ${provider.lastResult!.commodity}');
      debugPrint('Confidence: ${provider.lastResult!.confidenceDisplay}');

      context.push('/scan/result', extra: provider.lastResult);
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: provider.error!.contains('Tidak ada koneksi')
              ? AppColors.warning
              : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text('🔬 Scan Penyakit',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark)),
              const SizedBox(height: 4),
              const Text('Foto daun tanaman untuk mendeteksi penyakit',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),

              // Unsynced badge
              Consumer<DiseaseScanProvider>(
                builder: (_, provider, __) {
                  if (provider.unsyncedCount == 0) return const SizedBox();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sync_problem,
                            color: AppColors.warning, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              '${provider.unsyncedCount} scan belum tersinkronisasi',
                              style: const TextStyle(
                                  color: AppColors.warning, fontSize: 13)),
                        ),
                        TextButton(
                          onPressed: () async {
                            final result = await provider.syncOfflineScans();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${result['saved']} berhasil disinkronkan.')),
                              );
                            }
                          },
                          child: const Text('Sync',
                              style: TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Pilih komoditas
              const Text('Komoditas Tanaman',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                children: AppConstants.commodities.map((c) {
                  final selected = _commodity == c;
                  final color = AppColors.commodityColor(c);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _commodity = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? color : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: selected ? color : Colors.transparent),
                        ),
                        child: Column(
                          children: [
                            Text(AppConstants.commodityEmoji[c] ?? '',
                                style: const TextStyle(fontSize: 26)),
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
              const SizedBox(height: 24),

              // Preview gambar
              const Text('Foto Daun',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showSourceDialog(),
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImage != null
                          ? AppColors.primary
                          : AppColors.border,
                      width: _selectedImage != null ? 2 : 1,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_selectedImage!,
                              fit: BoxFit.cover, width: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.add_a_photo_outlined,
                                  size: 32, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            const Text('Ketuk untuk ambil/pilih foto',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            const Text(
                                'Pastikan daun terlihat jelas\ndengan pencahayaan cukup',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textHint)),
                          ],
                        ),
                ),
              ),

              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedImage = null),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Ganti Foto'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                ),
              ],

              const SizedBox(height: 24),

              // Tips
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.tips_and_updates_outlined,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Tips Foto Terbaik',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                              fontSize: 13)),
                    ]),
                    SizedBox(height: 8),
                    _TipItem(
                        'Foto satu daun yang menunjukkan gejala paling jelas'),
                    _TipItem('Jarak kamera 15-20 cm dari daun'),
                    _TipItem('Pastikan cahaya cukup, hindari bayangan'),
                    _TipItem('Gunakan latar belakang polos jika memungkinkan'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Scan button
              Consumer<DiseaseScanProvider>(
                builder: (_, provider, __) => ElevatedButton.icon(
                  onPressed: provider.isScanning ? null : _scan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: provider.isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.document_scanner),
                  label: Text(
                      provider.isScanning
                          ? 'Menganalisis...'
                          : 'Analisis Penyakit',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 12),

              // Lihat riwayat
              OutlinedButton.icon(
                onPressed: () => context.push('/scan/history'),
                icon: const Icon(Icons.history),
                label: const Text('Lihat Riwayat Scan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Sumber Foto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SourceOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.primaryDark)),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
