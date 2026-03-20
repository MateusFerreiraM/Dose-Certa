import 'package:flutter/material.dart';
import 'package:dose_certa/data/database/database_helper.dart';

class DbInspectorPage extends StatefulWidget {
  const DbInspectorPage({Key? key}) : super(key: key);

  @override
  State<DbInspectorPage> createState() => _DbInspectorPageState();
}

class _DbInspectorPageState extends State<DbInspectorPage> {
  final _db = DatabaseHelper.instance;
  String _output = '';
  final _queryController = TextEditingController();

  Future<void> _showSchema(String table) async {
    try {
      final db = await _db.database;
      final rows = await db.rawQuery("PRAGMA table_info($table);");
      setState(() {
        _output = rows.map((r) => r.toString()).join('\n');
      });
    } catch (e) {
      setState(() => _output = 'Error: $e');
    }
  }

  Future<void> _showFirstRow(String table) async {
    try {
      final db = await _db.database;
      final rows = await db.rawQuery('SELECT * FROM $table LIMIT 1');
      setState(() {
        if (rows.isEmpty)
          _output = 'No rows';
        else
          _output = rows.first.toString();
      });
    } catch (e) {
      setState(() => _output = 'Error: $e');
    }
  }

  Future<void> _ensureMedicationsColumns() async {
    setState(() => _output = 'Running ensureMedicationsColumns...');
    final colsToAdd = [
      MapEntry('dosage', "ALTER TABLE medications ADD COLUMN dosage TEXT"),
      MapEntry('dosage_amount',
          "ALTER TABLE medications ADD COLUMN dosage_amount REAL"),
      MapEntry('unit', "ALTER TABLE medications ADD COLUMN unit TEXT"),
      MapEntry(
          'frequency', "ALTER TABLE medications ADD COLUMN frequency TEXT"),
      MapEntry('days_of_week',
          "ALTER TABLE medications ADD COLUMN days_of_week TEXT"),
      MapEntry('times', "ALTER TABLE medications ADD COLUMN times TEXT"),
      MapEntry('start_date',
          "ALTER TABLE medications ADD COLUMN start_date INTEGER"),
      MapEntry(
          'end_date', "ALTER TABLE medications ADD COLUMN end_date INTEGER"),
      MapEntry('duration_days',
          "ALTER TABLE medications ADD COLUMN duration_days INTEGER"),
      MapEntry('stock_quantity',
          "ALTER TABLE medications ADD COLUMN stock_quantity INTEGER DEFAULT 0"),
      MapEntry('stock_alert_threshold',
          "ALTER TABLE medications ADD COLUMN stock_alert_threshold INTEGER DEFAULT 10"),
      MapEntry('stock_alerts_enabled',
          "ALTER TABLE medications ADD COLUMN stock_alerts_enabled INTEGER DEFAULT 1"),
      MapEntry('is_active',
          "ALTER TABLE medications ADD COLUMN is_active INTEGER DEFAULT 1"),
      MapEntry('is_paused',
          "ALTER TABLE medications ADD COLUMN is_paused INTEGER DEFAULT 0"),
      MapEntry(
          'description', "ALTER TABLE medications ADD COLUMN description TEXT"),
      MapEntry('notes', "ALTER TABLE medications ADD COLUMN notes TEXT"),
      MapEntry('created_at',
          "ALTER TABLE medications ADD COLUMN created_at INTEGER"),
      MapEntry('updated_at',
          "ALTER TABLE medications ADD COLUMN updated_at INTEGER"),
    ];

    try {
      final res = await _db.ensureMedicationsColumns(colsToAdd);
      setState(() =>
          _output = res.entries.map((e) => '${e.key}: ${e.value}').join('\n'));
    } catch (e) {
      setState(() => _output = 'Error ensuring columns: $e');
    }
  }

  Future<void> _runCustomQuery() async {
    final q = _queryController.text.trim();
    if (q.isEmpty) return;
    try {
      final db = await _db.database;
      final rows = await db.rawQuery(q);
      setState(() {
        _output = rows.map((r) => r.toString()).join('\n');
      });
    } catch (e) {
      setState(() => _output = 'Error: $e');
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DB Inspector')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _showSchema('medications'),
              child: const Text('Show medications schema'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _ensureMedicationsColumns,
              child: const Text('Ensure medications columns (run migration)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showFirstRow('medications'),
              child: const Text('Show first medication row'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _queryController,
              decoration: const InputDecoration(labelText: 'Custom SQL query'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _runCustomQuery,
              child: const Text('Run query'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_output),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
