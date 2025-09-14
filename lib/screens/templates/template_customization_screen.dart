import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/templates/workout_template.dart';
import '../../services/templates/workout_template_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class TemplateCustomizationScreen extends StatefulWidget {
  final WorkoutTemplate? baseTemplate;
  final bool isEditing;

  const TemplateCustomizationScreen({
    super.key,
    this.baseTemplate,
    this.isEditing = false,
  });

  @override
  State<TemplateCustomizationScreen> createState() => _TemplateCustomizationScreenState();
}

class _TemplateCustomizationScreenState extends State<TemplateCustomizationScreen> {
  final WorkoutTemplateService _templateService = WorkoutTemplateService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedDifficulty;
  late int _estimatedDuration;
  late List<String> _targetMuscles;
  late List<String> _equipment;
  late List<TemplateExercise> _exercises;
  
  final List<String> _availableCategories = [
    'strength',
    'cardio',
    'flexibility',
    'full_body',
    'hiit',
    'bodyweight'
  ];
  
  final List<String> _availableDifficulties = [
    'beginner',
    'intermediate',
    'advanced'
  ];
  
  final List<String> _availableMuscles = [
    'chest',
    'back',
    'shoulders',
    'biceps',
    'triceps',
    'legs',
    'glutes',
    'abs',
    'cardio'
  ];
  
  final List<String> _availableEquipment = [
    'none',
    'dumbbells',
    'barbell',
    'resistance_bands',
    'pull_up_bar',
    'kettlebell',
    'cable_machine'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromTemplate();
  }

  void _initializeFromTemplate() {
    if (widget.baseTemplate != null) {
      final template = widget.baseTemplate!;
      _nameController = TextEditingController(text: template.name);
      _descriptionController = TextEditingController(text: template.description);
      _selectedCategory = template.category;
      _selectedDifficulty = template.difficulty;
      _estimatedDuration = template.estimatedDuration;
      _targetMuscles = List.from(template.targetMuscles);
      _equipment = List.from(template.equipment);
      _exercises = template.exercises.map((e) => _copyExercise(e)).toList();
    } else {
      // Creating new template
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedCategory = 'strength';
      _selectedDifficulty = 'beginner';
      _estimatedDuration = 30;
      _targetMuscles = [];
      _equipment = ['none'];
      _exercises = [];
    }
  }

