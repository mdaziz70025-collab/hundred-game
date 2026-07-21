import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'game_models.dart';
import 'game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase init note: $e");
  }
  MobileAds.instance.initialize();
  runApp(HundredGameApp());
}

class HundredGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '100 Card Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Color(0xFF1B2A47),
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
  GameMode selectedMode = GameMode.offline;
  int totalPlayers = 4;
  int targetScore = 500;
  TextEditingController roomCodeController = TextEditingController();
  TextEditingController myNameController = TextEditingController(text: "Player 1");

  List<TextEditingController> nameControllers = [
    TextEditingController(text: "Aziz"),
    TextEditingController(text: "Mijanur"),
    TextEditingController(text: "Bozlul"),
    TextEditingController(text: "Robiul"),
  ];

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
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
    roomCodeController.dispose();
    myNameController.dispose();
    for (var controller in nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _generateRoomCode() {
    var rng = Random();
    return (1000 + rng.nextInt(9000)).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("100 Card Game", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF0F172A),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Select Game Mode", style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    SegmentedButton<GameMode>(
                      segments: [
                        ButtonSegment(value: GameMode.offline, label: Text("Offline")),
                        ButtonSegment(value: GameMode.online, label: Text("Online 🌐")),
                      ],
                      selected: {selectedMode},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          selectedMode = newSelection.first;
                        });
                      },
                    ),

                    SizedBox(height: 20),
                    if (selectedMode == GameMode.online) ...[
                      Text("Your Name", style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      TextField(
                        controller: myNameController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text("Enter Room Code (If Joining)", style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      TextField(
                        controller: roomCodeController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white, letterSpacing: 3, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: "e.g. 4821",
                          hintStyle: TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 20),
                    ] else ...[
                      Text("Number of Players", style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [2, 3, 4].map((count) {
                          return ChoiceChip(
                            label: Text("$count Players"),
                            selected: totalPlayers == count,
                            onSelected: (selected) {
                              if (selected) setState(() => totalPlayers = count);
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20),
                    ],

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        selectedMode == GameMode.online
                            ? (roomCodeController.text.trim().isEmpty ? "CREATE ROOM & PLAY" : "JOIN ROOM & PLAY")
                            : "START GAME",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        String code = roomCodeController.text.trim().isEmpty ? _generateRoomCode() : roomCodeController.text.trim();
                        List<String> names = selectedMode == GameMode.online
                            ? [myNameController.text.trim().isEmpty ? "Player 1" : myNameController.text.trim()]
                            : List.generate(totalPlayers, (i) => nameControllers[i].text.trim().isEmpty ? "Player ${i + 1}" : nameControllers[i].text.trim());

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              mode: selectedMode,
                              totalPlayers: totalPlayers,
                              targetScore: targetScore,
                              playerNames: names,
                              roomCode: code,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (_isBannerAdLoaded && _bannerAd != null)
              Container(
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
