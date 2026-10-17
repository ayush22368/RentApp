import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../constants/property_constants.dart';
import '../../models/property_model.dart';
import '../../services/admin_service.dart';
import '../../services/property_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../property/property_detail_screen.dart';

class AllPropertiesScreen extends StatefulWidget {
  const AllPropertiesScreen({super.key});

  @override
  State<AllPropertiesScreen> createState() => _AllPropertiesScreenState();
}

class _AllPropertiesScreenState extends State<AllPropertiesScreen> {
  final PropertyService _propertyService = PropertyService();
  final AdminService _adminService = AdminService();

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedAvailability = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Platform Listings'),
      ),
      body: Column(
        children: [
          // Filter Controls
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search title, locality, or owner email...',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          isDense: true,
                        ),
                        items: ['All', ...PropertyConstants.propertyTypes]
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedAvailability,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                        ),
                        items: ['All', ...PropertyConstants.availabilityStatuses]
                            .map((st) => DropdownMenuItem(
                                  value: st,
                                  child: Text(
                                    st,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedAvailability = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // Properties List
          Expanded(
            child: StreamBuilder<List<PropertyModel>>(
              stream: _propertyService.getAllPropertiesStream(
                categoryFilter: _selectedCategory == 'All' ? null : _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Error loading listings',
                    description: 'Unable to retrieve all platform properties.',
                  );
                }

                final all = snapshot.data ?? [];
                final query = _searchController.text.trim().toLowerCase();

                final filtered = all.where((p) {
                  if (query.isNotEmpty) {
                    final inTitle = p.title.toLowerCase().contains(query);
                    final inLoc = p.locality.toLowerCase().contains(query);
                    final inEmail = p.ownerEmail.toLowerCase().contains(query);
                    final inOwner = p.ownerName.toLowerCase().contains(query);
                    if (!inTitle && !inLoc && !inEmail && !inOwner) return false;
                  }

                  if (_selectedAvailability != 'All') {
                    if (p.availabilityStatus != _selectedAvailability) return false;
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.holiday_village_outlined,
                    title: 'No properties found',
                    description: 'No properties match the current search or filters.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final property = filtered[index];

                    return Stack(
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
                        // Super Admin Remove Action Button
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                              tooltip: 'Remove Listing (Admin Moderation)',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Property Listing'),
                                    content: Text(
                                      'Are you sure you want to remove "${property.title}"? This action cannot be undone.',
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
                                        child: const Text('Delete Property'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await _adminService.removeProperty(property.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Removed "${property.title}"'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
