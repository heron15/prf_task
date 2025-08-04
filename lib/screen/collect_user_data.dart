import 'package:flutter/material.dart';

class CollectUserData extends StatefulWidget {
  const CollectUserData({super.key});

  @override
  State<CollectUserData> createState() => _CollectUserDataState();
}

class _CollectUserDataState extends State<CollectUserData> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collect User Data'),
      ),
      body: const Center(
        child: Text('Collect User Data'),
      ),
    );
  }
}