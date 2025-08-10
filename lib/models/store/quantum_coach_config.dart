// Configuration data for Quantum Coach customization options
// Based on RIVE analysis showing 153 animations and comprehensive customization

class QuantumCoachConfig {
  // Eye customization - 13+ options (0-12+)
  static const List<EyeOption> eyeOptions = [
    EyeOption(id: 0, name: 'Default Eyes', description: 'Classic look'),
    EyeOption(id: 1, name: 'Bright Eyes', description: 'Vibrant and energetic'),
    EyeOption(id: 2, name: 'Mysterious Eyes', description: 'Deep and intriguing'),
    EyeOption(id: 3, name: 'Sparkling Eyes', description: 'Twinkling effect'),
    EyeOption(id: 4, name: 'Cool Eyes', description: 'Calm and collected'),
    EyeOption(id: 5, name: 'Warm Eyes', description: 'Friendly and inviting'),
    EyeOption(id: 6, name: 'Electric Eyes', description: 'High-energy look'),
    EyeOption(id: 7, name: 'Cosmic Eyes', description: 'Otherworldly appearance'),
    EyeOption(id: 8, name: 'Fire Eyes', description: 'Passionate and intense'),
    EyeOption(id: 9, name: 'Ice Eyes', description: 'Cool and crystalline'),
    EyeOption(id: 10, name: 'Devil Eyes', description: 'Mischievous look'),
    EyeOption(id: 11, name: 'Sea Salt Eyes', description: 'Ocean-inspired'),
    EyeOption(id: 12, name: 'Cowboy Eyes', description: 'Western style'),
  ];

  // Face expressions - 5+ options (0-4+)
  static const List<FaceOption> faceOptions = [
    FaceOption(id: 0, name: 'Neutral', description: 'Calm expression'),
    FaceOption(id: 1, name: 'Happy', description: 'Cheerful smile'),
    FaceOption(id: 2, name: 'Focused', description: 'Concentrated look'),
    FaceOption(id: 3, name: 'Confident', description: 'Self-assured expression'),
    FaceOption(id: 4, name: 'Playful', description: 'Fun and energetic'),
  ];

  // Skin tones - Multiple options
  static const List<SkinOption> skinOptions = [
    SkinOption(id: 0, name: 'Fair', description: 'Light skin tone'),
    SkinOption(id: 1, name: 'Medium', description: 'Medium skin tone'),
    SkinOption(id: 2, name: 'Olive', description: 'Olive skin tone'),
    SkinOption(id: 3, name: 'Tan', description: 'Tanned skin tone'),
    SkinOption(id: 4, name: 'Deep', description: 'Deep skin tone'),
  ];

  // Clothing items with triggers
  static const List<ClothingItem> clothingItems = [
    ClothingItem(
      category: ClothingCategory.tops,
      trigger: 'top_in',
      toggle: 'top_check',
      name: 'Shirts & Tops',
      description: 'Various shirt and top options',
      icon: '👕',
    ),
    ClothingItem(
      category: ClothingCategory.bottoms,
      trigger: 'pants_in',
      toggle: 'bottoms_check',
      name: 'Pants',
      description: 'Different pants styles',
      icon: '👖',
    ),
    ClothingItem(
      category: ClothingCategory.bottoms,
      trigger: 'skirt_in',
      toggle: 'skirt_check',
      name: 'Skirts',
      description: 'Various skirt options',
      icon: '👗',
    ),
    ClothingItem(
      category: ClothingCategory.footwear,
      trigger: 'shoes_in',
      toggle: 'shoes_check', // Added in RIVE editor
      name: 'Shoes',
      description: 'Different footwear styles',
      icon: '👟',
    ),
    ClothingItem(
      category: ClothingCategory.headwear,
      trigger: 'hat_in',
      toggle: 'hat_check', // Added in RIVE editor
      name: 'Hats',
      description: 'Head accessories and hats',
      icon: '🎩',
    ),
  ];

