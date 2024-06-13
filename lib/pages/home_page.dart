import 'package:flutter/material.dart';
import 'package:glife/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glife/pages/accessories.dart';
import 'package:health/health.dart';
import 'dart:async';
import 'steps_chart_page.dart'; // Import the new page
import 'exercise_chart_page.dart'; // Import the new page for exercise data

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late User? user;
  int noSteps = 0; // Variable to hold today's step count
  int noExercise = 0; // Variable to hold today's exercise count
  final TextEditingController _textController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _controller;
  late Animation<double> _animation;
  int goalSteps = 1000;
  int goalExercise = 30; // Daily exercise goal in minutes
  late Stream<int> stepCountStream;
  late Stream<int> exerciseCountStream;
  late StreamSubscription<int> stepCountSubscription;
  late StreamSubscription<int> exerciseCountSubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 1;
    user = Auth().currentUser;
    _checkAndRequestHealthAccess();

    // Initialize animation controller and animation
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    // Set up the step count stream
    stepCountStream = Stream.periodic(Duration(seconds: 10)).asyncMap((_) => fetchStepData());

    // Set up the exercise count stream
    exerciseCountStream = Stream.periodic(Duration(seconds: 10)).asyncMap((_) => fetchExerciseData());
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    stepCountSubscription.cancel();
    exerciseCountSubscription.cancel();
    // Dispose animation controller
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestHealthAccess() async {
    var types = [HealthDataType.STEPS, HealthDataType.EXERCISE_TIME];
    bool accessGranted = await Health().requestAuthorization(types);
    if (!accessGranted) {
      print("Health access not granted");
    }
  }

  Future<int> fetchStepData() async {
    int steps = 0;

    // Get steps for today (i.e., since midnight)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool stepsPermission = await Health().hasPermissions([HealthDataType.STEPS]) ?? false;
    if (!stepsPermission) {
      stepsPermission = await Health().requestAuthorization([HealthDataType.STEPS]);
    }

    if (stepsPermission) {
      try {
        steps = await Health().getTotalStepsInInterval(midnight, now) ?? 0;
      } catch (error) {
        debugPrint("Exception in getTotalStepsInInterval: $error");
      }
      await logDailySteps(user!.uid, steps);

      setState(() {
        noSteps = steps;
      });
    } else {
      debugPrint("Authorization not granted - error in authorization");
    }
    return steps;
  }

  Future<int> fetchExerciseData() async {
    int exercise = 0;

    // Get exercise minutes for today (i.e., since midnight)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool exercisePermission = await Health().hasPermissions([HealthDataType.EXERCISE_TIME]) ?? false;
    if (!exercisePermission) {
      exercisePermission = await Health().requestAuthorization([HealthDataType.EXERCISE_TIME]);
    }

    if (exercisePermission) {
      try {
        // Replace the following line with the actual method to fetch exercise minutes
        // Example: exercise = await Health().getTotalExerciseMinutesInInterval(midnight, now) ?? 0;
        
      } catch (error) {
        debugPrint("Exception in fetching exercise minutes: $error");
      }
      await logDailyExercise(user!.uid, exercise);

      setState(() {
        noExercise = exercise;
      });
    } else {
      debugPrint("Authorization not granted for exercise - error in authorization");
    }
    return exercise;
  }

  Future<void> logDailySteps(String userId, int steps) async {
    var now = DateTime.now();
    var midnight = DateTime(now.year, now.month, now.day);

    await _firestore.collection('users').doc(userId)
        .collection('days').doc(midnight.toIso8601String())
        .collection('steps').add({
      'steps': steps,
      'timestamp': now,
    });
  }

  Future<void> logDailyExercise(String userId, int exercise) async {
    var now = DateTime.now();
    var midnight = DateTime(now.year, now.month, now.day);

    await _firestore.collection('users').doc(userId)
        .collection('days').doc(midnight.toIso8601String())
        .collection('exercise').add({
      'exercise_minutes': exercise,
      'timestamp': now,
    });
  }

  int getUserStreak() {
    return 5; // Replace with actual logic
  }

  String getBedtime() {
    return '10:30 PM'; // Replace with actual logic
  }

List<Widget> _widgetOptions() {
  return <Widget>[
    const Center(child: Text('Achievements')),
    SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _animation,
            child: Text(
              "Welcome back, ${_getUserFirstName()}!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Image.asset('assets/images/character.jpeg'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => AccessoriesPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.checkroom),
            label: const Text(''),
            style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 16)),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StepsChartPage()),
              );
            },
            child: _buildStepProgressBar(),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExerciseChartPage()),
              );
            },
            child: _buildExerciseProgressBar(),
          ),
          SizedBox(height: 16),
          Column(
            children: [
              Text(
                'Your Bedtime Today:',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                getBedtime(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 200),
          ElevatedButton(
            onPressed: () async {
              await Auth().signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    ),
    const Center(child: Text('Groups')),
  ];
}

String _getUserFirstName() {
  if (user != null && user!.email != null) {
    return user!.email!.split('@')[0];
  } else {
    return 'User';
  }
}



  Widget _buildStepProgressBar() {
    // Define the goal number of steps
    return Column(
      children: [
        Text(
          'Steps Today',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ScaleTransition(
          scale: _animation,
          child: StreamBuilder<int>(
            stream: stepCountStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData) {
                return Text('No data');
              } else {
                final progress = snapshot.data! / goalSteps;
                return Column(
                  children: [
                    Container(
                      width: 300, // Fixed width for the progress bar
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[300],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0), // Ensure progress is between 0 and 1
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Color.fromARGB(255, 33, 243, 114),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_walk, color: Colors.teal, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '${snapshot.data!} / $goalSteps',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${(progress * 100).toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseProgressBar() {
    // Define the goal number of exercise minutes
    return Column(
      children: [
        Text(
          'Exercise Today',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ScaleTransition(
          scale: _animation,
          child: StreamBuilder<int>(
            stream: exerciseCountStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData) {
                return Text('No data');
              } else {
                final progress = snapshot.data! / goalExercise;
                return Column(
                  children: [
                    Container(
                      width: 300, // Fixed width for the progress bar
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[300],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0), // Ensure progress is between 0 and 1
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.blue, // Change color for exercise progress
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_run, color: Colors.blue, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '${snapshot.data!} / $goalExercise minutes',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${(progress * 100).toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showChangeGoalDialog(String title, String labelText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: _textController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: labelText),
          ),
          actions: [
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                setState(() {
                  if (title == 'Change Steps Goal') {
                    goalSteps = int.parse(_textController.text);
                  } else if (title == 'Change Exercise Goal') {
                    goalExercise = int.parse(_textController.text);
                  }
                });
                Navigator.of(context).pop();
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
    appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 11, 143, 110),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.menu,
          color: Colors.black87,
        ),
        onPressed: () {},
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.directions_run),
          onPressed: () {
            _showChangeGoalDialog('Change Exercise Goal', 'Enter new exercise goal');
          },
        ),
        SizedBox(width: 10), // Add spacing between icons
        IconButton(
          icon: Icon(Icons.track_changes),
          onPressed: () {
            _showChangeGoalDialog('Change Steps Goal', 'Enter new steps goal');
          },
        ),
      ],
    ),
    body: Center(
      child: _widgetOptions().elementAt(_selectedIndex),
    ),
    bottomNavigationBar: BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          label: 'Achievements',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Me',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Groups',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.green,
      onTap: _onItemTapped,
    ),
  );
}

}