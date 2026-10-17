import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../constants/property_constants.dart';
import '../../models/property_model.dart';
import '../../services/auth_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/property_service.dart';
import '../../widgets/app_network_image.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final PropertyModel? property; // null if adding new, non-null if editing

  const AddEditPropertyScreen({super.key, this.property});

  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final PropertyService _propertyService = PropertyService();
  final AuthService _authService = AuthService();
  final ImageUploadService _imageService = ImageUploadService();

  late TextEditingController _titleController;
  late TextEditingController _rentController;
  late TextEditingController _depositController;
  late TextEditingController _cityController;
  late TextEditingController _localityController;
  late TextEditingController _addressController;
  late TextEditingController _descController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _totalBedsController;
  late TextEditingController _availableBedsController;
  final TextEditingController _photoUrlController = TextEditingController();

  late String _propertyType;
  late String _availabilityStatus;
  late List<String> _photos;
  late Set<String> _selectedFacilities;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _showUrlField = false;

  bool get _isEditing => widget.property != null;
  bool get _isBedBased =>
      _propertyType == 'PG Accommodation' || _propertyType == 'Hostels';

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    final currentUser = _authService.currentUser;

    _titleController = TextEditingController(text: p?.title ?? '');
    _rentController = TextEditingController(
      text: p != null ? p.monthlyRent.toString() : '',
    );
    _depositController = TextEditingController(
      text: p != null ? p.securityDeposit.toString() : '',
    );
    _cityController = TextEditingController(text: p?.city ?? '');
    _localityController = TextEditingController(text: p?.locality ?? '');
    _addressController = TextEditingController(text: p?.completeAddress ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _ownerNameController = TextEditingController(
      text: p?.ownerName ?? currentUser?.displayName ?? '',
    );
    _phoneController = TextEditingController(text: p?.contactPhone ?? '');
    _totalBedsController = TextEditingController(
      text: p?.totalBeds?.toString() ?? '',
    );
    _availableBedsController = TextEditingController(
      text: p?.availableBeds?.toString() ?? '',
    );

    _propertyType = p?.propertyType ?? PropertyConstants.propertyTypes.first;
    _availabilityStatus =
        p?.availabilityStatus ?? PropertyConstants.statusAvailable;
    _photos = List<String>.from(p?.photos ?? []);
    _selectedFacilities = Set<String>.from(p?.facilities ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _cityController.dispose();
    _localityController.dispose();
    _addressController.dispose();
    _descController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _totalBedsController.dispose();
    _availableBedsController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upload photos.')),
      );
      return;
    }

    try {
      final files = await _imageService.pickFromGallery(allowMultiple: true);
      if (files.isEmpty) return;

      setState(() => _isUploadingPhoto = true);
      for (final file in files) {
        final url = await _imageService.uploadPhoto(file, ownerUid: user.uid);
        if (mounted) {
          setState(() {
            _photos.add(url);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load photos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _pickFromCamera() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use camera.')),
      );
      return;
    }

    try {
      final file = await _imageService.pickFromCamera();
      if (file == null) return;

      setState(() => _isUploadingPhoto = true);
      final url = await _imageService.uploadPhoto(file, ownerUid: user.uid);
      if (mounted) {
        setState(() {
          _photos.add(url);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _addPhotoUrl() {
    final url = _photoUrlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid HTTP or HTTPS image URL.')),
      );
      return;
    }
    setState(() {
      _photos.add(url);
      _photoUrlController.clear();
    });
  }

  void _showAddCustomFacilityDialog() {
    final customCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Facility / Amenity'),
        content: TextField(
          controller: customCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Facility Name',
            hintText: 'e.g. Swimming Pool, Solar Water',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = customCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _selectedFacilities.add(text);
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.')),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to publish a property.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final monthlyRent = num.parse(_rentController.text.trim());
      final securityDeposit = num.parse(_depositController.text.trim());
      final totalBeds = _isBedBased ? int.tryParse(_totalBedsController.text.trim()) : null;
      final availableBeds = _isBedBased ? int.tryParse(_availableBedsController.text.trim()) : null;

      if (_isEditing) {
        final updatedProperty = widget.property!.copyWith(
          title: _titleController.text.trim(),
          propertyType: _propertyType,
          photos: _photos,
          monthlyRent: monthlyRent,
          securityDeposit: securityDeposit,
          city: _cityController.text.trim(),
          locality: _localityController.text.trim(),
          completeAddress: _addressController.text.trim(),
          description: _descController.text.trim(),
          facilities: _selectedFacilities.toList(),
          ownerName: _ownerNameController.text.trim(),
          contactPhone: _phoneController.text.trim(),
          availabilityStatus: _availabilityStatus,
          totalBeds: totalBeds,
          availableBeds: availableBeds,
          updatedAt: DateTime.now(),
        );

        await _propertyService.updateProperty(updatedProperty);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property updated successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        final newProperty = PropertyModel(
          id: '',
          title: _titleController.text.trim(),
          propertyType: _propertyType,
          photos: _photos,
          monthlyRent: monthlyRent,
          securityDeposit: securityDeposit,
          city: _cityController.text.trim(),
          locality: _localityController.text.trim(),
          completeAddress: _addressController.text.trim(),
          description: _descController.text.trim(),
          facilities: _selectedFacilities.toList(),
          ownerName: _ownerNameController.text.trim(),
          contactPhone: _phoneController.text.trim(),
          availabilityStatus: _availabilityStatus,
          totalBeds: totalBeds,
          availableBeds: availableBeds,
          ownerUid: user.uid,
          ownerEmail: user.email?.toLowerCase().trim() ?? '',
          createdAt: DateTime.now(),
        );

        await _propertyService.addProperty(newProperty);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property published successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving property: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Property' : 'Add Property Listing'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitProperty,
              child: Text(
                _isEditing ? 'Update' : 'Publish',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Section 1: Basic Info
            _buildSectionHeader('Basic Details'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Property Title *',
                hintText: 'e.g. Spacious 2BHK Flat near Tech Park',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Property title is required' : null,
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _propertyType,
              decoration: const InputDecoration(labelText: 'Property Category *'),
              items: PropertyConstants.propertyTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(PropertyConstants.getCategoryIcon(type), size: 18),
                      const SizedBox(width: 8),
                      Text(type),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _propertyType = val);
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _availabilityStatus,
              decoration: const InputDecoration(labelText: 'Availability Status *'),
              items: PropertyConstants.availabilityStatuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _availabilityStatus = val);
              },
            ),

            // PG / Hostel Beds inputs
            if (_isBedBased) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _availableBedsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Available Beds *',
                        hintText: 'e.g. 4',
                      ),
                      validator: (v) {
                        if (!_isBedBased) return null;
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _totalBedsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Beds *',
                        hintText: 'e.g. 15',
                      ),
                      validator: (v) {
                        if (!_isBedBased) return null;
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Section 2: Pricing
            _buildSectionHeader('Pricing (in INR ₹)'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      labelText: 'Monthly Rent *',
                      hintText: '12000',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Rent is required';
                      final n = num.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _depositController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      labelText: 'Security Deposit *',
                      hintText: '25000',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Deposit is required';
                      final n = num.tryParse(v.trim());
                      if (n == null || n < 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section 3: Location
            _buildSectionHeader('Location & Address'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      hintText: 'e.g. Mumbai, Pune, Bangalore',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'City is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _localityController,
                    decoration: const InputDecoration(
                      labelText: 'Locality / Area *',
                      hintText: 'e.g. Kothrud, HSR Layout',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Locality is required' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Complete Address *',
                hintText: 'Building name, street, landmarks, pin code...',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),

            const SizedBox(height: 24),

            // Section 4: Photos Management
            // Section 4: Property Photos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Property Photos (${_photos.length})'),
                if (_photos.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _photos.clear()),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: AppTheme.statusUnavailable,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload clear photos of bedrooms, living area, kitchen, or exterior.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),

            // Two Primary Action Cards: Gallery & Camera
            Row(
              children: [
                // Gallery Picker Button
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isUploadingPhoto ? null : _pickFromGallery,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library_rounded, color: AppTheme.accent, size: 28),
                          SizedBox(height: 8),
                          Text(
                            'Choose Gallery',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Select multiple photos',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Camera Button
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isUploadingPhoto ? null : _pickFromCamera,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.statusAvailable.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.statusAvailable.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt_rounded, color: AppTheme.statusAvailable, size: 28),
                          SizedBox(height: 8),
                          Text(
                            'Take Photo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.statusAvailable,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Use device camera',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Optional: Web Image URL field toggle
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showUrlField = !_showUrlField),
                icon: Icon(
                  _showUrlField ? Icons.expand_less_rounded : Icons.link_rounded,
                  size: 16,
                ),
                label: Text(
                  _showUrlField ? 'Hide web URL option' : 'Or paste an image web link',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            if (_showUrlField) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _photoUrlController,
                      decoration: const InputDecoration(
                        hintText: 'https://images.unsplash.com/...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addPhotoUrl,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],

            // Uploading progress indicator
            if (_isUploadingPhoto) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing and uploading photo(s)...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Photos Preview Gallery
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  itemBuilder: (context, idx) {
                    final photo = _photos[idx];
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: AppNetworkImage(
                              imageUrl: photo,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Photo number badge
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${idx + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Delete thumbnail button
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _photos.removeAt(idx);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Section 5: Facilities & Amenities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Facilities & Amenities'),
                TextButton.icon(
                  onPressed: _showAddCustomFacilityDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Custom'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: {
                ...PropertyConstants.defaultAmenities,
                ..._selectedFacilities,
              }.map((facility) {
                final isSelected = _selectedFacilities.contains(facility);
                return FilterChip(
                  label: Text(facility),
                  selected: isSelected,
                  selectedColor: AppTheme.accent.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.accent,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFacilities.add(facility);
                      } else {
                        _selectedFacilities.remove(facility);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Section 6: Contact Information
            _buildSectionHeader('Owner / Contact Info'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: 'Owner / Agent Name *',
                hintText: 'e.g. Ramesh Sharma',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Phone Number (For Direct Calling) *',
                hintText: 'e.g. +91 9876543210',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                if (v.replaceAll(RegExp(r'[^\d]'), '').length < 8) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Section 7: Description
            _buildSectionHeader('Property Description'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText:
                    'Provide details about rules, furnishing, nearby transport, groceries, water timing, etc.',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Description is required' : null,
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitProperty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditing ? 'Save Changes' : 'Publish Property Listing',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
