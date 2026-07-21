import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game_models.dart';
import 'game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize(); // Initialize Google Ads Engine
  runApp(HundredGameApp());
}

class HundredGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '100 Card Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0F172A),
        primaryColor: Colors.amber,
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
  UserProfile userProfile = UserProfile();

  final List<String> avatars = ["👑", "🥷", "🦁", "🃏", "⚡", "💎", "🐉", "🔥"];
  final TextEditingController _nameController = TextEditingController();

  int selectedPlayers = 4;
  int targetScore = 100;

  @override
  void initState() {
    super.initState();
    _nameController.text = userProfile.name;
  }

  void _showProfileEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempAvatar = userProfile.avatar;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1E293B),
              title: Text("Edit Profile & Avatar", style: TextStyle(color: Colors.amber)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Player 1 Name",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
                      ),
                    ),
                    SizedBox(height: 15),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Choose Avatar:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: avatars.map((av) {
                        bool isSelected = (av == tempAvatar);
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => tempAvatar = av);
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amber : Color(0xFF0F172A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white24,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: Text(av, style: TextStyle(fontSize: 26)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("CANCEL", style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  child: Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() {
                      userProfile.name = _nameController.text.trim().isEmpty ? "Player 1" : _nameController.text.trim();
                      userProfile.avatar = tempAvatar;
                    });
                    Navigator.pop(context);
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  void _startMatchWithCustomNames() {
    List<TextEditingController> controllers = List.generate(
      selectedPlayers,
      (index) => TextEditingController(
        text: index == 0 ? userProfile.name : "Player ${index + 1}",
      ),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E293B),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Enter Player Names", style: TextStyle(color: Colors.amber, fontSize: 18)),
              TextButton(
                child: Text("Auto Bots", style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                onPressed: () {
                  for (int i = 1; i < selectedPlayers; i++) {
                    controllers[i].text = "Bot ${i + 1}";
                  }
                },
              )
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(selectedPlayers, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: TextField(
                    controller: controllers[index],
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: index == 0 ? "Player 1 (You)" : "Player ${index + 1} Name",
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                      prefixIcon: Icon(index == 0 ? Icons.person : Icons.group, color: Colors.amber, size: 20),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    ),
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              child: Text("CANCEL", style: TextStyle(color: Colors.white54)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: Text("PLAY NOW", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                List<String> names = controllers.map((c) => c.text.trim().isEmpty ? "Player" : c.text.trim()).toList();
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      mode: GameMode.offline,
                      totalPlayers: selectedPlayers,
                      targetScore: targetScore,
                      playerNames: names,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade600, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _showProfileEditDialog,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.amber,
                                child: Text(userProfile.avatar, style: TextStyle(fontSize: 32)),
                              ),
                              Container(
                                padding: EdgeInsets.all(3),
                                decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                child: Icon(Icons.edit, size: 12, color: Colors.white),
                              )
                            ],
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userProfile.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              SizedBox(height: 2),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(10)),
                                child: Text("Level ${userProfile.level} Novice", style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings, color: Colors.amber),
                          onPressed: _showProfileEditDialog,
                        )
                      ],
                    ),
                    Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem("Matches", "${userProfile.totalMatches}"),
                        _buildStatItem("Wins", "${userProfile.totalWins}"),
                        _buildStatItem("Win Rate", "${userProfile.winRate.toStringAsFixed(0)}%"),
                      ],
                    )
                  ],
                ),
              ),

              SizedBox(height: 25),

              Text("🎮 Game Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
              SizedBox(height: 15),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(15)),
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
                        bool isSelected = selectedPlayers == count;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : Color(0xFF0F172A),
                            foregroundColor: isSelected ? Colors.black : Colors.white,
                          ),
                          onPressed: () => setState(() => selectedPlayers = count),
                          child: Text("$count Players"),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),

              SizedBox(height: 15),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(15)),
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
                            backgroundColor: isSelected ? Colors.amber : Color(0xFF0F172A),
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

              Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(Icons.play_arrow, size: 28),
                  label: Text("START MATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: _startMatchWithCustomNames,
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 2),
        Text(title, style: TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}
