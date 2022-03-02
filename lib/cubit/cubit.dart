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
    eventsData = tempData.map((e) => EventData(e, this)).toList();
    emit(AppReadyState());
  }

  Future<void> saveTask(
      {required DateTime selectedDay,
      required TimeOfDay start,
      required TimeOfDay end,
      required BuildContext context,
      String? description}) async {
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
    var id = await database.insert("data", rowData);
    rowData["id"] = id;
    eventsData.add(EventData(rowData, this));
    Navigator.pop(context);

    emit(AddTaskState());
  }

  Future<void> editTask(
      {required DateTime selectedDay,
      required TimeOfDay start,
      required TimeOfDay end,
      required BuildContext context,
      required int index,
      required int id,
      String? description}) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
    String formattedStart = start.format(context);
    String formattedEnd = end.format(context);
    description = description == "" ? null : description;
    Map<String, dynamic> rowData = {
      "description": description ?? "No description",
      "date": formattedDate,
      "startTime": formattedStart,
      "endTime": formattedEnd,
      "id": id
    };
    await database.update("data", rowData, where: "id=$id");
    List<Map<String, dynamic>> tempData = await database.query("data");
    eventsData = tempData.map((e) => EventData(e, this)).toList();

    Navigator.pop(context);
    emit(AddTaskState());
  }

  Future<void> deleteTask(
      {required int index, required int id, String? description}) async {
    await database.delete("data", where: "id=$id");
    List<Map<String, dynamic>> tempData = await database.query("data");
    eventsData = tempData.map((e) => EventData(e, this)).toList();
    emit(AddTaskState());
  }

  int differentTimeMinutes(TimeOfDay st, TimeOfDay en) {
    int startMinutes = (st.hour * 60 + st.minute);
    int endMinutes = (en.hour * 60 + en.minute);
    int difInMinutes = endMinutes - startMinutes;
    return difInMinutes;
  }

  String minutesFormatted(int total) {
    int minutes = 0;
    int hours = 0;
    int days = 0;

    if (total < 60) {
      return '$total m';
    } else {
      minutes = total % 60;
      hours = ((total - minutes) / 60).ceil();
    }
    if (hours > 24) {
      int newHours = hours;
      hours = hours % 24;
      days = ((newHours - hours) / 24).ceil();
      return '$hours h $minutes m';
    } else {
      return '$hours h $minutes m';
    }
  }

  _notificationCallback(Map<String, dynamic> notificationData) async {
    thereNotification = true;
    emit(NewNotificationCome());
  }

  void setState() {
    emit(GeneralState());
  }
}
