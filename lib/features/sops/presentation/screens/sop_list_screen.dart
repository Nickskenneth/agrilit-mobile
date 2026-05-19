import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/commodity_chip.dart';
import '../../data/sop_provider.dart';

class SopListScreen extends StatefulWidget {
  const SopListScreen({super.key});

  @override
  State<SopListScreen> createState() => _SopListScreenState();
}

class _SopListScreenState extends State<SopListScreen> {
  String? _commodity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context.read<SopProvider>().fetchSops(commodity: _commodity);

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
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('📋 SOP Budidaya',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
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
                    CommodityChip(
                      label: 'Semua',
                      selected: _commodity == null,
                      onTap: () => setState(() {
                        _commodity = null;
                        _load();
                      }),
                    ),
                    ...['cabai', 'kentang', 'jagung'].map((c) => CommodityChip(
                          label:
                              '${AppConstants.commodityEmoji[c]} ${AppConstants.commodityLabel[c]}',
                          selected: _commodity == c,
                          color: AppColors.commodityColor(c),
                          onTap: () => setState(() {
                            _commodity = c;
                            _load();
                          }),
                        )),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Consumer<SopProvider>(
                builder: (context, provider, _) {
                  if (provider.isOffline) {
                    return Column(children: [
                      const OfflineBanner(),
                      Expanded(child: _buildGrid(provider)),
                    ]);
                  }
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null) {
                    return Center(child: Text(provider.error!));
                  }
                  return _buildGrid(provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(SopProvider provider) {
    if (provider.sops.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('Belum ada SOP tersedia',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchSops(commodity: _commodity),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 2.8,
          mainAxisSpacing: 12,
        ),
        itemCount: provider.sops.length,
        itemBuilder: (context, i) {
          final sop = provider.sops[i];
          final color = AppColors.commodityColor(sop.commodity);
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withOpacity(0.3)),
            ),
            child: InkWell(
              onTap: () => context.go('/sops/${sop.id}'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          AppConstants.commodityEmoji[sop.commodity] ?? '🌱',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sop.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (sop.durationDays != null) ...[
                                Icon(Icons.timer_outlined,
                                    size: 12, color: color),
                                const SizedBox(width: 4),
                                Text('${sop.durationDays} hari',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: color,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 12),
                              ],
                              Icon(Icons.list_alt_outlined,
                                  size: 12, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text('${sop.monthlyCalendar.length} aktivitas',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
