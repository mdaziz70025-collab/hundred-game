import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game_models.dart';
import 'game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Google Test Banner ID
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
    for (var controller in nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updatePlayerControllers(int count) {
    if (count > nameControllers.length) {
      for (int i = nameControllers.length; i < count; i++) {
        nameControllers.add(TextEditingController(text: "Player ${i + 1}"));
      }
    }
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
                        ButtonSegment(value: GameMode.offline, label: Text("Offline (Pass & Play)")),
                        ButtonSegment(value: GameMode.vsComputer, label: Text("VS Computer")),
                      ],
                      selected: {selectedMode},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          selectedMode = newSelection.first;
                        });
                      },
                    ),

                    SizedBox(height: 20),
                    Text("Number of Players", style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [2, 3, 4].map((count) {
                        return ChoiceChip(
                          label: Text("$count Players"),
                          selected: totalPlayers == count,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                totalPlayers = count;
                                _updatePlayerControllers(count);
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20),
                    Text("Target Score", style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [300, 500, 1000].map((score) {
                        return ChoiceChip(
                          label: Text("$score Pts"),
                          selected: targetScore == score,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                targetScore = score;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20),
                    Text("Player Names", style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Column(
                      children: List.generate(totalPlayers, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextField(
                            controller: nameControllers[index],
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Player ${index + 1} Name",
                              labelStyle: TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Color(0xFF0F172A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 25),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("START GAME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        List<String> names = List.generate(
                          totalPlayers,
                          (i) => nameControllers[i].text.trim().isEmpty ? "Player ${i + 1}" : nameControllers[i].text.trim(),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              mode: selectedMode,
                              totalPlayers: totalPlayers,
                              targetScore: targetScore,
                              playerNames: names,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // BANNER AD AT THE BOTTOM
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
