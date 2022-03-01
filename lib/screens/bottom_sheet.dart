import 'package:calender_app/modules/event_data.dart';
import 'package:calender_app/reusable/reusable_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubit/cubit.dart';
import '../cubit/states.dart';

// ignore: must_be_immutable
class BottomSheetLayout extends StatefulWidget {
  BottomSheetLayout(this.date, this.edit, this.index, this.eventData,
      {Key? key})
      : super(key: key);
  DateTime date;
  bool edit = false;
  EventData? eventData;
  int? index;

  @override
  // ignore: no_logic_in_create_state
  State<BottomSheetLayout> createState() => _BottomSheetLayoutState(date);
}

class _BottomSheetLayoutState extends State<BottomSheetLayout> {
  TextEditingController description = TextEditingController();
  TimeOfDay? start;
  TimeOfDay? end;
  DateTime date;
  int? differentTime;
  late int daysLeft;

  _BottomSheetLayoutState(this.date) {
    daysLeft = date.difference(DateTime.now()).inDays;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (widget.edit) {
        start = widget.eventData!.startTime;
        end = widget.eventData!.endTime;
        description.text = widget.eventData!.description;
        differentTime =
            AppCubit.get(context).differentTimeMinutes(start!, end!);
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (BuildContext context, AppStates state) {},
      builder: (BuildContext context, AppStates state) {
        AppCubit cubit = AppCubit.get(context);
        return GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Selected Date is ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      DateFormat('dd-MM-yyyy').format(date),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.blue),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: TextFormField(
                    controller: description,
                    minLines: 4,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'description',
                      prefixIcon: const Icon(Icons.message_outlined),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        OutlinedButton.icon(
                            onPressed: () async {
                              start = await _selectTime(context, start);
                              if (end != null) {
                                differentTime =
                                    cubit.differentTimeMinutes(start!, end!);
                              }
                              setState(() {});
                            },
                            icon: const Icon(Icons.timer_outlined),
                            label: const Text("Start time")),
                        Text(
                          start == null ? "" : start!.format(context),
                          style: const TextStyle(color: Colors.blue),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        OutlinedButton.icon(
                            onPressed: () async {
                              end = await _selectTime(context, end);
                              if (start != null) {
                                differentTime =
                                    cubit.differentTimeMinutes(start!, end!);
                              }
                              setState(() {});
                            },
                            icon: const Icon(Icons.timer_off_outlined),
                            label: const Text("end time")),
                        Text(
                          end == null ? "" : end!.format(context),
                          style: const TextStyle(color: Colors.blue),
                        )
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: differentTime == null ? 0 : 10,
                      ),
                      differenceTimeWidget(),
                      SizedBox(
                        height: differentTime == null ? 0 : 10,
                      ),
                      if (daysLeft == 0)
                        const Text(
                          "Date is Today",
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        )
                      else
                        Row(
                          children: [
                            const Text("days left : "),
                            Text(
                              "$daysLeft",
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            )
                          ],
                        ),
                      SizedBox(
                        height: (daysLeft == 0 && start != null) ? 10 : 0,
                      ),
                      daysLeft == 0 && start != null
                          ? cubit.differentTimeMinutes(
                                      TimeOfDay.now(), start!) <
                                  0
                              ? const Text(
                                  "invalid start",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                )
                              : Text(
                                  "left ${cubit.differentTimeMinutes(TimeOfDay.now(), start!)} minute to work")
                          : Container(),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        if (start == null || end == null) {
                          errorToast("Time can't be empty");
                        } else if (cubit.differentTimeMinutes(start!, end!) <=
                            0) {
                          infoToast("End time can't be before start");
                        } else if (daysLeft == 0 &&
                            cubit.differentTimeMinutes(
                                    TimeOfDay.now(), start!) <=
                                0) {
                          errorToast("Start Time invalid");
                        } else {
                          if (widget.edit) {
                            cubit.editTask(
                                selectedDay: date,
                                start: start!,
                                end: end!,
                                context: context,
                                description: description.text,
                                id: widget.eventData!.id,
                                index: widget.index!);
                          } else {
                            cubit.saveTask(
                                selectedDay: date,
                                start: start!,
                                end: end!,
                                context: context,
                                description: description.text);
                          }
                        }
                      },
                      child: Text(
                        widget.edit ? "Edit" : "Save",
                        style: const TextStyle(fontSize: 18),
                      )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget differenceTimeWidget() {
    return differentTime == null
        ? Container()
        : differentTime! <= 0
            ? const Center(
                child: Text(
                  "invalid times",
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              )
            : Row(
                children: [
                  const Text("Duration in minutes : "),
                  Text(
                    "$differentTime",
                    style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  )
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
}
