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
  DateTime now = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (BuildContext context, AppStates state) {},
      builder: (BuildContext context, AppStates state) {
        AppCubit cubit = AppCubit.get(context);
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
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
                        firstDay:
                            DateTime.utc(now.year - 10, now.month, now.day),
                        lastDay:
                            DateTime.utc(now.year + 10, now.month, now.day),
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
              TimeOfDay? start;
              TimeOfDay? end;
              TextEditingController description = TextEditingController();

              showModalBottomSheet(
                context: context,
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                          "selected Date is ${DateFormat('dd-MM-yyyy').format(date)}"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              ElevatedButton(
                                  onPressed: () async {
                                    start = await _selectTime(context, start);
                                  },
                                  child: const Text("Start time")),
                              Text(
                                  "at ${start == null ? "" : start!.format(context)}")
                            ],
                          ),
                          Column(
                            children: [
                              ElevatedButton(
                                  onPressed: () async {
                                    end = await _selectTime(context, end);
                                  },
                                  child: const Text("end time")),
                              Text(
                                  "at ${end == null ? "" : end!.format(context)}")
                            ],
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: description,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'description',
                          prefixIcon: const Icon(Icons.message_outlined),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.blue, width: 2.0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      OutlinedButton(
                          onPressed: () {
                            cubit.saveTask(
                                selectedDay: date,
                                start: start!,
                                end: end!,
                                context: context,
                                description: description.text);
                          },
                          child: const Text("save"))
                    ],
                  ),
                ),
              );
            },
            child: const Text("ADD Task"))
      ],
    );
  }

  Future<TimeOfDay?> _selectTime(
      BuildContext context, TimeOfDay? initialTime) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    return pickedTime;
  }

  // LiquidCircularProgressIndicator(
//   value: 0.25,
//   valueColor: AlwaysStoppedAnimation(Colors.pink), // Defaults to the current Theme's accentColor.
//   backgroundColor: Colors.white,
//   borderColor: Colors.blue,
//   borderWidth: 5.0,
//   direction: Axis.vertical,
//   center: Text("Tank ${0.25} %"),
// );
}
