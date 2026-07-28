import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'game_models.dart';
import 'game_screen.dart';

class FriendRoomScreen extends StatefulWidget {
  @override
  _FriendRoomScreenState createState() => _FriendRoomScreenState();
}

class _FriendRoomScreenState extends State<FriendRoomScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  bool isLoading = false;
  String errorMessage = "";

  String _generateRoomCode() {
    var rng = Random();
    return (1000 + rng.nextInt(9000)).toString();
  }

  void _createRoom() async {
    String name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => errorMessage = "Kripya apna naam likhein!");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    String roomCode = _generateRoomCode();

    try {
      await _dbRef.child("rooms").child(roomCode).set({
        "roomCode": roomCode,
        "hostName": name,
        "players": [name],
        "targetScore": 100,
        "status": "waiting",
        "createdAt": ServerValue.timestamp,
      });

      if (!mounted) return;
      setState(() => isLoading = false);

      _showWaitingDialog(roomCode, name, isHost: true);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error creating room: $e";
      });
    }
  }

  void _joinRoom() async {
    String name = _nameController.text.trim();
    String code = _roomCodeController.text.trim();

    if (name.isEmpty || code.isEmpty) {
      setState(() => errorMessage = "Naam aur Room Code dono bharein!");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      DataSnapshot snapshot = await _dbRef.child("rooms").child(code).get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> roomData = snapshot.value as Map<dynamic, dynamic>;
        List<dynamic> players = List.from(roomData['players'] ?? []);

        if (players.length >= 4) {
          setState(() {
            isLoading = false;
            errorMessage = "Room full ho chuka hai! (Max 4 players)";
          });
          return;
        }

        if (!players.contains(name)) {
          players.add(name);
          await _dbRef.child("rooms").child(code).update({"players": players});
        }

        if (!mounted) return;
        setState(() => isLoading = false);

        _showWaitingDialog(code, name, isHost: false);
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Sahi Room Code daalein! Yeh room nahi mila.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error joining room: $e";
      });
    }
  }

  void _showWaitingDialog(String roomCode, String currentUserName, {required bool isHost}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder(
          stream: _dbRef.child("rooms").child(roomCode).onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
              return AlertDialog(
                backgroundColor: Color(0xFF0F172A),
                title: Text("Connecting...", style: TextStyle(color: Colors.white)),
                content: CircularProgressIndicator(color: Colors.amber),
              );
            }

            Map<dynamic, dynamic> roomData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            List<String> players = List<String>.from(roomData['players'] ?? []);
            String status = roomData['status'] ?? "waiting";

            if (status == "playing") {
              Future.microtask(() {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      mode: GameMode.friend,
                      totalPlayers: players.length,
                      targetScore: roomData['targetScore'] ?? 100,
                      playerNames: players,
                    ),
                  ),
                );
              });
            }

            return AlertDialog(
              backgroundColor: Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Column(
                children: [
                  Text("🏠 Private Room", style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.indigo.shade900, borderRadius: BorderRadius.circular(8)),
                    child: Text("CODE: $roomCode", style: TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Dost ko yeh Code bataiye:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 15),
                  Text("Joined Players (${players.length}/4):", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ...players.map((p) => ListTile(
                        dense: true,
                        leading: Icon(Icons.person, color: Colors.amber),
                        title: Text(p, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                ],
              ),
              actions: [
                TextButton(
                  child: Text("LEAVE ROOM", style: TextStyle(color: Colors.redAccent)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                if (isHost)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("START GAME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: players.length >= 2
                        ? () {
                            _dbRef.child("rooms").child(roomCode).update({"status": "playing"});
                          }
                        : null,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1B2A47),
      appBar: AppBar(
        title: Text("Play With Friends"),
        backgroundColor: Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            Icon(Icons.groups, size: 80, color: Colors.amber),
            SizedBox(height: 10),
            Text("Friend Mode", textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
            Text("Private Room banayein ya apne dosto ke saath join karein", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 30),

            TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Apna Naam Likhein",
                labelStyle: TextStyle(color: Colors.amberAccent),
                prefixIcon: Icon(Icons.person, color: Colors.amber),
                filled: true,
                fillColor: Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),

            if (isLoading)
              Center(child: CircularProgressIndicator(color: Colors.amber))
            else ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.add_box, color: Colors.white),
                label: Text("CREATE ROOM (HOST)", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _createRoom,
              ),

              SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white30)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text("OR JOIN EXISTING ROOM", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: Colors.white30)),
                ],
              ),
              SizedBox(height: 25),

              TextField(
                controller: _roomCodeController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "4-Digit Room Code Daalein",
                  labelStyle: TextStyle(color: Colors.amberAccent),
                  prefixIcon: Icon(Icons.key, color: Colors.amber),
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 15),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.login, color: Colors.white),
                label: Text("JOIN ROOM", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _joinRoom,
              ),
            ],

            if (errorMessage.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(errorMessage, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ]
          ],
        ),
      ),
    );
  }
}
