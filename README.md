# RentApp — Local Rental Property Finder 🏠

A mobile Flutter application that connects tenants directly with verified property owners and agents for rental flats, rooms, PG accommodations, hostels, and houses in their city.

---

## 🌟 Key Features

### 1. Mandatory Google Authentication
- Seamless and secure **Google Sign-In** as the sole authentication provider (no email/password clutter).
- Automatic role detection:
  - **Super Admin** (`khardeayush2@gmail.com`)
  - **Authorized Owner / Agent**
  - **Rental Seeker / Normal User**

### 2. Multi-Tier Permission & Role Management
- **Platform Owner (Super Admin)**:
  - Authorizes owners by registering their Google account email address.
  - Activates or deactivates owner accounts with a single toggle.
  - Platform overview metrics (Total listings, Available, Unavailable, Authorized owners).
  - Content moderation: Review and remove inappropriate or outdated listings.
- **Authorized Owners & Agents**:
  - Access to dedicated Owner Dashboard with real metrics.
  - Add / edit property listings with comprehensive field validation.
  - **Photo Uploads**: Directly from **Device Gallery** (multi-select) or **Camera** capture, with image compression.
  - Real-time availability updater: *Available*, *Limited Availability*, *Rented / Full*, *Temporarily Unavailable*.
  - Bed tracker for PGs and Hostels (*e.g., "4 of 15 beds available"*).
- **Normal Users (Tenants)**:
  - Clean discover feed (automatically hides rented/unavailable listings).
  - Search by locality, area, city, and filter by budget and property category.
  - **1-Tap Direct Call**: Launches native device dialer with owner's contact phone number.
  - Save properties to **Favorites** with real-time availability updates.

---

## 🏢 Supported Property Categories

1. **Flats / Apartments**
2. **Single Rooms**
3. **PG Accommodation** (with total and available bed counters)
4. **Hostels** (with total and available bed counters)
5. **Independent Houses**
6. **Shops**
7. **Offices**
8. **Other**

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart 3.x)
- **Backend**: [Firebase](https://firebase.google.com/)
  - **Firebase Auth**: Google Sign-In authentication
  - **Cloud Firestore**: Real-time NoSQL database
  - **Firebase Storage**: Cloud media hosting with automatic compressed Base64 fallback
- **Hardware Integration**:
  - `image_picker`: Device camera and gallery selection
  - `url_launcher`: Native device phone dialer (`tel:`)

---

## 🚀 Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/<your-username>/rent.git
cd rent
```

### 2. Add Firebase Configuration
Download your `google-services.json` from the Firebase Console (Android App configuration) and place it into:
```
android/app/google-services.json
```
*(Note: `google-services.json` is ignored by `.gitignore` to prevent sensitive credentials from leaking to public repositories).*

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the Application
```bash
flutter run
```

### 5. Build Release APK
```bash
flutter build apk --release
```
The output APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🔒 Firebase Security Rules (Production Ready)

### Cloud Firestore Rules (`firestore.rules`)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isSuperAdmin() {
      return isAuthenticated() && 
        request.auth.token.email.lower() == 'khardeayush2@gmail.com';
    }
    
    function isAuthorizedOwner() {
      return isAuthenticated() && (
        isSuperAdmin() ||
        (exists(/databases/$(database)/documents/authorized_owners/$(request.auth.token.email.lower())) &&
         get(/databases/$(database)/documents/authorized_owners/$(request.auth.token.email.lower())).data.isActive == true)
      );
    }

    // Properties: Authenticated users can read; Authorized owners or Super Admin can create/update/delete
    match /properties/{propertyId} {
      allow read: if isAuthenticated();
      allow create: if isAuthorizedOwner();
      allow update: if isSuperAdmin() || (isAuthorizedOwner() && resource.data.ownerUid == request.auth.uid);
      allow delete: if isSuperAdmin() || (isAuthorizedOwner() && resource.data.ownerUid == request.auth.uid);
    }

    // Authorized Owners: Super Admin has full access; Owners can read their own status and update their login info
    match /authorized_owners/{email} {
      allow read: if isAuthenticated();
      allow create, delete: if isSuperAdmin();
      allow update: if isSuperAdmin() || 
        (isAuthenticated() && request.auth.token.email.lower() == email.lower());
    }

    // Users: Users can read/write their own profiles and favorites
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;

      match /favorites/{propertyId} {
        allow read, write: if isAuthenticated() && request.auth.uid == userId;
      }
    }
  }
}
```

### Firebase Storage Rules (`storage.rules`)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /properties/{ownerUid}/{allPaths=**} {
      // Any authenticated user can view property photos
      allow read: if request.auth != null;
      // Only the authenticated owner or super admin can upload photos
      allow write: if request.auth != null && 
        (request.auth.uid == ownerUid || request.auth.token.email.lower() == 'khardeayush2@gmail.com');
    }
  }
}
```

---

## 📱 Architecture Overview

```
lib/
├── constants/
│   ├── app_theme.dart            # Design tokens, color palette, typography
│   └── property_constants.dart   # Categories, amenities, availability statuses
├── models/
│   ├── property_model.dart       # Property entity & serialization
│   ├── authorized_owner_model.dart # Authorized owner entity
│   └── user_role.dart            # UserRole enum & helpers
├── services/
│   ├── auth_service.dart         # Google Auth & real-time role listener
│   ├── property_service.dart     # Firestore property operations & favorites
│   ├── admin_service.dart        # Super Admin management services
│   └── image_upload_service.dart # Camera/Gallery picker & Storage upload
├── widgets/
│   ├── app_network_image.dart    # Universal image renderer (Network/Base64/File)
│   ├── availability_badge.dart   # Color-coded status badge
│   ├── empty_state.dart          # Zero-dummy empty state widget
│   └── property_card.dart        # Property feed listing card
└── screens/
    ├── auth/                     # Google Sign-In screen
    ├── discover/                 # Discover feed & Search/Filters
    ├── property/                 # Property details & direct calling
    ├── favorites/                # Saved properties
    ├── profile/                  # User profile & portal navigation
    ├── owner/                    # Owner dashboard, my properties, add/edit listing
    └── admin/                    # Super Admin dashboard, manage owners, all listings
```
