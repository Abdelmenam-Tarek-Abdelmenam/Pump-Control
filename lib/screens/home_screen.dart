import 'package:calender_app/modules/event_data.dart';
import 'package:calender_app/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../cubit/cubit.dart';
import '../cubit/states.dart';
import '../reusable/reusable_functions.dart';

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
        AppCubit cubit = AppCubit.get(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text("Calender Control"),
            actions: [
              IconButton(
                iconSize: 30,
                onPressed: () {
                  navigateAndPush(context, const NotificationPage());
                },
                icon: cubit.thereNotification
                    ? Stack(
                        alignment: Alignment.topLeft,
                        children: const [
                          Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                          ),
                          CircleAvatar(
                            radius: 7,
                            backgroundColor: Colors.red,
                          ),
                        ],
                      )
                    : const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
              ),
            ],
          ),
          body: state is AppLoadingState
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                          return cubit.eventsData
                              .where((EventData element) =>
                                  isSameDay(date, element.day))
                              .toList();
                        },
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              // saved String
                              DateTime dateTime =
                                  DateFormat('yyyy-MM-dd').parse("2022-02-06");
                              print(dateTime);
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
                      const SizedBox(
                        height: 20,
                      ),
                      dayTasks(cubit, _selectedDay ?? DateTime.now())
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget dayTasks(AppCubit cubit, DateTime date) {
    List<EventData> data = cubit.eventsData
        .where((EventData element) => isSameDay(date, element.day))
        .toList();

    return Column(
      children: [
        data.isEmpty
            ? const Text("No Tasks for this day")
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  EventData event = data[index];
                  String formattedDate =
                      DateFormat('dd-MM-yyyy').format(event.day);
                  String formattedStart = event.startTime.format(context);
                  String formattedEnd = event.endTime.format(context);
                  return ListTile(
                    isThreeLine: true,
                    leading: CircleAvatar(
                      child: Text("${index + 1}"),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {},
                    ),
                    title: Text(event.description),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date $formattedDate"),
                        Text("Start at $formattedStart end at $formattedEnd")
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) {
                  return const Divider(
                    color: Colors.grey,
                  );
                },
                itemCount: data.length),
        const SizedBox(
          height: 10,
        ),
        OutlinedButton(
            onPressed: () {
              cubit.saveTask(
                  selectedDay: date,
                  start: const TimeOfDay(hour: 2, minute: 30),
                  end: const TimeOfDay(hour: 1, minute: 20),
                  context: context,
                  description: "water low");
              cubit.startApp(false);
            },
            child: const Text("ADD Task"))
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.now();

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime != null) {
      print(pickedTime.format(context));
    }
  }
}
