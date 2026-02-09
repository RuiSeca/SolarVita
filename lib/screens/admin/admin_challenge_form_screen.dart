import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final _maxTeamSizeController = TextEditingController();
  final _maxTeamsController = TextEditingController();

  // Community Goal Controllers
  final _communityGoalController = TextEditingController();
  final _communityUnitController = TextEditingController();
  final _minimumRequirementController = TextEditingController();

  // Prize Controllers
  final _communityPrizeController = TextEditingController();
  final List<TextEditingController> _individualPrizeControllers = [];
  final List<TextEditingController> _teamPrizeControllers = [];

  File? _selectedImage;
  String? _imageUrl;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  ChallengeType _selectedType = ChallengeType.sustainability;
  ChallengeMode _selectedMode = ChallengeMode.mixed;
  ChallengeStatus _selectedStatus = ChallengeStatus.upcoming;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isGlobal = true;
  bool _requiresPhoto = false;
  bool _allowTeams = true;
  bool _isSubmitting = false;
  bool _communityGoalRequired = true;
  PrizeTier _individualPrizeTier = PrizeTier.top5;
  PrizeTier _teamPrizeTier = PrizeTier.top5;

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
    _targetValueController.text = '1000';  // Legacy field - not used in new model
    _unitController.text = 'legacy';       // Legacy field - not used in new model
    _maxTeamSizeController.text = challenge.maxTeamSize?.toString() ?? '';
    _maxTeamsController.text = challenge.maxTeams?.toString() ?? '';

    // Community Goal
    _communityGoalController.text = challenge.communityGoal.targetValue.toString();
    _communityUnitController.text = challenge.communityGoal.unit;
    _minimumRequirementController.text = challenge.prizeConfiguration.minimumIndividualRequirement.toString();

    // Prizes
    _communityPrizeController.text = challenge.prizeConfiguration.communityPrize ?? '';
    _individualPrizeTier = challenge.prizeConfiguration.individualPrizeTier;
    _teamPrizeTier = challenge.prizeConfiguration.teamPrizeTier;
    _communityGoalRequired = challenge.prizeConfiguration.communityGoalRequired;

    _selectedType = challenge.type;
    _selectedMode = challenge.mode;
    _selectedStatus = widget.isDuplicate ? ChallengeStatus.upcoming : challenge.status;
    _startDate = widget.isDuplicate ? DateTime.now() : challenge.startDate;
    _endDate = widget.isDuplicate
        ? DateTime.now().add(const Duration(days: 7))
        : challenge.endDate;
    _allowTeams = challenge.acceptsTeams;
    _imageUrl = challenge.imageUrl;

    _initializePrizeControllers();
  }

  void _setDefaults() {
    _iconController.text = '🌱';
    _targetValueController.text = '1000';
    _unitController.text = 'participants';
    _maxTeamSizeController.text = '6';

    // Community Goal defaults
    _communityGoalController.text = '1000';
    _communityUnitController.text = 'bottles';
    _minimumRequirementController.text = '1';

    // Prize defaults
    _communityPrizeController.text = '50 coins';

    _initializePrizeControllers();
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
            onPressed: (_isSubmitting || _isUploadingImage) ? null : _saveChallenge,
            child: (_isSubmitting || _isUploadingImage)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isUploadingImage ? 'Uploading...' : 'Saving...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
            _buildImageSection(),
            const SizedBox(height: 24),
            _buildChallengeTypeSection(),
            const SizedBox(height: 24),
            _buildCommunityGoalSection(),
            const SizedBox(height: 24),
            _buildPrizeSystemSection(),
            const SizedBox(height: 24),
            _buildDateSection(),
            const SizedBox(height: 24),
            _buildTeamSettingsSection(),
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

  Widget _buildImageSection() {
    return _buildSection(
      title: 'Challenge Image',
      icon: Icons.image,
      children: [
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : _imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                      )
                    : _buildImagePlaceholder(),
          ),
        ),
        if (_selectedImage != null || _imageUrl != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (_selectedImage != null || _imageUrl != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _imageUrl = null;
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                ),
              const Spacer(),
              if (_selectedImage != null)
                Text(
                  'Image selected - will be uploaded on save',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to add challenge image',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recommended: 16:9 aspect ratio',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
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
                value: _selectedType,
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
                value: _selectedMode,
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
          value: _selectedStatus,
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

  Widget _buildCommunityGoalSection() {
    return _buildSection(
      title: 'Community Goal',
      icon: Icons.emoji_events,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _communityGoalController,
                decoration: const InputDecoration(
                  labelText: 'Community Target',
                  border: OutlineInputBorder(),
                  hintText: '1000',
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
                controller: _communityUnitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                  hintText: 'bottles, steps, etc.',
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
          controller: _minimumRequirementController,
          decoration: const InputDecoration(
            labelText: 'Minimum Per Person',
            border: OutlineInputBorder(),
            hintText: 'Minimum each participant must contribute',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            if (int.tryParse(value) == null || int.parse(value) < 1) {
              return 'Must be at least 1';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Community Goal Required'),
          subtitle: const Text('Must reach community goal for prizes'),
          value: _communityGoalRequired,
          onChanged: (value) {
            setState(() => _communityGoalRequired = value);
          },
        ),
      ],
    );
  }

  Widget _buildPrizeSystemSection() {
    return _buildSection(
      title: 'Prize System',
      icon: Icons.card_giftcard,
      children: [
        // Community Prize
        TextFormField(
          controller: _communityPrizeController,
          decoration: const InputDecoration(
            labelText: 'Community Prize (For Everyone)',
            border: OutlineInputBorder(),
            hintText: 'e.g., 50 coins, Special badge',
          ),
        ),
        const SizedBox(height: 16),

        // Individual Prize Tier
        Row(
          children: [
            Expanded(
              child: Text(
                'Individual Leaderboard',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DropdownButton<PrizeTier>(
              value: _individualPrizeTier,
              items: PrizeTier.values.map((tier) {
                return DropdownMenuItem(
                  value: tier,
                  child: Text(_getPrizeTierLabel(tier)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _individualPrizeTier = value!;
                  _initializePrizeControllers();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildIndividualPrizeFields(),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        // Team Prize Tier
        if (_allowTeams) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Team Leaderboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DropdownButton<PrizeTier>(
                value: _teamPrizeTier,
                items: PrizeTier.values.map((tier) {
                  return DropdownMenuItem(
                    value: tier,
                    child: Text(_getPrizeTierLabel(tier)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _teamPrizeTier = value!;
                    _initializePrizeControllers();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildTeamPrizeFields(),
        ],
      ],
    );
  }

  void _initializePrizeControllers() {
    // Clear existing controllers
    for (var controller in _individualPrizeControllers) {
      controller.dispose();
    }
    for (var controller in _teamPrizeControllers) {
      controller.dispose();
    }

    _individualPrizeControllers.clear();
    _teamPrizeControllers.clear();

    // Initialize individual prize controllers
    final individualCount = _getPrizeTierCount(_individualPrizeTier);
    for (int i = 0; i < individualCount; i++) {
      _individualPrizeControllers.add(TextEditingController());
    }

    // Initialize team prize controllers
    final teamCount = _getPrizeTierCount(_teamPrizeTier);
    for (int i = 0; i < teamCount; i++) {
      _teamPrizeControllers.add(TextEditingController());
    }
  }

  List<Widget> _buildIndividualPrizeFields() {
    return _individualPrizeControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '${_getPositionLabel(index + 1)} Place Prize',
            border: const OutlineInputBorder(),
            hintText: 'e.g., 100 coins, Gold badge',
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTeamPrizeFields() {
    return _teamPrizeControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '${_getPositionLabel(index + 1)} Place Team Prize',
            border: const OutlineInputBorder(),
            hintText: 'e.g., 500 coins for team, Team badge',
          ),
        ),
      );
    }).toList();
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
      // Upload image if selected
      if (_selectedImage != null) {
        _imageUrl = await _uploadImage(_selectedImage!);
      }
      // Create community goal
      final communityGoal = CommunityGoal(
        targetValue: int.parse(_communityGoalController.text),
        unit: _communityUnitController.text,
        currentProgress: 0,
        isReached: false,
      );

      // Create prize configuration
      final prizeConfiguration = PrizeConfiguration(
        communityPrize: _communityPrizeController.text.isEmpty ? null : _communityPrizeController.text,
        minimumIndividualRequirement: int.parse(_minimumRequirementController.text),
        individualPrizeTier: _individualPrizeTier,
        individualPrizes: _individualPrizeControllers.map((c) => c.text).where((text) => text.isNotEmpty).toList(),
        teamPrizeTier: _teamPrizeTier,
        teamPrizes: _teamPrizeControllers.map((c) => c.text).where((text) => text.isNotEmpty).toList(),
        communityGoalRequired: _communityGoalRequired,
      );

      final challenge = CommunityChallenge(
        id: widget.challenge?.id ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        mode: _selectedMode,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        icon: _iconController.text,
        imageUrl: _imageUrl,
        maxTeamSize: _maxTeamSizeController.text.isEmpty
            ? null
            : int.parse(_maxTeamSizeController.text),
        maxTeams: _maxTeamsController.text.isEmpty
            ? null
            : int.parse(_maxTeamsController.text),
        communityGoal: communityGoal,
        prizeConfiguration: prizeConfiguration,
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    setState(() => _isUploadingImage = true);

    try {
      final String fileName = 'challenge_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('challenges')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  String _getPrizeTierLabel(PrizeTier tier) {
    switch (tier) {
      case PrizeTier.top3:
        return 'Top 3';
      case PrizeTier.top5:
        return 'Top 5';
      case PrizeTier.top10:
        return 'Top 10';
      case PrizeTier.top15:
        return 'Top 15';
      case PrizeTier.top20:
        return 'Top 20';
    }
  }

  int _getPrizeTierCount(PrizeTier tier) {
    switch (tier) {
      case PrizeTier.top3:
        return 3;
      case PrizeTier.top5:
        return 5;
      case PrizeTier.top10:
        return 10;
      case PrizeTier.top15:
        return 15;
      case PrizeTier.top20:
        return 20;
    }
  }

  String _getPositionLabel(int position) {
    switch (position) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${position}th';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    _maxTeamSizeController.dispose();
    _maxTeamsController.dispose();

    // Community Goal Controllers
    _communityGoalController.dispose();
    _communityUnitController.dispose();
    _minimumRequirementController.dispose();

    // Prize Controllers
    _communityPrizeController.dispose();
    for (var controller in _individualPrizeControllers) {
      controller.dispose();
    }
    for (var controller in _teamPrizeControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}