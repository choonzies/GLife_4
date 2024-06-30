import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:glife/pages/home_page.dart';

class StepsChartPage extends StatefulWidget {
  @override
  _StepsChartPageState createState() => _StepsChartPageState();
}

class _StepsChartPageState extends State<StepsChartPage> {
  PageController _pageController = PageController(initialPage: 0);
  Map<int, List<BarChartGroupData>> cachedBarGroups = {};
  Map<int, List<String>> cachedWeekDays = {};
  int currentWeekIndex = 0;
  bool isLoading = true;
  int touchedIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchStepsData(currentWeekIndex);
  }

  Future<void> fetchStepsData(int weekIndex) async {
    var types = [
      HealthDataType.STEPS,
    ];

    bool permission = await Health().requestAuthorization(types);
    if (!permission) {
      debugPrint('Authorization not granted');
      return;
    }

    var now = DateTime.now();
    var pastWeek = now.subtract(Duration(days: 7 * weekIndex + 6));
    List<BarChartGroupData> tempBarGroups = [];
    List<String> tempWeekDays = [];

    for (int i = 0; i <= 6; i++) {
      var day = pastWeek.add(Duration(days: i));
      var midnight = DateTime(day.year, day.month, day.day);

      try {
        List<HealthDataPoint> healthData = await Health().getHealthDataFromTypes(
          startTime: midnight,
          endTime: midnight.add(Duration(days: 1)),
          types: types,
        );

        int totalSteps = 0;
        int steps = 0;
        for (HealthDataPoint dataPoint in healthData) {
          steps = dataPoint.toJson()['value'].numericValue.toInt();
          totalSteps += steps;
        }
        tempBarGroups.add(
          BarChartGroupData(
  x: i,
  barRods: [
    BarChartRodData(
      toY: totalSteps.toDouble(),
      gradient: LinearGradient(
        colors: [Colors.blueAccent, Colors.greenAccent],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ),
      width: 22,
      borderRadius: BorderRadius.circular(6),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: 10000,
        color: Colors.grey[300],
      ),
    ),
  ],
)
,
        );
        tempWeekDays.add(DateFormat.E().format(midnight));
      } catch (error) {
        debugPrint('Error fetching health data: $error');
      }
    }

    setState(() {
      cachedBarGroups[weekIndex] = tempBarGroups;
      cachedWeekDays[weekIndex] = tempWeekDays;
      isLoading = false;
    });
  }

  @override



  @override
@override
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Steps Over Days'),
    ),
    body: Center(
      child: isLoading
          ? CircularProgressIndicator()
          : Column(
              children: [
                Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.blueAccent,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 1,
          blurRadius: 3,
          offset: Offset(0, 2), // changes position of shadow
        ),
      ],
    ),
    padding: const EdgeInsets.all(16.0),
    child: Text(
      'You have walked ${calculateTotalSteps()} steps in the past 7 days!',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Roboto', // Example of custom font family
      ),
    ),
  ),
)
,
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) async {
                      setState(() {
                        isLoading = false;
                      });
                      await fetchStepsData(index);
                      setState(() {
                        currentWeekIndex = index;
                        isLoading = false;
                      });
                    },
                    itemBuilder: (context, index) {
                      if (!cachedBarGroups.containsKey(index) ||
                          !cachedWeekDays.containsKey(index)) {
                        return Center(child: CircularProgressIndicator());
                      }

                      // Calculate max value for dynamic y-axis
                      double maxY = 0;
                      for (var group in cachedBarGroups[index]!) {
                        for (var rod in group.barRods) {
                          if (rod.toY > maxY) {
                            maxY = rod.toY;
                          }
                        }
                      }
                      maxY = (maxY / 1000).ceil() * 1000;

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: BarChart(
                          BarChartData(
                            maxY: maxY,
                            alignment: BarChartAlignment.spaceAround,
                            barGroups: cachedBarGroups[index]!,
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 200 == 0) {
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
                                        cachedWeekDays[index]![value.toInt()],
                                        style: TextStyle(
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
                              show: false,
                              drawHorizontalLine: true,
                              drawVerticalLine: false,
                              horizontalInterval: 200,
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
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${cachedWeekDays[index]![group.x.toInt()]}\n',
                                    TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: '${rod.toY.toInt()} steps',
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
                              touchCallback:
                                  (FlTouchEvent event, barTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      barTouchResponse == null ||
                                      barTouchResponse.spot == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = barTouchResponse
                                      .spot!.touchedBarGroupIndex;
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    ),
  );
}

String calculateTotalSteps() {
  if (cachedBarGroups.containsKey(currentWeekIndex)) {
    int totalSteps = 0;
    for (var group in cachedBarGroups[currentWeekIndex]!) {
      totalSteps += group.barRods[0].toY.toInt();
    }
    return totalSteps.toString();
  }
  return '0';
}

}