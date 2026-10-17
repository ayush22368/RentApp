import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../owner/owner_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final user = authService.currentUser;
        final role = authService.currentRole;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
          ),
          body: user == null
              ? _buildSignedOutView(context, authService)
              : _buildSignedInView(context, authService, user, role),
        );
      },
    );
  }

  Widget _buildSignedOutView(BuildContext context, AuthService authService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_circle_outlined,
                size: 64,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sign in to RentApp',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use your Google account to save favorites and access verified owner features.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await authService.signInWithGoogle();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign-in failed: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignedInView(
    BuildContext context,
    AuthService authService,
    dynamic user,
    UserRole role,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                  child: user.photoURL == null
                      ? Text(
                          (user.displayName?.isNotEmpty ?? false)
                              ? user.displayName![0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accent,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Google User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRoleBadge(role),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Portal Access Cards based on Permissions
          if (role == UserRole.superAdmin) ...[
            _buildSuperAdminPortal(context),
            const SizedBox(height: 16),
          ] else if (role == UserRole.owner) ...[
            _buildOwnerPortal(context),
            const SizedBox(height: 16),
          ] else ...[
            _buildNormalUserNotice(),
            const SizedBox(height: 16),
          ],

          // Account Settings & Sign Out
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
                  title: const Text(
                    'About RentApp',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Local Rental Property Finder v1.0.0',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppTheme.statusUnavailable),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.statusUnavailable,
                    ),
                  ),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.statusUnavailable,
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await authService.signOut();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color color;
    IconData icon;
    String label;

    switch (role) {
      case UserRole.superAdmin:
        color = const Color(0xFF7C3AED); // Purple
        icon = Icons.admin_panel_settings_rounded;
        label = 'Super Admin';
        break;
      case UserRole.owner:
        color = AppTheme.statusAvailable; // Emerald
        icon = Icons.verified_user_rounded;
        label = 'Authorized Owner / Agent';
        break;
      case UserRole.normal:
        color = AppTheme.textSecondary;
        icon = Icons.person_outline_rounded;
        label = 'Rental Seeker';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperAdminPortal(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text(
                'Platform Administration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'You have Super Admin privileges. Authorize owners, review all properties, and manage the platform.',
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                ),
              );
            },
            icon: const Icon(Icons.dashboard_rounded, size: 18),
            label: const Text('Open Super Admin Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerPortal(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.statusAvailable.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.statusAvailable.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_center_rounded, color: AppTheme.statusAvailable),
              SizedBox(width: 8),
              Text(
                'Owner / Agent Management',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.statusAvailable,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Your account is authorized to publish and manage rental property listings.',
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OwnerDashboardScreen(),
                ),
              );
            },
            icon: const Icon(Icons.home_work_rounded, size: 18),
            label: const Text('Open Owner Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusAvailable,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalUserNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.help_outline_rounded, color: AppTheme.textSecondary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Want to list rental properties?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Only authorized owners and agents can add listings. Reach out to the platform Super Admin (khardeayush2@gmail.com) with your Google account email to request authorization.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
