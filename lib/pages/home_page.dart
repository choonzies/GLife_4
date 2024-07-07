import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glife/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glife/pages/accessories.dart';
import 'package:glife/pages/achievements.dart';
import 'package:glife/pages/groups.dart';
import 'package:glife/pages/profile.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'steps_chart_page.dart';
import 'exercise_chart_page.dart';
import 'package:carousel_slider/carousel_slider.dart';


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

  // Define state variables for character's gear image URLs
  String _baseImageUrl = 'assets/images/c2.jpg'; // Example initial image
  String _selectedHat = ''; // Initialize with empty string or default image URL
  String _chestImageUrl = ''; // Initialize with empty string or default image URL
  String _bootsImageUrl = ''; // Initialize with empty string or default image URL


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _controller;
  late Animation<double> _animation;
  int goalSteps = 1000;
  int goalExercise = 30; // Daily exercise goal in minutes
  late StreamController<int> _stepCountController;
  late StreamController<int> _exerciseCountController;
  int streak = 0;
  int _lastCheckedDate = 0;

  

  

  @override
  void initState() {
    super.initState();
    _selectedIndex = 1;
    user = Auth().currentUser;
    _checkAndRequestHealthAccess();
  _loadGearUrls();
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

    // Initialize StreamController
    _stepCountController = StreamController<int>.broadcast();
    _exerciseCountController = StreamController<int>.broadcast();

    // Load saved goals
    _loadGoals();

    // Set up the step count stream
    Timer.periodic(Duration(seconds: 10), (timer) => fetchStepData());

    // Set up the exercise count stream
    Timer.periodic(Duration(seconds: 10), (timer) => fetchActiveEnergyData());
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    _stepCountController.close();
    _exerciseCountController.close();
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
      

      setState(() {
        noSteps = steps;
      });

      _stepCountController.add(steps); // Add steps data to stream
    } else {
      debugPrint("Authorization not granted - error in authorization");
    }
    return steps;
  }








Future<int> fetchActiveEnergyData() async {
  int activeCalories = 0;
  var types = [HealthDataType.ACTIVE_ENERGY_BURNED];

  // Get active calories for today (i.e., since midnight)
  final now = DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day);

  bool caloriesPermission = await Health().hasPermissions(types) ?? false;
  if (!caloriesPermission) {
    caloriesPermission = await Health().requestAuthorization(types);
  }

  if (caloriesPermission) {
    try {
      // Fetch active calories data points from today
      List<HealthDataPoint> healthData = await Health().getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: types,
      );

      // Sum up the active calories from all data points
      int cal = 0;
      for (HealthDataPoint dataPoint in healthData) {
        cal = dataPoint.toJson()['value'].numericValue.toInt();
        activeCalories +=  cal; 
      }
    } catch (error) {
      debugPrint("Exception in fetching active calories: $error");
    }

    // Log daily active calories to Firestore
    

    // Update state and stream controller with active calories data
    setState(() {
      noExercise = activeCalories;
    });
    _exerciseCountController.add(activeCalories);
  } else {
    debugPrint("Authorization not granted for active calories - error in authorization");
  }

  return activeCalories;
}








Future<void> logDailyActiveCalories(String userId, int activeCalories) async {
  var now = DateTime.now();
  var midnight = DateTime(now.year, now.month, now.day);

  await _firestore.collection('users').doc(userId)
      .collection('days').doc(midnight.toIso8601String())
      .collection('active_calories').add({
    'active_calories': activeCalories,
    'timestamp': now,
  });
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

  Future<void> _loadGoals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      goalSteps = prefs.getInt('goalSteps') ?? 1000;
      goalExercise = prefs.getInt('goalExercise') ?? 30;
    });
  }

  Future<void> _saveGoals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goalSteps', goalSteps);
    await prefs.setInt('goalExercise', goalExercise);
  }

  Future<void> loadUserStreak() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      streak = prefs.getInt('streak') ?? 0;
    });
  }

