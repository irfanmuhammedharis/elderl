import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../common_widgets/senior_button.dart';
import '../../../../common_widgets/senior_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/request_repository.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  final String requestType;

  const CreateRequestScreen({
    super.key,
    required this.requestType,
  });

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isUrgent = false;
  bool _isLoading = false;
  bool _requestSubmitted = false;
  bool _useCurrentLocation = true;
  LocationData? _currentLocation;
  final _locationService = LocationService();

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

  String get _requestTitle {
    switch (widget.requestType) {
      case AppConstants.requestMedical:
        return 'Medical Help Request';
      case AppConstants.requestFood:
        return 'Food Help Request';
      case AppConstants.requestTransport:
        return 'Transport Request';
      case AppConstants.requestCompanion:
        return 'Companion Request';
      default:
        return 'Help Request';
    }
  }

  IconData get _requestIcon {
    switch (widget.requestType) {
      case AppConstants.requestMedical:
        return Icons.local_hospital;
      case AppConstants.requestFood:
        return Icons.restaurant;
      case AppConstants.requestTransport:
        return Icons.directions_car;
      case AppConstants.requestCompanion:
        return Icons.people;
      default:
        return Icons.help;
    }
  }

  Color get _requestColor {
    switch (widget.requestType) {
      case AppConstants.requestMedical:
        return Colors.red;
      case AppConstants.requestFood:
        return Colors.orange;
      case AppConstants.requestTransport:
        return Colors.blue;
      case AppConstants.requestCompanion:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authControllerProvider);
      final userId = authState.user?.uid;
      final userName = authState.user?.name ?? 'User';

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get fresh location if using current location
      if (_useCurrentLocation) {
        final location = await _locationService.getCurrentLocation();
        if (location != null) {
          _currentLocation = location;
        }
      }

      // Create request via repository
      final requestRepo = ref.read(requestRepositoryProvider);
      await requestRepo.create(
        seniorId: userId,
        seniorName: userName,
        type: widget.requestType,
        description: _descriptionController.text,
        address: _addressController.text,
        isUrgent: _isUrgent,
        location: _useCurrentLocation && _currentLocation != null
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
          _requestSubmitted = true;
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
      appBar: AppBar(
        title: Text(_requestTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _requestSubmitted
              ? _buildSuccessView(context)
              : _buildFormView(context),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Request type indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _requestColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(_requestIcon, size: 48, color: _requestColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _requestTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _requestColor,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description field
          SeniorTextField(
            controller: _descriptionController,
            labelText: 'Describe your need',
            hintText: 'Tell us how we can help you...',
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe what you need';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Address field
          SeniorTextField(
            controller: _addressController,
            labelText: 'Address',
            hintText: 'Where do you need help?',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 28),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Use current location toggle
          Card(
            child: SwitchListTile(
              title: Text(
                'Share my current location',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: _useCurrentLocation
                  ? Text(
                      _currentLocation != null
                          ? 'Location ready (±${_currentLocation!.accuracy.toStringAsFixed(0)}m)'
                          : 'Getting location...',
                      style: TextStyle(
                        color: _currentLocation != null ? Colors.green : Colors.orange,
                      ),
                    )
                  : const Text('Location not shared'),
              secondary: Icon(
                _currentLocation != null ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: _useCurrentLocation
                    ? (_currentLocation != null ? Colors.green : Colors.orange)
                    : Colors.grey,
                size: 28,
              ),
              value: _useCurrentLocation,
              onChanged: (value) {
                setState(() => _useCurrentLocation = value);
                if (value && _currentLocation == null) {
                  _fetchLocation();
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Urgent toggle
          Card(
            child: SwitchListTile(
              title: Text(
                'This is urgent',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(
                'Mark if you need immediate assistance',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              secondary: Icon(
                Icons.priority_high,
                color: _isUrgent ? Colors.red : Colors.grey,
                size: 32,
              ),
              value: _isUrgent,
              onChanged: (value) {
                setState(() => _isUrgent = value);
              },
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          SeniorButton(
            text: 'Submit Request',
            icon: Icons.send,
            isLoading: _isLoading,
            backgroundColor: _requestColor,
            onPressed: _submitRequest,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        const Icon(
          Icons.check_circle,
          size: 100,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          'Request Submitted!',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'A caregiver will be assigned to help you soon.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SeniorButton(
          text: 'Return Home',
          icon: Icons.home,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
