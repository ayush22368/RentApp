import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../constants/property_constants.dart';
import '../../models/property_model.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../property/property_detail_screen.dart';
import 'add_edit_property_screen.dart';
import 'my_properties_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final propertyService = PropertyService();
    final user = authService.currentUser;

    // Security check: Must be owner or super admin
    if (!authService.currentRole.canManageProperties || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Restricted')),
        body: const EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Authorization Required',
          description:
              'Only authorized property owners and agents can view this dashboard.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'My Properties',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyPropertiesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: propertyService.getOwnerPropertiesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final myProperties = snapshot.data ?? [];
          final total = myProperties.length;
          final available = myProperties.where((p) =>
              p.availabilityStatus == PropertyConstants.statusAvailable ||
              p.availabilityStatus == PropertyConstants.statusLimited).length;
          final unavailable = total - available;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.home_work_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user.displayName ?? 'Owner'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Manage your rental properties & availability',
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

                // Primary "Add Property" Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditPropertyScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_home_work_rounded, size: 22),
                    label: const Text('Add New Property Listing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Real Statistics Cards (3 cards)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Total Listings',
                        count: total,
                        color: AppTheme.accent,
                        icon: Icons.apartment_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Available',
                        count: available,
                        color: AppTheme.statusAvailable,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Unavailable',
                        count: unavailable,
                        color: AppTheme.statusUnavailable,
                        icon: Icons.pause_circle_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Recent Listings Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Listings',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (myProperties.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyPropertiesScreen(),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                if (myProperties.isEmpty)
                  EmptyState(
                    icon: Icons.apartment_outlined,
                    title: 'No properties published yet',
                    description:
                        'Tap the "Add New Property Listing" button above to publish your first rental property.',
                    actionLabel: 'Add Property',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditPropertyScreen(),
                        ),
                      );
                    },
                  )
                else
                  ...myProperties.take(3).map((property) {
                    return PropertyCard(
                      property: property,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PropertyDetailScreen(
                              propertyId: property.id,
                            ),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
