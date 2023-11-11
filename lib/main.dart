import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_todolist/models/todo.dart';
import '  TodoScreen.dart';

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo App',
      home: Home(),
    );
  }
}