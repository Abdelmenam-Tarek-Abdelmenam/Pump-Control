import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:sqflite/sqflite.dart';

class FireNotificationHelper {
  static Future<String?> token() => FirebaseMessaging.instance.getToken();
  final Function(Map<String, dynamic>) _callback;

  FireNotificationHelper(this._callback) {
    FirebaseMessaging.instance.subscribeToTopic("all").catchError((err) {
      print(err);
    });
    // app opened now
    FirebaseMessaging.onMessage
        .listen(_firebaseMessagingForegroundHandler)
        .onError((err) {
      print("err");
    });

    // app on back ground
    FirebaseMessaging.onMessageOpenedApp
        .listen(_firebaseMessagingBackgroundHandler)
        .onError((err) {
      print("err");
    });

    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundCloseHandler);
  }

  Future<void> _firebaseMessagingForegroundHandler(
      RemoteMessage message) async {
    Vibrate.vibrate();
    redirectPage(message.data);
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    redirectPage(message.data);
  }

  Future<void> redirectPage(Map<String, dynamic> data) async {
    Database database = await openDatabase(
      "notifications.db",
      version: 1,
      onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await db.execute('''CREATE TABLE "notification" (
                      "id"	INTEGER,
                      "seen"	INTEGER,
                  "data"	TEXT,
                PRIMARY KEY("id" AUTOINCREMENT)
                );''');
      },
    );

    database.insert("notification", {"seen": 0, "data": data.toString()});
    _callback(data);
  }
}

Future<void> _firebaseMessagingBackgroundCloseHandler(
    RemoteMessage message) async {
  Database database = await openDatabase(
    "notifications.db",
    version: 1,
    onCreate: (Database db, int version) async {
      // When creating the db, create the table
      await db.execute('''CREATE TABLE "notification" (
                      "id"	INTEGER,
                      "seen"	INTEGER,
                  "data"	TEXT,
                PRIMARY KEY("id" AUTOINCREMENT)
                );''');
    },
  );

  database.insert("notification", {"seen": 0, "data": message.data.toString()});
}
