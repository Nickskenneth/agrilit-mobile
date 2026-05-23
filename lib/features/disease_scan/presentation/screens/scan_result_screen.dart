import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/disease_scan_model.dart';

class ScanResultScreen extends StatelessWidget {
  final DiseaseScanModel? scan;
  const ScanResultScreen({super.key, this.scan});

  @override
  Widget build(BuildContext context) {
    if (scan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hasil Scan')),
        body: const Center(child: Text('Data tidak ditemukan.')),
      );
    }

    final isUnidentified = scan!.isUnidentified;
    final isHealthy = scan!.isHealthy;

    // Warna banner: abu-abu untuk tidak teridentifikasi, hijau/merah untuk hasil valid
    final color = isUnidentified
        ? const Color(0xFF757575)   // abu-abu
        : (isHealthy ? AppColors.success : AppColors.error);
    final commodityColor = AppColors.commodityColor(scan!.commodity);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Hasil Analisis'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Result banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isUnidentified
                        ? Icons.help_outline_rounded
                        : (isHealthy
                            ? Icons.check_circle
                            : Icons.warning_rounded),
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUnidentified
                        ? 'Tidak Dapat Diidentifikasi'
                        : (scan!.resultLabelId ??
                            scan!.resultLabel ??
                            'Tidak dapat dianalisis'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isUnidentified)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Pastikan foto menampilkan daun tanaman dengan jelas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tingkat Kepercayaan: ${scan!.confidenceDisplay}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Detail info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.eco_outlined,
                          label: 'Komoditas',
                          value:
                              '${AppConstants.commodityEmoji[scan!.commodity] ?? ''} ${AppConstants.commodityLabel[scan!.commodity] ?? scan!.commodity}',
                          color: commodityColor,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.label_outline,
                          label: 'Label Teknis',
                          value: isUnidentified
                              ? 'Gambar tidak valid'
                              : (scan!.resultLabel ?? 'Menunggu diagnosa'),
                          color: AppColors.textSecondary,
                        ),
                        if (scan!.locationName != null) ...[
                          const Divider(height: 20),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Lokasi',
                            value: scan!.locationName!,
                            color: AppColors.info,
                          ),
                        ],
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.access_time_outlined,
                          label: 'Waktu Scan',
                          value: scan!.scannedAt,
                          color: AppColors.info,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pesan tidak teridentifikasi
                  if (isUnidentified) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tips_and_updates_outlined,
                                  size: 18, color: Color(0xFF757575)),
                              SizedBox(width: 8),
                              Text(
                                'Tips untuk hasil lebih akurat:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          _TipItem(
                              '📸 Foto daun dari jarak dekat (20–30 cm)'),
                          _TipItem(
                              '☀️ Gunakan cahaya yang cukup, hindari bayangan'),
                          _TipItem(
                              '🍃 Pastikan daun tanaman memenuhi sebagian besar frame'),
                          _TipItem(
                              '🔍 Pilih daun yang menunjukkan gejala paling jelas'),
                          _TipItem(
                              '🌿 Pilih komoditas yang sesuai (cabai/jagung/kentang)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Rekomendasi (Hanya muncul jika tidak sehat dan teridentifikasi)
                  if (!isHealthy && !isUnidentified) ...[
                    const Text(
                      '💡 Rekomendasi Penanganan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._getRecommendations(scan!.resultLabel ?? '')
                              .map((rec) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ',
                                            style: TextStyle(
                                                color: AppColors.warning,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        Expanded(
                                          child: Text(rec,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textPrimary,
                                                  height: 1.5)),
                                        ),
                                      ],
                                    ),
                                  )),
                          const SizedBox(height: 8),
                          const Text(
                              '* Konsultasikan dengan pakar untuk penanganan lebih lanjut.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action buttons
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go('/scan');
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text(
                      'Scan Lagi',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/forum/create'),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Tanya Pakar di Forum'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getRecommendations(String label) {
    final map = <String, List<String>>{
      'Bacterial_spot': [
        'Semprotkan bakterisida berbahan aktif tembaga (copper hydroxide) 2g/liter',
        'Kurangi kelembaban dengan memperbaiki drainase dan sirkulasi udara',
        'Hindari penyiraman dari atas daun (gunakan irigasi tetes)',
        'Buang dan musnahkan bagian tanaman yang terinfeksi berat',
      ],
      'Late_blight': [
        'Segera semprotkan fungisida sistemik metalaksil+mankozeb 2g/liter',
        'Buang daun bergejala dan bakar, jangan tumpuk di kebun',
        'Perpendek interval semprot menjadi 5-7 hari saat musim hujan',
        'Pasang mulsa untuk mencegah percikan tanah ke daun',
      ],
      'Early_blight': [
        'Aplikasi fungisida mankozeb atau klorotalonil secara preventif',
        'Rotasi tanaman dengan non-solanaceae musim berikutnya',
        'Perbaiki nutrisi tanaman — pupuk kalium untuk ketahanan',
        'Buang daun tua bergejala dari bagian bawah tanaman',
      ],
      'Common_rust': [
        'Semprotkan fungisida triazol (propikonazol) pada gejala awal',
        'Gunakan varietas jagung tahan karat musim berikutnya',
        'Pastikan jarak tanam cukup renggang untuk sirkulasi udara',
      ],
      'Northern_Leaf_Blight': [
        'Aplikasi fungisida strobulurin atau triazol',
        'Pilih varietas jagung dengan gen ketahanan Ht1/Ht2',
        'Rotasi tanaman dan bersihkan sisa tanaman terinfeksi',
      ],
      'Blight': [
        'Segera aplikasi fungisida berbahan aktif mankozeb',
        'Perbaiki drainase lahan untuk mengurangi kelembaban',
        'Hindari budidaya jagung berulang di lahan yang sama',
      ],
      'Gray_Leaf_Spot': [
        'Gunakan fungisida berbahan aktif azoksistrobin',
        'Rotasi tanaman — hindari jagung-jagung berturut-turut',
        'Bajak sisa tanaman terinfeksi setelah panen',
      ],
    };

    for (final key in map.keys) {
      if (label.contains(key)) return map[key]!;
    }
    return [
      'Konsultasikan kondisi tanaman dengan pakar pertanian.',
      'Foto kondisi daun dan unggah ke forum untuk mendapat saran lebih spesifik.',
    ];
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF616161),
          height: 1.4,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text('$label: ',
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
