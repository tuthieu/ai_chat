import 'dart:io';

import 'package:ai_chat/models/message.dart';
import 'package:ai_chat/models/session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseProvider {
  DatabaseProvider._();

  static final DatabaseProvider db = DatabaseProvider._();
  static Database? _database;
  static SharedPreferences? _preferences;

  Future<Database> get database async => _database ??= await initDB();

  Future<SharedPreferences> get preferences async =>
      _preferences ??= await initPrefs();

  Future<Database> initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = '${documentsDirectory.path}chat.db';

    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute(
          'CREATE TABLE Session (id INTEGER PRIMARY KEY AUTOINCREMENT)');
      await db.execute(
          'CREATE TABLE SenderType (id INTEGER PRIMARY KEY, name TEXT)');
      await Future.wait([
        db.execute(
            'CREATE TABLE Message (id INTEGER PRIMARY KEY AUTOINCREMENT, sessionId INTEGER, content TEXT, sender INTEGER, time INTEGER, FOREIGN KEY (sessionId) REFERENCES Session(id) ON DELETE CASCADE, FOREIGN KEY (sender) REFERENCES SenderType(id))'),
        for (Sender sender in Sender.values)
          db.rawInsert('INSERT INTO SenderType (id, name) VALUES (?, ?)',
              [sender.index, sender.toString().split('.').last])
      ]);
    });
  }

  Future<SharedPreferences> initPrefs() async {
    return await SharedPreferences.getInstance().then((prefs) {
      Future.wait([
        if (!prefs.containsKey('language')) prefs.setString('language', 'en'),
        if (!prefs.containsKey('autoSpeech')) prefs.setBool('autoSpeech', true)
      ]);
      return prefs;
    });
  }

  Future<int> newSession() async {
    final db = await database;
    var res = await db.rawInsert('INSERT Into Session Default Values');
    return res;
  }

  Future<int> newMessage(int sessionId, String content, Sender sender) async {
    final db = await database;
    var res = await db.rawInsert(
        'INSERT Into Message (sessionId, content, sender, time) VALUES (?, ?, ?, ?)',
        [
          sessionId,
          content,
          sender.index,
          DateTime.now().millisecondsSinceEpoch
        ]);
    return res;
  }

  Future<Message?> getMessage(int id) async {
    final db = await database;
    var res = await db.rawQuery('SELECT * FROM Message WHERE id = ?', [id]);
    return res.isNotEmpty ? Message.fromMap(res.first) : null;
  }

  Future<List<Message>> getMessages(int sessionId) async {
    final db = await database;
    var res = await db.rawQuery(
        'SELECT * FROM Message WHERE sessionId = ? ORDER BY time ASC',
        [sessionId]);
    List<Message> list =
        res.isNotEmpty ? res.map((c) => Message.fromMap(c)).toList() : [];
    return list;
  }

  Future<List<Session>> getSessions({
    int offset = 0,
    int limit = 1000,
  }) async {
    final db = await database;
    var res = await db
        .rawQuery('SELECT * FROM Session LIMIT ? OFFSET ?', [limit, offset]);
    List<Session> list =
        res.isNotEmpty ? res.map((c) => Session.fromMap(c)).toList() : [];
    return list;
  }

  Future<Map<Session, Message?>> getSessionsWithLastMessage(
      {int offset = 0, int limit = 1000}) async {
    final db = await database;
    var res = await db
        .rawQuery('SELECT * FROM Session LIMIT ? OFFSET ?', [limit, offset]);
    List<Session> list =
        res.isNotEmpty ? res.map((c) => Session.fromMap(c)).toList() : [];
    Map<Session, Message?> map = {};
    for (Session session in list) {
      var res = await db.rawQuery(
          'SELECT * FROM Message WHERE sessionId = ? ORDER BY time DESC LIMIT 1',
          [session.id]);
      Message? message = res.isNotEmpty ? Message.fromMap(res.first) : null;
      map[session] = message;
    }
    return map;
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    var res = await db.rawDelete('DELETE FROM Session WHERE id = ?', [id]);
    return res;
  }

  Future<int> deleteAllSessions() async {
    final db = await database;
    var res = await db.rawDelete('DELETE FROM Session');
    return res;
  }

  Future<String?> getLanguage() async {
    final prefs = await preferences;
    return prefs.getString('language');
  }

  Future<bool> setLanguage(String language) async {
    final prefs = await preferences;
    return prefs.setString('language', language);
  }

  Future<bool?> getAutoReadAloud() async {
    final prefs = await preferences;
    return prefs.getBool('autoReadAloud');
  }

  Future<bool> setAutoReadAloud(bool autoReadAloud) async {
    final prefs = await preferences;
    return prefs.setBool('autoReadAloud', autoReadAloud);
  }
}
