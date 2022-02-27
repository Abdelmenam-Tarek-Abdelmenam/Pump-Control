import 'package:calender_app/cubit/states.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitial());
  static AppCubit get(context) => BlocProvider.of(context);

  final dataBase = FirebaseDatabase.instance.reference();

  void setState() {
    emit(GeneralState());
  }
}
