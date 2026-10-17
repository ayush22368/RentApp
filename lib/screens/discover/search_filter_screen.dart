import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../constants/property_constants.dart';
import '../../models/property_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../property/property_detail_screen.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final PropertyService _propertyService = PropertyService();
  final AuthService _authService = AuthService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minRentController = TextEditingController();
  final TextEditingController _maxRentController = TextEditingController();

  String _selectedPropertyType = 'All';
  String _selectedAvailability = 'All Available';

  @override
  void dispose() {
    _searchController.dispose();
    _minRentController.dispose();
    _maxRentController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _minRentController.clear();
      _maxRentController.clear();
      _selectedPropertyType = 'All';
      _selectedAvailability = 'All Available';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filters'),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Form Section
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Locality Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    hintText: 'Search by locality, area, or city...',
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 12),

                // Budget Range (Min - Max Rent)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minRentController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          labelText: 'Min Rent',
                          hintText: 'e.g. 5000',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxRentController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          labelText: 'Max Rent',
                          hintText: 'e.g. 25000',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Property Type & Availability Dropdowns
                Row(
                  children: [
                    // Property Type
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPropertyType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Property Type',
                          isDense: true,
                        ),
                        items: ['All', ...PropertyConstants.propertyTypes]
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPropertyType = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Availability
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedAvailability,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Availability',
                          isDense: true,
                        ),
                        items: [
                          'All Available',
                          PropertyConstants.statusAvailable,
                          PropertyConstants.statusLimited,
                        ]
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedAvailability = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppTheme.border),

          // Search Results
          Expanded(
            child: StreamBuilder<Set<String>>(
              stream: user != null
                  ? _propertyService.getFavoritePropertyIdsStream(user.uid)
                  : Stream.value(<String>{}),
              builder: (context, favSnapshot) {
                final favoriteIds = favSnapshot.data ?? <String>{};

                return StreamBuilder<List<PropertyModel>>(
                  stream: _propertyService.getPublicAvailablePropertiesStream(
                    categoryFilter: _selectedPropertyType == 'All'
                        ? null
                        : _selectedPropertyType,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Search Error',
                        description: 'Failed to retrieve search results.',
                        actionLabel: 'Retry',
                        onAction: () => setState(() {}),
                      );
                    }

                    final allList = snapshot.data ?? [];

                    // Apply in-memory client-side filters for locality, budget & availability
                    final query = _searchController.text.trim().toLowerCase();
                    final minRent = num.tryParse(_minRentController.text.trim());
                    final maxRent = num.tryParse(_maxRentController.text.trim());

                    final filtered = allList.where((p) {
                      // Locality / Area / City filter
                      if (query.isNotEmpty) {
                        final inLocality = p.locality.toLowerCase().contains(query);
                        final inCity = p.city.toLowerCase().contains(query);
                        final inAddress = p.completeAddress.toLowerCase().contains(query);
                        final inTitle = p.title.toLowerCase().contains(query);
                        if (!inLocality && !inCity && !inAddress && !inTitle) {
                          return false;
                        }
                      }

                      // Min rent
                      if (minRent != null && p.monthlyRent < minRent) {
                        return false;
                      }

                      // Max rent
                      if (maxRent != null && p.monthlyRent > maxRent) {
                        return false;
                      }

                      // Availability filter
                      if (_selectedAvailability != 'All Available') {
                        if (p.availabilityStatus != _selectedAvailability) {
                          return false;
                        }
                      }

                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching properties found',
                        description:
                            'Try adjusting your search keywords, budget, or filters.',
                        actionLabel: 'Reset Filters',
                        onAction: _clearFilters,
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            '${filtered.length} ${filtered.length == 1 ? 'property' : 'properties'} found',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final property = filtered[index];
                              final isFav = favoriteIds.contains(property.id);

                              return PropertyCard(
                                property: property,
                                isFavorite: isFav,
                                onFavoriteTap: () async {
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sign in with Google to save favorites.'),
                                      ),
                                    );
                                    return;
                                  }
                                  await _propertyService.toggleFavorite(
                                    user.uid,
                                    property.id,
                                  );
                                },
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