  TemplateExercise _copyExercise(TemplateExercise exercise) {
    return TemplateExercise(
      id: exercise.id,
      name: exercise.name,
      description: exercise.description,
      category: exercise.category,
      sets: exercise.sets.map((set) => TemplateSet(
        setNumber: set.setNumber,
        type: set.type,
        targetReps: set.targetReps,
        minReps: set.minReps,
        maxReps: set.maxReps,
        targetWeight: set.targetWeight,
        targetDistance: set.targetDistance,
        targetDuration: set.targetDuration,
        notes: set.notes,
      )).toList(),
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      videoUrl: exercise.videoUrl,
      imageUrl: exercise.imageUrl,
    );
  }

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) => _ExerciseDialog(
        onExerciseAdded: (exercise) {
          setState(() {
            _exercises.add(exercise);
          });
        },
      ),
    );
  }

  void _editExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => _ExerciseDialog(
        exercise: _exercises[index],
        onExerciseAdded: (exercise) {
          setState(() {
            _exercises[index] = exercise;
          });
        },
      ),
    );
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
    });
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate() || _exercises.isEmpty) {
      if (_exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'add_at_least_one_exercise')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final template = WorkoutTemplate(
      id: widget.isEditing ? widget.baseTemplate!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      estimatedDuration: _estimatedDuration,
      targetMuscles: _targetMuscles,
      equipment: _equipment,
      exercises: _exercises,
      isCustom: true,
      createdAt: widget.isEditing ? widget.baseTemplate!.createdAt : DateTime.now(),
    );

    bool success;
    if (widget.isEditing) {
      success = await _templateService.updateCustomTemplate(template);
    } else {
      success = await _templateService.saveCustomTemplate(template);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing 
              ? tr(context, 'template_updated') 
              : tr(context, 'template_saved')),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, template);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_saving_template')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        elevation: 0,
        title: Text(
          widget.isEditing ? tr(context, 'edit_template') : tr(context, 'create_template'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveTemplate,
            child: Text(
              tr(context, 'save'),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildTemplateSettings(),
              const SizedBox(height: 24),
              _buildTargetMuscles(),
              const SizedBox(height: 24),
              _buildEquipment(),
              const SizedBox(height: 24),
              _buildExercises(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'basic_information'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: tr(context, 'template_name'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return tr(context, 'please_enter_template_name');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: tr(context, 'description'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return tr(context, 'please_enter_description');
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'workout_settings'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: tr(context, 'category'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _availableCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(tr(context, category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDifficulty,
                  decoration: InputDecoration(
                    labelText: tr(context, 'difficulty'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _availableDifficulties.map((difficulty) {
                    return DropdownMenuItem(
                      value: difficulty,
                      child: Text(tr(context, difficulty)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDifficulty = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: TextEditingController(text: _estimatedDuration.toString()),
            decoration: InputDecoration(
              labelText: tr(context, 'estimated_duration_minutes'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              _estimatedDuration = int.tryParse(value) ?? 30;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTargetMuscles() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'target_muscles'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableMuscles.map((muscle) {
              final isSelected = _targetMuscles.contains(muscle);
              return FilterChip(
                label: Text(tr(context, muscle)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _targetMuscles.add(muscle);
                    } else {
                      _targetMuscles.remove(muscle);
                    }
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'equipment_needed'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableEquipment.map((equipment) {
              final isSelected = _equipment.contains(equipment);
              return FilterChip(
                label: Text(tr(context, equipment)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (!_equipment.contains(equipment)) {
                        _equipment.add(equipment);
                      }
                    } else {
                      _equipment.remove(equipment);
                    }
                    
                    // Ensure at least 'none' is selected if nothing else
                    if (_equipment.isEmpty) {
                      _equipment.add('none');
                    }
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExercises() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tr(context, 'exercises'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _addExercise,
                icon: Icon(
                  Icons.add,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_exercises.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: AppTheme.textColor(context).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'no_exercises_added'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'tap_add_to_start'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exercises.length,
              onReorder: _reorderExercises,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return Container(
                  key: ValueKey(exercise.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textColor(context).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.drag_handle,
                        color: AppTheme.textColor(context).withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${exercise.sets.length} ${tr(context, 'sets')}',
                              style: TextStyle(
                                color: AppTheme.textColor(context).withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _editExercise(index),
                        icon: Icon(
                          Icons.edit,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeExercise(index),
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _ExerciseDialog extends StatefulWidget {
  final TemplateExercise? exercise;
  final Function(TemplateExercise) onExerciseAdded;

  const _ExerciseDialog({
    this.exercise,
    required this.onExerciseAdded,
  });

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _restController;
  late String _selectedCategory;
  late List<TemplateSet> _sets;

  @override
  void initState() {
    super.initState();
    
    if (widget.exercise != null) {
      final exercise = widget.exercise!;
      _nameController = TextEditingController(text: exercise.name);
      _descriptionController = TextEditingController(text: exercise.description ?? '');
      _notesController = TextEditingController(text: exercise.notes ?? '');
      _restController = TextEditingController(
        text: exercise.restSeconds != null ? (exercise.restSeconds! ~/ 60).toString() : '');
      _selectedCategory = exercise.category;
      _sets = List.from(exercise.sets);
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _notesController = TextEditingController();
      _restController = TextEditingController(text: '2');
      _selectedCategory = 'strength';
      _sets = [
        TemplateSet(
          setNumber: 1,
          targetReps: 10,
          targetWeight: 0,
        ),
      ];
    }
  }

  void _addSet() {
    setState(() {
      _sets.add(TemplateSet(
        setNumber: _sets.length + 1,
        targetReps: _sets.isNotEmpty ? _sets.last.targetReps : 10,
        targetWeight: _sets.isNotEmpty ? _sets.last.targetWeight : 0,
      ));
    });
  }

  void _removeSet(int index) {
    if (_sets.length <= 1) return;
    setState(() {
      _sets.removeAt(index);
      // Renumber remaining sets
      for (int i = 0; i < _sets.length; i++) {
        _sets[i] = TemplateSet(
          setNumber: i + 1,
          type: _sets[i].type,
          targetReps: _sets[i].targetReps,
          minReps: _sets[i].minReps,
          maxReps: _sets[i].maxReps,
          targetWeight: _sets[i].targetWeight,
          targetDistance: _sets[i].targetDistance,
          targetDuration: _sets[i].targetDuration,
          notes: _sets[i].notes,
        );
      }
    });
  }

  void _saveExercise() {
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    final exercise = TemplateExercise(
      id: widget.exercise?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty 
        ? _descriptionController.text.trim() : null,
      category: _selectedCategory,
      sets: _sets,
      restSeconds: int.tryParse(_restController.text) != null 
        ? int.parse(_restController.text) * 60 : null,
      notes: _notesController.text.trim().isNotEmpty 
        ? _notesController.text.trim() : null,
    );

    widget.onExerciseAdded(exercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.exercise != null 
                  ? tr(context, 'edit_exercise')
                  : tr(context, 'add_exercise'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: tr(context, 'exercise_name'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: tr(context, 'description_optional'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: tr(context, 'category'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ['strength', 'cardio', 'flexibility'].map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(tr(context, category)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _restController,
                      decoration: InputDecoration(
                        labelText: tr(context, 'rest_minutes'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Text(
                    tr(context, 'sets'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _addSet,
                    icon: Icon(
                      Icons.add,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              
              ..._sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text('${index + 1}'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: set.targetWeight?.toString() ?? '0',
                          decoration: InputDecoration(
                            labelText: tr(context, 'weight'),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _sets[index] = TemplateSet(
                              setNumber: set.setNumber,
                              type: set.type,
                              targetReps: set.targetReps,
                              targetWeight: double.tryParse(value) ?? 0,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: set.targetReps?.toString() ?? '10',
                          decoration: InputDecoration(
                            labelText: tr(context, 'reps'),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _sets[index] = TemplateSet(
                              setNumber: set.setNumber,
                              type: set.type,
                              targetReps: int.tryParse(value) ?? 10,
                              targetWeight: set.targetWeight,
                            );
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: _sets.length > 1 ? () => _removeSet(index) : null,
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: tr(context, 'notes_optional'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr(context, 'cancel')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(tr(context, 'save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _restController.dispose();
    super.dispose();
  }
}