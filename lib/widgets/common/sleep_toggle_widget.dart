import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/translation_helper.dart';

enum SleepState {
  awake,           // Default awake state, ready to log bedtime
  sleeping,        // Bedtime logged, waiting for wake time
  readyToWake,     // Showing sleep duration, can wake up
}

class SleepToggleWidget extends StatefulWidget {
  final Function(double sleepHours)? onSleepUpdated;
  final double width;
  final double height;

  const SleepToggleWidget({
    super.key,
    this.onSleepUpdated,
    this.width = 50,
    this.height = 50,
  });

  @override
  State<SleepToggleWidget> createState() => _SleepToggleWidgetState();
}

class _SleepToggleWidgetState extends State<SleepToggleWidget> {
  Artboard? _artboard;
  StateMachineController? _controller;
  SMITrigger? _clickTrigger;
  
  SleepState _currentState = SleepState.awake;
  DateTime? _bedtime;
  DateTime? _wakeTime;
  double _sleepHours = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSleepState();
    _loadRiveAsset();
  }

  Future<void> _loadSleepState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateString(DateTime.now());
    final sleepDate = prefs.getString('sleep_date') ?? '';
    
    // Reset if it's a new day
    if (sleepDate != today) {
      await _resetSleepData();
      return;
    }
    
    // Load existing data
    final bedtimeStr = prefs.getString('sleep_bedtime');
    final waketimeStr = prefs.getString('sleep_waketime');
    final sleepHours = prefs.getDouble('sleep_duration') ?? 0.0;
    
    if (bedtimeStr != null) {
      _bedtime = DateTime.parse(bedtimeStr);
      
      if (waketimeStr != null) {
        _wakeTime = DateTime.parse(waketimeStr);
        _sleepHours = sleepHours;
        _currentState = SleepState.readyToWake;
      } else {
        _currentState = SleepState.sleeping;
      }
    } else {
      _currentState = SleepState.awake;
    }
    
    if (mounted) setState(() {});
  }

  Future<void> _loadRiveAsset() async {
    final file = await RiveFile.asset('assets/rive/sleep_toggle.riv');
    final artboard = file.mainArtboard;
    
    var controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (controller != null) {
      artboard.addController(controller);
      _clickTrigger = controller.findInput<bool>('Click') as SMITrigger?;
    }
    
    setState(() {
      _artboard = artboard;
      _controller = controller;
    });
    
    // Set initial state
    _updateRiveState();
  }

  void _updateRiveState() {
    if (_controller == null) return;
    
    // For awake state, don't trigger anything - let it stay in default state
    // Only trigger for non-default states
    switch (_currentState) {
      case SleepState.awake:
        // Default awake state - don't trigger, stay in initial state
        break;
      case SleepState.sleeping:
        // Trigger once to go to sleeping state
        _clickTrigger?.fire();
        break;
      case SleepState.readyToWake:
        // Trigger twice to go to final state
        _clickTrigger?.fire();
        Future.delayed(const Duration(milliseconds: 100), () {
          _clickTrigger?.fire();
        });
        break;
    }
  }

  Future<void> _onSleepToggleTapped() async {
    switch (_currentState) {
      case SleepState.awake:
        await _showBedtimePicker();
        break;
      case SleepState.sleeping:
        await _showWakeTimePicker();
        break;
      case SleepState.readyToWake:
        await _showEditSleepDialog();
        break;
    }
  }

  Future<void> _showBedtimePicker() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 22, minute: 30),
      helpText: tr(context, 'select_bedtime'),
    );
    
    if (time != null) {
      final now = DateTime.now();
      _bedtime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      
      await _saveBedtime();
      _currentState = SleepState.sleeping;
      _clickTrigger?.fire();
      setState(() {});
    }
  }

  Future<void> _showWakeTimePicker() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 7, minute: 0),
      helpText: tr(context, 'select_wake_time'),
    );
    
    if (time != null && _bedtime != null) {
      final bedtimeDate = DateTime(_bedtime!.year, _bedtime!.month, _bedtime!.day);
      var wakeDate = bedtimeDate;
      
      // If wake time is before bedtime, assume it's next day
      if (time.hour < _bedtime!.hour || 
          (time.hour == _bedtime!.hour && time.minute <= _bedtime!.minute)) {
        wakeDate = bedtimeDate.add(const Duration(days: 1));
      }
      
      _wakeTime = DateTime(wakeDate.year, wakeDate.month, wakeDate.day, time.hour, time.minute);
      
      await _calculateAndSaveSleep();
      _currentState = SleepState.readyToWake;
      _clickTrigger?.fire();
      setState(() {});
    }
  }

  Future<void> _showEditSleepDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'edit_sleep_times')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bedtime),
              title: Text(tr(context, 'bedtime')),
              subtitle: Text(_formatTime(_bedtime!)),
              onTap: () async {
                Navigator.pop(context);
                await _editBedtime();
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny),
              title: Text(tr(context, 'wake_time')),
              subtitle: Text(_formatTime(_wakeTime!)),
              onTap: () async {
                Navigator.pop(context);
                await _editWakeTime();
              },
            ),
            const SizedBox(height: 16),
            Text(
              '${tr(context, 'sleep_duration')}: ${_sleepHours.toStringAsFixed(1)}h',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'done')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSleepData();
            },
            child: Text(tr(context, 'reset')),
          ),
        ],
      ),
    );
  }

  Future<void> _editBedtime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_bedtime!),
      helpText: tr(context, 'select_bedtime'),
    );
    
    if (time != null) {
      _bedtime = DateTime(_bedtime!.year, _bedtime!.month, _bedtime!.day, time.hour, time.minute);
      await _saveBedtime();
      if (_wakeTime != null) {
        await _calculateAndSaveSleep();
      }
      setState(() {});
    }
  }

  Future<void> _editWakeTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_wakeTime!),
      helpText: tr(context, 'select_wake_time'),
    );
    
    if (time != null && _bedtime != null) {
      final bedtimeDate = DateTime(_bedtime!.year, _bedtime!.month, _bedtime!.day);
      var wakeDate = bedtimeDate;
      
      // If wake time is before bedtime, assume it's next day
      if (time.hour < _bedtime!.hour || 
          (time.hour == _bedtime!.hour && time.minute <= _bedtime!.minute)) {
        wakeDate = bedtimeDate.add(const Duration(days: 1));
      }
      
      _wakeTime = DateTime(wakeDate.year, wakeDate.month, wakeDate.day, time.hour, time.minute);
      await _calculateAndSaveSleep();
      setState(() {});
    }
  }

  Future<void> _saveBedtime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sleep_bedtime', _bedtime!.toIso8601String());
    await prefs.setString('sleep_date', _getDateString(_bedtime!));
  }

  Future<void> _calculateAndSaveSleep() async {
    if (_bedtime == null || _wakeTime == null) return;
    
    final duration = _wakeTime!.difference(_bedtime!);
    _sleepHours = duration.inMinutes / 60.0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sleep_waketime', _wakeTime!.toIso8601String());
    await prefs.setDouble('sleep_duration', _sleepHours);
    
    // Notify parent widget
    widget.onSleepUpdated?.call(_sleepHours);
  }

  Future<void> _resetSleepData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sleep_bedtime');
    await prefs.remove('sleep_waketime');
    await prefs.remove('sleep_duration');
    await prefs.remove('sleep_date');
    
    _bedtime = null;
    _wakeTime = null;
    _sleepHours = 0.0;
    _currentState = SleepState.awake;
    
    // Reset Rive animation to default state
    // Don't call _updateRiveState() as we want to stay in the default awake state
    
    widget.onSleepUpdated?.call(0.0);
    setState(() {});
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  double get sleepHours => _sleepHours;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onSleepToggleTapped,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _artboard != null
            ? Rive(artboard: _artboard!)
            : Icon(
                Icons.bedtime,
                color: Colors.indigo,
                size: widget.width * 0.5,
              ),
      ),
    );
  }
}