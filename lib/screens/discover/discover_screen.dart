import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../constants/property_constants.dart';
import '../../models/property_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../property/property_detail_screen.dart';
import 'search_filter_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final PropertyService _propertyService = PropertyService();
  final AuthService _authService = AuthService();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rental Properties',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Find flats, rooms, PGs & houses',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search & Filters',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchFilterScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Quick Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchFilterScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search by area, locality, or rent...',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Categories Horizontal Selector
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All', null),
                ...PropertyConstants.propertyTypes.map((cat) {
                  return _buildCategoryChip(
                    cat,
                    PropertyConstants.getCategoryIcon(cat),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Realtime Properties Feed
          Expanded(
            child: StreamBuilder<Set<String>>(
              stream: user != null
                  ? _propertyService.getFavoritePropertyIdsStream(user.uid)
                  : Stream.value(<String>{}),
              builder: (context, favSnapshot) {
                final favoriteIds = favSnapshot.data ?? <String>{};

                return StreamBuilder<List<PropertyModel>>(
                  stream: _propertyService.getPublicAvailablePropertiesStream(
                    categoryFilter: _selectedCategory,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Unable to load properties',
                        description: 'Please check your connection and try again.',
                        actionLabel: 'Retry',
                        onAction: () => setState(() {}),
                      );
                    }

                    final properties = snapshot.data ?? [];

                    if (properties.isEmpty) {
                      return EmptyState(
                        icon: Icons.holiday_village_outlined,
                        title: _selectedCategory == 'All'
                            ? 'No properties available right now'
                            : 'No $_selectedCategory listed',
                        description:
                            'Check back soon or explore other property categories.',
                        actionLabel: _selectedCategory != 'All'
                            ? 'Show all categories'
                            : null,
                        onAction: () {
                          setState(() {
                            _selectedCategory = 'All';
                          });
                        },
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        final property = properties[index];
                        final isFav = favoriteIds.contains(property.id);

                        return PropertyCard(
                          property: property,
                          isFavorite: isFav,
                          onFavoriteTap: () async {
                            if (user == null) {
                              _promptSignIn(context);
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

  Widget _buildCategoryChip(String title, IconData? icon) {
    final isSelected = _selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(title),
          ],
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        backgroundColor: AppTheme.surface,
        selectedColor: AppTheme.primary,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = title;
          });
        },
      ),
    );
  }

  void _promptSignIn(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sign in with Google to save favorites.'),
        action: SnackBarAction(
          label: 'Sign In',
          textColor: Colors.amberAccent,
          onPressed: () {
            _authService.signInWithGoogle();
          },
        ),
      ),
    );
  }
}
