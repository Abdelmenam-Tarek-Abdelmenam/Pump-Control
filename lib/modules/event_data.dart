import 'package:calender_app/cubit/cubit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class EventData {
  late DateTime day;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  late String description;
  late int id;
  late EventState state;

  EventData(Map<String, dynamic> rowData, AppCubit cubit) {
    description = rowData['description'];
    id = rowData['id'];
    day = DateFormat('yyyy-MM-dd').parse(rowData['date']);
    final format = DateFormat.jm();
    startTime = TimeOfDay.fromDateTime(format.parse(rowData['startTime']));
    endTime = TimeOfDay.fromDateTime(format.parse(rowData['endTime']));

    // if not today
    DateTime today = DateTime.now();
    if (isSameDay(today, day)) {
      // may be done - waiting , running
      TimeOfDay now = TimeOfDay.now();
      if (cubit.differentTimeMinutes(now, startTime) > 0) {
        state = EventState.waiting;
      } else if (cubit.differentTimeMinutes(endTime, now) > 0) {
        state = EventState.done;
      } else {
        state = EventState.running;
      }

      ///
    } else {
      // may be old or new
      bool isOld = today.difference(day).isNegative;
      if (isOld) {
        state = EventState.waiting;
      } else {
        state = EventState.done;
      }
    }
  }
}

enum EventState { waiting, running, done }
