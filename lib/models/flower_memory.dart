class FlowerMemory {
  final String id;
  final String photoPath;
  final String flowerName;
  final String flowerLang;
  final String scientificName;
  final String family;
  final String aiNote;
  final String tip;
  final String memo;
  final String location;
  final DateTime date;
  final String season;

  const FlowerMemory({
    required this.id,
    required this.photoPath,
    required this.flowerName,
    required this.flowerLang,
    required this.scientificName,
    required this.family,
    required this.aiNote,
    required this.tip,
    required this.memo,
    required this.location,
    required this.date,
    required this.season,
  });

  // Hive는 Map으로 저장 (Android의 SharedPreferences에 JSON 넣는 것과 비슷)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoPath': photoPath,
      'flowerName': flowerName,
      'flowerLang': flowerLang,
      'scientificName': scientificName,
      'family': family,
      'aiNote': aiNote,
      'tip': tip,
      'memo': memo,
      'location': location,
      'date': date.millisecondsSinceEpoch,
      'season': season,
    };
  }

  factory FlowerMemory.fromMap(Map<dynamic, dynamic> map) {
    return FlowerMemory(
      id: map['id'] ?? '',
      photoPath: map['photoPath'] ?? '',
      flowerName: map['flowerName'] ?? '',
      flowerLang: map['flowerLang'] ?? '',
      scientificName: map['scientificName'] ?? '',
      family: map['family'] ?? '',
      aiNote: map['aiNote'] ?? '',
      tip: map['tip'] ?? '',
      memo: map['memo'] ?? '',
      location: map['location'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      season: map['season'] ?? '',
    );
  }
}
