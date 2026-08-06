import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 👈 Google Sign-In Import
import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;

  void proceedToMenu(String userName) {
    if (userName.trim().isEmpty) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MenuScreen(userName: userName)),
    );
  }

  // 🔴 Facebook Login Method
  Future<void> signInWithFacebook() async {
    setState(() => isLoading = true);
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

        String userName = userCredential.user?.displayName ?? "FB Player";
        proceedToMenu(userName);
      } else if (result.status == LoginStatus.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Facebook Login cancelled")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Facebook Login Error: ${result.message}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🟢 Google Passwordless/One-Tap Login Method
  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);
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

        String userName = userCredential.user?.displayName ?? "Google Player";
        proceedToMenu(userName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Login cancelled")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Login Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.amber)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.style, size: 80, color: Colors.amber),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "100 CARD GAME",
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber),
                    ),
                    const Text(
                      "Welcome! Please login to continue.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 40),

                    // Google Login Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.redAccent),
                      label: const Text("Continue with Google",
                          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: signInWithGoogle,
                    ),
                    const SizedBox(height: 12),

                    // Facebook Login Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.facebook, color: Colors.white),
                      label: const Text("Continue with Facebook",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: signInWithFacebook,
                    ),
                    const SizedBox(height: 12),

                    // Mobile Login Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: const Text("Continue with Mobile Number",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: () => proceedToMenu("Mobile User"),
                    ),
                    const SizedBox(height: 25),

                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.white30)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text("OR",
                              style: TextStyle(color: Colors.white54)),
                        ),
                        Expanded(child: Divider(color: Colors.white30)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1B2A47),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        labelText: "Enter Guest Name",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.person_outline, color: Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Play as Guest",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () => proceedToMenu(
                          nameController.text.isEmpty
                              ? "Guest"
                              : nameController.text),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
