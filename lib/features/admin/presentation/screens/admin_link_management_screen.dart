import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../controllers/admin_controller.dart';
import '../../../linking/presentation/controllers/linking_controller.dart';

/// Admin Link Management Screen
/// Allows admins to link seniors with caregivers and family members
class AdminLinkManagementScreen extends ConsumerStatefulWidget {
  const AdminLinkManagementScreen({super.key});

  @override
  ConsumerState<AdminLinkManagementScreen> createState() =>
      _AdminLinkManagementScreenState();
}

class _AdminLinkManagementScreenState
    extends ConsumerState<AdminLinkManagementScreen> {
  String? _selectedSeniorId;
  bool _showAddCaregiver = false;
  bool _showAddFamily = false;

  @override
  Widget build(BuildContext context) {
    final allUsersAsync = ref.watch(allUsersStreamProvider);
    // Watch linking state for rebuild on link/unlink operations
    ref.watch(linkingControllerProvider);
    
    final linkedUsersAsync = _selectedSeniorId != null
        ? ref.watch(linkedUsersProvider(_selectedSeniorId!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: allUsersAsync.when(
        data: (users) {
          final seniors = users.where((u) => u.role == 'senior').toList();
          final caregivers = users.where((u) => u.role == 'caregiver').toList();
          final family = users.where((u) => u.role == 'family').toList();

          return Row(
            children: [
              // Left Panel: Senior List
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.elderly, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Seniors (${seniors.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: seniors.length,
                        itemBuilder: (context, index) {
                          final senior = seniors[index];
                          final isSelected = _selectedSeniorId == senior.uid;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
                            leading: CircleAvatar(
                              backgroundImage: senior.avatarUrl != null
                                  ? NetworkImage(senior.avatarUrl!)
                                  : null,
                              child: senior.avatarUrl == null
                                  ? Text(senior.name[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(senior.name),
                            subtitle: Text(senior.email),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedSeniorId = senior.uid;
                                _showAddCaregiver = false;
                                _showAddFamily = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),

              // Right Panel: Link Details
              Expanded(
                child: _selectedSeniorId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.link,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select a senior to manage links',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : linkedUsersAsync?.when(
                        data: (linkedUsers) {
                          final linkedCaregivers = linkedUsers['caregivers'] ?? [];
                          final linkedFamily = linkedUsers['family'] ?? [];
                          
                          final availableCaregivers = caregivers
                              .where((c) => !linkedCaregivers.any((lc) => lc.uid == c.uid))
                              .toList();
                          final availableFamily = family
                              .where((f) => !linkedFamily.any((lf) => lf.uid == f.uid))
                              .toList();

                          final isValid = linkedCaregivers.isNotEmpty && linkedFamily.length >= 2;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Validation Status
                                Card(
                                  color: isValid ? Colors.green[50] : Colors.orange[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isValid ? Icons.check_circle : Icons.warning,
                                          color: isValid ? Colors.green : Colors.orange,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isValid
                                                    ? 'Minimum Requirements Met'
                                                    : 'Requirements Not Met',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isValid ? Colors.green[900] : Colors.orange[900],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Need: 1+ Caregiver, 2+ Family Members',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Caregivers Section
                                _buildSection(
                                  context: context,
                                  title: 'Assigned Caregivers',
                                  count: linkedCaregivers.length,
                                  required: '1+ required',
                                  icon: Icons.medical_services,
                                  color: Colors.blue,
                                  items: linkedCaregivers,
                                  onAdd: () => setState(() => _showAddCaregiver = !_showAddCaregiver),
                                  onRemove: (user) => _unlinkCaregiver(user.uid),
                                  showAddForm: _showAddCaregiver,
                                  availableUsers: availableCaregivers,
                                  onSelect: (user) => _linkCaregiver(user.uid),
                                ),
                                const SizedBox(height: 24),

                                // Family Members Section
                                _buildSection(
                                  context: context,
                                  title: 'Linked Family Members',
                                  count: linkedFamily.length,
                                  required: '2+ required',
                                  icon: Icons.family_restroom,
                                  color: Colors.purple,
                                  items: linkedFamily,
                                  onAdd: () => setState(() => _showAddFamily = !_showAddFamily),
                                  onRemove: (user) => _unlinkFamilyMember(user.uid),
                                  showAddForm: _showAddFamily,
                                  availableUsers: availableFamily,
                                  onSelect: (user) => _linkFamilyMember(user.uid),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Text('Error: $error'),
                        ),
                      ) ??
                    const Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading users: $error'),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required int count,
    required String required,
    required IconData icon,
    required Color color,
    required List<AppUser> items,
    required VoidCallback onAdd,
    required Function(AppUser) onRemove,
    required bool showAddForm,
    required List<AppUser> availableUsers,
    required Function(AppUser) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Chip(
              label: Text('$count - $required'),
              backgroundColor: count >= (title.contains('Caregiver') ? 1 : 2)
                  ? Colors.green[100]
                  : Colors.orange[100],
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: Icon(showAddForm ? Icons.close : Icons.add),
              label: Text(showAddForm ? 'Cancel' : 'Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Add Form
        if (showAddForm)
          Card(
            color: color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: availableUsers.isEmpty
                  ? const Text('No users available to link')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Users:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...availableUsers.map((user) => ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(user.name[0].toUpperCase())
                                    : null,
                              ),
                              title: Text(user.name),
                              subtitle: Text(user.email),
                              trailing: ElevatedButton(
                                onPressed: () => onSelect(user),
                                child: const Text('Link'),
                              ),
                            )),
                      ],
                    ),
            ),
          ),
        const SizedBox(height: 8),

        // Linked Users List
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No ${title.toLowerCase()} linked',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ...items.map((user) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(user.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => onRemove(user),
                  ),
                ),
              )),
      ],
    );
  }

  Future<void> _linkCaregiver(String caregiverId) async {
    if (_selectedSeniorId == null) return;
    
    await ref.read(linkingControllerProvider.notifier).linkCaregiver(
          _selectedSeniorId!,
          caregiverId,
        );
    
    setState(() => _showAddCaregiver = false);
    ref.invalidate(linkedUsersProvider(_selectedSeniorId!));
  }

  Future<void> _linkFamilyMember(String familyId) async {
    if (_selectedSeniorId == null) return;
    
    await ref.read(linkingControllerProvider.notifier).linkFamilyMember(
          _selectedSeniorId!,
          familyId,
        );
    
    setState(() => _showAddFamily = false);
    ref.invalidate(linkedUsersProvider(_selectedSeniorId!));
  }

  Future<void> _unlinkCaregiver(String caregiverId) async {
    if (_selectedSeniorId == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unlink'),
        content: const Text('Are you sure you want to unlink this caregiver?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(linkingControllerProvider.notifier).unlinkCaregiver(
            _selectedSeniorId!,
            caregiverId,
          );
      ref.invalidate(linkedUsersProvider(_selectedSeniorId!));
    }
  }

  Future<void> _unlinkFamilyMember(String familyId) async {
    if (_selectedSeniorId == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unlink'),
        content: const Text('Are you sure you want to unlink this family member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(linkingControllerProvider.notifier).unlinkFamilyMember(
            _selectedSeniorId!,
            familyId,
          );
      ref.invalidate(linkedUsersProvider(_selectedSeniorId!));
    }
  }
}
