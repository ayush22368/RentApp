import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/property_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../property/property_detail_screen.dart';

class OwnerPropertiesScreen extends StatelessWidget {
  final String ownerEmail;
  final String? ownerName;

  const OwnerPropertiesScreen({
    super.key,
    required this.ownerEmail,
    this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ownerName?.isNotEmpty ?? false ? ownerName! : 'Owner Properties',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              ownerEmail,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: adminService.getOwnerProperties(ownerEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final properties = snapshot.data ?? [];

          if (properties.isEmpty) {
            return EmptyState(
              icon: Icons.holiday_village_outlined,
              title: 'No listings by this owner',
              description: '$ownerEmail has not published any rental properties yet.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
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
            },
          );
        },
      ),
    );
  }
}
