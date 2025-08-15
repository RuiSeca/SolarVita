// Configuration data for Director Coach customization options
// Based on RIV analysis showing Timeline 1 base animation and comprehensive customization

class DirectorCoachConfig {
  // Eye customization - 10 options (eye 0 through eye 9)
  static const Map<int, String> eyeColors = {
    0: 'Brown Eyes',
    1: 'Blue Eyes', 
    2: 'Green Eyes',
    3: 'Hazel Eyes',
    4: 'Gray Eyes',
    5: 'Amber Eyes',
    6: 'Violet Eyes',
    7: 'Black Eyes',
    8: 'Red Eyes',
    9: 'Golden Eyes',
  };

  // Face expressions and variations
  static const Map<int, String> faces = {
    0: 'Neutral',
    1: 'Confident', 
    2: 'Determined',
    3: 'Friendly',
    4: 'Serious',
    5: 'Charismatic',
  };

  // Skin color variations
  static const Map<int, String> skinColors = {
    0: 'Fair',
    1: 'Light',
    2: 'Medium',
    3: 'Olive',
    4: 'Tan',
    5: 'Dark',
  };

  // Clothing and accessory toggles based on RIV inputs
  static const Map<String, String> clothingToggles = {
    'top_check': 'Director Jacket',
    'bottoms_check': 'Professional Pants', 
    'skirt_check': 'Director Skirt',
    'shoes_check': 'Professional Shoes',
    'hat_check': 'Director Cap',
  };

  // Accessories
  static const Map<String, String> accessories = {
    'earring_check': 'Earrings',
    'necklace_check': 'Director Chain',
    'glass_check': 'Director Glasses',
    'hair_check': 'Styled Hair',
    'back_check': 'Cape/Coat',
    'handobject_check': 'Megaphone',
  };

  // Animation states
  static const Map<int, String> actionStates = {
    0: 'Idle',
    1: 'Directing',
    2: 'Action Call',
    3: 'Cut Call',
  };

  // Sitting positions
  static const Map<int, String> sittingPositions = {
    0: 'Standing',
    1: 'Director Chair',
    2: 'Relaxed Pose',
  };

  // Flower/prop states (if applicable)
  static const Map<int, String> propStates = {
    0: 'No Props',
    1: 'Megaphone',
    2: 'Clapperboard', 
    3: 'Script',
  };

  // Default customization values
  static const Map<String, dynamic> defaults = {
    'eye_color': 1, // Blue eyes
    'face': 2, // Determined expression
    'skin_color': 2, // Medium skin
    'sit': 0, // Standing
    'stateaction': 0, // Idle
    'flower_state': 0, // No props
    'flower_check': false,
    'top_check': true, // Director jacket
    'bottoms_check': true, // Professional pants
    'skirt_check': false,
    'shoes_check': true, // Professional shoes
    'hat_check': false,
    'earring_check': false,
    'necklace_check': false,
    'glass_check': false,
    'hair_check': true, // Styled hair
    'back_check': false,
    'handobject_check': false,
    'home': false,
    'jumpright_check': false,
  };

  // Get display name for a customization option
  static String getDisplayName(String key, dynamic value) {
    switch (key) {
      case 'eye_color':
        return eyeColors[value as int] ?? 'Unknown';
      case 'face':
        return faces[value as int] ?? 'Unknown';
      case 'skin_color':
        return skinColors[value as int] ?? 'Unknown';
      case 'sit':
        return sittingPositions[value as int] ?? 'Unknown';
      case 'stateaction':
        return actionStates[value as int] ?? 'Unknown';
      case 'flower_state':
        return propStates[value as int] ?? 'Unknown';
      default:
        if (clothingToggles.containsKey(key)) {
          return clothingToggles[key]!;
        }
        if (accessories.containsKey(key)) {
          return accessories[key]!;
        }
        return key;
    }
  }

  // Get all customization categories
  static List<String> get customizationCategories => [
    'Appearance', // eye_color, face, skin_color
    'Clothing',   // top_check, bottoms_check, skirt_check, shoes_check, hat_check
    'Accessories', // earring_check, necklace_check, glass_check, hair_check, back_check, handobject_check
    'Pose',       // sit, stateaction
    'Props',      // flower_state, flower_check
  ];

  // Get customization options for a category
  static Map<String, dynamic> getOptionsForCategory(String category) {
    switch (category) {
      case 'Appearance':
        return {
          'eye_color': eyeColors,
          'face': faces,
          'skin_color': skinColors,
        };
      case 'Clothing':
        return clothingToggles;
      case 'Accessories':
        return accessories;
      case 'Pose':
        return {
          'sit': sittingPositions,
          'stateaction': actionStates,
        };
      case 'Props':
        return {
          'flower_state': propStates,
          'flower_check': 'Show Props',
        };
      default:
        return {};
    }
  }
}