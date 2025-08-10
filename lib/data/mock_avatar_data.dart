import '../models/store/avatar_item.dart';

class MockAvatarData {
  static List<AvatarItem> getAvatarItems() {
    return [
      const AvatarItem(
        id: 'classic_coach',
        name: 'Classic Coach',
        description: 'The original AI fitness coach with a friendly demeanor',
        rivAssetPath: 'assets/avatars/classic_coach.riv',
        previewImagePath: '', // No preview image for mock data
        cost: 0,
        coinType: CoinType.streakCoin,
        accessType: AvatarAccessType.free,
        category: AvatarCategory.skins,
        isUnlocked: true,
        isEquipped: true,
        rarity: 1,
        tags: ['default', 'friendly', 'classic'],
      ),
      const AvatarItem(
        id: 'neon_runner',
        name: 'Neon Runner',
        description: 'A futuristic coach with glowing neon accents',
        rivAssetPath: 'assets/avatars/neon_runner.riv',
        previewImagePath: '', // No preview image for mock data
        cost: 50,
        coinType: CoinType.streakCoin,
        accessType: AvatarAccessType.free,
        category: AvatarCategory.skins,
        rarity: 2,
        tags: ['futuristic', 'neon', 'runner'],
      ),
      const AvatarItem(
        id: 'zen_master',
        name: 'Zen Master',
        description: 'A calm and peaceful coach for meditation and mindfulness',
        rivAssetPath: 'assets/avatars/zen_master.riv',
        previewImagePath: '', // No preview image for mock data
        cost: 100,
        coinType: CoinType.coachPoints,
        accessType: AvatarAccessType.free,
        category: AvatarCategory.skins,
        rarity: 3,
        tags: ['zen', 'peaceful', 'meditation'],
      ),
      const AvatarItem(
        id: 'galaxy_warrior',
        name: 'Galaxy Warrior',
        description: 'An interstellar fitness coach from distant worlds',
        rivAssetPath: 'assets/avatars/galaxy_warrior.riv',
        previewImagePath: '', // No preview image for mock data
        cost: 200,
        coinType: CoinType.fitGems,
        accessType: AvatarAccessType.paid,
        category: AvatarCategory.skins,
        rarity: 4,
        tags: ['galaxy', 'warrior', 'space'],
      ),
      const AvatarItem(
        id: 'elite_trainer',
        name: 'Elite Trainer',
        description: 'Exclusive coach available only to premium members',
        rivAssetPath: 'assets/avatars/elite_trainer.riv',
        previewImagePath: '', // No preview image for mock data
        cost: 0,
        coinType: CoinType.streakCoin,
        accessType: AvatarAccessType.member,
        category: AvatarCategory.skins,
        rarity: 5,
        tags: ['elite', 'exclusive', 'premium'],
      ),
      const AvatarItem(
        id: 'victory_skin',
        name: 'Victory Skin',
        description: 'Special animated skin for celebrating achievements',
        rivAssetPath: 'assets/avatars/skins/victory_skin.riv',
        previewImagePath: '', // No preview image for mock data
        cost: 75,
        coinType: CoinType.coachPoints,
        accessType: AvatarAccessType.free,
        category: AvatarCategory.skins,
        rarity: 2,
        tags: ['victory', 'animated', 'skin'],
      ),
      // Mummy Skin - New Test Skin
      const AvatarItem(
        id: 'mummy_coach',
        name: 'Mummy Coach',
        description:
            'Ancient Egyptian mummy fitness coach with mystical powers',
        rivAssetPath: 'assets/rive/mummy.riv',
        previewImagePath: '', // No preview image for mock data
        cost: 0,
        coinType: CoinType.streakCoin,
        accessType: AvatarAccessType.free,
        category: AvatarCategory.skins,
        isUnlocked: true,
        rarity: 3,
        tags: ['mummy', 'ancient', 'mystical', 'free'],
        animations: ['attack', 'run', 'jump'], // Available animations
      ),
      const AvatarItem(
        id: 'cyber_ninja',
        name: 'Cyber Ninja',
        description: 'Stealthy digital warrior focused on agility training',
        rivAssetPath: 'assets/avatars/cyber_ninja.riv',
        previewImagePath: '', // No preview image for mock data
        cost: 150,
        coinType: CoinType.fitGems,
        accessType: AvatarAccessType.paid,
        category: AvatarCategory.skins,
        rarity: 4,
        tags: ['cyber', 'ninja', 'agility'],
      ),
      const AvatarItem(
        id: 'solar_guardian',
        name: 'Solar Guardian',
        description: 'Protector of sustainable fitness powered by solar energy',
        rivAssetPath: 'assets/avatars/solar_guardian.riv',
        previewImagePath: '', // No preview image for mock data
        cost: 300,
        coinType: CoinType.coachPoints,
        accessType: AvatarAccessType.member,
        category: AvatarCategory.skins,
        rarity: 5,
        tags: ['solar', 'guardian', 'eco'],
      ),
      const AvatarItem(
        id: 'quantum_coach',
        name: 'Quantum Coach',
        description:
            'Advanced AI from the future with quantum-enhanced training capabilities',
        rivAssetPath: 'assets/rive/quantum_coach.riv',
        previewImagePath: '', // No preview image for mock data
        cost: 0, // Free for testing
        coinType: CoinType.fitGems,
        accessType: AvatarAccessType.free, // Made free for testing
        category: AvatarCategory.skins,
        isUnlocked: true, // Unlocked by default
        rarity: 5,
        tags: ['quantum', 'future', 'advanced', 'customizable'],
        animations: ['Idle', 'Jump', 'Run', 'Attack', 'Teleport'], // Available animations
      ),
    ];
  }
}
