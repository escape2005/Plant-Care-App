import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;
final user = supabase.auth.currentUser;

final userId = user?.id;

class IndiPlants extends StatefulWidget {
  final String speciesName;
  final String scientificName;
  final String? imageUrl;
  final int waterFrequencyDays;

  const IndiPlants({
    Key? key,
    required this.speciesName,
    required this.scientificName,
    this.imageUrl,
    required this.waterFrequencyDays,
  }) : super(key: key);

  @override
  State<IndiPlants> createState() => _IndiPlantsState();
}

class _IndiPlantsState extends State<IndiPlants> {
  String? adoptionId;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAdoptionId();
  }

  Future<void> _fetchAdoptionId() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      // Print some debug information
      print('Fetching plant_id for species: ${widget.speciesName}');
      print('Current user ID: ${user.id}');

      // Step 2: Fetch plant_id from plant_catalog based on species_name
      final plantCatalogResponse = await supabase
          .from('plant_catalog')
          .select('plant_id')
          .eq('species_name', widget.speciesName)
          .limit(1);

      print('Plant catalog response: $plantCatalogResponse');

      if (plantCatalogResponse == null || plantCatalogResponse.isEmpty) {
        setState(() {
          errorMessage = 'Plant not found in catalog';
          isLoading = false;
        });
        return;
      }

      // Step 3: Extract the plant_id
      final plantId = plantCatalogResponse[0]['plant_id'];
      print('Found plant_id: $plantId for species: ${widget.speciesName}');

      // Step 4: Get adoption_id using plant_id and user_id
      final adoptionResponse = await supabase
          .from('adoption_record')
          .select('adoption_id')
          .eq('plant_id', plantId)
          .eq('user_id', user.id)
          .limit(1);

      print('Adoption response: $adoptionResponse');

      if (adoptionResponse == null || adoptionResponse.isEmpty) {
        setState(() {
          errorMessage = 'Adoption record not found';
          isLoading = false;
        });
        return;
      }

      // Step 5: Store the adoption_id
      final id = adoptionResponse[0]['adoption_id'];
      print('Found adoption_id: $id');

      setState(() {
        adoptionId = id.toString();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching adoption ID: $e');
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: const Text('Plantify', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : adoptionId == null
              ? Center(
                child: Text(
                  'Error: $errorMessage',
                  style: TextStyle(color: Colors.red),
                ),
              )
              : PlantDetailsWidget(
                adoptionId: adoptionId!,
                speciesName: widget.speciesName,
                scientificName: widget.scientificName,
                imageUrl: widget.imageUrl,
                waterFrequencyDays: widget.waterFrequencyDays,
              ),
    );
  }
}

class PlantDetailsWidget extends StatefulWidget {
  final String adoptionId;
  final String speciesName;
  final String scientificName;
  final String? imageUrl;
  final int waterFrequencyDays;

  const PlantDetailsWidget({
    Key? key,
    required this.adoptionId,
    required this.speciesName,
    required this.scientificName,
    this.imageUrl,
    required this.waterFrequencyDays,
  }) : super(key: key);

  @override
  State<PlantDetailsWidget> createState() => _PlantDetailsWidgetState();
}

class _PlantDetailsWidgetState extends State<PlantDetailsWidget> {
  bool isLoading = true;
  String lastWateredDate = 'Loading...';
  double wateringProgress = 0.0;
  String wateringStatus = 'Loading...';
  Color statusColor = Colors.grey;
  DateTime? lastWateredDateTime;
  DateTime? adoptionDateTime;
  List<DateTime> wateredDays = [];
  late DateTime today;
  bool wateredToday = false;

  @override
  void initState() {
    super.initState();
    today = _getToday();
    _loadData();
  }

  DateTime _getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([fetchAdoptionDate(), fetchAllWateringActivities()]);
      fetchLastWateringActivity();
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> fetchAdoptionDate() async {
    try {
      final supabase = Supabase.instance.client;

      final response =
          await supabase
              .from('adoption_record')
              .select('adoption_date')
              .eq('adoption_id', widget.adoptionId)
              .single();

      if (response != null && response['adoption_date'] != null) {
        adoptionDateTime = DateTime.parse(response['adoption_date']);
        print('Adoption date: $adoptionDateTime');
      }
    } catch (e) {
      print('Error fetching adoption date: $e');
    }
  }

  Future<void> fetchAllWateringActivities() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('daily_activity')
          .select('activity_time')
          .eq('adoption_id', widget.adoptionId)
          .order('activity_time', ascending: true);

