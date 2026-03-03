import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../common_widgets/senior_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/checkin_repository.dart';

class DailyCheckInScreen extends ConsumerStatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  ConsumerState<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends ConsumerState<DailyCheckInScreen> {
  bool _isLoading = false;
  String _selectedStatus = 'ok';
  final TextEditingController _messageController = TextEditingController();

  static const _moodOptions = [
    {'status': 'ok', 'label': 'Doing Well', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.green},
    {'status': 'not_great', 'label': 'Not Great', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.orange},
    {'status': 'need_help', 'label': 'Need Help', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.red},
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isLoading = true);
    
    try {
      final authState = ref.read(authControllerProvider);
      final userId = authState.user?.uid;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final checkInRepo = ref.read(checkInRepositoryProvider);
      
      // Create check-in record in Firebase
      final checkIn = CheckIn(
        seniorId: userId,
        status: _selectedStatus,
        message: _messageController.text.trim().isEmpty
            ? _defaultMessage(_selectedStatus)
            : _messageController.text.trim(),
        checkinTime: DateTime.now(),
      );
      
      await checkInRepo.createCheckIn(checkIn);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in successful! Your family has been notified.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final userId = authState.user?.uid;
    
    // Stream today's check-in status
    final todayCheckInAsync = userId != null 
        ? ref.watch(todayCheckInStreamProvider(userId))
        : const AsyncValue<CheckIn?>.data(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: todayCheckInAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (todayCheckIn) {
            final isCheckedIn = todayCheckIn != null;
            
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Icon
                  Icon(
                    isCheckedIn ? Icons.check_circle : Icons.schedule,
                    size: 120,
                    color: isCheckedIn ? AppTheme.successColor : Colors.grey,
                  ),
                  const SizedBox(height: 32),

                  // Status Text
                  Text(
                    isCheckedIn
                        ? "You've Checked In!"
                        : 'Daily Check-In',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    isCheckedIn
                        ? 'Your family and caregivers know you are safe.'
                        : 'Let your family know you are safe and well today.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (isCheckedIn && todayCheckIn.checkinTime != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Checked in at ${_formatTime(todayCheckIn.checkinTime!)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.successColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 48),

                  // Check-In Button
                  if (!isCheckedIn) ...[
                    // Mood selector
                    Text(
                      'How are you feeling?',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _moodOptions.map((option) {
                        final isSelected = _selectedStatus == option['status'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStatus = option['status'] as String),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (option['color'] as Color).withAlpha(40)
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: option['color'] as Color, width: 2)
                                      : null,
                                ),
                                child: Icon(
                                  option['icon'] as IconData,
                                  size: 36,
                                  color: isSelected
                                      ? option['color'] as Color
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? option['color'] as Color : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Optional message
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Add a note (optional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SeniorButton(
                      text: "Check In",
                      icon: Icons.check_circle,
                      backgroundColor: AppTheme.successColor,
                      isLoading: _isLoading,
                      onPressed: _handleCheckIn,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                    ),
                  ],

                  if (isCheckedIn) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.successColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.successColor,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Checked in today',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SeniorButton(
                      text: 'Go Back Home',
                      icon: Icons.home,
                      onPressed: () => context.pop(),
                    ),
                  ],

                  const Spacer(),

                  // Info text
                  Text(
                    'Check-in daily to let your loved ones know you are safe.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _defaultMessage(String status) {
    return switch (status) {
      'ok' => "I'm doing well today",
      'not_great' => "I'm not feeling great today",
      'need_help' => "I need some help today",
      _ => "Check-in",
    };
  }
}
