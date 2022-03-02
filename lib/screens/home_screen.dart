import 'package:calender_app/modules/event_data.dart';
import 'package:calender_app/screens/notification_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
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
  DateTime _focusedDay = DateTime.now();
  DateTime now = DateTime.now();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _selectedDay;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  double percentage = 50;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (BuildContext context, AppStates state) {},
      builder: (BuildContext context, AppStates state) {
        AppCubit cubit = AppCubit.get(context);
        Duration diff = DateTime.now().difference(_selectedDay ?? now);
        bool newDate = diff.isNegative || diff.inDays == 0;

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text(
              "Pump Tasks",
              style: TextStyle(color: Colors.blue),
            ),
            actions: [
              waterTank(percentage),
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
                            color: Colors.blue,
                          ),
                          CircleAvatar(
                            radius: 7,
                            backgroundColor: Colors.red,
                          ),
                        ],
                      )
                    : const Icon(
                        Icons.notifications,
                        color: Colors.blue,
                      ),
              ),
            ],
          ),
          floatingActionButton: newDate? FloatingActionButton(
            onPressed: (){
              showModalBottomSheet(
              context: context,
              barrierColor: Colors.white.withOpacity(0.8),
              elevation: 20,
              isScrollControlled: true,
              //constraints: const BoxConstraints(maxHeight: 650),
              backgroundColor: Colors.white,
              builder: (context) => BottomSheetLayout(
                  _selectedDay ?? now, false, null, null),
            );
            },
            child: const Icon(Icons.add,size: 40,),
          ) : null,
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
                        Container(
                          color: const Color(0xffECECEC),
                          child: TableCalendar(
                            headerStyle: const HeaderStyle(
                                titleCentered: true,
                              formatButtonVisible: false
                            ),

                            firstDay: DateTime.utc(now.year - 1, now.month, now.day),
                            lastDay: DateTime.utc(now.year + 1, now.month, now.day),
                            focusedDay: _focusedDay,
                            startingDayOfWeek: StartingDayOfWeek.saturday,
                            calendarFormat: CalendarFormat.month,

                            calendarStyle:    const CalendarStyle(
                              outsideDaysVisible: false,
                               markerDecoration: BoxDecoration(color: Colors.black,shape: BoxShape.circle),
                               selectedDecoration: BoxDecoration(color: Colors.blue,shape: BoxShape.circle),
                               todayDecoration: BoxDecoration(color: Colors.blueGrey,shape: BoxShape.circle),
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
    List<EventData> data = cubit.eventsData.where((EventData element) => isSameDay(date, element.day)).toList();

    int daysLeft = now.difference(date).inDays;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            height: 30,
            decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white),
                ),
                Text(
                  DateFormat('dd-MM-yyyy').format(date),
                  style: const TextStyle(
                      //fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white),
                ),
                DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    //fontWeight: FontWeight.bold,
                    fontSize: 18),
                    child: daysLeft == 0?
                    const Text(
                      "[ Today ]",
                    )
                        :
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("[ "),
                        Text(
                          "${daysLeft.abs()}",
                        ),
                        const Text(' Day'),
                        Text(daysLeft.abs() == 1? "":"s" ),
                        const Text(' left ]'),
                      ],
                    ),)
              ],
            ),
          ),
        ),
        const SizedBox(height: 10,),
        data.isEmpty
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.format_list_numbered,
                    size: 40,
                  ),
                  Text(
                    "  No Tasks",
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              )
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
                                  child: const Text("YES"),
                                ),
                              ],
                            ),
                          )) ??
                          false;
                    },
                    onDismissed: (_) {
                      cubit.deleteTask(index: index, id: event.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Deleted successfully'),
                        duration: Duration(seconds: 1),
                      ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ListTile(
                        onTap: (){
                          if(event.state == EventState.waiting){
                            showModalBottomSheet(
                              context: context,
                              barrierColor: Colors.white.withOpacity(0.8),
                              elevation: 20,
                              isScrollControlled: true,
                              //constraints: const BoxConstraints(maxHeight: 650),
                              backgroundColor: Colors.white,
                              builder: (context) => BottomSheetLayout(
                                  event.day, true, index, event),
                            );
                          }
                          },
                        tileColor: {
                          EventState.running: Colors.blue.withOpacity(0.3),
                          EventState.waiting: Colors.white.withOpacity(0.5),
                          EventState.done: Colors.grey.withOpacity(0.5)
                        }[event.state],
                        isThreeLine: true,
                        leading: CircleAvatar(
                          child: Text("${index + 1}"),
                        ),

                        title: Text(event.description),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Start at $formattedStart End at $formattedEnd"),
                            Row(
                              children: [
                                const Text("Duration : "),
                                Text(
                                  "${cubit.differentTimeMinutes(event.startTime, event.endTime)}",
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const Text(" min "),
                              ],
                            ),
                            event.state == EventState.running
                                ? Row(
                                    children: [
                                      const Text("End in "),
                                      Text(
                                        "${cubit.differentTimeMinutes(TimeOfDay.now(), event.endTime)}",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(" min"),
                                    ],
                                  )
                                : Container(),
                            event.state == EventState.waiting &&
                                    isSameDay(now, event.day)
                                ? Row(
                                    children: [
                                      const Text("Start in : "),
                                      Text(
                                        "${cubit.differentTimeMinutes(TimeOfDay.now(), event.startTime)}",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(" min"),
                                    ],
                                  )
                                : Container(),
                            event.state == EventState.done &&
                                    isSameDay(now, event.day)
                                ? Row(
                                    children: [
                                      const Text("Ended from : "),
                                      Text(
                                        "${cubit.differentTimeMinutes(event.endTime, TimeOfDay.now())}",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(" min"),
                                    ],
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Divider(
                      color: Colors.grey,
                    ),
                  );
                },
                itemCount: data.length),
      ],
    );
  }

  /// force stop now
  //  cubit.editTask(
  //                             selectedDay: date,
  //                             start: event.startTime,
  //                             end: TimeOfDay.now(),
  //                             context: context,
  //                             index: index,
  //                             id: event.id);
  Widget waterTank(double percentage) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: 90,
        //height: 60,
        child: LiquidLinearProgressIndicator(
          value: percentage / 100,
          valueColor: const AlwaysStoppedAnimation(Color(0xff85F4FF)),
          backgroundColor: Colors.white,
          borderColor: Colors.blue,
          borderWidth: 1.0,
          direction: Axis.vertical,
          center: Text(
            "${percentage.round()}%",
            style: const TextStyle(
                fontSize: 20,
                color:  Colors.blue,
                fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
