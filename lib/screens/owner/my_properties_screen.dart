import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../constants/property_constants.dart';
import '../../models/property_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../property/property_detail_screen.dart';
import 'add_edit_property_screen.dart';

class MyPropertiesScreen extends StatelessWidget {
  const MyPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final propertyService = PropertyService();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Properties')),
        body: const Center(child: Text('Please sign in to view your properties.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Properties'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditPropertyScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Property'),
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: propertyService.getOwnerPropertiesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Error Loading Properties',
              description: 'Unable to retrieve your listings at this moment.',
            );
          }

          final properties = snapshot.data ?? [];

          if (properties.isEmpty) {
            return EmptyState(
              icon: Icons.holiday_village_outlined,
              title: 'No listings yet',
              description:
                  'You haven\'t published any properties yet. Tap "Add Property" below to start.',
              actionLabel: 'Add First Property',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditPropertyScreen(),
                  ),
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];

              return Column(
                children: [
                  PropertyCard(
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
                  ),
                  // Owner Quick Controls Strip
                  Container(
                    margin: const EdgeInsets.only(top: 0, bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quick Availability Changer
                        OutlinedButton.icon(
                          onPressed: () => _showQuickStatusDialog(
                            context,
                            propertyService,
                            property,
                          ),
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: Text(
                            property.availabilityStatus,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),

                        Row(
                          children: [
                            // Edit Button
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              color: AppTheme.accent,
                              tooltip: 'Edit Listing',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditPropertyScreen(
                                      property: property,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              color: AppTheme.statusUnavailable,
                              tooltip: 'Delete Listing',
                              onPressed: () => _confirmDelete(
                                context,
                                propertyService,
                                property,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showQuickStatusDialog(
    BuildContext context,
    PropertyService service,
    PropertyModel property,
  ) {
    String selectedStatus = property.availabilityStatus;
    final availBedsCtrl = TextEditingController(
      text: property.availableBeds?.toString() ?? '',
    );
    final totalBedsCtrl = TextEditingController(
      text: property.totalBeds?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Availability'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select current availability for this property:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                ...PropertyConstants.availabilityStatuses.map((status) {
                  return RadioListTile<String>(
                    title: Text(status, style: const TextStyle(fontSize: 14)),
                    value: status,
                    groupValue: selectedStatus,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedStatus = val);
                      }
                    },
                  );
                }),
                if (property.isBedBased) ...[
                  const Divider(height: 20),
                  const Text(
                    'Bed Availability (PG / Hostel)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: availBedsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Available Beds',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: totalBedsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Beds',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final availBeds = int.tryParse(availBedsCtrl.text.trim());
                  final totalBeds = int.tryParse(totalBedsCtrl.text.trim());

                  await service.updateAvailability(
                    propertyId: property.id,
                    status: selectedStatus,
                    availableBeds: availBeds,
                    totalBeds: totalBeds,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Status'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    PropertyService service,
    PropertyModel property,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text(
          'Are you sure you want to delete "${property.title}"? This cannot be undone.',
        ),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.deleteProperty(property.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${property.title}"')),
        );
      }
    }
  }
}
