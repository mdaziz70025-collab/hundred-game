import 'package:flutter/material.dart';
import 'game_models.dart';
import 'game_screen.dart';

class MenuScreen extends StatefulWidget {
  final String userName;
  MenuScreen({required this.userName});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  GameMode selectedMode = GameMode.offline;
  int selectedPlayers = 2;
  int selectedTarget = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome, ${widget.userName}")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Mode:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                ChoiceChip(
                  label: Text("Offline (Same Phone)"),
                  selected: selectedMode == GameMode.offline,
                  onSelected: (val) => setState(() => selectedMode = GameMode.offline),
                ),
                SizedBox(width: 10),
                ChoiceChip(
                  label: Text("Online (Room)"),
                  selected: selectedMode == GameMode.online,
                  onSelected: (val) => setState(() => selectedMode = GameMode.online),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Number of Players:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [2, 3, 4].map((p) {
                return Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text("$p Players"),
                    selected: selectedPlayers == p,
                    onSelected: (val) => setState(() => selectedPlayers = p),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text("Target Points:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [300, 500, 1000].map((t) {
                return Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text("$t Pts"),
                    selected: selectedTarget == t,
                    onSelected: (val) => setState(() => selectedTarget = t),
                  ),
                );
              }).toList(),
            ),
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              child: Text("START GAME", style: TextStyle(fontSize: 20)),
              onPressed: () {
                List<String> names = List.generate(selectedPlayers, (i) => i == 0 ? widget.userName : "Player ${i + 1}");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      mode: selectedMode,
                      totalPlayers: selectedPlayers,
                      targetScore: selectedTarget,
                      playerNames: names,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
