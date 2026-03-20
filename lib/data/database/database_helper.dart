import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'dose_certa.db';
  static const int _dbVersion = 3;
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    await _ensureDosesTableExists(_database!);
    return _database!;
  }

  Future<void> _ensureDosesTableExists(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS doses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medication_id INTEGER NOT NULL,
          scheduled_time INTEGER NOT NULL,
          status TEXT DEFAULT 'pending',
          taken_at INTEGER,
          dose_amount REAL,
          unit TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER,
          FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
        )
      ''');
    } catch (e) {
      print('Failed to ensure doses table exists: $e');
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _updateTables,
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS doses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER NOT NULL,
            scheduled_time INTEGER NOT NULL,
            status TEXT DEFAULT 'pending',
            taken_at INTEGER,
            dose_amount REAL,
            unit TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER,
            FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT,
        dosage_amount REAL NOT NULL,
        unit TEXT NOT NULL,
        frequency TEXT NOT NULL,
        days_of_week TEXT,
        times TEXT,
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        duration_days INTEGER,
        stock_quantity INTEGER DEFAULT 0,
        stock_alert_threshold INTEGER DEFAULT 10,
        stock_alerts_enabled INTEGER DEFAULT 1,
        is_active INTEGER DEFAULT 1,
        is_paused INTEGER DEFAULT 0,
        description TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE medication_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        time TEXT NOT NULL,
        days_of_week TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE medication_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        scheduled_time INTEGER NOT NULL,
        status TEXT DEFAULT 'pending',
        taken_at INTEGER,
        notes TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE doses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        scheduled_time INTEGER NOT NULL,
        status TEXT DEFAULT 'pending',
        taken_at INTEGER,
        dose_amount REAL,
        unit TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE favorite_pharmacies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT,
        latitude REAL,
        longitude REAL,
        opening_hours TEXT,
        services TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        '''CREATE INDEX idx_medication_reminders_scheduled ON medication_reminders(scheduled_time)''');
    await db.execute(
        '''CREATE INDEX idx_medication_schedules_medication ON medication_schedules(medication_id)''');
    await db.execute(
        '''CREATE INDEX idx_medications_active ON medications(is_active)''');
  }

  Future<void> _updateTables(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      print(
          'Database upgrade: from $oldVersion to $newVersion - starting migration to v2');
      try {
        await db.execute('ALTER TABLE medications ADD COLUMN dosage TEXT');
        print('Migration: added column dosage');
      } catch (e) {
        print('Migration: failed to add column dosage: $e');
      }
      try {
        await db
            .execute('ALTER TABLE medications ADD COLUMN dosage_amount REAL');
        print('Migration: added column dosage_amount');
      } catch (e) {
        print('Migration: failed to add column dosage_amount: $e');
      }
      try {
        await db.execute('ALTER TABLE medications ADD COLUMN unit TEXT');
        print('Migration: added column unit');
      } catch (e) {
        print('Migration: failed to add column unit: $e');
      }
      try {
        await db.execute('ALTER TABLE medications ADD COLUMN frequency TEXT');
        print('Migration: added column frequency');
      } catch (e) {
        print('Migration: failed to add column frequency: $e');
      }
      try {
        await db
            .execute('ALTER TABLE medications ADD COLUMN days_of_week TEXT');
        print('Migration: added column days_of_week');
      } catch (e) {
        print('Migration: failed to add column days_of_week: $e');
      }
      try {
        await db.execute('ALTER TABLE medications ADD COLUMN times TEXT');
        print('Migration: added column times');
      } catch (e) {
        print('Migration: failed to add column times: $e');
      }
      try {
        await db
            .execute('ALTER TABLE medications ADD COLUMN start_date INTEGER');
        print('Migration: added column start_date');
      } catch (e) {
        print('Migration: failed to add column start_date: $e');
      }
      try {
        await db.execute('ALTER TABLE medications ADD COLUMN end_date INTEGER');
        print('Migration: added column end_date');
      } catch (e) {
        print('Migration: failed to add column end_date: $e');
      }
      try {
        await db.execute(
            'ALTER TABLE medications ADD COLUMN duration_days INTEGER');
        print('Migration: added column duration_days');
      } catch (e) {
        print('Migration: failed to add column duration_days: $e');
      }
      try {
        await db.execute(
            'ALTER TABLE medications ADD COLUMN stock_quantity INTEGER DEFAULT 0');
        print('Migration: added column stock_quantity');
      } catch (e) {
        print('Migration: failed to add column stock_quantity: $e');
      }
      try {
        await db.execute(
            'ALTER TABLE medications ADD COLUMN stock_alert_threshold INTEGER DEFAULT 10');
        print('Migration: added column stock_alert_threshold');
      } catch (e) {
        print('Migration: failed to add column stock_alert_threshold: $e');
      }
      try {
        await db.execute(
            'ALTER TABLE medications ADD COLUMN stock_alerts_enabled INTEGER DEFAULT 1');
        print('Migration: added column stock_alerts_enabled');
      } catch (e) {
        print('Migration: failed to add column stock_alerts_enabled: $e');
      }
      try {
        await db.execute(
            'ALTER TABLE medications ADD COLUMN is_active INTEGER DEFAULT 1');
        print('Migration: added column is_active');
      } catch (e) {
        print('Migration: failed to add column is_active: $e');
      }
      try {
        await db.execute(
            'ALTER TABLE medications ADD COLUMN is_paused INTEGER DEFAULT 0');
        print('Migration: added column is_paused');
      } catch (e) {
        print('Migration: failed to add column is_paused: $e');
      }
      try {
        await db.execute('ALTER TABLE medications ADD COLUMN description TEXT');
        print('Migration: added column description');
      } catch (e) {
        print('Migration: failed to add column description: $e');
      }
      try {
        await db.execute('ALTER TABLE medications ADD COLUMN notes TEXT');
        print('Migration: added column notes');
      } catch (e) {
        print('Migration: failed to add column notes: $e');
      }
      try {
        await db
            .execute('ALTER TABLE medications ADD COLUMN created_at INTEGER');
        print('Migration: added column created_at');
      } catch (e) {
        print('Migration: failed to add column created_at: $e');
      }
      try {
        await db
            .execute('ALTER TABLE medications ADD COLUMN updated_at INTEGER');
        print('Migration: added column updated_at');
      } catch (e) {
        print('Migration: failed to add column updated_at: $e');
      }

      print(
          'Database upgrade: migration to v2 - completed attempts to alter medications table');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medication_schedules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medication_id INTEGER NOT NULL,
          time TEXT NOT NULL,
          days_of_week TEXT NOT NULL,
          is_active INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS medication_reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medication_id INTEGER NOT NULL,
          scheduled_time INTEGER NOT NULL,
          status TEXT DEFAULT 'pending',
          taken_at INTEGER,
          notes TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS doses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medication_id INTEGER NOT NULL,
          scheduled_time INTEGER NOT NULL,
          status TEXT DEFAULT 'pending',
          taken_at INTEGER,
          dose_amount REAL,
          unit TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER,
          FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_pharmacies (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          phone TEXT,
          latitude REAL,
          longitude REAL,
          opening_hours TEXT,
          services TEXT,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        -- user_profiles table removed (feature deprecated)
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_medication_reminders_scheduled ON medication_reminders(scheduled_time)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_medication_schedules_medication ON medication_schedules(medication_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_medications_active ON medications(is_active)');
    }
  }

  Future<List<Map<String, dynamic>>> getAllMedications() async {
    final db = await database;
    return await db.query('medications', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getMedicationById(int id) async {
    final db = await database;
    final results = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertMedication(Map<String, dynamic> medication) async {
    final db = await database;
    return await db.insert('medications', medication);
  }

  Future<bool> updateMedication(int id, Map<String, dynamic> medication) async {
    final db = await database;
    final result = await db.update(
      'medications',
      medication,
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  Future<bool> deleteMedication(int id) async {
    final db = await database;
    final result = await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  Future<List<Map<String, dynamic>>> getLowStockMedications() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM medications 
      WHERE stock_quantity <= stock_alert_threshold 
      AND stock_alerts_enabled = 1 
      AND is_active = 1
      ORDER BY stock_quantity ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getMedicationSchedules(
      int medicationId) async {
    final db = await database;
    return await db.query(
      'medication_schedules',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'time ASC',
    );
  }

  Future<int> insertMedicationSchedule(Map<String, dynamic> schedule) async {
    final db = await database;
    return await db.insert('medication_schedules', schedule);
  }

  Future<bool> updateMedicationSchedule(
      int id, Map<String, dynamic> schedule) async {
    final db = await database;
    final result = await db.update(
      'medication_schedules',
      schedule,
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  Future<bool> deleteMedicationSchedules(int medicationId) async {
    final db = await database;
    final result = await db.delete(
      'medication_schedules',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
    );
    return result > 0;
  }

  Future<int> insertReminder(Map<String, dynamic> reminder) async {
    final db = await database;
    return await db.insert('medication_reminders', reminder);
  }

  Future<int> insertDose(Map<String, dynamic> dose) async {
    final db = await database;
    return await db.insert('doses', dose);
  }

  Future<List<Map<String, dynamic>>> getDosesForMedicationOnDate(
      int medicationId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return await db.query(
      'doses',
      where: '''medication_id = ? AND (
                (scheduled_time >= ? AND scheduled_time < ?) OR
                (taken_at IS NOT NULL AND taken_at >= ? AND taken_at < ?)
              )''',
      whereArgs: [
        medicationId,
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'scheduled_time ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getDosesForMedicationInRange(
    int medicationId,
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    final db = await database;
    final startMs =
        DateTime(startInclusive.year, startInclusive.month, startInclusive.day)
            .millisecondsSinceEpoch;
    final endMs =
        DateTime(endExclusive.year, endExclusive.month, endExclusive.day)
            .millisecondsSinceEpoch;

    return await db.query(
      'doses',
      where: '''medication_id = ? AND (
                (scheduled_time >= ? AND scheduled_time < ?) OR
                (taken_at IS NOT NULL AND taken_at >= ? AND taken_at < ?)
              )''',
      whereArgs: [
        medicationId,
        startMs,
        endMs,
        startMs,
        endMs,
      ],
      orderBy: 'scheduled_time ASC',
    );
  }

  Future<bool> markDoseAsTaken(int doseId, DateTime takenAt) async {
    final db = await database;
    final data = <String, dynamic>{
      'status': 'taken',
      'taken_at': takenAt.millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    final result =
        await db.update('doses', data, where: 'id = ?', whereArgs: [doseId]);
    return result > 0;
  }

  Future<bool> updateDose(int id, Map<String, dynamic> dose) async {
    final db = await database;
    final result =
        await db.update('doses', dose, where: 'id = ?', whereArgs: [id]);
    return result > 0;
  }

  Future<bool> deleteDose(int id) async {
    final db = await database;
    final result = await db.delete('doses', where: 'id = ?', whereArgs: [id]);
    return result > 0;
  }

  Future<int> deleteDosesForMedication(int medicationId) async {
    final db = await database;
    return await db
        .delete('doses', where: 'medication_id = ?', whereArgs: [medicationId]);
  }

  Future<List<Map<String, dynamic>>> getPendingReminders() async {
    final db = await database;
    return await db.query(
      'medication_reminders',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'scheduled_time ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getTodayReminders() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await db.query(
      'medication_reminders',
      where: 'scheduled_time >= ? AND scheduled_time < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch
      ],
      orderBy: 'scheduled_time ASC',
    );
  }

  Future<bool> updateReminderStatus(int id, String status,
      {DateTime? takenAt}) async {
    final db = await database;
    final data = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    if (takenAt != null) {
      data['taken_at'] = takenAt.millisecondsSinceEpoch;
    }

    final result = await db.update(
      'medication_reminders',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  Future<List<Map<String, dynamic>>> getFavoritePharmacies() async {
    final db = await database;
    return await db.query('favorite_pharmacies', orderBy: 'name ASC');
  }

  Future<int> insertFavoritePharmacy(Map<String, dynamic> pharmacy) async {
    final db = await database;
    return await db.insert(
      'favorite_pharmacies',
      pharmacy,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> deleteFavoritePharmacy(int id) async {
    final db = await database;
    final result = await db.delete(
      'favorite_pharmacies',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('doses');
    await db.delete('medication_reminders');
    await db.delete('medication_schedules');
    await db.delete('medications');
    await db.delete('favorite_pharmacies');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final medications =
        await db.rawQuery('SELECT COUNT(*) as count FROM medications');
    final reminders =
        await db.rawQuery('SELECT COUNT(*) as count FROM medication_reminders');
    final schedules =
        await db.rawQuery('SELECT COUNT(*) as count FROM medication_schedules');
    final pharmacies =
        await db.rawQuery('SELECT COUNT(*) as count FROM favorite_pharmacies');

    return {
      'medications': medications.first['count'] as int,
      'reminders': reminders.first['count'] as int,
      'schedules': schedules.first['count'] as int,
      'pharmacies': pharmacies.first['count'] as int,
    };
  }

  Future<List<String>> getTableColumns(String table) async {
    final db = await database;
    final rows = await db.rawQuery("PRAGMA table_info($table);");
    final cols = <String>[];
    for (final r in rows) {
      final name = r['name'];
      if (name is String) cols.add(name);
    }
    return cols;
  }

  Future<Map<String, String>> ensureMedicationsColumns(
      List<MapEntry<String, String>> columnsToAdd) async {
    final result = <String, String>{};
    final db = await database;
    final existing = await getTableColumns('medications');

    for (final entry in columnsToAdd) {
      final col = entry.key;
      final sql =
          entry.value; // e.g. "ALTER TABLE medications ADD COLUMN foo TEXT"
      if (existing.contains(col)) {
        result[col] = 'exists';
        continue;
      }
      try {
        await db.execute(sql);
        result[col] = 'added';
      } catch (e) {
        result[col] = 'error: $e';
      }
    }

    return result;
  }
}
