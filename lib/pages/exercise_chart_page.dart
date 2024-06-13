import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExerciseChartPage extends StatefulWidget {
  @override
  _ExerciseChartPageState createState() => _ExerciseChartPageState();
}

class _ExerciseChartPageState extends State<ExerciseChartPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<BarChartGroupData> barGroups = [];
  List<String> weekDays = [];

  @override
  void initState() {
    super.initState();
    fetchExerciseData();
  }

  Future<void> fetchExerciseData() async {
    var user = _auth.currentUser;
    if (user == null) {
      // Handle the case where user is not logged in
      return;
    }

    var now = DateTime.now();
    var pastWeek = now.subtract(Duration(days: 6));
    List<BarChartGroupData> tempBarGroups = [];
    weekDays = [];

    for (int i = 0; i <= 6; i++) {
      var day = pastWeek.add(Duration(days: i));
      var midnight = DateTime(day.year, day.month, day.day);

      QuerySnapshot exerciseSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('days')
          .doc(midnight.toIso8601String())
          .collection('exercise')
          .get();

      int maxExercise = 0;
      for (var doc in exerciseSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        int exerciseMinutes = data['exercise_minutes'] as int;
        if (exerciseMinutes > maxExercise) {
          maxExercise = exerciseMinutes;
        }
      }

      tempBarGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: maxExercise.toDouble(),
              color: Colors.blueAccent,
              width: 22,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100, // Assuming max exercise minutes to be 100 for background bar
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
      );
      weekDays.add(DateFormat.E().format(midnight));
    }

    setState(() {
      barGroups = tempBarGroups;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Over Days'),
      ),
      body: Center(
        child: barGroups.isEmpty
            ? CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            if (value % 20 == 0) {
                              return Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                  color: Color(0xff67727d),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                weekDays[value.toInt()],
                                style: const TextStyle(
                                  color: Color(0xff68737d),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Color(0xffe7e8ec),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${weekDays[group.x.toInt()]}\n',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: '${rod.toY.toInt()} minutes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
