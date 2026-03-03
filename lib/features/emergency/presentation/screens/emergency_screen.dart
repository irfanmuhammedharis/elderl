import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/location_service.dart';
import '../../../../common_widgets/senior_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/emergency_repository.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  bool _emergencyTriggered = false;
  bool _isLoading = false;
  int _countdown = 5;
  bool _countdownActive = false;
  LocationData? _currentLocation;
  String? _emergencyId;
  final _locationService = LocationService();

  @override
  void dispose() {
    _countdownActive = false;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() => _currentLocation = location);
    }
  }

  void _startCountdown() {
    setState(() => _countdownActive = true);
    _runCountdown();
  }

  Future<void> _runCountdown() async {
    for (int i = 5; i > 0; i--) {
      if (!_countdownActive || !mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (_countdownActive && mounted) {
      _triggerEmergency();
    }
  }

  void _cancelCountdown() {
    setState(() {
      _countdownActive = false;
      _countdown = 5;
    });
  }

  Future<void> _triggerEmergency() async {
    setState(() {
      _isLoading = true;
      _countdownActive = false;
    });

    try {
      final authState = ref.read(authControllerProvider);
      final userId = authState.user?.uid;
      final userName = authState.user?.name ?? 'User';
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get fresh location
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _currentLocation = location;
      }

      // Call emergency repository
      final emergencyRepo = ref.read(emergencyRepositoryProvider);
      final emergencyId = await emergencyRepo.triggerEmergency(
        seniorId: userId,
        seniorName: userName,
        emergencyType: 'general',
        location: _currentLocation != null
            ? {
                'latitude': _currentLocation!.latitude,
                'longitude': _currentLocation!.longitude,
                'accuracy': _currentLocation!.accuracy,
                'timestamp': _currentLocation!.timestamp.toIso8601String(),
              }
            : null,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emergencyTriggered = true;
          _emergencyId = emergencyId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _countdownActive || _emergencyTriggered
          ? AppTheme.emergencyColor.withOpacity(0.1)
          : null,
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: AppTheme.emergencyColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_emergencyTriggered) ...[
                _buildEmergencyTriggeredView(context),
              ] else if (_countdownActive) ...[
                _buildCountdownView(context),
              ] else if (_isLoading) ...[
                _buildLoadingView(context),
              ] else ...[
                _buildInitialView(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialView(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.emergency,
          size: 100,
          color: AppTheme.emergencyColor,
        ),
        const SizedBox(height: 32),
        Text(
          'Emergency Assistance',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.emergencyColor,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Press the button below to alert your emergency contacts and nearby caregivers.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Location status indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _currentLocation != null
                ? Colors.green.shade50
                : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _currentLocation != null ? Icons.location_on : Icons.location_searching,
                color: _currentLocation != null ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _currentLocation != null
                    ? 'Location ready (±${_currentLocation!.accuracy.toStringAsFixed(0)}m)'
                    : 'Getting location...',
                style: TextStyle(
                  color: _currentLocation != null ? Colors.green[700] : Colors.orange[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SeniorButton(
          text: 'CALL FOR HELP',
          icon: Icons.emergency,
          backgroundColor: AppTheme.emergencyColor,
          onPressed: _startCountdown,
          padding: const EdgeInsets.symmetric(vertical: 28),
        ),
        const SizedBox(height: 24),
        Text(
          'Your location will be shared with emergency contacts.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCountdownView(BuildContext context) {
    return Column(
      children: [
        Text(
          'Calling for help in...',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          width: 150,
          height: 150,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.emergencyColor,
          ),
          child: Center(
            child: Text(
              '$_countdown',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        SeniorButton(
          text: 'CANCEL',
          icon: Icons.close,
          backgroundColor: Colors.grey,
          onPressed: _cancelCountdown,
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        const SizedBox(height: 16),
        Text(
          'Press cancel if you pressed by mistake.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(
          color: AppTheme.emergencyColor,
          strokeWidth: 6,
        ),
        const SizedBox(height: 32),
        Text(
          'Sending emergency alert...',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmergencyTriggeredView(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          size: 100,
          color: AppTheme.successColor,
        ),
        const SizedBox(height: 32),
        Text(
          'Help is on the way!',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your emergency contacts have been notified.\nStay calm and wait for assistance.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Show location shared
        if (_currentLocation != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.share_location, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Location shared',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Emergency contacts notified:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('Family Member'),
                subtitle: Text('Notification sent'),
              ),
              const ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('Nearby Caregiver'),
                subtitle: Text('Notification sent'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Cancel emergency button
        SeniorButton(
          text: 'Cancel Emergency',
          icon: Icons.cancel,
          backgroundColor: Colors.orange,
          onPressed: _cancelEmergency,
        ),
        const SizedBox(height: 16),
        SeniorButton(
          text: 'Return Home',
          icon: Icons.home,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  Future<void> _cancelEmergency() async {
    if (_emergencyId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Emergency?'),
        content: const Text(
          'Are you sure you want to cancel this emergency? '
          'Only cancel if you no longer need assistance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep Active'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final emergencyRepo = ref.read(emergencyRepositoryProvider);
        await emergencyRepo.cancelEmergency(_emergencyId!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency cancelled')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling: $e')),
          );
        }
      }
    }
  }
}
