import '../../widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../constants/property_constants.dart';
import '../../models/property_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../widgets/availability_badge.dart';
import '../../widgets/empty_state.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final PropertyService _propertyService = PropertyService();
  final AuthService _authService = AuthService();
  int _activePhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return StreamBuilder<PropertyModel?>(
      stream: _propertyService.getPropertyStream(widget.propertyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final property = snapshot.data;
        if (property == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Property Not Found',
              description: 'This listing may have been removed or is no longer available.',
            ),
          );
        }

        return StreamBuilder<Set<String>>(
          stream: user != null
              ? _propertyService.getFavoritePropertyIdsStream(user.uid)
              : Stream.value(<String>{}),
          builder: (context, favSnapshot) {
            final favoriteIds = favSnapshot.data ?? <String>{};
            final isFavorite = favoriteIds.contains(property.id);

            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  // App Bar with Photo Slider
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    stretch: true,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? const Color(0xFFEF4444) : AppTheme.textPrimary,
                          ),
                          onPressed: () async {
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sign in with Google to save favorites.'),
                                ),
                              );
                              return;
                            }
                            await _propertyService.toggleFavorite(user.uid, property.id);
                          },
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildPhotoSlider(property),
                    ),
                  ),

                  // Content Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type & Availability Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      PropertyConstants.getCategoryIcon(property.propertyType),
                                      size: 15,
                                      color: AppTheme.accent,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      property.propertyType,
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              AvailabilityBadge(status: property.availabilityStatus),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Property Title
                          Text(
                            property.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Locality & City
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${property.locality.isNotEmpty ? '${property.locality}, ' : ''}${property.city}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Rent & Deposit Highlights
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Monthly Rent',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currencyFormatter.format(property.monthlyRent),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.accent,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 36,
                                  width: 1,
                                  color: AppTheme.border,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Security Deposit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currencyFormatter.format(property.securityDeposit),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bed Availability section for PG / Hostel
                          if (property.isBedBased && property.totalBeds != null && property.totalBeds! > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.accentTeal.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.accentTeal.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.hotel_rounded,
                                        color: AppTheme.accentTeal,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Bed Availability',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.accentTeal,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        property.bedAvailabilityText,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.accentTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: (property.availableBeds ?? 0) / property.totalBeds!,
                                      backgroundColor: AppTheme.border,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppTheme.accentTeal,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Complete Address
                          const Text(
                            'Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              property.completeAddress.isNotEmpty
                                  ? property.completeAddress
                                  : '${property.locality}, ${property.city}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Description
                          const Text(
                            'About Property',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            property.description.isNotEmpty
                                ? property.description
                                : 'No description provided by the owner.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Facilities & Amenities
                          const Text(
                            'Facilities & Amenities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (property.facilities.isEmpty)
                            const Text(
                              'Standard amenities included.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: property.facilities.map((facility) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        PropertyConstants.getAmenityIcon(facility),
                                        size: 16,
                                        color: AppTheme.accent,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        facility,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 24),

                          // Owner / Agent Details Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppTheme.accent,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property.ownerName.isNotEmpty
                                            ? property.ownerName
                                            : 'Property Owner / Agent',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 14,
                                            color: AppTheme.statusAvailable,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Authorized Lister',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.statusAvailable,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Sticky Action Bar with Call Button
              bottomNavigationBar: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: const Border(top: BorderSide(color: AppTheme.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Rent Summary
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Rent',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            currencyFormatter.format(property.monthlyRent),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),

                      // Direct Call Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callOwner(context, property.contactPhone),
                          icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                          label: const Text('Call Owner / Agent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.statusAvailable,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPhotoSlider(PropertyModel property) {
    if (property.photos.isEmpty) {
      return Container(
        color: AppTheme.borderLight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PropertyConstants.getCategoryIcon(property.propertyType),
                size: 60,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 8),
              const Text(
                'No photos uploaded',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: property.photos.length,
          onPageChanged: (idx) {
            setState(() {
              _activePhotoIndex = idx;
            });
          },
          itemBuilder: (context, index) {
            return AppNetworkImage(
              imageUrl: property.photos[index],
              fit: BoxFit.cover,
            );
          },
        ),

        // Photo indicator dots
        if (property.photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(property.photos.length, (idx) {
                final isCurrent = idx == _activePhotoIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isCurrent ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Future<void> _callOwner(BuildContext context, String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number provided for this property.')),
      );
      return;
    }

    final success = await PropertyService.callPhoneNumber(phone);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open phone dialer for $phone')),
      );
    }
  }
}
