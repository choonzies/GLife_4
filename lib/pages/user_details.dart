import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetails extends StatelessWidget {
  final String username;
  const UserDetails(this.username, {super.key});

  Future<String?> getUidByUsername(String username) async {
    String? uid;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        uid = querySnapshot.docs.first.id;
      }
    } catch (e) {
      print('Error getting UID by username: $e');
    }

    return uid;
  }

  Future<int> getHighestStreaks(String username) async {
    try {
      String? uid = await getUidByUsername(username);
      if (uid != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          return userDoc.get('highestStreak');
        }
      }
    } catch (e) {
      print('Error getting highest streaks: $e');
    }
    return 0;
  }

  Future<int> getSteps(String username) async {
    try {
      String? uid = await getUidByUsername(username);
      if (uid != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          return userDoc.get('totalSteps');
        }
      }
    } catch (e) {
      print('Error getting totalSteps: $e');
    }
    return 0;
  }

  Future<int> getCalories(String username) async {
    try {
      String? uid = await getUidByUsername(username);
      if (uid != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          return userDoc.get('totalCalories');
        }
      }
    } catch (e) {
      print('Error getting total Calories: $e');
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('User Details'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Colors.green, Colors.blue],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade200, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 242, 245, 244),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.1),
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stats',
                          style: TextStyle(
                            color: Color(0xFF101213),
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FutureBuilder<int>(
                              future: getHighestStreaks(username),
                              builder: (context, snapshot) {
                                return _buildAchievementCard(
                                  context,
                                  icon: Icons.local_fire_department_sharp,
                                  value: snapshot.connectionState ==
                                          ConnectionState.waiting
                                      ? 'Loading...'
                                      : snapshot.hasError
                                          ? 'Error'
                                          : snapshot.data.toString(),
                                  label: 'Highest Streaks',
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FutureBuilder<int>(
                              future: getSteps(username),
                              builder: (context, snapshot) {
                                return _buildAchievementCard(
                                  context,
                                  icon: Icons.directions_walk,
                                  value: snapshot.connectionState ==
                                          ConnectionState.waiting
                                      ? 'Loading...'
                                      : snapshot.hasError
                                          ? 'Error'
                                          : snapshot.data.toString(),
                                  label: 'Total Steps',
                                );
                              },
                            ),
                            FutureBuilder<int>(
                              future: getCalories(username),
                              builder: (context, snapshot) {
                                return _buildAchievementCard(
                                  context,
                                  icon: Icons.fitness_center,
                                  value: snapshot.connectionState ==
                                          ConnectionState.waiting
                                      ? 'Loading...'
                                      : snapshot.hasError
                                          ? 'Error'
                                          : snapshot.data.toString(),
                                  label: 'Total Calories',
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context,
      {required IconData icon, required String value, required String label}) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.blue,
                size: 36,
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
