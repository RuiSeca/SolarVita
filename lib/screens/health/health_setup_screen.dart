import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../providers/riverpod/health_data_provider.dart';

class HealthSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSetupComplete;

  const HealthSetupScreen({
    super.key,
    this.onSetupComplete,
  });

  @override
  ConsumerState<HealthSetupScreen> createState() => _HealthSetupScreenState();
}

class _HealthSetupScreenState extends ConsumerState<HealthSetupScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildStepIndicator(),
                const SizedBox(height: 32),
                _buildCurrentStep(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Data Setup',
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Connect your health data for personalized insights',
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: i <= _currentStep ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: i <= _currentStep ? Colors.white : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (i < 2)
            Expanded(
              child: Container(
                height: 2,
                color: i < _currentStep ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildPermissionsStep();
      case 2:
        return _buildCompletedStep();
      default:
        return _buildWelcomeStep();
    }
  }

  Widget _buildWelcomeStep() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Platform.isIOS ? Icons.favorite : Icons.fitness_center,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                Platform.isIOS ? 'Connect to Apple Health' : 'Connect to Health Connect',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Get real-time health insights by connecting your ${Platform.isIOS ? 'Apple Health' : 'Health Connect'} data. '
                'Track your steps, calories, heart rate, and more.',
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildFeatureList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.directions_walk, 'title': 'Steps & Distance', 'description': 'Daily activity tracking'},
      {'icon': Icons.local_fire_department, 'title': 'Calories Burned', 'description': 'Energy expenditure'},
      {'icon': Icons.favorite, 'title': 'Heart Rate', 'description': 'Cardiovascular health'},
      {'icon': Icons.bedtime, 'title': 'Sleep Quality', 'description': 'Rest and recovery'},
      if (Platform.isIOS) {'icon': Icons.water_drop, 'title': 'Water Intake', 'description': 'Hydration tracking'},
    ];

    return Column(
      children: features.map((feature) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      feature['description'] as String,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionsStep() {
    return Consumer(
      builder: (context, ref, child) {
        final healthAppInstalled = ref.watch(healthAppInstalledProvider);

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  healthAppInstalled.when(
                    data: (isInstalled) {
                      if (!isInstalled && Platform.isAndroid) {
                        return _buildInstallHealthConnectSection();
                      }
                      return _buildPermissionsSection();
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => _buildErrorSection(error.toString()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstallHealthConnectSection() {
    return Column(
      children: [
        Icon(
          Icons.download,
          size: 64,
          color: Colors.orange,
        ),
        const SizedBox(height: 24),
        Text(
          'Install Health Connect',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Health Connect is required to access your health data on Android. '
          'It\'s free and available on the Play Store.',
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.7),
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () async {
            final service = ref.read(healthDataServiceProvider);
            await service.showHealthAppInstallDialog(context);
          },
          icon: const Icon(Icons.download),
          label: const Text('Install Health Connect'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      children: [
        Icon(
          Icons.security,
          size: 64,
          color: AppColors.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Grant Health Permissions',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We need permission to access your health data. '
          'Your data stays private and secure on your device.',
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.7),
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.privacy_tip,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your health data is processed locally and never leaves your device.',
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedStep() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Setup Complete!',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your health data is now connected. SolarVita will sync your latest '
                'health metrics and provide personalized insights.',
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Health data will sync automatically in the background.',
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSection(String error) {
    return Column(
      children: [
        Icon(
          Icons.error,
          size: 64,
          color: Colors.red,
        ),
        const SizedBox(height: 24),
        Text(
          'Setup Error',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          error,
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.7),
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_currentStep < 2)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 0 ? 'Get Started' : 'Grant Permissions',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        if (_currentStep == 2)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSetupComplete?.call();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue to Health Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            _currentStep == 2 ? 'Skip for now' : 'Maybe later',
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleNextStep() async {
    if (_currentStep == 0) {
      setState(() {
        _currentStep = 1;
      });
    } else if (_currentStep == 1) {
      setState(() {
        _isLoading = true;
      });

      try {
        final service = ref.read(healthDataServiceProvider);
        final shouldShowDialog = await service.showPermissionsDialog(context);
        
        if (shouldShowDialog) {
          final permissionsNotifier = ref.read(healthPermissionsNotifierProvider.notifier);
          await permissionsNotifier.requestPermissions();
          
          // Wait for permission state to be updated and check again
          await permissionsNotifier.checkPermissions();
          final permissionsStatus = ref.read(healthPermissionsNotifierProvider).value;
          
          if (permissionsStatus?.isGranted == true) {
            // Trigger health data sync
            final healthDataNotifier = ref.read(healthDataNotifierProvider.notifier);
            await healthDataNotifier.syncHealthData();
            
            setState(() {
              _currentStep = 2;
            });
          } else {
            // Show manual setup instructions
            if (mounted) {
              await _showManualSetupDialog();
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error setting up health data: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showManualSetupDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manual Health Setup Required'),
          content: const Text(
            'The automatic permission setup failed. Please follow these steps:\n\n'
            '1. Open Health Connect app on your device\n'
            '2. Go to "App permissions"\n'
            '3. Find "SolarVita" in the list\n'
            '4. Enable permissions for:\n'
            '   • Steps\n'
            '   • Active calories burned\n'
            '   • Heart rate\n'
            '   • Sleep\n'
            '   • Exercise\n'
            '   • Hydration\n\n'
            'After granting permissions, tap "Check Permissions" below.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Health Connect'),
              onPressed: () async {
                final service = ref.read(healthDataServiceProvider);
                await service.openHealthConnectSettings();
              },
            ),
            TextButton(
              child: const Text('Check Permissions'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _recheckPermissions();
              },
            ),
            TextButton(
              child: const Text('Skip for now'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _recheckPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final permissionsNotifier = ref.read(healthPermissionsNotifierProvider.notifier);
      await permissionsNotifier.checkPermissions();
      final permissionsStatus = ref.read(healthPermissionsNotifierProvider).value;
      
      if (permissionsStatus?.isGranted == true) {
        // Trigger health data sync
        final healthDataNotifier = ref.read(healthDataNotifierProvider.notifier);
        await healthDataNotifier.syncHealthData();
        
        setState(() {
          _currentStep = 2;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Health permissions granted successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Health permissions not yet granted. Please try the manual setup again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking permissions: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}