      if (response != null && response.isNotEmpty) {
        wateredDays =
            response
                .map<DateTime>(
                  (activity) => DateTime.parse(activity['activity_time']),
                )
                .map<DateTime>(
                  (dateTime) =>
                      DateTime(dateTime.year, dateTime.month, dateTime.day),
                )
                .toList();

        print('Fetched ${wateredDays.length} watering activities');
      }
    } catch (e) {
      print('Error fetching watering activities: $e');
    }
  }

  Future<void> fetchLastWateringActivity() async {
    try {
      final supabase = Supabase.instance.client;

      // Print debug information
      print('Fetching watering activity for adoption_id: ${widget.adoptionId}');

      // Fetch the latest activity_time for the given adoption_id
      final response = await supabase
          .from('daily_activity')
          .select('activity_time')
          .eq('adoption_id', widget.adoptionId)
          .order('activity_time', ascending: false)
          .limit(1);

      print('Daily activity response: $response');

      if (response != null && response.isNotEmpty) {
        // Parse the timestamp
        final activityTimeStr = response[0]['activity_time'];
        lastWateredDateTime = DateTime.parse(activityTimeStr);

        // Format the date for display
        lastWateredDate = DateFormat(
          'MMMM d, yyyy',
        ).format(lastWateredDateTime!);
        print('Last watered date: $lastWateredDate');

        // Calculate watering progress
        final now = DateTime.now();
        final nowDate = DateTime(now.year, now.month, now.day);
        final lastWateredDateOnly = DateTime(
          lastWateredDateTime!.year,
          lastWateredDateTime!.month,
          lastWateredDateTime!.day,
        );
        final difference = nowDate.difference(lastWateredDateOnly).inDays;

        void checkWateredToday() {
          if (lastWateredDateTime != null) {
            final now = DateTime.now();
            final todayDate = DateTime(now.year, now.month, now.day);
            final lastWateredDateOnly = DateTime(
              lastWateredDateTime!.year,
              lastWateredDateTime!.month,
              lastWateredDateTime!.day,
            );

            // Check if the last watered date is today
            wateredToday = todayDate.isAtSameMomentAs(lastWateredDateOnly);
            print('Watered today: $wateredToday');
          } else {
            wateredToday = false;
          }
        }

        print('Days since last watered: $difference');

        // The maximum days (denominator) is the water frequency or default to 15
        final maxDays =
            widget.waterFrequencyDays > 0 ? widget.waterFrequencyDays : 15;

        // Calculate progress as days since last watered divided by max days
        wateringProgress = difference / maxDays;

        // Cap progress at 1.0 (100%)
        if (wateringProgress > 1.0) {
          wateringProgress = 1.0;
        }

        // Determine status based on progress
        if (wateringProgress < 0.4) {
          wateringStatus = 'Healthy';
          statusColor = Colors.green;
        } else if (wateringProgress < 0.7) {
          wateringStatus = 'Needs attention \nsoon';
          statusColor = Colors.orange;
        } else {
          wateringStatus = 'Needs \nwatering!';
          statusColor = Colors.red;
        }
        checkWateredToday();
      } else {
        // No watering record found
        lastWateredDate = 'No watering record found';
        wateringProgress = 1.0;
        wateringStatus = 'Needs watering!';
        statusColor = Colors.red;
      }
    } catch (e) {
      print('Error fetching watering activity: $e');
      lastWateredDate = 'Error fetching data';
      wateringProgress = 0.0;
      wateringStatus = 'Error';
      statusColor = Colors.grey;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool _isWateredDay(DateTime day) {
    return wateredDays.any(
      (wateredDay) =>
          wateredDay.year == day.year &&
          wateredDay.month == day.month &&
          wateredDay.day == day.day,
    );
  }

  bool _isBeforeAdoptionDate(DateTime day) {
    if (adoptionDateTime == null) return false;

    // Compare only date components without time
    final adoptionDate = DateTime(
      adoptionDateTime!.year,
      adoptionDateTime!.month,
      adoptionDateTime!.day,
    );

    final compareDate = DateTime(day.year, day.month, day.day);
    return compareDate.isBefore(adoptionDate);
  }

  bool _isPastOrToday(DateTime day) {
    final compareDate = DateTime(day.year, day.month, day.day);
    return compareDate.compareTo(today) <= 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, thickness: 1),

        // Using Expanded to prevent overflow
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plant Image with Details Overlay
                Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Image.network(
                      widget.imageUrl ??
                          'https://cdn.pixabay.com/photo/2020/06/21/19/49/mango-5326518_1280.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 300,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.9),
                            Colors.black.withOpacity(0.0),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Using FittedBox to prevent overflow of text
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.speciesName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Using FittedBox for scientific name
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.scientificName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Using FittedBox for last watered date
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Last watered on $lastWateredDate',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),

                // Watering Status
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed row layout for status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Watering Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              wateringStatus,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor:
                                      1.0 -
                                      wateringProgress, // Inverted to show water level
                                  child: Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          wateringProgress < 0.4
                                              ? Colors.green.shade700
                                              : wateringProgress < 0.7
                                              ? Colors.orange.shade700
                                              : Colors.red.shade700,
                                          wateringProgress < 0.4
                                              ? Colors.green.shade400
                                              : wateringProgress < 0.7
                                              ? Colors.orange.shade400
                                              : Colors.red.shade400,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                      const SizedBox(height: 20),
                      // Modified plant stats layout to prevent overflow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(vertical: 4.0),
                          //   child: Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       Icon(
                          //         Icons.thermostat_outlined,
                          //         color: Colors.green[400],
                          //       ),
                          //       const SizedBox(width: 4),
                          //       const Text(
                          //         '24°C',
                          //         style: TextStyle(fontSize: 16),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(vertical: 4.0),
                          //   child: Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       Icon(
                          //         Icons.water_drop_outlined,
                          //         color: Colors.green[400],
                          //       ),
                          //       const SizedBox(width: 4),
                          //       const Text(
                          //         '65% Humidity',
                          //         style: TextStyle(fontSize: 16),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.green[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.waterFrequencyDays} days water cycle',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Watering Calendar Schedule - Using LayoutBuilder to handle calendar width
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return TableCalendar(
                        focusedDay: DateTime.now(),
                        firstDay: DateTime(2025, 01, 01),
                        lastDay: DateTime(2025, 12, 31),
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                          CalendarFormat.twoWeeks: '2 Weeks',
                          CalendarFormat.week: 'Week',
                        },
                        selectedDayPredicate: (day) {
                          return lastWateredDateTime != null &&
                              isSameDay(lastWateredDateTime!, day);
                        },
                        enabledDayPredicate: (day) {
                          // Disable dates before adoption date
                          return !_isBeforeAdoptionDate(day);
                        },
                        calendarStyle: CalendarStyle(
                          // Default styling for the calendar
                          markersMaxCount: 0,
                          markersAnchor: 0,
                          markerMargin: const EdgeInsets.only(top: 8),
                          markerSize: 8,
                          markerDecoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          // Make sure the day cells don't overflow
                          cellMargin: const EdgeInsets.all(2),
                          cellPadding: const EdgeInsets.all(0),
                        ),
                        // Smaller row height to prevent overflow in smaller devices
                        rowHeight: 48,
                        // Use calendarBuilders to customize individual day cells
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, date, _) {
                            // Only apply special styling to past dates and today
                            if (_isPastOrToday(date)) {
                              // Apply green background for watered days
                              if (_isWateredDay(date)) {
                                return Container(
                                  margin: const EdgeInsets.all(2.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${date.day}',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              }
                              // Apply red background for non-watered past days
                              else {
                                return Container(
                                  margin: const EdgeInsets.all(2.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${date.day}',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              }
                            }
                            return null; // Return null to use default styling for future dates
                          },
                          todayBuilder: (context, date, _) {
                            // Custom builder for today
                            if (_isWateredDay(date)) {
                              return Container(
                                margin: const EdgeInsets.all(2.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                margin: const EdgeInsets.all(2.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                          },
                          selectedBuilder: (context, date, _) {
                            // Custom builder for selected day
                            return Container(
                              margin: const EdgeInsets.all(2.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    _isWateredDay(date)
                                        ? Colors.green
                                        : Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                          disabledBuilder: (context, date, _) {
                            // Custom builder for disabled days (before adoption)
                            return Container(
                              margin: const EdgeInsets.all(2.0),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize:
                                      14, // Smaller font size for disabled dates
                                ),
                              ),
                            );
                          },
                          // Customize header style to prevent overflow
                          headerTitleBuilder: (context, date) {
                            return Center(
                              child: Text(
                                DateFormat.yMMMM().format(date),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          // Smaller weekday labels to prevent overflow
                          weekdayStyle: TextStyle(fontSize: 12),
                          weekendStyle: TextStyle(fontSize: 12),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible:
                              constraints.maxWidth >
                              320, // Hide format button on very small screens
                          titleCentered: true,
                          formatButtonShowsNext: false,
                          formatButtonDecoration: BoxDecoration(
                            color: Colors.green[400],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          formatButtonTextStyle: const TextStyle(
                            color: Colors.white,
                          ),
                          titleTextStyle: const TextStyle(fontSize: 16),
                        ),
                        // Provide the watered days to the event loader for markers
                        eventLoader: (day) {
                          return [];
                        },
                      );
                    },
                  ),
                ),

                // Water Now Button
                Container(
                  margin: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        wateredToday
                            ? null // Disable button if already watered today
                            : () async {
                              // Update the water status in the database
                              try {
                                final supabase = Supabase.instance.client;
                                final now =
                                    DateTime.now().toUtc().toIso8601String();

                                final response = await supabase
                                    .from('daily_activity')
                                    .insert({
                                      'user_id': userId,
                                      'adoption_id': widget.adoptionId,
                                      'activity_time': now,
                                    });

                                print('Water now response: $response');

                                // Add the new watering date to our list
                                setState(() {
                                  wateredDays.add(today);
                                  wateredToday =
                                      true; // Update watered today status
                                });

                                // Refresh the data
                                fetchLastWateringActivity();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Watering recorded successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                print('Error recording watering: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error recording watering: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          wateredToday ? Colors.grey : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      wateredToday ? 'Already Watered' : 'Water Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
