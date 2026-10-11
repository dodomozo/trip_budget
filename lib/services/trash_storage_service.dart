import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/trash_entry.dart';

class TrashStorageService {
  static const String _trashKey = 'trash_entries';

  Future<List<TrashEntry>> loadTrash() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getString(_trashKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawEntries) as List<dynamic>;

      return decoded
          .map(
            (entry) =>
                TrashEntry.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList()
        ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    } catch (error) {
      throw FormatException(
        'Unable to read Trash data. Existing data was preserved.',
        error,
      );
    }
  }

  Future<void> saveTrash(List<TrashEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _trashKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> addToTrash(TrashEntry entry) async {
    final entries = await loadTrash();

    entries.removeWhere((existing) => existing.id == entry.id);
    entries.add(entry);

    await saveTrash(entries);
  }

  Future<void> removeFromTrash(String entryId) async {
    final entries = await loadTrash();

    entries.removeWhere((entry) => entry.id == entryId);

    await saveTrash(entries);
  }

  Future<void> clearTrash() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_trashKey);
  }
}
