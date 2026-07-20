import 'package:flutter/material.dart';

void main() {
  runApp(const HundredGame());
}

class HundredGame extends StatelessWidget {
  const HundredGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Hundred Game')),
        body: const Center(child: GameCounter()),
      ),
    );
  }
}

class GameCounter extends StatefulWidget {
  const GameCounter({super.key});
  @override
  State<GameCounter> createState() => _GameCounterState();
}

class _GameCounterState extends State<GameCounter> {
  int _counter = 0;

  void _increment() {
    setState(() {
      if (_counter < 100) _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Score: $_counter', style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _increment,
          child: const Text('Tap to Count'),
        ),
      ],
    );
  }
}