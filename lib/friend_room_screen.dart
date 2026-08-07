import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game_models.dart';
import 'game_screen.dart';

class FriendRoomScreen extends StatefulWidget {
  final String? userName;

  const FriendRoomScreen({Key? key, this.userName}) : super(key: key);

  @override
  _FriendRoomScreenState createState() => _FriendRoomScreenState();
}

class _FriendRoomScreenState extends State<FriendRoomScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  bool isLoading = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    String currentName = FirebaseAuth.instance.currentUser?.displayName ?? widget.userName ?? "";
    if (currentName.isNotEmpty) {
      _nameController.text = currentName;
    }
  }

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
        "currentDealerIndex": 0,
        "totalRoundsPlayed": 1,
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
              return const AlertDialog(
                backgroundColor: Color(0xFF0F172A),
                title: Text("Connecting...", style: TextStyle(color: Colors.white)),
                content: CircularProgressIndicator(color: Colors.amber),
              );
            }

            Map<dynamic, dynamic> roomData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            List<String> players = List<String>.from(roomData['players'] ?? []);
            String status = roomData['status'] ?? "waiting";
            String hostName = roomData['hostName'] ?? "";

            if (status == "playing") {
              List<String> orderedPlayers = List<String>.from(players);
              int myIndex = orderedPlayers.indexOf(currentUserName);
              if (myIndex != -1 && myIndex != 0) {
                List<String> rotated = [];
                for (int i = 0; i < orderedPlayers.length; i++) {
                  rotated.add(orderedPlayers[(myIndex + i) % orderedPlayers.length]);
                }
                orderedPlayers = rotated;
              }

              Future.microtask(() {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      mode: GameMode.friend,
                      totalPlayers: orderedPlayers.length,
                      targetScore: roomData['targetScore'] ?? 100,
                      playerNames: orderedPlayers,
                      isHost: isHost,
                      roomCode: roomCode,
                      myPlayerName: currentUserName,
                    ),
                  ),
                );
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Column(
                children: [
                  const Text("🏠 Private Room", style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.indigo.shade900, borderRadius: BorderRadius.circular(8)),
                    child: Text("CODE: $roomCode", style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Dost ko yeh Code bataiye:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 15),
                  Text("Joined Players (${players.length}/4):", style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...players.map((p) => ListTile(
                        dense: true,
                        leading: Icon(Icons.person, color: p == hostName ? Colors.amber : Colors.white70),
                        title: Text("$p ${p == hostName ? '(Host)' : ''}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("LEAVE ROOM", style: TextStyle(color: Colors.redAccent)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                if (isHost)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("START GAME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFF1B2A47),
      appBar: AppBar(
        title: const Text("Play With Friends"),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.groups, size: 80, color: Colors.amber),
            const SizedBox(height: 10),
            const Text("Friend Mode", textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Private Room banayein ya apne dosto ke saath join karein", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 30),

            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Apna Naam Likhein",
                labelStyle: const TextStyle(color: Colors.amberAccent),
                prefixIcon: const Icon(Icons.person, color: Colors.amber),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.amber))
            else ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_box, color: Colors.white),
                label: const Text("CREATE ROOM (HOST)", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _createRoom,
              ),

              const SizedBox(height: 25),
              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.white30)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text("OR JOIN EXISTING ROOM", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: Colors.white30)),
                ],
              ),
              const SizedBox(height: 25),

              TextField(
                controller: _roomCodeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "4-Digit Room Code Daalein",
                  labelStyle: const TextStyle(color: Colors.amberAccent),
                  prefixIcon: const Icon(Icons.key, color: Colors.amber),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text("JOIN ROOM", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _joinRoom,
              ),
            ],

            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(errorMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ]
          ],
        ),
      ),
    );
  }
}
