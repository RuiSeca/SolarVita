import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer' as dev;

/// Debug tool to track and catch RangeError with full stack traces
class RangeErrorTracker extends StatefulWidget {
  const RangeErrorTracker({super.key});

  @override
  State<RangeErrorTracker> createState() => _RangeErrorTrackerState();
}

class _RangeErrorTrackerState extends State<RangeErrorTracker> {
  final List<String> _errorLogs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupErrorTracking();
  }

  void _setupErrorTracking() {
    // Override the default error handling to catch RangeErrors
    FlutterError.onError = (FlutterErrorDetails details) {
      _captureError('FlutterError', details.exception, details.stack);
      
      // Call the original handler too
      FlutterError.dumpErrorToConsole(details);
    };

    // Set up zone error handling
    runZonedGuarded(() {
      // This will catch any unhandled errors
    }, (error, stack) {
      _captureError('ZonedGuarded', error, stack);
    });
  }

  void _captureError(String source, Object error, StackTrace? stack) {
    if (error.toString().contains('RangeError')) {
      final timestamp = DateTime.now().toIso8601String();
      final errorInfo = StringBuffer();
      
      errorInfo.writeln('🔴 RANGEERROR DETECTED [$source]');
      errorInfo.writeln('Time: $timestamp');
      errorInfo.writeln('Error: $error');
      errorInfo.writeln();
      errorInfo.writeln('FULL STACK TRACE:');
      errorInfo.writeln(stack.toString());
      errorInfo.writeln('=' * 60);
      
      setState(() {
        _errorLogs.add(errorInfo.toString());
      });
      
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
      // Also log to developer console
      dev.log(
        'RangeError captured: $error',
        name: 'RangeErrorTracker',
        error: error,
        stackTrace: stack,
      );
    }
  }

  void _simulateRangeError() {
    try {
      // Simulate the type of RangeError we're seeing
      final list = [0, 1]; // Only indices 0 and 1
      final _ = list[2]; // Try to access index 2
    } catch (e, stack) {
      _captureError('Simulation', e, stack);
    }
  }

  void _clearLogs() {
    setState(() {
      _errorLogs.clear();
    });
  }

  void _copyLogs() {
    final allLogs = _errorLogs.join('\n\n');
    Clipboard.setData(ClipboardData(text: allLogs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RangeError Tracker'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Logs',
          ),
          IconButton(
            onPressed: _copyLogs,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Captured ${_errorLogs.length} RangeError(s). This tool will automatically capture any RangeError that occurs.',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _simulateRangeError,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _errorLogs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bug_report,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No RangeErrors captured yet.\nNavigate to solar_coach to trigger the error.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _errorLogs.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: SelectableText(
                          _errorLogs[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.red,
                            height: 1.3,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// Helper function to set up global error tracking
void setupGlobalRangeErrorTracking() {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('RangeError')) {
      dev.log(
        'Global RangeError: ${details.exception}',
        name: 'GlobalRangeErrorTracker',
        error: details.exception,
        stackTrace: details.stack,
      );
    }
    FlutterError.dumpErrorToConsole(details);
  };
}