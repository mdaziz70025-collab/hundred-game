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
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Header
              Icon(Icons.style, size: 80, color: Colors.amber),
              SizedBox(height: 10),
              Text(
                "100 CARD GAME",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
              Text(
                "Welcome! Please login to continue.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 40),

              // 1. Facebook Login
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1877F2),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.facebook, color: Colors.white),
                label: Text("Continue with Facebook", style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: () => proceedToMenu("FB Player"),
              ),
              SizedBox(height: 12),

              // 2. Phone Login
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.phone, color: Colors.white),
                label: Text("Continue with Mobile Number", style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: () => proceedToMenu("Mobile User"),
              ),
              SizedBox(height: 25),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white30)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text("OR", style: TextStyle(color: Colors.white54)),
                  ),
                  Expanded(child: Divider(color: Colors.white30)),
                ],
              ),
              SizedBox(height: 20),

              // 3. Guest Login
              TextField(
                controller: nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF1B2A47),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  labelText: "Enter Guest Name",
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.person_outline, color: Colors.amber),
                ),
              ),
              SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Play as Guest", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => proceedToMenu(nameController.text.isEmpty ? "Guest" : nameController.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
