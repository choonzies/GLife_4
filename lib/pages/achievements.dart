import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementsPage extends StatefulWidget {
  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  int totalSteps = 0;
  int previousSteps = 0;
  int highestStreak = 0;
  int totalCalories = 0;
  int coins = 0;
  bool hasChestplate = false;
  bool baseImageChanged = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      totalSteps = prefs.getInt('totalSteps') ?? 0;
      previousSteps = prefs.getInt('previousSteps') ?? 0;
      highestStreak = prefs.getInt('highestStreak') ?? 0;
      totalCalories = prefs.getInt('totalCalories') ?? 0;
      coins = prefs.getInt('coins') ?? 0;
      hasChestplate =
          (prefs.getStringList('ownedChestplates') ?? []).isNotEmpty;
      baseImageChanged = (prefs.getString('baseImageUrl') ?? '').isNotEmpty;
    });
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> addFieldListItem(
      String collection, String document, String field, String item) async {
    try {
      print(123);
      await _firestore.collection(collection).doc(document).update({
        field: FieldValue.arrayUnion([item]),
      });
      print('Item added to ListField successfully');
    } catch (e) {
      print('Error adding item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    addFieldListItem('users', 'whatthe', 'awuw', 'faq111qq');
    print('huh');
    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            AchievementCard(
              title: '10 000 Steps!',
              description: 'You walked 10 000 steps in a day!',
              unlocked: previousSteps >= 10000,
            ),
            SizedBox(height: 16),
            AchievementCard(
              title: 'Master of Streaks',
              description: 'Achieved a 7-day streak!',
              unlocked: highestStreak >= 7,
            ),
            SizedBox(height: 16),
            AchievementCard(
              title: '100k Club',
              description: 'Total steps over 100,000!',
              unlocked: totalSteps >= 100000,
            ),
            SizedBox(height: 16),
            AchievementCard(
              title: 'Calorie Burner',
              description: 'Burned over 10,000 calories!',
              unlocked: totalCalories >= 10000,
            ),
            SizedBox(height: 16),

            SizedBox(height: 16),
            AchievementCard(
              title: 'Persistent Achiever',
              description: 'Logged activity for 30 consecutive days!',
              unlocked: highestStreak >= 30,
            ),
            SizedBox(height: 16),
            AchievementCard(
              title: 'Coin Collector',
              description: 'Collected 100 coins!',
              unlocked: coins >= 100,
            ),
            SizedBox(height: 16),
            AchievementCard(
              title: 'First Chestplate',
              description: 'Obtained your first chestplate!',
              unlocked: hasChestplate,
            ),
            SizedBox(height: 16),

            // Add more AchievementCard widgets as needed
          ],
        ),
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final bool unlocked;

  const AchievementCard({
    required this.title,
    required this.description,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: unlocked ? 5 : 2,
      color: unlocked ? Colors.white : Colors.grey[300],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: unlocked ? Colors.orangeAccent : Colors.grey,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.star,
                color: unlocked ? Colors.white : Colors.grey[400],
                size: 40,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: unlocked ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: unlocked ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
