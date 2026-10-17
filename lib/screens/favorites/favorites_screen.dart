import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/property_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/property_card.dart';
import '../property/property_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final propertyService = PropertyService();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Properties')),
        body: EmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'Sign in to view favorites',
          description: 'Keep track of properties you like by signing in with Google.',
          actionLabel: 'Sign in with Google',
          onAction: () {
            authService.signInWithGoogle();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Properties'),
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: propertyService.getFavoritePropertiesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Error loading favorites',
              description: 'Unable to retrieve your saved listings.',
            );
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No saved properties yet',
              description:
                  'Tap the heart icon on any rental property card to save it here for quick access.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final property = favorites[index];

              return PropertyCard(
                property: property,
                isFavorite: true,
                onFavoriteTap: () async {
                  await propertyService.toggleFavorite(user.uid, property.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed "${property.title}" from favorites.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
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
      ),
    );
  }
}
