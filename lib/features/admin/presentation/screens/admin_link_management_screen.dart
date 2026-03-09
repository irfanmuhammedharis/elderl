import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../controllers/admin_controller.dart';

/// Admin Link Management Screen - Assign/link caregivers, family, and seniors
class AdminLinkManagementScreen extends ConsumerStatefulWidget {
  const AdminLinkManagementScreen({super.key});

  @override
  ConsumerState<AdminLinkManagementScreen> createState() =>
      _AdminLinkManagementScreenState();
}

class _AdminLinkManagementScreenState
    extends ConsumerState<AdminLinkManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(approvedSeniorsProvider);
    ref.invalidate(approvedCaregiversProvider);
    ref.invalidate(approvedFamilyProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.medical_services), text: 'Caregiver → Senior'),
            Tab(icon: Icon(Icons.family_restroom), text: 'Family → Senior'),
            Tab(icon: Icon(Icons.elderly), text: 'Senior Overview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CaregiverSeniorTab(),
          _FamilySeniorTab(),
          _SeniorOverviewTab(),
        ],
      ),
    );
  }
}

// ─── Tab 1: Caregiver ↔ Senior Assignment ────────────────────────────

class _CaregiverSeniorTab extends ConsumerWidget {
  const _CaregiverSeniorTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caregiversAsync = ref.watch(approvedCaregiversProvider);
    final seniorsAsync = ref.watch(approvedSeniorsProvider);

    return caregiversAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (caregivers) => seniorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (seniors) => _CaregiverSeniorContent(
          caregivers: caregivers,
          seniors: seniors,
        ),
      ),
    );
  }
}

class _CaregiverSeniorContent extends ConsumerStatefulWidget {
  final List<AppUser> caregivers;
  final List<AppUser> seniors;

  const _CaregiverSeniorContent({
    required this.caregivers,
    required this.seniors,
  });

  @override
  ConsumerState<_CaregiverSeniorContent> createState() =>
      _CaregiverSeniorContentState();
}