Future<String> getBedtime() async {

    DateTime now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String bedtimeStr = prefs.getString('bedtime') ?? '22:30';
    List<String> timeParts = bedtimeStr.split(':');
    int hours = int.parse(timeParts[0]);
    int minutes = int.parse(timeParts[1]);
    DateTime bedtime = DateTime(now.year, now.month, now.day, hours, minutes);
    if (now.isAfter(bedtime)) {
      bedtime = bedtime.add(Duration(days: 1)); // Move to the next day if bedtime has passed
    }
    Duration duration = bedtime.difference(now);
    int leftHours = duration.inHours;
    int leftMinutes = duration.inMinutes % 60;
    
    return 'Time left to bedtime: ${leftHours}h ${leftMinutes}m';
  }
  Future<void> setBedtime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay(hour: 22, minute: 30);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String bedtimeStr = prefs.getString('bedtime') ?? '22:30';
    List<String> timeParts = bedtimeStr.split(':');
    int hours = int.parse(timeParts[0]);
    int minutes = int.parse(timeParts[1]);
    initialTime = TimeOfDay(hour: hours, minute: minutes);

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      setState(() {
        String formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
        prefs.setString('bedtime', formattedTime);
      });
    }
  }


  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.person),
              title: Text('View Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()), // Navigate to ProfilePage
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await Auth().signOut();
                Navigator.pop(context); // Close the bottom sheet
              },
            ),
          ],
        );
      },
    );
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
                  _saveGoals(); // Save the new goals
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
void _showChangeBedtimeDialog(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String bedtimeStr = prefs.getString('bedtime') ?? '22:30'; // Default bedtime if not set
  List<String> timeParts = bedtimeStr.split(':');
  int hours = int.parse(timeParts[0]);
  int minutes = int.parse(timeParts[1]);
  TimeOfDay initialTime = TimeOfDay(hour: hours, minute: minutes);

  // Show time picker dialog
  TimeOfDay? selectedTime = await showTimePicker(
    context: context,
    initialTime: initialTime,
  );

  // If the user selects a time, update the bedtime in SharedPreferences
  if (selectedTime != null) {
    String formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
    try {
      await prefs.setString('bedtime', formattedTime);
      setState(() {}); // Update the UI if necessary
    } catch (error) {
      print('Error changing bedtime: $error');
      // Handle error gracefully (show snackbar, log error, etc.)
    }
  }
}





 @override
 @override
@override
Widget build(BuildContext context) {
  List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('')),
    Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                "Welcome back, ${_getUserFirstName()}!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // Larger character image below the welcome message
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccessoriesPage(
                        onUpdateCharacter: _updateCharacter,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Image.asset(
                        _baseImageUrl, // Base image
                        width: 300,
                        height: 400,
                        fit: BoxFit.contain,
                      ),
                      if (_selectedHat.isNotEmpty)
                        Positioned(
                          top: -80,
                          left: -50,
                          child: Image.asset(
                            _selectedHat,
                            width: 400,
                            height: 400,
                            fit: BoxFit.contain,
                          ),
                        ),
                      if (_chestImageUrl.isNotEmpty)
                        Positioned(
                          top: -100,
                          left: -145,
                          child: Image.asset(
                            _chestImageUrl,
                            width: 600,
                            height: 500,
                            fit: BoxFit.contain,
                          ),
                        ),
                      if (_bootsImageUrl.isNotEmpty)
                        Image.asset(
                          _bootsImageUrl,
                          width: 300,
                          height: 400,
                          fit: BoxFit.contain,
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StepsChartPage()),
                  );
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildStepProgressBar(),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ActiveEnergyChartPage()),
                  );
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildExerciseProgressBar(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      FutureBuilder<String>(
                        future: getBedtime(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data!,
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            );
                          } else {
                            return Text(
                              'Error fetching bedtime',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            );
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _showChangeBedtimeDialog(context);
                        },
                        child: Text('Change Bedtime'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  await Auth().signOut();
                },
                child: Text('Sign Out'),
              ),
            ],
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Builder(
            builder: (context) {
              _checkGoalsCompletion(); // Call the function directly

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                color: Colors.amberAccent.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    '${streak} Day Streak!',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
    Center(child: Text('Groups')),
  ];

  return Scaffold(
    appBar: AppBar(
      title: Text('GLife'),
      backgroundColor: Colors.green,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Colors.green, Colors.blue],
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.menu, color: Colors.black87),
        onPressed: () {
          _showMenuOptions(context);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.directions_run),
          onPressed: () {
            _showChangeGoalDialog('Change Exercise Goal', 'Enter new exercise goal');
          },
        ),
        SizedBox(width: 10),
        IconButton(
          icon: Icon(Icons.track_changes),
          onPressed: () {
            _showChangeGoalDialog('Change Steps Goal', 'Enter new steps goal');
          },
        ),
      ],
    ),
    body: Center(
      child: _widgetOptions.elementAt(_selectedIndex),
    ),
    bottomNavigationBar: BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Achievements'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.green,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        // Handle navigation to AchievementsPage
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AchievementsPage()),
          );
        }

        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Friends()),
          );
        }
      },
    ),
  );
}






