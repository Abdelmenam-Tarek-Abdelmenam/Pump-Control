import 'package:calender_app/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';

import 'cubit/cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(// navigation bar color
    statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,

  ));
  await Firebase.initializeApp();
  bool newNotification = false;
  Database database = await openDatabase(
    "notifications.db",
    version: 1,
    onCreate: (Database db, int version) async {
      await db.execute('''CREATE TABLE "notification" (
                      "id"	INTEGER,
                      "seen"	INTEGER,
                      "data"	TEXT,
                PRIMARY KEY("id" AUTOINCREMENT)
                );''');
    },
  ).catchError((err) {
    print(err);
  });
  try {
    newNotification =
        (await database.query("notification", where: "seen=0")).isNotEmpty;
  } catch (err) {
    newNotification = false;
    print(err);
  }

  runApp(MyApp(newNotification));
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  MyApp(this.newNotification, {Key? key}) : super(key: key);
  bool newNotification;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => AppCubit()..startApp(newNotification),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Calender APP',
        home: HomeScreen(),
      ),
    );
  }
}
