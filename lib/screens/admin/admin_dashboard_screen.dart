import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/empty_state.dart';
import 'all_properties_screen.dart';
import 'manage_owners_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final adminService = AdminService();

    // Security check: only designated super admin
    if (authService.currentRole != UserRole.superAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const EmptyState(
          icon: Icons.gpp_bad_rounded,
          title: 'Unauthorized Access',
          description: 'Only the designated Super Admin can access this panel.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
      ),
      body: StreamBuilder<Map<String, int>>(
        stream: adminService.getDashboardStatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ?? {
            'totalProperties': 0,
            'available': 0,
            'unavailable': 0,
            'totalOwners': 0,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Platform Overview',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Real-time metrics and administration controls',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4 Real Metrics Cards (2x2 Grid)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Listings',
                        count: stats['totalProperties'] ?? 0,
                        icon: Icons.apartment_rounded,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Available',
                        count: stats['available'] ?? 0,
                        icon: Icons.check_circle_rounded,
                        color: AppTheme.statusAvailable,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Unavailable',
                        count: stats['unavailable'] ?? 0,
                        icon: Icons.pause_circle_rounded,
                        color: AppTheme.statusUnavailable,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Authorized Owners',
                        count: stats['totalOwners'] ?? 0,
                        icon: Icons.verified_user_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Navigation Actions
                const Text(
                  'Management Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                _buildActionCard(
                  context,
                  title: 'Manage Owners & Agents',
                  subtitle:
                      'Authorize Google accounts, activate or deactivate owners',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageOwnersScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildActionCard(
                  context,
                  title: 'All Property Listings',
                  subtitle:
                      'Review all properties, search, filter, and remove listings',
                  icon: Icons.holiday_village_rounded,
                  color: AppTheme.accent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllPropertiesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
