import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/sop_provider.dart';
import '../../data/sop_model.dart';

class SopDetailScreen extends StatefulWidget {
  final int id;
  const SopDetailScreen({super.key, required this.id});

  @override
  State<SopDetailScreen> createState() => _SopDetailScreenState();
}

class _SopDetailScreenState extends State<SopDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SopProvider>().fetchSopDetail(widget.id);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(SopModel sop) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text(sop.title)),
          pw.Paragraph(text: sop.description ?? ''),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, child: pw.Text('Kalender Aktivitas')),
          pw.Table.fromTextArray(
            headers: ['Bulan', 'Minggu', 'Aktivitas', 'Detail'],
            data: sop.monthlyCalendar
                .map((row) => [
                      row['month']?.toString() ?? '',
                      row['week']?.toString() ?? '',
                      row['activity']?.toString() ?? '',
                      row['details']?.toString() ?? '',
                    ])
                .toList(),
          ),
          if (sop.inputsNeeded != null) ...[
            pw.SizedBox(height: 16),
            pw.Header(level: 1, child: pw.Text('Kebutuhan Input')),
            pw.Table.fromTextArray(
              headers: ['Nama', 'Dosis', 'Waktu'],
              data: sop.inputsNeeded!
                  .map((inp) => [
                        inp['name']?.toString() ?? '',
                        inp['dose']?.toString() ?? '',
                        inp['timing']?.toString() ?? '',
                      ])
                  .toList(),
            ),
          ],
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${sop.title}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<SopProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }
          final sop = provider.selected;
          if (sop == null) return const SizedBox();

          final color = AppColors.commodityColor(sop.commodity);

          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                pinned: true,
                backgroundColor: color,
                title: Text(sop.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    tooltip: 'Ekspor PDF',
                    onPressed: () => _exportPdf(sop),
                  ),
                ],
                bottom: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Kalender'),
                    Tab(text: 'Kebutuhan Input'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildCalendar(sop, color),
                _buildInputs(sop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendar(SopModel sop, Color color) {
    if (sop.monthlyCalendar.isEmpty) {
      return const Center(child: Text('Belum ada data kalender.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sop.monthlyCalendar.length,
      itemBuilder: (context, i) {
        final row = sop.monthlyCalendar[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: bulan & minggu
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: color),
                    const SizedBox(width: 8),
                    Text(
                      'Bulan ${row['month'] ?? '-'} · Minggu ${row['week'] ?? '-'}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row['activity']?.toString() ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (row['details'] != null) ...[
                      const SizedBox(height: 8),
                      Text(row['details'].toString(),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5)),
                    ],
                    if (row['inputs'] != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (row['inputs'] as List)
                            .map((inp) => Chip(
                                  label: Text(inp.toString(),
                                      style: const TextStyle(fontSize: 11)),
                                  backgroundColor: color.withOpacity(0.1),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputs(SopModel sop) {
    final inputs = sop.inputsNeeded;
    if (inputs == null || inputs.isEmpty) {
      return const Center(
        child: Text('Belum ada data kebutuhan input.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inputs.length,
      itemBuilder: (context, i) {
        final inp = inputs[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.science_outlined,
                  color: AppColors.primary, size: 20),
            ),
            title: Text(inp['name']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${inp['dose'] ?? ''} · ${inp['timing'] ?? ''}',
                style: const TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}
