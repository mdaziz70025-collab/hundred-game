import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game_models.dart';
import 'game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase init error: $e");
  }
  MobileAds.instance.initialize();
  runApp(HundredCardApp());
}

class HundredCardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '100 Card Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0D1B2A),
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
  int totalPlayers = 4;
  int targetScore = 100;
  List<TextEditingController> nameControllers = [
    TextEditingController(text: "Guest Player"),
    TextEditingController(text: "Player 2"),
    TextEditingController(text: "Player 3"),
    TextEditingController(text: "Player 4"),
  ];

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBannerAd();
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad ID
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    for (var c in nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _showPlayerNamesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E293B),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Enter Player Names", style: TextStyle(color: Colors.amberAccent, fontSize: 18)),
              Text("Auto Bots", style: TextStyle(color: Colors.cyanAccent, fontSize: 14)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(totalPlayers, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: TextField(
                    controller: nameControllers[index],
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF0F172A),
                      labelText: index == 0 ? "Player 1 (You)" : "Player ${index + 1} Name",
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              child: Text("CANCEL", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: Text("PLAY NOW", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                List<String> names = nameControllers.take(totalPlayers).map((c) => c.text.isEmpty ? "Player" : c.text).toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      totalPlayers: totalPlayers,
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
      appBar: AppBar(
        title: Text("100 Card Game", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF0F172A),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Box (Screenshot Match)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.amber,
                                child: Icon(Icons.person, size: 35, color: Colors.black),
                              ),
                              SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Guest Player", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 5),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text("Level 1 Novice", style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              Spacer(),
                              IconButton(
                                icon: Icon(Icons.settings, color: Colors.amber),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          Divider(color: Colors.white24, height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(children: [
                                Text("0", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("Matches", style: TextStyle(color: Colors.white60, fontSize: 12)),
                              ]),
                              Column(children: [
                                Text("0", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("Wins", style: TextStyle(color: Colors.white60, fontSize: 12)),
                              ]),
                              Column(children: [
                                Text("0%", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("Win Rate", style: TextStyle(color: Colors.white60, fontSize: 12)),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Text("🎮 Game Settings", style: TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 15),
                    Text("Select Players:", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [2, 3, 4].map((count) {
                        bool isSelected = totalPlayers == count;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : Color(0xFF1E293B),
                            foregroundColor: isSelected ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("$count Players"),
                          onPressed: () => setState(() => totalPlayers = count),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    Text("Target Score:", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [100, 200, 500].map((score) {
                        bool isSelected = targetScore == score;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : Color(0xFF1E293B),
                            foregroundColor: isSelected ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("$score Pts"),
                          onPressed: () => setState(() => targetScore = score),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 35),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text("START MATCH", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      onPressed: _showPlayerNamesDialog,
                    ),
                  ],
                ),
              ),
            ),
            if (_isAdLoaded && _bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}
