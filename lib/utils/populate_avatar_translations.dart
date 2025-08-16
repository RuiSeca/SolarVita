import 'package:logging/logging.dart';
import '../services/translation/firebase_translation_service.dart';

final log = Logger('PopulateAvatarTranslations');

/// Utility to populate Firebase with avatar translations
/// This script should be run once to seed the database with localized avatar data
class AvatarTranslationPopulator {
  final FirebaseTranslationService _translationService;

  AvatarTranslationPopulator(this._translationService);

  /// Populate all avatar translations
  Future<void> populateAllAvatarTranslations() async {
    log.info('🌐 Starting avatar translation population...');

    try {
      // Avatar translations data
      final avatarTranslations = {
        'mummy_coach': {
          'en': LocalizedAvatarData(
            name: 'Mummy Coach',
            description: 'Ancient Egyptian mummy fitness coach with mystical powers',
            personality: 'Mysterious and wise',
            speciality: 'Ancient fitness techniques',
          ),
          'de': LocalizedAvatarData(
            name: 'Mumien-Trainer',
            description: 'Alter ägyptischer Mumien-Fitness-Trainer mit mystischen Kräften',
            personality: 'Mysteriös und weise',
            speciality: 'Alte Fitness-Techniken',
          ),
          'es': LocalizedAvatarData(
            name: 'Entrenador Momia',
            description: 'Entrenador de fitness momia egipcia antigua con poderes místicos',
            personality: 'Misterioso y sabio',
            speciality: 'Técnicas de fitness antiguas',
          ),
          'fr': LocalizedAvatarData(
            name: 'Coach Momie',
            description: 'Coach fitness momie égyptienne ancienne avec des pouvoirs mystiques',
            personality: 'Mystérieux et sage',
            speciality: 'Techniques de fitness anciennes',
          ),
          'hi': LocalizedAvatarData(
            name: 'मम्मी कोच',
            description: 'रहस्यमय शक्तियों वाला प्राचीन मिस्री मम्मी फिटनेस कोच',
            personality: 'रहस्यमय और बुद्धिमान',
            speciality: 'प्राचीन फिटनेस तकनीकें',
          ),
          'it': LocalizedAvatarData(
            name: 'Allenatore Mummia',
            description: 'Allenatore di fitness mummia egizia antica con poteri mistici',
            personality: 'Misterioso e saggio',
            speciality: 'Tecniche di fitness antiche',
          ),
          'ja': LocalizedAvatarData(
            name: 'ミイラコーチ',
            description: '神秘的な力を持つ古代エジプトのミイラフィットネスコーチ',
            personality: '神秘的で賢明',
            speciality: '古代のフィットネス技術',
          ),
          'ko': LocalizedAvatarData(
            name: '미라 코치',
            description: '신비한 힘을 가진 고대 이집트 미라 피트니스 코치',
            personality: '신비롭고 지혜로운',
            speciality: '고대 피트니스 기법',
          ),
          'pt': LocalizedAvatarData(
            name: 'Treinador Múmia',
            description: 'Treinador de fitness múmia egípcia antiga com poderes místicos',
            personality: 'Misterioso e sábio',
            speciality: 'Técnicas de fitness antigas',
          ),
          'ru': LocalizedAvatarData(
            name: 'Тренер Мумия',
            description: 'Древнеегипетский фитнес тренер мумия с мистическими силами',
            personality: 'Загадочный и мудрый',
            speciality: 'Древние фитнес техники',
          ),
          'zh': LocalizedAvatarData(
            name: '木乃伊教练',
            description: '具有神秘力量的古埃及木乃伊健身教练',
            personality: '神秘且睿智',
            speciality: '古代健身技巧',
          ),
        },
        'quantum_coach': {
          'en': LocalizedAvatarData(
            name: 'Quantum Coach',
            description: 'Advanced AI from the future with quantum-enhanced training',
            personality: 'Analytical and futuristic',
            speciality: 'Scientific training methods',
          ),
          'de': LocalizedAvatarData(
            name: 'Quantum-Trainer',
            description: 'Fortgeschrittene KI aus der Zukunft mit quantum-verbessertem Training',
            personality: 'Analytisch und futuristisch',
            speciality: 'Wissenschaftliche Trainingsmethoden',
          ),
          'es': LocalizedAvatarData(
            name: 'Entrenador Cuántico',
            description: 'IA avanzada del futuro con entrenamiento mejorado cuánticamente',
            personality: 'Analítico y futurista',
            speciality: 'Métodos de entrenamiento científicos',
          ),
          'fr': LocalizedAvatarData(
            name: 'Coach Quantique',
            description: 'IA avancée du futur avec entraînement amélioré quantiquement',
            personality: 'Analytique et futuriste',
            speciality: 'Méthodes d\'entraînement scientifiques',
          ),
          'hi': LocalizedAvatarData(
            name: 'क्वांटम कोच',
            description: 'क्वांटम-संवर्धित प्रशिक्षण के साथ भविष्य का उन्नत AI',
            personality: 'विश्लेषणात्मक और भविष्यवादी',
            speciality: 'वैज्ञानिक प्रशिक्षण विधियां',
          ),
          'it': LocalizedAvatarData(
            name: 'Allenatore Quantico',
            description: 'IA avanzata dal futuro con allenamento potenziato quantisticamente',
            personality: 'Analitico e futuristico',
            speciality: 'Metodi di allenamento scientifici',
          ),
          'ja': LocalizedAvatarData(
            name: 'クアンタムコーチ',
            description: '量子強化トレーニングを持つ未来の先進AI',
            personality: '分析的で未来的',
            speciality: '科学的トレーニング方法',
          ),
          'ko': LocalizedAvatarData(
            name: '퀀텀 코치',
            description: '양자 강화 트레이닝을 갖춘 미래의 고급 AI',
            personality: '분석적이고 미래지향적',
            speciality: '과학적 트레이닝 방법',
          ),
          'pt': LocalizedAvatarData(
            name: 'Treinador Quântico',
            description: 'IA avançada do futuro com treinamento aprimorado quanticamente',
            personality: 'Analítico e futurista',
            speciality: 'Métodos de treinamento científicos',
          ),
          'ru': LocalizedAvatarData(
            name: 'Квантовый Тренер',
            description: 'Продвинутый ИИ из будущего с квантово-улучшенными тренировками',
            personality: 'Аналитический и футуристический',
            speciality: 'Научные методы тренировок',
          ),
          'zh': LocalizedAvatarData(
            name: '量子教练',
            description: '来自未来的先进AI，具有量子增强训练',
            personality: '分析性和未来主义',
            speciality: '科学训练方法',
          ),
        },
        'director_coach': {
          'en': LocalizedAvatarData(
            name: 'Director Coach',
            description: 'Charismatic fitness director with Hollywood style. Commands your workout like an epic movie scene.',
            personality: 'Charismatic and dramatic',
            speciality: 'Cinematic fitness experiences',
          ),
          'de': LocalizedAvatarData(
            name: 'Regisseur-Trainer',
            description: 'Charismatischer Fitness-Regisseur mit Hollywood-Stil. Leitet dein Workout wie eine epische Filmszene.',
            personality: 'Charismatisch und dramatisch',
            speciality: 'Kinoreife Fitness-Erlebnisse',
          ),
          'es': LocalizedAvatarData(
            name: 'Entrenador Director',
            description: 'Director de fitness carismático con estilo de Hollywood. Dirige tu entrenamiento como una escena épica de película.',
            personality: 'Carismático y dramático',
            speciality: 'Experiencias de fitness cinematográficas',
          ),
          'fr': LocalizedAvatarData(
            name: 'Coach Réalisateur',
            description: 'Directeur de fitness charismatique avec un style hollywoodien. Dirige votre entraînement comme une scène de film épique.',
            personality: 'Charismatique et dramatique',
            speciality: 'Expériences de fitness cinématographiques',
          ),
          'hi': LocalizedAvatarData(
            name: 'निर्देशक कोच',
            description: 'हॉलीवुड शैली के साथ करिश्माई फिटनेस निर्देशक। आपकी कसरत को एक महाकाव्य फिल्म दृश्य की तरह निर्देशित करता है।',
            personality: 'करिश्माई और नाटकीय',
            speciality: 'सिनेमाई फिटनेस अनुभव',
          ),
          'it': LocalizedAvatarData(
            name: 'Allenatore Regista',
            description: 'Regista di fitness carismatico con stile hollywoodiano. Dirige il tuo allenamento come una scena epica di un film.',
            personality: 'Carismatico e drammatico',
            speciality: 'Esperienze di fitness cinematografiche',
          ),
          'ja': LocalizedAvatarData(
            name: 'ディレクターコーチ',
            description: 'ハリウッドスタイルのカリスマ的フィットネスディレクター。壮大な映画シーンのようにワークアウトを指揮。',
            personality: 'カリスマ的で劇的',
            speciality: '映画的フィットネス体験',
          ),
          'ko': LocalizedAvatarData(
            name: '디렉터 코치',
            description: '할리우드 스타일의 카리스마 넘치는 피트니스 디렉터. 서사적인 영화 장면처럼 운동을 지휘합니다.',
            personality: '카리스마 있고 드라마틱',
            speciality: '영화적 피트니스 경험',
          ),
          'pt': LocalizedAvatarData(
            name: 'Treinador Diretor',
            description: 'Diretor de fitness carismático com estilo de Hollywood. Comanda seu treino como uma cena épica de filme.',
            personality: 'Carismático e dramático',
            speciality: 'Experiências de fitness cinematográficas',
          ),
          'ru': LocalizedAvatarData(
            name: 'Тренер-Режиссёр',
            description: 'Харизматичный фитнес-режиссёр в голливудском стиле. Руководит вашей тренировкой как эпической киносценой.',
            personality: 'Харизматичный и драматичный',
            speciality: 'Кинематографические фитнес-переживания',
          ),
          'zh': LocalizedAvatarData(
            name: '导演教练',
            description: '具有好莱坞风格的魅力健身导演。像史诗电影场景一样指挥您的锻炼。',
            personality: '魅力十足且戏剧性',
            speciality: '电影般的健身体验',
          ),
        },
      };

      // Batch populate all avatar translations
      for (final entry in avatarTranslations.entries) {
        await _translationService.addAvatarTranslations(entry.key, entry.value);
        log.info('✅ Added translations for avatar: ${entry.key}');
      }

      log.info('🎉 Successfully populated all avatar translations');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to populate avatar translations: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Run the population script
  static Future<void> run() async {
    final service = FirebaseTranslationService();
    await service.initialize();
    
    final populator = AvatarTranslationPopulator(service);
    await populator.populateAllAvatarTranslations();
    
    await service.dispose();
  }
}