import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community/community_challenge.dart';
import '../../services/community/community_challenge_service.dart';
import '../../theme/app_theme.dart';

class AdminChallengeFormScreen extends ConsumerStatefulWidget {
  final CommunityChallenge? challenge;
  final bool isDuplicate;

  const AdminChallengeFormScreen({
    super.key,
    this.challenge,
    this.isDuplicate = false,
  });

  @override
  ConsumerState<AdminChallengeFormScreen> createState() => _AdminChallengeFormScreenState();
}

class _AdminChallengeFormScreenState extends ConsumerState<AdminChallengeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _unitController = TextEditingController();
  final _prizeController = TextEditingController();
  final _maxTeamSizeController = TextEditingController();
  final _maxTeamsController = TextEditingController();

  ChallengeType _selectedType = ChallengeType.sustainability;
  ChallengeMode _selectedMode = ChallengeMode.mixed;
  ChallengeStatus _selectedStatus = ChallengeStatus.upcoming;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isGlobal = true;
  bool _requiresPhoto = false;
  bool _allowTeams = true;
  bool _isSubmitting = false;

  final CommunityChallengeService _challengeService = CommunityChallengeService();

  @override
  void initState() {
    super.initState();
    if (widget.challenge != null) {
      _populateFromChallenge(widget.challenge!);
    } else {
      _setDefaults();
    }
  }

  void _populateFromChallenge(CommunityChallenge challenge) {
    _titleController.text = widget.isDuplicate ? '${challenge.title} (Copy)' : challenge.title;
    _descriptionController.text = challenge.description;
    _iconController.text = challenge.icon;
    _targetValueController.text = challenge.targetValue.toString();
    _unitController.text = challenge.unit;
    _prizeController.text = challenge.prize ?? '';
    _maxTeamSizeController.text = challenge.maxTeamSize?.toString() ?? '';
    _maxTeamsController.text = challenge.maxTeams?.toString() ?? '';

    _selectedType = challenge.type;
    _selectedMode = challenge.mode;
    _selectedStatus = widget.isDuplicate ? ChallengeStatus.upcoming : challenge.status;
    _startDate = widget.isDuplicate ? DateTime.now() : challenge.startDate;
    _endDate = widget.isDuplicate
        ? DateTime.now().add(const Duration(days: 7))
        : challenge.endDate;
    _allowTeams = challenge.acceptsTeams;
  }

  void _setDefaults() {
    _iconController.text = '🌱';
    _targetValueController.text = '1000';
    _unitController.text = 'participants';
    _maxTeamSizeController.text = '6';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          widget.challenge == null
              ? 'Create Challenge'
              : widget.isDuplicate
                  ? 'Duplicate Challenge'
                  : 'Edit Challenge',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveChallenge,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildChallengeTypeSection(),
            const SizedBox(height: 24),
            _buildTargetSection(),
            const SizedBox(height: 24),
            _buildDateSection(),
            const SizedBox(height: 24),
            _buildTeamSettingsSection(),
            const SizedBox(height: 24),
            _buildAdvancedSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.info_outline,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Challenge Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildChallengeTypeSection() {
    return _buildSection(
      title: 'Challenge Configuration',
      icon: Icons.settings,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ChallengeType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ChallengeType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getCategoryLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<ChallengeMode>(
                initialValue: _selectedMode,
                decoration: const InputDecoration(
                  labelText: 'Participation Mode',
                  border: OutlineInputBorder(),
                ),
                items: ChallengeMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(_getModeLabel(mode)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedMode = value!);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ChallengeStatus>(
          initialValue: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(),
          ),
          items: ChallengeStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(_getStatusLabel(status)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedStatus = value!);
          },
        ),
      ],
    );
  }

  Widget _buildTargetSection() {
    return _buildSection(
      title: 'Target & Rewards',
      icon: Icons.flag,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _targetValueController,
                decoration: const InputDecoration(
                  labelText: 'Target Value',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Must be a number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _prizeController,
          decoration: const InputDecoration(
            labelText: 'Prize/Reward (Optional)',
            border: OutlineInputBorder(),
            hintText: 'e.g., 100 coins, Special badge',
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return _buildSection(
      title: 'Schedule',
      icon: Icons.schedule,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(_startDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(_endDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Duration: ${_endDate.difference(_startDate).inDays} days',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSettingsSection() {
    return _buildSection(
      title: 'Team Settings',
      icon: Icons.group,
      children: [
        SwitchListTile(
          title: const Text('Allow Team Participation'),
          subtitle: const Text('Users can form teams for this challenge'),
          value: _allowTeams,
          onChanged: (value) {
            setState(() => _allowTeams = value);
          },
        ),
        if (_allowTeams) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _maxTeamSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Max Team Size',
                    border: OutlineInputBorder(),
                    hintText: '6',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null) {
                        return 'Must be a number';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _maxTeamsController,
                  decoration: const InputDecoration(
                    labelText: 'Max Teams (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Unlimited',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null) {
                        return 'Must be a number';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return _buildSection(
      title: 'Advanced Settings',
      icon: Icons.tune,
      children: [
        SwitchListTile(
          title: const Text('Global Challenge'),
          subtitle: const Text('Visible to all users worldwide'),
          value: _isGlobal,
          onChanged: (value) {
            setState(() => _isGlobal = value);
          },
        ),
        SwitchListTile(
          title: const Text('Requires Photo Verification'),
          subtitle: const Text('Users must submit photos to complete'),
          value: _requiresPhoto,
          onChanged: (value) {
            setState(() => _requiresPhoto = value);
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: AppTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          if (picked.isAfter(_startDate)) {
            _endDate = picked;
          }
        }
      });
    }
  }

  Future<void> _saveChallenge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final challenge = CommunityChallenge(
        id: widget.challenge?.id ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        mode: _selectedMode,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        targetValue: int.parse(_targetValueController.text),
        unit: _unitController.text,
        icon: _iconController.text,
        prize: _prizeController.text.isEmpty ? null : _prizeController.text,
        maxTeamSize: _maxTeamSizeController.text.isEmpty
            ? null
            : int.parse(_maxTeamSizeController.text),
        maxTeams: _maxTeamsController.text.isEmpty
            ? null
            : int.parse(_maxTeamsController.text),
      );

      await _challengeService.createChallenge(challenge);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.challenge == null
                  ? 'Challenge created successfully!'
                  : 'Challenge updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getCategoryLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.fitness:
        return 'Fitness';
      case ChallengeType.nutrition:
        return 'Nutrition';
      case ChallengeType.sustainability:
        return 'Sustainability';
      case ChallengeType.community:
        return 'Community';
    }
  }

  String _getModeLabel(ChallengeMode mode) {
    switch (mode) {
      case ChallengeMode.individual:
        return 'Individual Only';
      case ChallengeMode.team:
        return 'Team Only';
      case ChallengeMode.mixed:
        return 'Individual & Team';
    }
  }

  String _getStatusLabel(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.upcoming:
        return 'Draft';
      case ChallengeStatus.active:
        return 'Active';
      case ChallengeStatus.completed:
        return 'Completed';
      case ChallengeStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    _prizeController.dispose();
    _maxTeamSizeController.dispose();
    _maxTeamsController.dispose();
    super.dispose();
  }
}