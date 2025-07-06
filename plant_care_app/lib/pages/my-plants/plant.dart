class Plant {
  final String speciesName;
  final String scientificName;
  final String? description;
  final String? careDifficulty;
  final int? waterFrequencyDays;
  final String? sunlightRequirement;
  final String? imageUrl;
  final int? currentAvailability;
  final String userId;
  DateTime?
      lastWateredDate; // Added field to track when the plant was last watered
  final String? plantId;
  final String? adoptionId; // Added to store the adoption record ID
  String? alarmTiming; // Added to store the alarm timing from adoption_record
  bool? isVerified; // Added to store the verification status

  Plant({
    required this.speciesName,
    required this.scientificName,
    this.description,
    this.careDifficulty,
    this.waterFrequencyDays,
    this.sunlightRequirement,
    this.imageUrl,
    this.currentAvailability,
    required this.userId,
    this.lastWateredDate,
    this.plantId,
    this.adoptionId,
    this.alarmTiming,
    this.isVerified,
  });

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      speciesName: map['species_name'] ?? '',
      scientificName: map['scientific_name'] ?? '',
      description: map['description'],
      careDifficulty: map['care_difficulty'],
      waterFrequencyDays: int.tryParse(map['days_to_water']?.toString() ?? '0'),
      sunlightRequirement: map['sunlight_requirement'],
      imageUrl: map['image_url'],
      currentAvailability: map['current_availability'],
      userId: map['user_id'] ?? '',
      plantId: map['plant_id'],
    );
  }
}