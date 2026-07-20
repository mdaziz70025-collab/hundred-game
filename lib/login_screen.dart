import 'package:flutter/material.dart';
import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();

  void proceedToMenu(String userName) {
    if (userName.trim().isEmpty) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MenuScreen(userName: userName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("100 CARD GAME", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1877F2), minimumSize: Size(double.infinity, 48)),
              icon: Icon(Icons.facebook, color: Colors.white),
              label: Text("Continue with Facebook", style: TextStyle(color: Colors.white)),
              onPressed: () => proceedToMenu("FB Player"),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: Size(double.infinity, 48)),
              icon: Icon(Icons.phone, color: Colors.white),
              label: Text("Continue with Phone Number", style: TextStyle(color: Colors.white)),
              onPressed: () => proceedToMenu("Mobile User"),
            ),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter Guest Name",
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
              child: Text("Play as Guest"),
              onPressed: () => proceedToMenu(nameController.text.isEmpty ? "Guest" : nameController.text),
            ),
          ],
        ),
      ),
    );
  }
}
