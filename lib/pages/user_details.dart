import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glife/pages/friends.dart';

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
          .limit(1) // Assuming there is only one user with the given username
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        uid = querySnapshot.docs.first.id; // Get the document ID (UID)
      }
    } catch (e) {
      print('Error getting UID by username: $e');
    }

    return uid;
  }
  
  String getPhoto() {
    return 'assets/images/emptyprofile.jpeg';
  }

  String getDescription() {
    return 'I like to exercise.';
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

  int getGoodNights() {
    return 258;
  }

  int getSteps() {
    return 200000;
  }

  int getWorkoutHours() {
    return 67;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('User Details'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade200, Colors.green.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  username,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
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
                SizedBox(height: 16),
                Text(
                  'Current Streak/Add friend (next time)',
                  style: TextStyle(
                    color: Colors.brown,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  getDescription(),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 30),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                            'Achievements',
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildAchievementCard(
                context,
                icon: Icons.local_fire_department_sharp,
                value: 'Loading...',
                label: 'Highest Streaks',
              );
            } else if (snapshot.hasError) {
              return _buildAchievementCard(
                context,
                icon: Icons.local_fire_department_sharp,
                value: 'Error',
                label: 'Highest Streaks',
              );
            } else {
              return _buildAchievementCard(
                context,
                icon: Icons.local_fire_department_sharp,
                value: snapshot.data.toString(),
                label: 'Highest Streaks',
              );
            }
          },
        ),
        _buildAchievementCard(
          context,
          icon: Icons.mode_night,
          value: getGoodNights().toString(),
          label: 'Good Nights',
        ),
      ],
    ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildAchievementCard(
                                context,
                                icon: Icons.do_not_step,
                                value: getSteps().toString(),
                                label: 'Steps accumulated',
                              ),
                              _buildAchievementCard(
                                context,
                                icon: Icons.fitness_center,
                                value: getWorkoutHours().toString(),
                                label: 'Workout hours',
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
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, {required IconData icon, required String value, required String label}) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Color(0xFF101213),
                size: 44,
              ),
              SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  color: Color(0xFF101213),
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Color(0xFF57636C),
                  fontSize: 12,
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
