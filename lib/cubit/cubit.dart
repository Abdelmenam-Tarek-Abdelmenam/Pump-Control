import 'package:calender_app/cubit/states.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import '../shared/messaging/fire_message.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitial());
  static AppCubit get(context) => BlocProvider.of(context);

  final fireBase = FirebaseDatabase.instance.reference();
  late Database database;
  static bool thereNotification = false;

  Future<void> startApp(bool isNotification) async {
    emit(AppLoadingState());
    if (await Permission.notification.request().isGranted) {
      FireNotificationHelper(_notificationCallback);
    }
    database = await openDatabase(
      "data.db",
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''CREATE TABLE "data" (
                      "id"	INTEGER,
                      "description"	TEXT,
                      "date"	TEXT,
                      "startTime"	TEXT,
                      "endTime"	TEXT,
                PRIMARY KEY("id" AUTOINCREMENT)
                );''');
      },
    ).catchError((err) {
      print(err);
    });
    thereNotification = isNotification;
    emit(AppReadyState());
  }

  _notificationCallback(Map<String, dynamic> notificationData) async {
    thereNotification = true;
    emit(NewNotificationCome());
  }

  void setState() {
    emit(GeneralState());
  }
}
