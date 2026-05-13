import 'dart:convert';
import 'package:flutter/services.dart';

class EmergencyNumberService {
  Map<String, String> _emergencyMap = {};
  bool _isLoaded = false;

  /// Loads the emergency numbers database.
  Future<void> loadDatabase() async {
    if (_isLoaded) return;
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/emergency_numbers.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _emergencyMap = jsonData.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      _isLoaded = true;
    } catch (e) {
      print('Error loading emergency numbers: $e');
    }
  }

  /// Returns the primary emergency number for a given country.
  /// Falls back to "112" if country is not found.
  String getNumberForCountry(String countryName) {
    return _emergencyMap[countryName] ?? "112";
  }
}
