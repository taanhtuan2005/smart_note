import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class LocalStorageService {
  static const String _notesKey = 'notes';
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  static LocalStorageService get instance => _instance;

  // Save list of notes to SharedPreferences
  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert list of Note objects to list of JSON maps
    final List<Map<String, dynamic>> jsonList = notes
        .map((note) => note.toJson())
        .toList();
    // Encode list of maps to JSON string
    final String jsonString = jsonEncode(jsonList);
    // Save to SharedPreferences
    await prefs.setString(_notesKey, jsonString);
  }

  // Load list of notes from SharedPreferences
  Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_notesKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      // Decode JSON string to list of dynamic objects
      final List<dynamic> jsonList = jsonDecode(jsonString);
      // Map dynamic objects to Note instances
      return jsonList.map((json) => Note.fromJson(json)).toList();
    } catch (e) {
      print('Error decoding notes: $e');
      return [];
    }
  }
}
