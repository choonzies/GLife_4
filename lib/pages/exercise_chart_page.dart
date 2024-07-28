import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';

class ActiveEnergyChartPage extends StatefulWidget {
  @override
  _ActiveEnergyChartPageState createState() => _ActiveEnergyChartPageState();
}

class _ActiveEnergyChartPageState extends State<ActiveEnergyChartPage> {
  PageController _pageController =
      PageController(initialPage: 0, keepPage: true);
  Map<int, List<BarChartGroupData>> cachedBarGroups = {};
  Map<int, List<String>> cachedWeekDays = {};
  int currentWeekIndex = 0;
  bool isLoading = true;
  int touchedIndex = -1;
  String selectedDate = '';

  @override
  void initState() {
    super.initState();
    fetchActiveEnergyData(currentWeekIndex);
  }

  Future<void> fetchActiveEnergyData(int weekIndex) async {
    var types = [
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];

    // bool permission = await Health().requestAuthorization(types);
    // if (!permission) {
    //   debugPrint('Authorization not granted');
    //   return;
    // }

    var now = DateTime.now();
    var startOfWeek =
        now.subtract(Duration(days: now.weekday - 1 + 7 * weekIndex));
    List<BarChartGroupData> tempBarGroups = [];
    List<String> tempWeekDays = [];

    for (int i = 0; i <= 6; i++) {
      var day = startOfWeek.add(Duration(days: i));
      var midnight = DateTime(day.year, day.month, day.day);

      try {
        List<HealthDataPoint> healthData =
            await Health().getHealthDataFromTypes(
          startTime: midnight,
          endTime: midnight.add(Duration(days: 1)),
          types: types,
        );

        int totalActiveEnergy = 0;
        int energy = 0;
        for (HealthDataPoint dataPoint in healthData) {
          energy = dataPoint.toJson()['value'].numericValue.toInt();
          totalActiveEnergy += energy;
        }
        tempBarGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: totalActiveEnergy.toDouble(),
                gradient: LinearGradient(
                  colors: [Colors.orangeAccent, Colors.redAccent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 22,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 5000,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
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

  String calculateTotalActiveEnergy() {
    if (cachedBarGroups.containsKey(currentWeekIndex)) {
      int totalActiveEnergy = 0;
      for (var group in cachedBarGroups[currentWeekIndex]!) {
        totalActiveEnergy += group.barRods[0].toY.toInt();
      }
      return totalActiveEnergy.toString();
    }
    return '0';
  }

  String getDateRange(int weekIndex) {
    var now = DateTime.now();
    var startOfWeek =
        now.subtract(Duration(days: now.weekday - 1 + 7 * weekIndex));
    var endOfWeek = startOfWeek.add(Duration(days: 6));
    return '${DateFormat.yMMMd().format(startOfWeek)} - ${DateFormat.yMMMd().format(endOfWeek)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calories Over Days'),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blueAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'You have burnt ${calculateTotalActiveEnergy()} kcal this week!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Date Range: ${getDateRange(currentWeekIndex)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedDate.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Selected Date: $selectedDate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) async {
                        setState(() {
                          isLoading = false;
                        });
                        await fetchActiveEnergyData(index);
                        setState(() {
                          currentWeekIndex = index;
                          isLoading = false;
                          selectedDate = '';
                        });
                      },
                      itemBuilder: (context, index) {
                        if (!cachedBarGroups.containsKey(index) ||
                            !cachedWeekDays.containsKey(index)) {
                          return Center(child: CircularProgressIndicator());
                        }

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
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
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
                                          text: '${rod.toY.toInt()} kcal',
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
                                      selectedDate = '';
                                      return;
                                    }
                                    touchedIndex = barTouchResponse
                                        .spot!.touchedBarGroupIndex;
                                    var startOfWeek = DateTime.now().subtract(
                                        Duration(
                                            days: DateTime.now().weekday -
                                                1 +
                                                7 * currentWeekIndex));
                                    selectedDate = DateFormat.yMMMd().format(
                                        startOfWeek
                                            .add(Duration(days: touchedIndex)));
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
}
