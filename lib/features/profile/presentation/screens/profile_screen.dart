import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Aplikasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    // Label & warna untuk role
    final roleLabel = switch (user?.role) {
      'admin'  => 'Admin',
      'pakar'  => 'Pakar',
      _        => 'Petani',
    };
    final roleColor = switch (user?.role) {
      'admin'  => AppColors.info,
      'pakar'  => AppColors.warning,
      _        => AppColors.primary,
    };

    // Initial avatar dari nama
    final initial = (user?.name.isNotEmpty == true)
        ? user!.name[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header hijau ──────────────────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  const Text(
                    'Profil Saya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Avatar lingkaran
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '-',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Badge role
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info card ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoCard(
                      children: [
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user?.email ?? '-',
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Nomor HP',
                          value: (user?.phone?.isNotEmpty == true)
                              ? user!.phone!
                              : 'Belum diisi',
                          valueColor: (user?.phone?.isNotEmpty == true)
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Wilayah',
                          value: (user?.region?.isNotEmpty == true)
                              ? user!.region!
                              : 'Belum diisi',
                          valueColor: (user?.region?.isNotEmpty == true)
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Peran',
                          value: roleLabel,
                          valueColor: roleColor,
                          valueBold: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Tombol logout
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmLogout(context),
                        icon: const Icon(Icons.logout,
                            color: AppColors.error),
                        label: const Text(
                          'Keluar',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget helpers ─────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 14,
                fontWeight:
                    valueBold ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
