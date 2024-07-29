import 'package:flutter/material.dart';
import 'package:glife/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glife/pages/accessories.dart';
import 'package:glife/pages/achievements.dart';
import 'package:glife/pages/store.dart';
import 'package:glife/pages/friends.dart';
import 'package:glife/pages/profile.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'steps_chart_page.dart';
import 'exercise_chart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late User? user;
  int noSteps = 0; // Variable to hold today's step count
  int noExercise = 0; // Variable to hold today's exercise count

  // Define state variables for character's gear image URLs
  String _baseImageUrl = 'assets/images/c2.jpg'; // Example initial image
  String _selectedHat = ''; // Initialize with empty string or default image URL
  String _chestImageUrl =
      ''; // Initialize with empty string or default image URL
  String _bootsImageUrl =
      ''; // Initialize with empty string or default image URL

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _controller;
  late Animation<double> _animation;
  int goalSteps = 10000;
  int goalExercise = 2500;
  late StreamController<int> _stepCountController;
  late StreamController<int> _exerciseCountController;
  int streak = 0;
  String lastCheckedDate = '';
  int coins = 0;
  String username = '';

  void asyncInit() async {
    await getUsername();
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = 1;
    user = Auth().currentUser;
    _checkAndRequestHealthAccess();
    _loadGearUrls();
    _loadGoals();
    loadStreak();
    _loadCoins();
    asyncInit();
    getUsername();
    _checkGoalsCompletion();

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

    fetchActiveEnergyData();
    fetchStepData();
    // Set up the step count stream

    _printSharedPreferencesValues();
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

  void _printSharedPreferencesValues() async {
    final prefs = await SharedPreferences.getInstance();
    Set<String> keys = prefs.getKeys();
    Map<String, dynamic> values = {};
    for (String key in keys) {
      values[key] = prefs.get(key);
    }
    print('SharedPreferences values: $values');
  }

  Future<void> _checkAndRequestHealthAccess() async {
    var types = [HealthDataType.STEPS, HealthDataType.ACTIVE_ENERGY_BURNED];
    bool accessGranted = await Health().requestAuthorization(types);
    if (!accessGranted) {
      print("Health access not granted");
    }
  }

  Future<int> fetchStepData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // // Get steps for today (i.e., since midnight)
    // final now = DateTime.now();
    // final midnight = DateTime(now.year, now.month, now.day);

    // bool stepsPermission =
    //     await Health().hasPermissions([HealthDataType.STEPS]) ?? false;
    // if (!stepsPermission) {
    //   stepsPermission =
    //       await Health().requestAuthorization([HealthDataType.STEPS]);
    // }

    // if (stepsPermission) {
    //   try {
    //     steps = await Health().getTotalStepsInInterval(midnight, now) ?? 0;
    //   } catch (error) {
    //     debugPrint("Exception in getTotalStepsInInterval: $error");
    //   }

    int steps = prefs.getInt('previousSteps') ?? 500;

    setState(() {
      noSteps = steps;
    });

    if (prefs.getInt('previousSteps') == null) {
      prefs.setInt('previousSteps', steps);
    }

    //   //_stepCountController.add(steps); // Add steps data to stream
    // } else {
    //   debugPrint("Authorization not granted - error in authorization");
    // }
    saveAndLogTotalSteps(steps);
    return steps;
  }

  Future<int> fetchActiveEnergyData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // var types = [HealthDataType.ACTIVE_ENERGY_BURNED];

    // // Get active calories for today (i.e., since midnight)
    // final now = DateTime.now();
    // final midnight = DateTime(now.year, now.month, now.day);

    // bool caloriesPermission = await Health().hasPermissions(types) ?? false;
    // if (!caloriesPermission) {
    //   caloriesPermission = await Health().requestAuthorization(types);
    // }

    // if (caloriesPermission) {
    //   try {
    //     // Fetch active calories data points from today
    //     List<HealthDataPoint> healthData =
    //         await Health().getHealthDataFromTypes(
    //       startTime: midnight,
    //       endTime: now,
    //       types: types,
    //     );

    //     // Sum up the active calories from all data points
    //     int cal = 0;
    //     for (HealthDataPoint dataPoint in healthData) {
    //       cal = dataPoint.toJson()['value'].numericValue.toInt();
    //       activeCalories += cal;
    //     }
    //   } catch (error) {
    //     debugPrint("Exception in fetching active calories: $error");
    //   }

    //   // Log daily active calories to Firestore

    //   // Update state and stream controller with active calories data

    int activeCalories = prefs.getInt('previousCalories') ?? 500;

    setState(() {
      noExercise = activeCalories;
    });

    if (prefs.getInt('previousCalories') == null) {
      prefs.setInt('previousCalories', noExercise);
    }

    //   _exerciseCountController.add(activeCalories);
    // } else {
    //   debugPrint(
    //       "Authorization not granted for active calories - error in authorization");
    // }
    saveAndLogTotalCalories(activeCalories);
    return activeCalories;
  }

  Future<void> _loadGoals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {

      goalSteps = prefs.getInt('goalSteps') ?? 10000;
      goalExercise = prefs.getInt('goalExercise') ?? 2500;

    });
  }

  Future<void> _loadCoins() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      int? storedCoins = prefs.getInt('coins');

      if (storedCoins == null) {
        coins = 100;
        prefs.setInt('coins', coins);
      } else {
        coins = storedCoins;
      }
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
      bedtime = bedtime
          .add(Duration(days: 1)); // Move to the next day if bedtime has passed
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
        String formattedTime =
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
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
                  MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage()), // Navigate to ProfilePage
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
    TextEditingController ctrller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: labelText),
          ),
          actions: [
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                setState(() {
                  if (title == 'Change Steps Goal') {
                    goalSteps = int.parse(ctrller.text);
                  } else if (title == 'Change Exercise Goal') {
                    goalExercise = int.parse(ctrller.text);
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
    String bedtimeStr =
        prefs.getString('bedtime') ?? '22:30'; // Default bedtime if not set
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
      String formattedTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
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
  Widget build(BuildContext context) {
    List<Widget> _widgetOptions = <Widget>[
      AchievementsPage(),
      Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 0),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.blue, Colors.green],
                    tileMode: TileMode.mirror,
                  ).createShader(bounds),
                  child: Text(
                    "Welcome back, $username!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                      MaterialPageRoute(
                          builder: (context) => ActiveEnergyChartPage()),
                    );
                  },
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildExerciseProgressBar(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              );
                            } else {
                              return Text(
                                'Error fetching bedtime',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
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
            top: 60,
            child: Builder(
              builder: (context) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amberAccent, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0.0, vertical: 3.0),
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department,
                            color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '${streak} Day Streak!',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 10,
            top: 100,
            child: Builder(
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StorePage(
                          onItemsPurchased: _loadGearUrls,
                          onCoinsChanged: _reloadCoins,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 6, 171, 91),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 3.0),
                      child: Row(
                        children: [
                          Icon(Icons.store, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '$coins Coins',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 10,
            top: 660,
            child: Builder(
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      noSteps += 1000;
                      saveAndLogTotalSteps(noSteps);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 3.0),
                      child: Row(
                        children: [
                          Icon(Icons.android, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'STEPS MOCKER',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 10,
            top: 700,
            child: Builder(
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      noExercise += 1000;
                      saveAndLogTotalCalories(noExercise);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 3.0),
                      child: Row(
                        children: [
                          Icon(Icons.android, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'CALORIES MOCKER',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      Friends(),
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
            icon: Icon(Icons.do_not_step),
            onPressed: () {
              _showChangeGoalDialog(
                  'Change Steps Goal', 'Enter new steps goal');
            },
          ),
          SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.directions_run),
            onPressed: () {
              _showChangeGoalDialog(
                  'Change Exercise Goal', 'Enter new exercise goal');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchStepData();
          await fetchActiveEnergyData();
        },
        child: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'Achievements'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Friends'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
                final progress = noSteps / goalSteps;
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
                        Icon(Icons.do_not_step, color: Colors.teal, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '${noSteps} / $goalSteps',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '(${(progress * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal),
                        ),
                      ],
                    ),
                  ],
                );
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
                        Icon(Icons.directions_walk,
                            color: Colors.teal, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '${snapshot.data!} / $goalSteps',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '(${(progress * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal),
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
                final progress = noExercise / goalExercise;
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
                        Icon(Icons.directions_run,
                            color: Colors.blue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '${noExercise} / $goalExercise kcal',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '(${(progress * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                );
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
                        Icon(Icons.directions_run,
                            color: Colors.blue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '${snapshot.data!} / $goalExercise kcal',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '(${(progress * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
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

  Future<void> getUsername() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            username = userDoc.get('username');
          });
        } else {
          print('User document does not exist');
        }
      } catch (e) {
        print('Error fetching username from home_page: $e');
      }
    } else {
      print('No user signed in');
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

  Future<void> _reloadCoins() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      coins = prefs.getInt('coins') ?? 0;
    });
  }

  void gainCoins() async {
    bool stepsGoalMet = await checkStepsGoal();
    bool energyGoalMet = await checkEnergyGoal();
    bool addedCoinsTdy = false;
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toString().substring(0, 10);
    String lastAdded = prefs.getString('lastAdded') ?? '';
    int _streak = prefs.getInt('streak') ?? 0;
    int _coins = prefs.getInt('coins') ?? 0;

    if (lastAdded == today) {
      addedCoinsTdy = true;
    }

    if (!addedCoinsTdy && stepsGoalMet && energyGoalMet) {
      _coins += 10;
      for (int i = 0; i < _streak; i++) {
        _coins += 10;
      }

      setState(() {
        coins = _coins;
      });
      prefs.setInt('coins', _coins);
      prefs.setString('lastAdded', today);
    }
  }

  void _checkGoalsCompletion() async {
    final prefs = await SharedPreferences.getInstance();

    // Assuming these functions return boolean values
    bool stepsGoalMet = await checkStepsGoal();
    bool energyGoalMet = await checkEnergyGoal();

    String todayDate = DateTime.now().toString().substring(0, 10);
    String yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toString()
        .substring(0, 10);

    String _lastCheckedDate =
        prefs.getString('lastCheckedDate') ?? lastCheckedDate;
    int _streak = prefs.getInt('streak') ?? streak;

    if (_lastCheckedDate != yesterday && _lastCheckedDate != todayDate) {
      _streak = 0; // Reset the streak if the user missed a day
      setState(() {
        streak = _streak;
        lastCheckedDate = todayDate;
        prefs.setInt('streak', _streak);
        prefs.setString('lastCheckedDate', todayDate);
      });
    }

    if (_lastCheckedDate == yesterday) {
      if (stepsGoalMet && energyGoalMet) {
        _streak += 1; // Continue the streak
        setState(() {
          streak = _streak;
          lastCheckedDate = todayDate;
          prefs.setString('lastCheckedDate', todayDate);
          prefs.setInt('streak', _streak);
        });
      }
    }
    saveHighestStreak();
    logHighestStreak();
  }

  Future<void> loadStreak() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      streak = prefs.getInt('streak') ?? 0;
      lastCheckedDate = prefs.getString('lastCheckedDate') ?? '';
    });
  }

  Future<bool> checkStepsGoal() async {
    int step = await fetchStepData();
    return step >= goalSteps;
  }

  Future<bool> checkEnergyGoal() async {
    int cal = await fetchActiveEnergyData();
    return cal >= goalExercise;
  }

  void saveHighestStreak() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int highestStreak = prefs.getInt('highestStreak') ?? -1;
    if (streak > highestStreak) {
      await prefs.setInt('highestStreak', streak);
    }
  }

  void logHighestStreak() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      int highestStreak = 0;
      final prefs = await SharedPreferences.getInstance();
      highestStreak = prefs.getInt('highestStreak') ?? 0;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'highestStreak': highestStreak});
    }
  }

  Future<void> saveAndLogTotalSteps(int currentSteps) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve current and previous step counts
    int totalSteps = prefs.getInt('totalSteps') ?? 500;
    int previousSteps = prefs.getInt('previousSteps') ?? 0;

    // Fetch current step data
    // Implement this method to get current steps from the health API or source

    // Calculate steps to add (steps taken since last update)
    int stepsToAdd = currentSteps - previousSteps;
    if (stepsToAdd < 0) {
      stepsToAdd = 0; // Prevent negative steps if the source resets at midnight
    }

    // Accumulate total steps
    totalSteps += stepsToAdd;

    // Update SharedPreferences
    await prefs.setInt('previousSteps', currentSteps);
    await prefs.setInt('totalSteps', totalSteps);

    // Update Firestore
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'totalSteps': totalSteps});
      } catch (e) {
        print('Error updating total steps in Firestore: $e');
      }
    }
  }

  Future<void> saveAndLogTotalCalories(int currentCalories) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve current and previous step counts
    int totalCalories = prefs.getInt('totalCalories') ?? 500;
    int previousCalories = prefs.getInt('previousCalories') ?? 0;

    // Fetch current step data
    // Implement this method to get current steps from the health API or source

    // Calculate steps to add (steps taken since last update)
    int caloriessToAdd = currentCalories - previousCalories;
    if (caloriessToAdd < 0) {
      caloriessToAdd =
          0; // Prevent negative steps if the source resets at midnight
    }

    // Accumulate total steps
    totalCalories += caloriessToAdd;

    // Update SharedPreferences
    await prefs.setInt('previousCalories', currentCalories);
    await prefs.setInt('totalCalories', totalCalories);

    // Update Firestore
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'totalCalories': totalCalories});
      } catch (e) {
        print('Error updating total calories in Firestore: $e');
      }
    }
  }
}
