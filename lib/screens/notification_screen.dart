import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../cubit/cubit.dart';
import '../cubit/states.dart';
import '../reusable/reusable_functions.dart';

// ignore: must_be_immutable
class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Database database;

  _NotificationPageState() {
    _readData();
  }

  List<Map<String, dynamic>>? data;

  bool loading = true;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (BuildContext context, AppStates state) {},
      builder: (BuildContext context, AppStates state) {
        AppCubit cubit = AppCubit.get(context);
        if (cubit.thereNotification & !loading) {
          cubit.thereNotification = false;
          _readData();
        }
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            foregroundColor: Colors.blue,
            backgroundColor: Colors.white,
            title: const Text(
              'Notifications',
              style: TextStyle(
                  //fontSize: 25,
                  //fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    removeAll();
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.blue,
                  ))
            ],
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: (data ?? []).isEmpty
                      ? SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.notifications_off_outlined,
                                  size: 60, color: Colors.grey),
                              Text(
                                "There is No Notifications to Show",
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(
                                height: 50,
                              )
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text("Swipe to remove "),
                                Icon(Icons.swipe),
                              ],
                            ),
                            Expanded(
                              child: ListView.separated(
                                itemCount: data!.length,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (BuildContext context, int index) {
                                  index = data!.length - index - 1;
                                  Map<String, dynamic> notificationData =
                                      data![index];
                                  bool seen = notificationData['seen'] == 1;
                                  int id = notificationData['id'];
                                  notificationData =
                                      json.decode(notificationData['data']);
                                  return defaultWidget(
                                      seen: seen,
                                      index: index,
                                      id: id,
                                      subTitle: notificationData['title'] ??
                                          "no Title",
                                      title:
                                          notificationData['body'] ?? "no body",
                                      date: notificationData['date'] ??
                                          DateTime.now().toString());
                                },
                                separatorBuilder:
                                    (BuildContext context, int index) {
                                  return const Divider();
                                },
                              ),
                            ),
                          ],
                        ),
                ),
        );
      },
    );
  }

  _readData() async {
    database = await openDatabase(
      "notifications.db",
      version: 1,
      onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await db.execute('''CREATE TABLE "notification" (
                      "id"	INTEGER,
                      "seen"	INTEGER,
                  "data"	TEXT,
                PRIMARY KEY("id" AUTOINCREMENT)
                );''');
      },
    );

    data = await database.query("notification").catchError((error) {
      setState(() {
        loading = false;
      });
    });
    data = data!.map((e) => {...e}).toList();

    setState(() {
      loading = false;
    });

    _callback();
  }

  Widget defaultWidget(
      {required int index,
      required int id,
      required String title,
      String? subTitle,
      String? date,
      required bool seen}) {
    DateTime temp =
        DateFormat("yyyy-MM-dd hh:mm").parse(date ?? DateTime.now().toString());
    date = DateFormat('MM/dd/yyyy - hh:mm a').format(temp);

    return Dismissible(
      background: Container(
        color: Colors.red,
        child: const Icon(
          Icons.delete_outlined,
          size: 40,
        ),
      ),
      child: ListTile(
        tileColor: seen ? null : Colors.blue.withOpacity(0.2),
        isThreeLine: subTitle != null,
        leading: const Icon(Icons.notifications_none),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            subTitle == null ? Container() : Text(subTitle),
            Text(
              date,
              style: const TextStyle(color: Colors.green, fontSize: 15),
            )
          ],
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          data!.removeAt(index);
          database.delete("notification", where: "id=$id");
        });
      },
      key: UniqueKey(),
    );
  }

  void _callback() async {
    List<Map<String, dynamic>> newData;
    AppCubit cubit = AppCubit.get(context);
    cubit.thereNotification = false;
    cubit.setState();

    newData = await database.query("notification", where: "seen = 0");
    for (Map<String, dynamic> notificationData in newData) {
      int id = notificationData["id"];
      notificationData = json.decode(notificationData['data']);
      database.update("notification", {"seen": 1}, where: "id=$id");
    }
  }

  void removeAll() {
    database.delete("notification").then((value) {
      setState(() {
        if (data == null) {
          errorToast("No notification to delete");
        } else {
          data = [];
        }
      });
    }).catchError((err) {
      errorToast("Error while deleting data");
    });
  }
}
