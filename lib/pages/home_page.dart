import 'package:flutter/material.dart';
import 'package:glife/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'accessories.dart';
import 'ProfilePage.dart';
import 'Info/Info.dart';
import 'Social/Friends.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // this is to default the ME tab

  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  int getUserStreak() {
    // Placeholder for getting the user's streak, replace with actual logic
    return 5;
  }

  String getBedtime() {
    // Placeholder for getting bedtime for today
    return '10:30 PM';
  }

  double waterProgress = 0.7; // Placeholder value for water drank progress
  double exerciseProgress = 0.5; // Placeholder value for minutes spent exercising progress

  List<Widget> _widgetOptions() {
    return <Widget>[
      const Center(child: Text('Achievements')),
      SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome ' + (user?.displayName ?? 'User email'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: Image.asset(
                'assets/images/character.jpeg',
                width: 300, // Adjust width as needed
                height: 300, // Adjust height as needed
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccessoriesPage()),
                );
              },
              icon: const Icon(Icons.checkroom), // Use a valid icon for "shirt"
              label: const Text('Accessories'),
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: signOut,
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 20),
            // Custom circular progress indicators for Water Drank and Minutes Spent Exercising
            _buildCircularProgressIndicator('Water Drank', waterProgress, Colors.blue),
            const SizedBox(height: 16),
            _buildCircularProgressIndicator('Minutes Spent Exercising', exerciseProgress, Colors.green),
            const SizedBox(height: 16),
            // Prominent display of Bedtime
            Text(
              'Bedtime today:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              getBedtime(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // Additional whitespace at the bottom
            const SizedBox(height: 200),
          ],
        ),
      ),
      const Center(child: Text('Groups')),
    ];
  }

  void _onItemTapped(int index) {
    // setState(() {
    //   _selectedIndex = index;
    // });

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Info()),
      );
    } else if (index == 1) {
      // do nothing
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Friends()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GLife'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                '🔥 Streak: ${getUserStreak()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions().elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_sharp),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face),
            label: 'Me',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Groups',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCircularProgressIndicator(String title, double progress, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
