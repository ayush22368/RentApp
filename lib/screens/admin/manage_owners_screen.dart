import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/authorized_owner_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/empty_state.dart';
import 'owner_properties_screen.dart';

class ManageOwnersScreen extends StatefulWidget {
  const ManageOwnersScreen({super.key});

  @override
  State<ManageOwnersScreen> createState() => _ManageOwnersScreenState();
}

class _ManageOwnersScreenState extends State<ManageOwnersScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();

  void _showAddOwnerDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppTheme.accent),
            SizedBox(width: 8),
            Text('Authorize Owner / Agent'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the Google account email address of the owner or agent. Once authorized, they can sign in using this Google account to publish and manage properties.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Google Account Email *',
                  hintText: 'e.g. owner@gmail.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!val.contains('@') || !val.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Owner / Agency Name (Optional)',
                  hintText: 'e.g. John Doe / Skyline Realty',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final email = emailController.text.trim();
                final name = nameController.text.trim();
                final superAdmin = _authService.currentUser?.email ?? 'Super Admin';

                try {
                  await _adminService.authorizeOwner(
                    email: email,
                    name: name.isNotEmpty ? name : null,
                    authorizedBy: superAdmin,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully authorized $email')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Authorize'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Owners & Agents'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOwnerDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Authorize Owner'),
      ),
      body: StreamBuilder<List<AuthorizedOwnerModel>>(
        stream: _adminService.getAuthorizedOwnersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Error loading owners',
              description: 'Unable to load authorized owners list.',
            );
          }

          final owners = snapshot.data ?? [];

          if (owners.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No authorized owners yet',
              description:
                  'Use the button below to authorize owners by entering their Google email address.',
              actionLabel: 'Authorize Owner',
              onAction: _showAddOwnerDialog,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: owners.length,
            itemBuilder: (context, index) {
              final owner = owners[index];
              return _buildOwnerCard(context, owner);
            },
          );
        },
      ),
    );
  }

  Widget _buildOwnerCard(BuildContext context, AuthorizedOwnerModel owner) {
    final isPending = owner.status == 'pending';
    final isActive = owner.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppTheme.border : AppTheme.statusUnavailable.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isActive
                    ? AppTheme.accent.withValues(alpha: 0.1)
                    : AppTheme.borderLight,
                child: Icon(
                  isActive ? Icons.verified_user_rounded : Icons.person_off_rounded,
                  color: isActive ? AppTheme.accent : AppTheme.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (owner.name != null && owner.name!.isNotEmpty)
                      Text(
                        owner.name!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    Text(
                      owner.email,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: owner.name == null ? FontWeight.w700 : FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status Pill
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPending
                                ? AppTheme.statusLimited.withValues(alpha: 0.12)
                                : AppTheme.statusAvailable.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPending ? 'Pending First Sign-In' : 'Registered & Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isPending ? AppTheme.statusLimited : AppTheme.statusAvailable,
                            ),
                          ),
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.statusUnavailable.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Deactivated',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.statusUnavailable,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Active / Deactive Switch
              Column(
                children: [
                  Switch(
                    value: isActive,
                    activeColor: AppTheme.statusAvailable,
                    onChanged: (val) async {
                      await _adminService.setOwnerActiveStatus(
                        email: owner.email,
                        isActive: val,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? 'Activated owner: ${owner.email}'
                                  : 'Deactivated owner: ${owner.email}',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  Text(
                    isActive ? 'Active' : 'Disabled',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppTheme.statusAvailable : AppTheme.statusUnavailable,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 24, color: AppTheme.border),

          // Action Buttons: View Properties and Remove
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OwnerPropertiesScreen(
                        ownerEmail: owner.email,
                        ownerName: owner.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.apartment_rounded, size: 16),
                label: const Text('View Properties', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusUnavailable),
                tooltip: 'Remove Authorization',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Revoke Authorization'),
                      content: Text(
                        'Are you sure you want to completely remove owner authorization for ${owner.email}?',
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
                          child: const Text('Revoke'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _adminService.removeOwnerAuthorization(owner.email);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
