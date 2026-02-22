import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../controllers/admin_controller.dart';

/// User Detail Screen - Comprehensive profile view for admin
class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  bool _isEditing = false;

  // Edit controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _medicalConditionsController;
  late TextEditingController _allergiesController;
  late TextEditingController _notesController;
  String? _selectedBloodType;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _medicalConditionsController = TextEditingController();
    _allergiesController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _populateControllers(AppUser user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone ?? '';
    _addressController.text = user.address ?? '';
    _emergencyContactController.text = user.emergencyContact ?? '';
    _emergencyPhoneController.text = user.emergencyPhone ?? '';
    _medicalConditionsController.text = user.medicalConditions ?? '';
    _allergiesController.text = user.allergies ?? '';
    _notesController.text = user.notes ?? '';
    _selectedBloodType = user.bloodType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDetailStreamProvider(widget.userId));
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
              onPressed: () {
                final user = userAsync.value;
                if (user != null) {
                  _populateControllers(user);
                  setState(() => _isEditing = true);
                }
              },
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () => setState(() => _isEditing = false),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Changes',
              onPressed: () => _saveChanges(userAsync.value),
            ),
          ],
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('User not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (!_isEditing && _nameController.text.isEmpty) {
            // Initialize controllers when user is first loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _populateControllers(user);
            });
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 48 : 16,
              vertical: 24,
            ),
            child: isWideScreen
                ? _buildWideLayout(context, user)
                : _buildNarrowLayout(context, user),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(userDetailStreamProvider(widget.userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, AppUser user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Profile Card & Actions
        SizedBox(
          width: 350,
          child: Column(
            children: [
              _buildProfileCard(context, user),
              const SizedBox(height: 16),
              _buildStatusCard(context, user),
              const SizedBox(height: 16),
              _buildActionsCard(context, user),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Column - Details
        Expanded(
          child: Column(
            children: [
              _buildContactInfoCard(context, user),
              const SizedBox(height: 16),
              if (user.isSenior) ...[
                _buildMedicalInfoCard(context, user),
                const SizedBox(height: 16),
                _buildEmergencyContactCard(context, user),
                const SizedBox(height: 16),
              ],
              _buildRelationshipsCard(context, user),
              const SizedBox(height: 16),
              _buildActivityCard(context, user),
              const SizedBox(height: 16),
              _buildNotesCard(context, user),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, AppUser user) {
    return Column(
      children: [
        _buildProfileCard(context, user),
        const SizedBox(height: 16),
        _buildStatusCard(context, user),
        const SizedBox(height: 16),
        _buildActionsCard(context, user),
        const SizedBox(height: 16),
        _buildContactInfoCard(context, user),
        const SizedBox(height: 16),
        if (user.isSenior) ...[
          _buildMedicalInfoCard(context, user),
          const SizedBox(height: 16),
          _buildEmergencyContactCard(context, user),
          const SizedBox(height: 16),
        ],
        _buildRelationshipsCard(context, user),
        const SizedBox(height: 16),
        _buildActivityCard(context, user),
        const SizedBox(height: 16),
        _buildNotesCard(context, user),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, AppUser user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _getRoleColor(user.role).withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 40,
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: _getRoleColor(user.role), width: 2),
                    ),
                    child: Icon(
                      _getRoleIcon(user.role),
                      size: 18,
                      color: _getRoleColor(user.role),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            if (_isEditing)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              )
            else
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),

            // Email
            Text(
              user.email,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getRoleColor(user.role)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getRoleIcon(user.role),
                      size: 18, color: _getRoleColor(user.role)),
                  const SizedBox(width: 8),
                  Text(
                    user.roleDisplayName,
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // UID
            Text(
              'ID: ${user.uid}',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, AppUser user) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (user.approvalStatus) {
      case ApprovalStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending Approval';
        break;
      case ApprovalStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case ApprovalStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Status',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (user.approvedBy != null) ...[
              const Divider(height: 20),
              _buildInfoRow(Icons.admin_panel_settings, 'Processed by:',
                  user.approvedBy!),
            ],
            if (user.approvedAt != null)
              _buildInfoRow(
                Icons.schedule,
                'Processed on:',
                DateFormat('MMM dd, yyyy hh:mm a').format(user.approvedAt!),
              ),
            if (user.rejectionReason != null &&
                user.rejectionReason!.isNotEmpty) ...[
              const Divider(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rejection Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.rejectionReason!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (user.isPending) ...[
              ElevatedButton.icon(
                onPressed: () => _handleApprove(context, user),
                icon: const Icon(Icons.check),
                label: const Text('Approve User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showRejectDialog(context, user),
                icon: const Icon(Icons.close),
                label: const Text('Reject User'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
            if (user.isApproved)
              OutlinedButton.icon(
                onPressed: () => _handleSuspend(context, user),
                icon: const Icon(Icons.block),
                label: const Text('Suspend User'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            if (user.isRejected) ...[
              ElevatedButton.icon(
                onPressed: () => _handleReset(context, user),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset to Pending'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
            const Divider(height: 24),
            OutlinedButton.icon(
              onPressed: () => _showDeleteDialog(context, user),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete User'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[700]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard(BuildContext context, AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Contact Information', Icons.contact_phone),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ] else ...[
              _buildInfoRow(
                  Icons.phone, 'Phone:', user.phone ?? 'Not provided'),
              _buildInfoRow(Icons.location_on, 'Address:',
                  user.address ?? 'Not provided'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoCard(BuildContext context, AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                'Medical Information', Icons.medical_information),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedBloodType,
                decoration: const InputDecoration(
                  labelText: 'Blood Type',
                  prefixIcon: Icon(Icons.bloodtype),
                  border: OutlineInputBorder(),
                ),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBloodType = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicalConditionsController,
                decoration: const InputDecoration(
                  labelText: 'Medical Conditions',
                  prefixIcon: Icon(Icons.healing),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  prefixIcon: Icon(Icons.warning),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ] else ...[
              _buildInfoRow(Icons.bloodtype, 'Blood Type:',
                  user.bloodType ?? 'Not provided'),
              _buildInfoRow(
                Icons.cake,
                'Date of Birth:',
                user.dateOfBirth != null
                    ? DateFormat('MMMM dd, yyyy').format(user.dateOfBirth!)
                    : 'Not provided',
              ),
              if (user.medicalConditions != null &&
                  user.medicalConditions!.isNotEmpty)
                _buildInfoBox(
                    'Medical Conditions', user.medicalConditions!, Colors.blue),
              if (user.allergies != null && user.allergies!.isNotEmpty)
                _buildInfoBox('Allergies', user.allergies!, Colors.orange),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(BuildContext context, AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Emergency Contact', Icons.emergency,
                color: Colors.red),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.phone,
              ),
            ] else ...[
              _buildInfoRow(
                Icons.person,
                'Contact Name:',
                user.emergencyContact ?? 'Not provided',
              ),
              _buildInfoRow(
                Icons.phone,
                'Contact Phone:',
                user.emergencyPhone ?? 'Not provided',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipsCard(BuildContext context, AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Relationships', Icons.people),
            const SizedBox(height: 16),
            if (user.isSenior) ...[
              _buildRelationshipSection(
                'Linked Family Members',
                user.linkedFamily,
                Icons.family_restroom,
                Colors.indigo,
              ),
              const SizedBox(height: 12),
              _buildRelationshipSection(
                'Assigned Caregivers',
                user.assignedCaregivers,
                Icons.medical_services,
                Colors.teal,
              ),
            ],
            if (user.isFamily) ...[
              _buildInfoRow(
                Icons.elderly,
                'Linked Senior:',
                user.linkedSeniorId ?? 'Not linked',
              ),
            ],
            if (user.isCaregiver) ...[
              _buildRelationshipSection(
                'Assigned Seniors',
                user.assignedSeniors,
                Icons.elderly,
                Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipSection(
      String title, List<String>? ids, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        if (ids == null || ids.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                Text(
                  'None assigned',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ids
                .map((id) => Chip(
                      avatar: Icon(icon, size: 16, color: color),
                      label: Text(
                        id.length > 8 ? '${id.substring(0, 8)}...' : id,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: color.withOpacity(0.1),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Activity Information', Icons.history),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Registered:',
              user.createdAt != null
                  ? DateFormat('MMMM dd, yyyy hh:mm a').format(user.createdAt!)
                  : 'Unknown',
            ),
            _buildInfoRow(
              Icons.login,
              'Last Login:',
              user.lastLogin != null
                  ? DateFormat('MMMM dd, yyyy hh:mm a').format(user.lastLogin!)
                  : 'Never',
            ),
            _buildInfoRow(
              Icons.access_time,
              'Last Active:',
              user.lastActiveAt != null
                  ? DateFormat('MMMM dd, yyyy hh:mm a')
                      .format(user.lastActiveAt!)
                  : 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Admin Notes', Icons.note),
            const SizedBox(height: 16),
            if (_isEditing)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add any notes about this user...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.notes?.isNotEmpty == true
                      ? user.notes!
                      : 'No notes added',
                  style: TextStyle(
                    color: user.notes?.isNotEmpty == true
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? AppTheme.primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String content, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  Future<void> _saveChanges(AppUser? user) async {
    if (user == null) return;

    final data = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'emergencyContact': _emergencyContactController.text.trim().isEmpty
          ? null
          : _emergencyContactController.text.trim(),
      'emergencyPhone': _emergencyPhoneController.text.trim().isEmpty
          ? null
          : _emergencyPhoneController.text.trim(),
      'medicalConditions': _medicalConditionsController.text.trim().isEmpty
          ? null
          : _medicalConditionsController.text.trim(),
      'allergies': _allergiesController.text.trim().isEmpty
          ? null
          : _allergiesController.text.trim(),
      'bloodType': _selectedBloodType,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    final success = await ref
        .read(adminUserControllerProvider.notifier)
        .updateUser(user.uid, data);

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update profile'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleApprove(BuildContext context, AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve User'),
        content: Text('Are you sure you want to approve ${user.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(adminUserControllerProvider.notifier)
          .approveUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'User approved successfully'
                : 'Failed to approve user'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context, AppUser user) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${user.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              Navigator.pop(context);
              final success = await ref
                  .read(adminUserControllerProvider.notifier)
                  .rejectUser(user.uid, reasonController.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? 'User rejected' : 'Failed to reject user'),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _handleReset(BuildContext context, AppUser user) async {
    final success = await ref
        .read(adminUserControllerProvider.notifier)
        .resetToPending(user.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'User reset to pending' : 'Failed to reset user'),
          backgroundColor: success ? Colors.blue : Colors.red,
        ),
      );
    }
  }

  void _handleSuspend(BuildContext context, AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: Text(
            'Are you sure you want to suspend ${user.name}? This will set their status to rejected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(adminUserControllerProvider.notifier)
          .rejectUser(user.uid, 'Account suspended by administrator');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(success ? 'User suspended' : 'Failed to suspend user'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to permanently delete ${user.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(adminUserControllerProvider.notifier)
                  .deleteUser(user.uid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? 'User deleted' : 'Failed to delete user'),
                    backgroundColor: success ? Colors.red : Colors.grey,
                  ),
                );
                if (success) context.pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'senior':
        return Colors.purple;
      case 'caregiver':
        return Colors.teal;
      case 'family':
        return Colors.indigo;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'senior':
        return Icons.elderly;
      case 'caregiver':
        return Icons.medical_services;
      case 'family':
        return Icons.family_restroom;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }
}
