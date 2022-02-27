import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../cubit/cubit.dart';
import '../cubit/states.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (BuildContext context, AppStates state) {},
      builder: (BuildContext context, AppStates state) {
        AppCubit cubit = AppCubit.get(context);
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              cubit.dataBase.child("test").update({"val": "val"});
            },
            child: const Icon(Icons.eight_k),
          ),
          appBar: AppBar(
            title: const Text("Calender Control"),
          ),
          body: TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              focusedDay: _focusedDay,
              onDaySelected: (selectedDay, focusedDay) {
                print(selectedDay);
                setState(() {
                  _focusedDay = selectedDay;
                });
                print(focusedDay);
              }),
        );
      },
    );
  }
}
