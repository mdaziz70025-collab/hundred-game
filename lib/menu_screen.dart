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
  int selectedPlayers = 4;
  int selectedTarget = 500;

  late List<TextEditingController> nameControllers;

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  void _updateControllers() {
    nameControllers = List.generate(
      selectedPlayers,
      (i) => TextEditingController(
        text: i == 0 ? widget.userName : "Player ${i + 1}",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("100 Card Game - Setup"),
        backgroundColor: Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Mode:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
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

            Text("Number of Players:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [2, 3, 4].map((p) {
                return Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text("$p Players"),
                    selected: selectedPlayers == p,
                    onSelected: (val) {
                      setState(() {
                        selectedPlayers = p;
                        _updateControllers();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            Text("Target Points:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
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
            SizedBox(height: 20),

            // 5. PLAYERS NAME INPUT SYSTEM
            Text("Enter Player Names:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Column(
              children: List.generate(selectedPlayers, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TextField(
                    controller: nameControllers[index],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Player ${index + 1} Name",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("START GAME", style: TextStyle(fontSize: 20, color: Colors.white)),
              onPressed: () {
                List<String> names = nameControllers.map((c) => c.text.isEmpty ? "Player" : c.text).toList();
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
