import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game_models.dart';
import 'game_screen.dart';
import 'friend_room_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(HundredCardApp());
}

class HundredCardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '100 Card Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF1B2A47),
        primarySwatch: Colors.amber,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalPlayers = 2;
  int targetScore = 100;

  void _startPassAndPlay() {
    List<String> defaultNames = List.generate(totalPlayers, (index) => "Player ${index + 1}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          mode: GameMode.passNPlay, // 👈 Fixed GameMode name
          totalPlayers: totalPlayers,
          targetScore: targetScore,
          playerNames: defaultNames,
          isHost: true,
        ),
      ),
    );
  }

  void _openFriendMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendRoomScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1B2A47),
      appBar: AppBar(
        title: Text("100 Card Game", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        backgroundColor: Color(0xFF0F172A),
        elevation: 4,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.style, size: 80, color: Colors.amber),
              SizedBox(height: 10),
              Text(
                "100 Card Game",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              SizedBox(height: 25),

              // Select Players Option
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Select Players:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [2, 3, 4].map((count) {
                        bool isSelected = totalPlayers == count;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : Color(0xFF1B2A47),
                            foregroundColor: isSelected ? Colors.black : Colors.white,
                          ),
                          onPressed: () => setState(() => totalPlayers = count),
                          child: Text("$count Players"),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),

              SizedBox(height: 15),

              // Select Target Score Option
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Target Score:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [100, 200, 500].map((score) {
                        bool isSelected = targetScore == score;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : Color(0xFF1B2A47),
                            foregroundColor: isSelected ? Colors.black : Colors.white,
                          ),
                          onPressed: () => setState(() => targetScore = score),
                          child: Text("$score Pts"),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),

              SizedBox(height: 35),

              // 1. PASS & PLAY BUTTON
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.phone_android, color: Colors.white),
                label: Text("PASS & PLAY (OFFLINE)", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _startPassAndPlay,
              ),

              SizedBox(height: 15),

              // 2. PLAY WITH FRIENDS BUTTON
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.groups, color: Colors.white),
                label: Text("PLAY WITH FRIENDS (ONLINE)", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _openFriendMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
