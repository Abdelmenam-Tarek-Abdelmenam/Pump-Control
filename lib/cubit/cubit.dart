import 'package:calender_app/cubit/states.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import '../modules/event_data.dart';
import '../shared/messaging/fire_message.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitial());
  static AppCubit get(context) => BlocProvider.of(context);

  final fireBase = FirebaseDatabase.instance.reference();
  late Database database;
  bool thereNotification = false;
  late List<EventData> eventsData;

  Future<void> startApp(bool isNotification) async {
    emit(AppLoadingState());
    thereNotification = isNotification;
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
    List<Map<String, dynamic>> tempData = await database.query("data");
    eventsData = tempData.map((e) => EventData(e)).toList();
    emit(AppReadyState());
  }

  void saveTask(
      {required DateTime selectedDay,
      required TimeOfDay start,
      required TimeOfDay end,
      required BuildContext context,
      String? description}) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
    String formattedStart = start.format(context);
    String formattedEnd = end.format(context);
    description = description == "" ? null : description;
    print("date is $formattedDate");
    print("start at $formattedStart");
    print("end at $formattedEnd");
    Map<String, dynamic> rowData = {
      "description": description ?? "No description",
      "date": formattedDate,
      "startTime": formattedStart,
      "endTime": formattedEnd,
    };
    database.insert("data", rowData);

    eventsData.add(EventData(rowData));
    emit(AddTaskState());
  }

  void editTask(
      {required DateTime selectedDay,
      required TimeOfDay start,
      required TimeOfDay end,
      required BuildContext context,
      required int index,
      required int id,
      String? description}) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
    String formattedStart = start.format(context);
    String formattedEnd = end.format(context);
    description = description == "" ? null : description;
    Map<String, dynamic> rowData = {
      "description": description ?? "No description",
      "date": formattedDate,
      "startTime": formattedStart,
      "endTime": formattedEnd,
    };
    database.update("data", rowData, where: "id=$id");

    eventsData[index] = (EventData(rowData));
    emit(AddTaskState());
  }

  _notificationCallback(Map<String, dynamic> notificationData) async {
    thereNotification = true;
    emit(NewNotificationCome());
  }

  void setState() {
    emit(GeneralState());
  }
}
