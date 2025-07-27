// Debug menu screen for development tools
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/social_service.dart';
import '../../providers/riverpod/user_profile_provider.dart';
import '../../theme/app_theme.dart';

class DebugMenuScreen extends ConsumerStatefulWidget {
  const DebugMenuScreen({super.key});

  @override
  ConsumerState<DebugMenuScreen> createState() => _DebugMenuScreenState();
}

class _DebugMenuScreenState extends ConsumerState<DebugMenuScreen> {
  final SocialService _socialService = SocialService();
  bool _isLoading = false;
  String? _lastResult;

  Future<void> _checkAndFixSupporterCount() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final result = await _socialService.checkAndFixMySuppoterCount();
      
      setState(() {
        _lastResult = 'Supporter Count Check:\n'
            'User ID: ${result['userId']}\n'
            'Stored Count: ${result['storedCount']}\n'
            'Actual Count: ${result['actualCount']}\n'
            'Was Fixed: ${result['wasFixed'] ? 'Yes' : 'No'}';
      });

      // Refresh the UI if something was fixed
      if (result['wasFixed'] == true) {
        // Use silent refresh to avoid loading states that might trigger navigation
        await ref.read(userProfileNotifierProvider.notifier).silentRefreshSupporterCount();
        
        _showSnackBar(
          '✅ Fixed! Count updated from ${result['storedCount']} to ${result['actualCount']}. Changes applied!',
          Colors.green,
        );
      } else {
        _showSnackBar(
          '✅ No fix needed - counts already match (${result['actualCount']})',
          Colors.blue,
        );
      }
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
      });
      _showSnackBar('❌ Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugRelationshipState() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final result = await _socialService.debugRelationshipState();
      
      setState(() {
        _lastResult = 'Relationship Debug:\n'
            'Current User: ${result['currentUserId']}\n'
            'Supporter Requests: ${result['supporterRequests']['total']}\n'
            '- As Requester: ${result['supporterRequests']['asRequester']}\n'
            '- As Receiver: ${result['supporterRequests']['asReceiver']}\n'
            'Supports:\n'
            '- Supporting: ${result['supports']['supporting']}\n'
            '- Supporters: ${result['supports']['supporters']}\n\n'
            'Full Details:\n${result.toString()}';
      });

      _showSnackBar('✅ Debug data generated', Colors.blue);
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
      });
      _showSnackBar('❌ Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeSupportersCount() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      await _socialService.initializeSupportersCount();
      
      // Use silent refresh to avoid loading states that might trigger navigation
      await ref.read(userProfileNotifierProvider.notifier).silentRefreshSupporterCount();
      
      setState(() {
        _lastResult = 'Supporters count initialized successfully. Changes applied!';
      });

      _showSnackBar('✅ Supporters count initialized! Changes applied.', Colors.green);
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
      });
      _showSnackBar('❌ Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Menu'),
        backgroundColor: AppTheme.surfaceColor(context),
        foregroundColor: AppTheme.textColor(context),
      ),
      backgroundColor: AppTheme.surfaceColor(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(76)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Developer Tools',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        Text(
                          'These tools are for debugging and fixing data issues',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textColor(context).withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Debug Actions
            Text(
              'Supporter System Debug',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),

            const SizedBox(height: 16),

            // Check and Fix Supporter Count
            _buildDebugCard(
              title: 'Check & Fix Supporter Count',
              description: 'Verifies and corrects your supporter count',
              icon: Icons.healing,
              color: Colors.green,
              onTap: _isLoading ? null : _checkAndFixSupporterCount,
            ),

            const SizedBox(height: 12),

            // Debug Relationship State
            _buildDebugCard(
              title: 'Debug Relationship State',
              description: 'Shows detailed relationship data for analysis',
              icon: Icons.analytics,
              color: Colors.blue,
              onTap: _isLoading ? null : _debugRelationshipState,
            ),

            const SizedBox(height: 12),

            // Initialize Supporters Count
            _buildDebugCard(
              title: 'Initialize Supporters Count',
              description: 'Force recalculate supporters count from actual data',
              icon: Icons.refresh,
              color: Colors.purple,
              onTap: _isLoading ? null : _initializeSupportersCount,
            ),

            const SizedBox(height: 24),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing...'),
                  ],
                ),
              ),

            // Results
            if (_lastResult != null && !_isLoading) ...[
              Text(
                'Last Result:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.textColor(context).withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.textColor(context).withAlpha(76),
                  ),
                ),
                child: Text(
                  _lastResult!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                'Debug Mode Only - Not visible in production',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textColor(context).withAlpha(128),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textColor(context).withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textColor(context).withAlpha(128),
              ),
            ],
          ),
        ),
      ),
    );
  }
}