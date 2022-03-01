import 'package:calender_app/modules/event_data.dart';
import 'package:calender_app/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:table_calendar/table_calendar.dart';

import '../cubit/cubit.dart';
import '../cubit/states.dart';
import '../reusable/reusable_functions.dart';
import 'bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime now = DateTime.now();
  DateTime? _selectedDay;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

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
              : SmartRefresher(
                  enablePullUp: false,
                  controller: _refreshController,
                  onRefresh: () async {
                    List<Map<String, dynamic>> tempData =
                        await cubit.database.query("data");
                    cubit.eventsData =
                        tempData.map((e) => EventData(e, cubit)).toList();
                    cubit.setState();
                    _refreshController.refreshCompleted();
                  },
                  child: SingleChildScrollView(
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
                                _focusedDay = focusedDay;
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
                ),
        );
      },
    );
  }

  Widget dayTasks(AppCubit cubit, DateTime date) {
    List<EventData> data = cubit.eventsData
        .where((EventData element) => isSameDay(date, element.day))
        .toList();
    Duration diff = DateTime.now().difference(date);
    bool newDate = diff.isNegative || diff.inDays == 0;
    int daysLeft = now.difference(date).inDays;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Selected Date is ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              DateFormat('dd-MM-yyyy').format(date),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blue),
            )
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        if (daysLeft == 0)
          const Text(
            "Date is Today",
            style: TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 15),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("days left : "),
              Text(
                "${daysLeft.abs()}",
                style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              )
            ],
          ),
        const SizedBox(
          height: 10,
        ),
        data.isEmpty
            ? const Text("No Tasks for this day")
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  EventData event = data[index];

                  String formattedStart = event.startTime.format(context);
                  String formattedEnd = event.endTime.format(context);

                  return Dismissible(
                    background: Container(
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    key: UniqueKey(),
                    confirmDismiss: (_) async {
                      if (event.state == EventState.running) {
                        errorToast("Task is running");
                        return Future.value(false);
                      }
                      return (await showDialog<bool?>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Warning ..."),
                              content: const Text(
                                  "Are Tou Sure you wan't to delete the task"),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("NO"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("yES"),
                                ),
                              ],
                            ),
                          )) ??
                          false;
                    },
                    onDismissed: (_) {
                      cubit.deleteTask(index: index, id: event.id);
                    },
                    child: ListTile(
                      tileColor: {
                        EventState.running: Colors.green.withOpacity(0.5),
                        EventState.waiting: Colors.blue.withOpacity(0.5),
                        EventState.done: Colors.grey.withOpacity(0.5)
                      }[event.state],
                      isThreeLine: true,
                      leading: CircleAvatar(
                        child: Text("${index + 1}"),
                      ),
                      trailing: SizedBox(
                        width: event.state == EventState.waiting ? 50 : 0,
                        child: Row(
                          children: [
                            event.state == EventState.waiting
                                ? IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => showModalBottomSheet(
                                          context: context,
                                          builder: (context) =>
                                              BottomSheetLayout(event.day, true,
                                                  index, event),
                                        ))
                                : Container(),
                          ],
                        ),
                      ),
                      title: Text(event.description),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Start at $formattedStart end at $formattedEnd"),
                          Row(
                            children: [
                              const Text("Duration in minutes : "),
                              Text(
                                "${cubit.differentTimeMinutes(event.startTime, event.endTime)}",
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              )
                            ],
                          ),
                          event.state == EventState.running
                              ? Row(
                                  children: [
                                    const Text("minutes to stop "),
                                    Text(
                                      "${cubit.differentTimeMinutes(TimeOfDay.now(), event.endTime)}",
                                      style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    )
                                  ],
                                )
                              : Container(),
                          event.state == EventState.waiting &&
                                  isSameDay(now, event.day)
                              ? Row(
                                  children: [
                                    const Text("Minutes to work : "),
                                    Text(
                                      "${cubit.differentTimeMinutes(TimeOfDay.now(), event.startTime)}",
                                      style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    )
                                  ],
                                )
                              : Container(),
                          event.state == EventState.done &&
                                  isSameDay(now, event.day)
                              ? Row(
                                  children: [
                                    const Text("Minutes from stop : "),
                                    Text(
                                      "${cubit.differentTimeMinutes(event.endTime, TimeOfDay.now())}",
                                      style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    )
                                  ],
                                )
                              : Container(),
                        ],
                      ),
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
        newDate
            ? OutlinedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) =>
                        BottomSheetLayout(date, false, null, null),
                  );
                },
                child: const Text("ADD Task"))
            : Container()
      ],
    );
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
