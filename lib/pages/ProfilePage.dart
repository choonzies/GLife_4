import 'package:flutter/material.dart';
import 'package:glife/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = Auth().currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Character image with sunglasses
              SizedBox(
                width: 300, // Adjust width as needed
                height: 300, // Adjust height as needed
                child: Image.asset(
                  'assets/images/character.jpeg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              // Username sample text
              Text(
                'Username: ' + (user?.displayName ?? 'User email'),
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              // Email sample text
              Text(
                'Email: ' + (user?.email ?? 'User email'),
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              // Password sample text
              Text(
                'Password: ********',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
