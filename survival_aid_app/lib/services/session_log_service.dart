import 'dart:async';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
import '../models/protocol.dart';
import 'gps_service.dart';

class SessionLogService {
  // Database? _db;

  /// Initializes the SQLite database and creates tables if they don't exist.
  Future<void> initDb() async {
    // final path = join(await getDatabasesPath(), 'survival_aid.db');
    // _db = await openDatabase(
    //   path,
    //   version: 1,
    //   onCreate: (db, version) async {
    //     await db.execute('''
    //       CREATE TABLE session_log (
    //         id INTEGER PRIMARY KEY AUTOINCREMENT,
    //         session_id TEXT,
    //         node_id TEXT,
    //         timestamp INTEGER,
    //         user_choice TEXT
    //       )
    //     ''');
    //     await db.execute('''
    //       CREATE TABLE position_log (
    //         id INTEGER PRIMARY KEY AUTOINCREMENT,
    //         session_id TEXT,
    //         latitude REAL,
    //         longitude REAL,
    //         altitude REAL,
    //         timestamp INTEGER
    //       )
    //     ''');
    //   },
    // );
  }

  /// Logs a step taken in the protocol.
  Future<void> logStep({
    required String sessionId,
    required String nodeId,
    required String userChoice,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // await _db?.insert('session_log', {
    //   'session_id': sessionId,
    //   'node_id': nodeId,
    //   'timestamp': timestamp,
    //   'user_choice': userChoice,
    // });
    print('Logged step: $nodeId ($userChoice)');
  }

  /// Logs a GPS position.
  Future<void> logPosition({
    required String sessionId,
    required GpsCoordinates coords,
  }) async {
    // await _db?.insert('position_log', {
    //   'session_id': sessionId,
    //   'latitude': coords.latitude,
    //   'longitude': coords.longitude,
    //   'altitude': coords.altitude,
    //   'timestamp': coords.timestamp.millisecondsSinceEpoch,
    // });
    print('Logged position: ${coords.latitude}, ${coords.longitude}');
  }
}
