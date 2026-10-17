import 'package:flutter/material.dart';

class PropertyConstants {
  // Designated Super Admin Email
  static const String superAdminEmail = 'khardeayush2@gmail.com';

  // 8 Property Categories as required by PRD
  static const List<String> propertyTypes = [
    'Flats / Apartments',
    'Single Rooms',
    'PG Accommodation',
    'Hostels',
    'Independent Houses',
    'Shops',
    'Offices',
    'Other',
  ];

  // 4 Availability Statuses as required by PRD
  static const String statusAvailable = 'Available';
  static const String statusLimited = 'Limited Availability';
  static const String statusRented = 'Rented / Full';
  static const String statusUnavailable = 'Temporarily Unavailable';

  static const List<String> availabilityStatuses = [
    statusAvailable,
    statusLimited,
    statusRented,
    statusUnavailable,
  ];

  // Common amenities / facilities list
  static const List<String> defaultAmenities = [
    'WiFi',
    'Air Conditioner (AC)',
    'Geyser',
    'Parking',
    'RO Water',
    'Power Backup',
    'Furnished',
    'Semi-Furnished',
    'Kitchen',
    'Washing Machine',
    'CCTV / Security',
    'Lift / Elevator',
    'Attached Washroom',
    'Balcony',
    'Refrigerator',
    'Mess / Food Included',
  ];

  static IconData getCategoryIcon(String type) {
    switch (type) {
      case 'Flats / Apartments':
        return Icons.apartment_rounded;
      case 'Single Rooms':
        return Icons.bed_rounded;
      case 'PG Accommodation':
        return Icons.groups_rounded;
      case 'Hostels':
        return Icons.hotel_rounded;
      case 'Independent Houses':
        return Icons.home_rounded;
      case 'Shops':
        return Icons.storefront_rounded;
      case 'Offices':
        return Icons.business_center_rounded;
      default:
        return Icons.roofing_rounded;
    }
  }

  static IconData getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit_rounded;
    if (lower.contains('geyser') || lower.contains('water heater')) return Icons.water_drop_rounded;
    if (lower.contains('parking')) return Icons.local_parking_rounded;
    if (lower.contains('ro') || lower.contains('water')) return Icons.water_rounded;
    if (lower.contains('power') || lower.contains('backup')) return Icons.bolt_rounded;
    if (lower.contains('furnished')) return Icons.chair_rounded;
    if (lower.contains('kitchen')) return Icons.kitchen_rounded;
    if (lower.contains('washing')) return Icons.local_laundry_service_rounded;
    if (lower.contains('cctv') || lower.contains('security')) return Icons.shield_rounded;
    if (lower.contains('lift') || lower.contains('elevator')) return Icons.elevator_rounded;
    if (lower.contains('washroom')) return Icons.bathtub_rounded;
    if (lower.contains('balcony')) return Icons.deck_rounded;
    if (lower.contains('refrigerator')) return Icons.kitchen_rounded;
    if (lower.contains('mess') || lower.contains('food')) return Icons.restaurant_rounded;
    return Icons.check_circle_outline_rounded;
  }
}