Widget _buildStepProgressBar() {
  return Column(
    children: [
      Text(
        'Steps Today',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      ScaleTransition(
        scale: _animation,
        child: StreamBuilder<int>(
          stream: _stepCountController.stream,
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
                    width: 300,
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
                            widthFactor: progress.clamp(0.0, 1.0),
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
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_walk, color: Colors.teal, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '${snapshot.data!} / $goalSteps',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '(${(progress * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
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
  return Column(
    children: [
      Text(
        'Active Calories Burnt Today',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      ScaleTransition(
        scale: _animation,
        child: StreamBuilder<int>(
          stream: _exerciseCountController.stream,
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
                    width: 300,
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
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_run, color: Colors.blue, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '${snapshot.data!} / $goalExercise kcal',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '(${(progress * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
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

String _getUserFirstName() {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null && user.email != null) {
    return user.email!.split('@')[0];
  } else {
    return 'User';
  }
}
void _updateCharacter(Map<String, String> gearUrls) {
  setState(() {
    _baseImageUrl = gearUrls['baseImageUrl'] ?? _baseImageUrl;
    _selectedHat = gearUrls['Hat'] ?? _selectedHat;
    _chestImageUrl = gearUrls['Chest'] ?? _chestImageUrl;
    _bootsImageUrl = gearUrls['bootsImageUrl'] ?? _bootsImageUrl;
  });
  _saveGearUrls(); // Save the updated gear URLs
}



Future<void> _saveGearUrls() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('baseImageUrl', _baseImageUrl);
  await prefs.setString('selectedHat', _selectedHat);
  await prefs.setString('chestImageUrl', _chestImageUrl);
  await prefs.setString('bootsImageUrl', _bootsImageUrl);
}

Future<void> _loadGearUrls() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    _baseImageUrl = prefs.getString('baseImageUrl') ?? 'assets/images/c2.jpg';
    _selectedHat = prefs.getString('selectedHat') ?? '';
    _chestImageUrl = prefs.getString('chestImageUrl') ?? '';
    _bootsImageUrl = prefs.getString('bootsImageUrl') ?? '';
  });
}

void _checkGoalsCompletion() async {
  final prefs = await SharedPreferences.getInstance();

  // Assuming these functions return boolean values
  bool stepsGoalMet = await checkStepsGoal();
  bool energyGoalMet = await checkEnergyGoal();

  DateTime now = DateTime.now();
  int todayDate = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

  int _lastCheckedDate = prefs.getInt('lastCheckedDate') ?? 0;
  int _currentStreak = prefs.getInt('streak') ?? 0;

 
  if (stepsGoalMet && energyGoalMet) {
    if (_lastCheckedDate == todayDate - Duration(days: 1).inMilliseconds) {
      _currentStreak += 1; // Continue the streak
    } else {
      
      _currentStreak = 1; // Reset the streak
    }
  } else {
    _currentStreak = 0; // Reset the streak
  }
  setState(() {
    streak = _currentStreak;
    _lastCheckedDate = todayDate;
  });

  prefs.setInt('lastCheckedDate', todayDate);
  prefs.setInt('streak', _currentStreak);

  
}


bool checkStepsGoal() {

  return noSteps >= goalSteps;
  }
  
bool checkEnergyGoal()  {
  return noExercise >= goalExercise;
}

}