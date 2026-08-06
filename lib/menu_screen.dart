import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

    // Menu open hote hi agar user logged in nahi hai toh Ludo King Dialog Popup aayega
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser == null) {
        showLoginDialog();
      }
    });
  }

  void _updateControllers() {
    // Current logged-in user ya guest name set karein
    String currentName = FirebaseAuth.instance.currentUser?.displayName ?? widget.userName;
    nameControllers = List.generate(
      selectedPlayers,
      (i) => TextEditingController(
        text: i == 0 ? currentName : "Player ${i + 1}",
      ),
    );
  }

  // 🔴 Facebook Login Method
  Future<void> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken.tokenString,
        );

        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        setState(() {
          _updateControllers();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Welcome ${userCredential.user?.displayName}!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook Login Error: $e")),
      );
    }
  }

  // 🟢 Google Login Method
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '603420736879-74mj432hklrj4gld5on957ulq7q3h1qs.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        setState(() {
          _updateControllers();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Welcome ${userCredential.user?.displayName}!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Login Error: $e")),
      );
    }
  }

  // 👑 Ludo King Style Login Dialog
  void showLoginDialog() {
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
                    signInWithFacebook();
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
                    signInWithGoogle();
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