class _CaregiverSeniorContentState
    extends ConsumerState<_CaregiverSeniorContent> {
  String? _selectedCaregiverId;
  String? _selectedSeniorId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Assignment Form Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Assign Caregiver to Senior',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (isWide)
                        Row(
                          children: [
                            Expanded(child: _buildCaregiverDropdown()),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(Icons.arrow_forward,
                                  color: Colors.grey),
                            ),
                            Expanded(child: _buildSeniorDropdown()),
                          ],
                        )
                      else ...[
                        _buildCaregiverDropdown(),
                        const SizedBox(height: 12),
                        _buildSeniorDropdown(),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _canAssign() && !_isProcessing
                                  ? _handleAssignCaregiver
                                  : null,
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.link),
                              label: const Text('Assign'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _canAssign() && !_isProcessing
                                  ? _handleUnassignCaregiver
                                  : null,
                              icon: const Icon(Icons.link_off),
                              label: const Text('Unassign'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Current Assignments
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Current Caregiver Assignments',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.caregivers.isEmpty)
                        _buildEmptyState('No approved caregivers found')
                      else
                        ...widget.caregivers.map(
                            (cg) => _buildCaregiverAssignmentTile(cg)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCaregiverId,
      decoration: InputDecoration(
        labelText: 'Select Caregiver',
        prefixIcon:
            const Icon(Icons.medical_services, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.teal.withOpacity(0.05),
      ),
      items: widget.caregivers
          .map((cg) => DropdownMenuItem(
                value: cg.uid,
                child: Text(cg.name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedCaregiverId = v),
    );
  }

  Widget _buildSeniorDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSeniorId,
      decoration: InputDecoration(
        labelText: 'Select Senior',
        prefixIcon: const Icon(Icons.elderly, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.purple.withOpacity(0.05),
      ),
      items: widget.seniors
          .map((s) => DropdownMenuItem(
                value: s.uid,
                child: Text(s.name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedSeniorId = v),
    );
  }

  bool _canAssign() =>
      _selectedCaregiverId != null && _selectedSeniorId != null;

  Future<void> _handleAssignCaregiver() async {
    setState(() => _isProcessing = true);
    final success = await ref
        .read(adminUserControllerProvider.notifier)
        .assignCaregiverToSenior(_selectedCaregiverId!, _selectedSeniorId!);
    setState(() => _isProcessing = false);

    if (mounted) {
      _showResult(success, 'Caregiver assigned to senior',
          'Failed to assign caregiver');
      if (success) _refreshData();
    }
  }

  Future<void> _handleUnassignCaregiver() async {
    final confirmed = await _confirmAction(
      'Unassign Caregiver',
      'Remove this caregiver-senior assignment?',
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final success = await ref
        .read(adminUserControllerProvider.notifier)
        .unassignCaregiverFromSenior(
            _selectedCaregiverId!, _selectedSeniorId!);
    setState(() => _isProcessing = false);

    if (mounted) {
      _showResult(
          success, 'Caregiver unassigned', 'Failed to unassign caregiver');
      if (success) _refreshData();
    }
  }

  Widget _buildCaregiverAssignmentTile(AppUser caregiver) {
    final seniorIds = caregiver.assignedSeniors ?? [];
    final assignedSeniors = widget.seniors
        .where((s) => seniorIds.contains(s.uid))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal.withOpacity(0.1),
                child: const Icon(Icons.medical_services,
                    color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(caregiver.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(caregiver.email,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Chip(
                label: Text('${assignedSeniors.length} seniors'),
                backgroundColor: Colors.teal.withOpacity(0.1),
                labelStyle:
                    const TextStyle(fontSize: 12, color: Colors.teal),
              ),
            ],
          ),
          if (assignedSeniors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: assignedSeniors
                  .map((s) => Chip(
                        avatar: const Icon(Icons.elderly,
                            size: 14, color: Colors.purple),
                        label: Text(s.name,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        deleteIcon:
                            const Icon(Icons.close, size: 14),
                        onDeleted: () => _quickUnassignCaregiver(
                            caregiver.uid, s.uid, caregiver.name, s.name),
                      ))
                  .toList(),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('No seniors assigned',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
            ),
        ],
      ),
    );
  }

  Future<void> _quickUnassignCaregiver(
      String caregiverId, String seniorId, String cgName, String sName) async {
    final confirmed = await _confirmAction(
      'Remove Assignment',
      'Unassign $cgName from $sName?',
    );
    if (confirmed != true) return;

    final success = await ref
        .read(adminUserControllerProvider.notifier)
        .unassignCaregiverFromSenior(caregiverId, seniorId);

    if (mounted) {
      _showResult(success, 'Assignment removed', 'Failed to remove');
      if (success) _refreshData();
    }
  }

  void _refreshData() {
    ref.invalidate(approvedCaregiversProvider);
    ref.invalidate(approvedSeniorsProvider);
  }

  void _showResult(bool success, String successMsg, String failMsg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMsg : failMsg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<bool?> _confirmAction(String title, String msg) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ─── Tab 2: Family ↔ Senior Linking ──────────────────────────────────

class _FamilySeniorTab extends ConsumerWidget {
  const _FamilySeniorTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(approvedFamilyProvider);
    final seniorsAsync = ref.watch(approvedSeniorsProvider);

    return familyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (family) => seniorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (seniors) => _FamilySeniorContent(
          familyMembers: family,
          seniors: seniors,
        ),
      ),
    );
  }
}

class _FamilySeniorContent extends ConsumerStatefulWidget {
  final List<AppUser> familyMembers;
  final List<AppUser> seniors;

  const _FamilySeniorContent({
    required this.familyMembers,
    required this.seniors,
  });

  @override
  ConsumerState<_FamilySeniorContent> createState() =>
      _FamilySeniorContentState();
}

class _FamilySeniorContentState extends ConsumerState<_FamilySeniorContent> {
  String? _selectedFamilyId;
  String? _selectedSeniorId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Link Form Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Link Family Member to Senior',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (isWide)
                        Row(
                          children: [
                            Expanded(child: _buildFamilyDropdown()),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(Icons.arrow_forward,
                                  color: Colors.grey),
                            ),
                            Expanded(child: _buildSeniorDropdown()),
                          ],
                        )
                      else ...[
                        _buildFamilyDropdown(),
                        const SizedBox(height: 12),
                        _buildSeniorDropdown(),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Note: A family member can only be linked to one senior at a time. '
                        'Linking to a new senior will replace the existing link.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade700),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _canLink() && !_isProcessing
                                  ? _handleLinkFamily
                                  : null,
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.link),
                              label: const Text('Link'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _canLink() && !_isProcessing
                                  ? _handleUnlinkFamily
                                  : null,
                              icon: const Icon(Icons.link_off),
                              label: const Text('Unlink'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Current Family Links
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.family_restroom,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Current Family Links',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.familyMembers.isEmpty)
                        _buildEmptyState('No approved family members found')
                      else
                        ...widget.familyMembers
                            .map((fm) => _buildFamilyLinkTile(fm)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFamilyId,
      decoration: InputDecoration(
        labelText: 'Select Family Member',
        prefixIcon:
            const Icon(Icons.family_restroom, color: Colors.indigo),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.indigo.withOpacity(0.05),
      ),
      items: widget.familyMembers
          .map((fm) => DropdownMenuItem(
                value: fm.uid,
                child: Text(fm.name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedFamilyId = v),
    );
  }

  Widget _buildSeniorDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSeniorId,
      decoration: InputDecoration(
        labelText: 'Select Senior',
        prefixIcon: const Icon(Icons.elderly, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.purple.withOpacity(0.05),
      ),
      items: widget.seniors
          .map((s) => DropdownMenuItem(
                value: s.uid,
                child: Text(s.name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedSeniorId = v),
    );
  }

  bool _canLink() => _selectedFamilyId != null && _selectedSeniorId != null;

  Future<void> _handleLinkFamily() async {
    // Check if family member is already linked to a different senior
    final familyMember = widget.familyMembers
        .firstWhere((fm) => fm.uid == _selectedFamilyId);
    if (familyMember.linkedSeniorId != null &&
        familyMember.linkedSeniorId!.isNotEmpty &&
        familyMember.linkedSeniorId != _selectedSeniorId) {
      final confirmed = await _confirmAction(
        'Replace Existing Link',
        '${familyMember.name} is already linked to another senior. '
            'This will replace their existing link. Continue?',
      );
      if (confirmed != true) return;

      // Unlink from old senior first
      setState(() => _isProcessing = true);
      await ref
          .read(adminUserControllerProvider.notifier)
          .unlinkFamilyFromSenior(
              _selectedFamilyId!, familyMember.linkedSeniorId!);
    } else {
      setState(() => _isProcessing = true);
    }

    final success = await ref
        .read(adminUserControllerProvider.notifier)
        .linkFamilyToSenior(_selectedFamilyId!, _selectedSeniorId!);
    setState(() => _isProcessing = false);

    if (mounted) {
      _showResult(
          success, 'Family member linked to senior', 'Failed to link');
      if (success) _refreshData();
    }
  }

  Future<void> _handleUnlinkFamily() async {
    final confirmed = await _confirmAction(
      'Unlink Family Member',
      'Remove this family-senior link?',
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final success = await ref
        .read(adminUserControllerProvider.notifier)
        .unlinkFamilyFromSenior(_selectedFamilyId!, _selectedSeniorId!);
    setState(() => _isProcessing = false);

    if (mounted) {
      _showResult(success, 'Family member unlinked', 'Failed to unlink');
      if (success) _refreshData();
    }
  }

  Widget _buildFamilyLinkTile(AppUser familyMember) {
    final linkedSenior = familyMember.linkedSeniorId != null
        ? widget.seniors
            .where((s) => s.uid == familyMember.linkedSeniorId)
            .firstOrNull
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.withOpacity(0.1),
            child: const Icon(Icons.family_restroom,
                color: Colors.indigo, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(familyMember.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(familyMember.email,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          if (linkedSenior != null)
            Chip(
              avatar:
                  const Icon(Icons.elderly, size: 14, color: Colors.purple),
              label: Text(linkedSenior.name,
                  style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.purple.withOpacity(0.1),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => _quickUnlinkFamily(
                  familyMember.uid,
                  linkedSenior.uid,
                  familyMember.name,
                  linkedSenior.name),
            )
          else
            Text('Not linked',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Future<void> _quickUnlinkFamily(
      String familyId, String seniorId, String fName, String sName) async {
    final confirmed = await _confirmAction(
      'Remove Link',
      'Unlink $fName from $sName?',
    );
    if (confirmed != true) return;

    final success = await ref
        .read(adminUserControllerProvider.notifier)
        .unlinkFamilyFromSenior(familyId, seniorId);

    if (mounted) {
      _showResult(success, 'Link removed', 'Failed to remove link');
      if (success) _refreshData();
    }
  }

  void _refreshData() {
    ref.invalidate(approvedFamilyProvider);
    ref.invalidate(approvedSeniorsProvider);
  }

  void _showResult(bool success, String successMsg, String failMsg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMsg : failMsg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<bool?> _confirmAction(String title, String msg) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ─── Tab 3: Senior Overview (All relationships) ──────────────────────

class _SeniorOverviewTab extends ConsumerWidget {
  const _SeniorOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seniorsAsync = ref.watch(approvedSeniorsProvider);
    final caregiversAsync = ref.watch(approvedCaregiversProvider);
    final familyAsync = ref.watch(approvedFamilyProvider);

    return seniorsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (seniors) => caregiversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (caregivers) => familyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (family) => _SeniorOverviewContent(
            seniors: seniors,
            caregivers: caregivers,
            familyMembers: family,
          ),
        ),
      ),
    );
  }
}

class _SeniorOverviewContent extends StatelessWidget {
  final List<AppUser> seniors;
  final List<AppUser> caregivers;
  final List<AppUser> familyMembers;

  const _SeniorOverviewContent({
    required this.seniors,
    required this.caregivers,
    required this.familyMembers,
  });

  @override
  Widget build(BuildContext context) {
    if (seniors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.elderly, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No approved seniors found',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: seniors.length,
      itemBuilder: (context, index) =>
          _buildSeniorCard(context, seniors[index]),
    );
  }

  Widget _buildSeniorCard(BuildContext context, AppUser senior) {
    final assignedCgs = caregivers
        .where(
            (cg) => senior.assignedCaregivers?.contains(cg.uid) ?? false)
        .toList();
    final linkedFam = familyMembers
        .where((fm) => fm.linkedSeniorId == senior.uid)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Senior Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  child: Text(
                    senior.name.isNotEmpty
                        ? senior.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.purple, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(senior.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(senior.email,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      if (senior.phone != null)
                        Text(senior.phone!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Assigned Caregivers
            Row(
              children: [
                const Icon(Icons.medical_services,
                    size: 18, color: Colors.teal),
                const SizedBox(width: 8),
                Text('Caregivers (${assignedCgs.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            if (assignedCgs.isEmpty)
              Text('  No caregivers assigned',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: assignedCgs
                    .map((cg) => Chip(
                          avatar: const Icon(Icons.medical_services,
                              size: 14, color: Colors.teal),
                          label: Text(cg.name,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.teal.withOpacity(0.1),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 12),

            // Linked Family Members
            Row(
              children: [
                const Icon(Icons.family_restroom,
                    size: 18, color: Colors.indigo),
                const SizedBox(width: 8),
                Text('Family Members (${linkedFam.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            if (linkedFam.isEmpty)
              Text('  No family members linked',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: linkedFam
                    .map((fm) => Chip(
                          avatar: const Icon(Icons.family_restroom,
                              size: 14, color: Colors.indigo),
                          label: Text(fm.name,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
