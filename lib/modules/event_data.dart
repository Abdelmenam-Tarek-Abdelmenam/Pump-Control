import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventData {
  late DateTime day;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  late String description;

  EventData(Map<String, dynamic> rowData) {
    description = rowData['description'];
    day = DateFormat('yyyy-MM-dd').parse(rowData['date']);
    final format = DateFormat.jm();
    startTime = TimeOfDay.fromDateTime(format.parse(rowData['startTime']));
    endTime = TimeOfDay.fromDateTime(format.parse(rowData['endTime']));
  }
}