  // Accessories with triggers
  static const List<AccessoryItem> accessoryItems = [
    AccessoryItem(
      trigger: 'earring_in',
      toggle: 'earring_check', // Added in RIVE editor
      name: 'Earrings',
      description: 'Beautiful ear accessories',
      icon: '💎',
      category: AccessoryCategory.jewelry,
    ),
    AccessoryItem(
      trigger: 'necklace_in',
      toggle: 'necklace_check', // Added in RIVE editor
      name: 'Necklaces',
      description: 'Elegant neck jewelry',
      icon: '📿',
      category: AccessoryCategory.jewelry,
    ),
    AccessoryItem(
      trigger: 'glass_in',
      toggle: 'glass_check', // Added in RIVE editor
      name: 'Glasses',
      description: 'Stylish eyewear',
      icon: '🤓',
      category: AccessoryCategory.face,
    ),
    AccessoryItem(
      trigger: 'hair_in',
      toggle: 'hair_check', // Added in RIVE editor
      name: 'Hairstyles',
      description: 'Different hair options',
      icon: '💇',
      category: AccessoryCategory.hair,
    ),
    AccessoryItem(
      trigger: 'back_in',
      toggle: 'back_check', // Added in RIVE editor
      name: 'Back Accessories',
      description: 'Wings, capes, and back items',
      icon: '🦋',
      category: AccessoryCategory.back,
    ),
    AccessoryItem(
      trigger: 'Handobject_in',
      toggle: 'handobject_check', // Added in RIVE editor
      name: 'Handheld Items',
      description: 'Items to hold and carry',
      icon: '⚡',
      category: AccessoryCategory.handheld,
    ),
  ];

  // Interactive actions
  static const List<InteractiveAction> interactiveActions = [
    InteractiveAction(
      trigger: 'Act_Touch',
      name: 'Touch Response',
      description: 'Regular touch interaction',
      icon: '👆',
      category: ActionCategory.interaction,
    ),
    InteractiveAction(
      trigger: 'starAct_Touch',
      name: 'Special Touch',
      description: 'Special star touch effect',
      icon: '⭐',
      category: ActionCategory.interaction,
    ),
    InteractiveAction(
      trigger: 'Act_1',
      name: 'Action 1',
      description: 'Primary action animation',
      icon: '🎭',
      category: ActionCategory.animation,
    ),
    InteractiveAction(
      trigger: 'jump',
      name: 'Jump',
      description: 'Character jump animation',
      icon: '🦘',
      category: ActionCategory.movement,
    ),
    InteractiveAction(
      trigger: 'win',
      name: 'Victory',
      description: 'Celebration animation',
      icon: '🏆',
      category: ActionCategory.celebration,
    ),
  ];

  // State controls
  static const List<StateControl> stateControls = [
    StateControl(
      parameter: 'sit',
      name: 'Sitting Position',
      description: 'Different sitting poses (0-6)',
      min: 0,
      max: 6,
      icon: '🪑',
    ),
    StateControl(
      parameter: 'flower_state',
      name: 'Flower Effects',
      description: 'Flower animation states',
      min: 0,
      max: 7,
      icon: '🌸',
    ),
    StateControl(
      parameter: 'stateaction',
      name: 'State Action',
      description: 'Character state control',
      min: 0,
      max: 10,
      icon: '⚙️',
    ),
  ];
}

// Data classes
class EyeOption {
  final int id;
  final String name;
  final String description;

  const EyeOption({
    required this.id,
    required this.name,
    required this.description,
  });
}

class FaceOption {
  final int id;
  final String name;
  final String description;

  const FaceOption({
    required this.id,
    required this.name,
    required this.description,
  });
}

class SkinOption {
  final int id;
  final String name;
  final String description;

  const SkinOption({
    required this.id,
    required this.name,
    required this.description,
  });
}

class ClothingItem {
  final ClothingCategory category;
  final String trigger;
  final String? toggle;
  final String name;
  final String description;
  final String icon;

  const ClothingItem({
    required this.category,
    required this.trigger,
    this.toggle,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class AccessoryItem {
  final String trigger;
  final String? toggle;
  final String name;
  final String description;
  final String icon;
  final AccessoryCategory category;

  const AccessoryItem({
    required this.trigger,
    this.toggle,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
  });
}

class InteractiveAction {
  final String trigger;
  final String name;
  final String description;
  final String icon;
  final ActionCategory category;

  const InteractiveAction({
    required this.trigger,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
  });
}

class StateControl {
  final String parameter;
  final String name;
  final String description;
  final double min;
  final double max;
  final String icon;

  const StateControl({
    required this.parameter,
    required this.name,
    required this.description,
    required this.min,
    required this.max,
    required this.icon,
  });
}

// Enums
enum ClothingCategory { tops, bottoms, footwear, headwear }
enum AccessoryCategory { jewelry, face, hair, back, handheld }
enum ActionCategory { interaction, animation, movement, celebration }