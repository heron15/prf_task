import 'package:flutter/material.dart';
import 'package:prf_task/screen/home_screen.dart';

class PRFTaskApp extends StatefulWidget {
  const PRFTaskApp({super.key});

  @override
  State<PRFTaskApp> createState() => _PRFTaskAppState();
}

class _PRFTaskAppState extends State<PRFTaskApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
