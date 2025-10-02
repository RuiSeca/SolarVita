import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import '../../models/translation/translated_meal.dart';
import '../../models/translation/translated_exercise.dart';

final log = Logger('TranslationDatabaseService');

class TranslationDatabaseService {
  static const String _databaseName = 'translations.db';
  static const int _databaseVersion = 2;

  static const String _mealsTable = 'translated_meals';
  static const String _exercisesTable = 'translated_exercises';
  static const String _refreshTrackingTable = 'refresh_tracking';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    log.info('📂 Initializing translation database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    log.info('🏗️ Creating translation database tables');

    // Create translated meals table
    await db.execute('''
      CREATE TABLE $_mealsTable (
        id TEXT NOT NULL,
        originalLanguage TEXT NOT NULL,
        targetLanguage TEXT NOT NULL,
        originalName TEXT NOT NULL,
        translatedName TEXT NOT NULL,
        originalInstructions TEXT NOT NULL,
        translatedInstructions TEXT NOT NULL,
        originalIngredients TEXT NOT NULL,
        translatedIngredients TEXT NOT NULL,
        originalMeasures TEXT,
        translatedMeasures TEXT,
        originalCategory TEXT,
        translatedCategory TEXT,
        originalArea TEXT,
        translatedArea TEXT,
        translatedAt INTEGER NOT NULL,
        youtubeUrl TEXT,
        imagePath TEXT,
        calories TEXT,
        prepTime TEXT,
        cookTime TEXT,
        difficulty TEXT,
        servings INTEGER,
        isVegan INTEGER,
        nutritionFacts TEXT,
        PRIMARY KEY (id, targetLanguage)
      )
    ''');

    // Create translated exercises table
    await db.execute('''
      CREATE TABLE $_exercisesTable (
        id TEXT NOT NULL,
        originalLanguage TEXT NOT NULL,
        targetLanguage TEXT NOT NULL,
        originalName TEXT NOT NULL,
        translatedName TEXT NOT NULL,
        originalDescription TEXT NOT NULL,
        translatedDescription TEXT NOT NULL,
        originalInstructions TEXT NOT NULL,
        translatedInstructions TEXT NOT NULL,
        originalBodyPart TEXT,
        translatedBodyPart TEXT,
        originalTarget TEXT,
        translatedTarget TEXT,
        originalEquipment TEXT NOT NULL,
        translatedEquipment TEXT NOT NULL,
        originalTips TEXT NOT NULL,
        translatedTips TEXT NOT NULL,
        translatedAt INTEGER NOT NULL,
        gifUrl TEXT,
        duration TEXT,
        difficulty TEXT,
        caloriesBurn TEXT,
        rating REAL,
        PRIMARY KEY (id, targetLanguage)
      )
    ''');

    // Create refresh tracking table
    await db.execute('''
      CREATE TABLE $_refreshTrackingTable (
        language TEXT PRIMARY KEY,
        lastRefreshMeals INTEGER,
        lastRefreshExercises INTEGER,
        mealCount INTEGER DEFAULT 0,
        exerciseCount INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_meals_language ON $_mealsTable (targetLanguage)');
    await db.execute('CREATE INDEX idx_meals_translated_at ON $_mealsTable (translatedAt)');
    await db.execute('CREATE INDEX idx_exercises_language ON $_exercisesTable (targetLanguage)');
    await db.execute('CREATE INDEX idx_exercises_translated_at ON $_exercisesTable (translatedAt)');

    log.info('✅ Translation database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    log.info('⬆️ Upgrading translation database from $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Add measures columns to translated_meals table
      log.info('📝 Adding measures columns to translated_meals table');
      await db.execute('ALTER TABLE $_mealsTable ADD COLUMN originalMeasures TEXT');
      await db.execute('ALTER TABLE $_mealsTable ADD COLUMN translatedMeasures TEXT');
      log.info('✅ Database upgrade to version 2 completed');
    }
  }

  // MEAL OPERATIONS

  Future<void> saveMeal(TranslatedMeal meal) async {
    final db = await database;
    try {
      await db.insert(
        _mealsTable,
        meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      log.fine('💾 Saved meal translation: ${meal.translatedName} (${meal.targetLanguage})');
    } catch (e) {
      log.severe('❌ Failed to save meal translation: ${meal.id}', e);
      rethrow;
    }
  }

  Future<void> saveMealsBatch(List<TranslatedMeal> meals) async {
    final db = await database;
    final batch = db.batch();

    try {
      for (final meal in meals) {
        batch.insert(
          _mealsTable,
          meal.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      log.info('💾 Batch saved ${meals.length} meal translations');
    } catch (e) {
      log.severe('❌ Failed to batch save meal translations', e);
      rethrow;
    }
  }

  Future<TranslatedMeal?> getMeal(String id, String language) async {
    final db = await database;
    try {
      final maps = await db.query(
        _mealsTable,
        where: 'id = ? AND targetLanguage = ?',
        whereArgs: [id, language],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return TranslatedMeal.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      log.severe('❌ Failed to get meal: $id ($language)', e);
      return null;
    }
  }

  Future<List<TranslatedMeal>> getMealsForLanguage(String language) async {
    final db = await database;
    try {
      final maps = await db.query(
        _mealsTable,
        where: 'targetLanguage = ?',
        whereArgs: [language],
        orderBy: 'translatedAt DESC',
      );

      return maps.map((map) => TranslatedMeal.fromMap(map)).toList();
    } catch (e) {
      log.severe('❌ Failed to get meals for language: $language', e);
      return [];
    }
  }

  // EXERCISE OPERATIONS

  Future<void> saveExercise(TranslatedExercise exercise) async {
    final db = await database;
    try {
      await db.insert(
        _exercisesTable,
        exercise.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      log.fine('💾 Saved exercise translation: ${exercise.translatedName} (${exercise.targetLanguage})');
    } catch (e) {
      log.severe('❌ Failed to save exercise translation: ${exercise.id}', e);
      rethrow;
    }
  }

  Future<void> saveExercisesBatch(List<TranslatedExercise> exercises) async {
    final db = await database;
    final batch = db.batch();

    try {
      for (final exercise in exercises) {
        batch.insert(
          _exercisesTable,
          exercise.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      log.info('💾 Batch saved ${exercises.length} exercise translations');
    } catch (e) {
      log.severe('❌ Failed to batch save exercise translations', e);
      rethrow;
    }
  }

  Future<TranslatedExercise?> getExercise(String id, String language) async {
    final db = await database;
    try {
      final maps = await db.query(
        _exercisesTable,
        where: 'id = ? AND targetLanguage = ?',
        whereArgs: [id, language],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return TranslatedExercise.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      log.severe('❌ Failed to get exercise: $id ($language)', e);
      return null;
    }
  }

  Future<List<TranslatedExercise>> getExercisesForLanguage(String language) async {
    final db = await database;
    try {
      final maps = await db.query(
        _exercisesTable,
        where: 'targetLanguage = ?',
        whereArgs: [language],
        orderBy: 'translatedAt DESC',
      );

      return maps.map((map) => TranslatedExercise.fromMap(map)).toList();
    } catch (e) {
      log.severe('❌ Failed to get exercises for language: $language', e);
      return [];
    }
  }

  // REFRESH TRACKING OPERATIONS

  Future<void> updateRefreshTracking(
    String language, {
    DateTime? lastRefreshMeals,
    DateTime? lastRefreshExercises,
    int? mealCount,
    int? exerciseCount,
  }) async {
    final db = await database;

    try {
      final data = <String, dynamic>{};
      if (lastRefreshMeals != null) {
        data['lastRefreshMeals'] = lastRefreshMeals.millisecondsSinceEpoch;
      }
      if (lastRefreshExercises != null) {
        data['lastRefreshExercises'] = lastRefreshExercises.millisecondsSinceEpoch;
      }
      if (mealCount != null) {
        data['mealCount'] = mealCount;
      }
      if (exerciseCount != null) {
        data['exerciseCount'] = exerciseCount;
      }

      await db.insert(
        _refreshTrackingTable,
        {'language': language, ...data},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      log.fine('📊 Updated refresh tracking for $language');
    } catch (e) {
      log.severe('❌ Failed to update refresh tracking for $language', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getRefreshTracking(String language) async {
    final db = await database;
    try {
      final maps = await db.query(
        _refreshTrackingTable,
        where: 'language = ?',
        whereArgs: [language],
        limit: 1,
      );

      return maps.isNotEmpty ? maps.first : null;
    } catch (e) {
      log.severe('❌ Failed to get refresh tracking for $language', e);
      return null;
    }
  }

  // UTILITY OPERATIONS

  Future<bool> hasTranslationsForLanguage(String language) async {
    final db = await database;
    try {
      final mealCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_mealsTable WHERE targetLanguage = ?',
        [language],
      )) ?? 0;

      final exerciseCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_exercisesTable WHERE targetLanguage = ?',
        [language],
      )) ?? 0;

      return mealCount > 0 || exerciseCount > 0;
    } catch (e) {
      log.severe('❌ Failed to check translations for language: $language', e);
      return false;
    }
  }

  Future<void> clearTranslationsForLanguage(String language) async {
    final db = await database;
    final batch = db.batch();

    try {
      batch.delete(_mealsTable, where: 'targetLanguage = ?', whereArgs: [language]);
      batch.delete(_exercisesTable, where: 'targetLanguage = ?', whereArgs: [language]);
      batch.delete(_refreshTrackingTable, where: 'language = ?', whereArgs: [language]);

      await batch.commit(noResult: true);
      log.info('🗑️ Cleared all translations for language: $language');
    } catch (e) {
      log.severe('❌ Failed to clear translations for language: $language', e);
      rethrow;
    }
  }

  Future<void> clearOldTranslations({int daysOld = 30}) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(Duration(days: daysOld));
    final batch = db.batch();

    try {
      batch.delete(
        _mealsTable,
        where: 'translatedAt < ?',
        whereArgs: [cutoffTime.millisecondsSinceEpoch],
      );
      batch.delete(
        _exercisesTable,
        where: 'translatedAt < ?',
        whereArgs: [cutoffTime.millisecondsSinceEpoch],
      );

      await batch.commit(noResult: true);
      log.info('🧹 Cleared translations older than $daysOld days');
    } catch (e) {
      log.severe('❌ Failed to clear old translations', e);
    }
  }

  Future<Map<String, int>> getTranslationCounts() async {
    final db = await database;
    try {
      final mealCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_mealsTable',
      )) ?? 0;

      final exerciseCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_exercisesTable',
      )) ?? 0;

      return {
        'meals': mealCount,
        'exercises': exerciseCount,
        'total': mealCount + exerciseCount,
      };
    } catch (e) {
      log.severe('❌ Failed to get translation counts', e);
      return {'meals': 0, 'exercises': 0, 'total': 0};
    }
  }

  Future<Map<String, int>> getTranslationCountsForLanguage(String languageCode) async {
    final db = await database;
    try {
      final mealCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_mealsTable WHERE targetLanguage = ?',
        [languageCode],
      )) ?? 0;

      final exerciseCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_exercisesTable WHERE targetLanguage = ?',
        [languageCode],
      )) ?? 0;

      return {
        'meals': mealCount,
        'exercises': exerciseCount,
        'total': mealCount + exerciseCount,
      };
    } catch (e) {
      log.severe('❌ Failed to get translation counts for $languageCode', e);
      return {'meals': 0, 'exercises': 0, 'total': 0};
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      log.info('🔒 Translation database closed');
    }
  }
}