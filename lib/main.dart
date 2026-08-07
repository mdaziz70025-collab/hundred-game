import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game_models.dart';
import 'game_screen.dart';
import 'friend_room_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("MobileAds init error: $e");
  }

  runApp(HundredGameApp());
}

class HundredGameApp extends StatefulWidget {
  @override
  _HundredGameAppState createState() => _HundredGameAppState();
}

class _HundredGameAppState extends State<HundredGameApp> {
  AppOpenAdManager appOpenAdManager = AppOpenAdManager();

  @override
  void initState() {
    super.initState();
    appOpenAdManager.loadAd();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '100 Card Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.amber,
      ),
      home: HomeScreen(),
    );
  }
}

class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  final String _appOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';

  void loadAd() {
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          showAdIfAvailable();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  void showAdIfAvailable() {
    if (_appOpenAd != null && !_isShowingAd) {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
        },
        onAdDismissedFullScreenContent: (ad) {
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
        },
      );
      _appOpenAd!.show();
    }
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile userProfile = UserProfile();
  User? _currentUser;

  final List<String> avatars = ["👑", "🥷", "🦁", "🃏", "⚡", "💎", "🐉", "🔥"];
  final TextEditingController _nameController = TextEditingController();

  int selectedPlayers = 4;
  int targetScore = 100;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      userProfile.name = _currentUser!.displayName ?? "Player 1";
    }
    _nameController.text = userProfile.name;

    // Check login state on screen startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentUser == null) {
        _showLoginDialog();
      }
    });
  }

  // 👑 LUDO KING STYLE LOGIN DIALOG
  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.amber, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "LOGIN TO CONTINUE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Facebook Login
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.facebook, color: Colors.white),
                  label: const Text(
                    "Login with Facebook",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _signInWithFacebook();
                  },
                ),
                const SizedBox(height: 12),

                // 2. Google Login
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                  label: const Text(
                    "Sign in with Google",
                    style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _signInWithGoogle();
                  },
                ),

                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.white30)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text("OR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: Colors.white30)),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Play as Guest
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    "Play as Guest",
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔴 GOOGLE SIGN IN FUNCTION
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '603420736879-74mj432hklrj4gld5on957ulq7q3h1qs.apps.googleusercontent.com',
      );

      // Reset previous session to resolve password loop
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      setState(() {
        _currentUser = userCredential.user;
        userProfile.name = _currentUser?.displayName ?? "Player 1";
        _nameController.text = userProfile.name;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged in as ${userProfile.name}"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign In Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // 🔵 FACEBOOK SIGN IN FUNCTION
  Future<void> _signInWithFacebook() async {
    try {
      await FacebookAuth.instance.logOut();

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.nativeWithFallback,
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);

        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        if (!mounted) return;

        setState(() {
          _currentUser = userCredential.user;
          userProfile.name = _currentUser?.displayName ?? "Player 1";
          _nameController.text = userProfile.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logged in as ${userProfile.name}"), backgroundColor: Colors.green),
        );
      } else if (result.status == LoginStatus.cancelled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Facebook Login Cancelled"), backgroundColor: Colors.orange),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Facebook Login Failed: ${result.message}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      try {
        final AccessToken? accessToken = await FacebookAuth.instance.accessToken;

        if (accessToken != null) {
          final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);
          final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

          if (!mounted) return;

          setState(() {
            _currentUser = userCredential.user;
            userProfile.name = _currentUser?.displayName ?? "Player 1";
            _nameController.text = userProfile.name;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Logged in as ${userProfile.name}"),
              backgroundColor: Colors.green,
            ),
          );
          return;
        }
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Facebook Sign In Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🚪 SIGN OUT FUNCTION
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    if (!mounted) return;
    setState(() {
      _currentUser = null;
      userProfile.name = "Player 1";
      _nameController.text = "Player 1";
    });
    _showLoginDialog();
  }

  void _showProfileEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempAvatar = userProfile.avatar;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text("Edit Profile & Account", style: TextStyle(color: Colors.amber)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Player Name",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Choose Avatar:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                    const SizedBox(height: 10),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amber : const Color(0xFF0F172A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white24,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: Text(av, style: const TextStyle(fontSize: 26)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    if (_currentUser == null) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                        label: const Text("Login with Google", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          _signInWithGoogle();
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        icon: const Icon(Icons.facebook, size: 20),
                        label: const Text("Login with Facebook", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          _signInWithFacebook();
                        },
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text("Sign Out"),
                        onPressed: () {
                          Navigator.pop(context);
                          _signOut();
                        },
                      )
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _startMatchWithOptions(String modeType) {
    if (modeType == 'FRIENDS') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FriendRoomScreen()),
      );
      return;
    }

    if (modeType == 'ONLINE') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("🚀 Online mode coming soon in next update!"), backgroundColor: Colors.amber.shade800),
      );
      return;
    }

    List<TextEditingController> controllers = List.generate(
      selectedPlayers,
      (index) => TextEditingController(
        text: index == 0 ? userProfile.name : (modeType == 'COMPUTER' ? "Bot $index" : "Player ${index + 1}"),
      ),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            modeType == 'COMPUTER' ? "VS Computer Setup" : "Pass N Play Setup",
            style: const TextStyle(color: Colors.amber, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(selectedPlayers, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: TextField(
                    controller: controllers[index],
                    style: const TextStyle(color: Colors.white),
                    enabled: !(modeType == 'COMPUTER' && index > 0),
                    decoration: InputDecoration(
                      labelText: index == 0 ? "Player 1 (You)" : "Player ${index + 1} Name",
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                      prefixIcon: Icon(index == 0 ? Icons.person : Icons.smart_toy, color: Colors.amber, size: 20),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    ),
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: const Text("START MATCH", style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade600, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
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
                                child: Text(userProfile.avatar, style: const TextStyle(fontSize: 32)),
                              ),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                child: const Icon(Icons.edit, size: 12, color: Colors.white),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userProfile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(10)),
                                child: Text(_currentUser != null ? "VERIFIED PLAYER" : "Level ${userProfile.level} Novice", style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.amber),
                          onPressed: _showProfileEditDialog,
                        )
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
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
              const SizedBox(height: 20),
              Text("🎮 Select Game Mode", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildModeCard("ONLINE", "🌍", Colors.blue.shade700, () => _startMatchWithOptions("ONLINE"))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildModeCard("FRIENDS", "❤️", Colors.pink.shade700, () => _startMatchWithOptions("FRIENDS"))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildModeCard("COMPUTER", "🤖", Colors.indigo.shade700, () => _startMatchWithOptions("COMPUTER"))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildModeCard("PASS N PLAY", "👥", Colors.green.shade700, () => _startMatchWithOptions("PASS"))),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Select Players:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [2, 3, 4].map((count) {
                        bool isSelected = selectedPlayers == count;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : const Color(0xFF0F172A),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Target Score:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [100, 200, 500].map((score) {
                        bool isSelected = targetScore == score;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : const Color(0xFF0F172A),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(String title, String emoji, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade400, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}
