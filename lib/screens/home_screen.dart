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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (BuildContext context, AppStates state) {},
      builder: (BuildContext context, AppStates state) {
        // AppCubit cubit = AppCubit.get(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text("Calender Control"),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _focusedDay,
                  startingDayOfWeek: StartingDayOfWeek.saturday,
                  calendarFormat: _calendarFormat,
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false,
                  ),
                  eventLoader: (DateTime date) {
                    if (date.day % 5 == 0) {
                      return ["kk", "kk"];
                    } else {
                      return [];
                    }
                  },
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                OutlinedButton(
                    onPressed: () {
                      _selectTime(context);
                    },
                    child: const Text("chooee Start Date")),
                OutlinedButton(
                    onPressed: () {
                      _selectTime(context);
                    },
                    child: const Text("choose end Date"))
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.now();
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    print(pickedTime);
  }
}
