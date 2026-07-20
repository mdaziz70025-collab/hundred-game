import 'package:flutter/material.dart';
import 'game_screen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.blue),
    home: GameScreen(),
  ));
}
