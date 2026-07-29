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
  UserProfile userProfile = UserProfile();

  void _startOfflineGame() {
    List<String> defaultNames = List.generate(totalPlayers, (index) => "Player ${index + 1}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          mode: GameMode.offline,
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
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.amber,
                      child: Text(userProfile.avatar, style: TextStyle(fontSize: 26)),
                    ),
                    SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userProfile.name, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Win Rate: ${userProfile.winRate.toStringAsFixed(1)}%", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25),

              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Select Players:", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [2, 3, 4].map((count) {
                        bool isSelected = totalPlayers == count;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : Color(0xFF1B2A47),
                            foregroundColor: isSelected ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => setState(() => totalPlayers = count),
                          child: Text("$count Players", style: TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),

              SizedBox(height: 15),

              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Target Score:", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [100, 200, 500].map((score) {
                        bool isSelected = targetScore == score;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : Color(0xFF1B2A47),
                            foregroundColor: isSelected ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => setState(() => targetScore = score),
                          child: Text("$score Pts", style: TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),

              SizedBox(height: 30),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  minimumSize: Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.phone_android, color: Colors.white),
                label: Text("PASS & PLAY (OFFLINE)", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _startOfflineGame,
              ),

              SizedBox(height: 15),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  minimumSize: Size(double.infinity, 52),
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
