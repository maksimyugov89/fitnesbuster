class BodyMeasurement {
  final DateTime date;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? bodyFatPercent;

  const BodyMeasurement({
    required this.date,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.bodyFatPercent,
  });

  bool get hasData => chestCm != null || waistCm != null || hipsCm != null || bodyFatPercent != null;

  Map<String, dynamic> toMap() => {
    'date': date.millisecondsSinceEpoch,
    if (chestCm != null) 'chestCm': chestCm,
    if (waistCm != null) 'waistCm': waistCm,
    if (hipsCm != null) 'hipsCm': hipsCm,
    if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
  };

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) => BodyMeasurement(
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    chestCm: (map['chestCm'] as num?)?.toDouble(),
    waistCm: (map['waistCm'] as num?)?.toDouble(),
    hipsCm: (map['hipsCm'] as num?)?.toDouble(),
    bodyFatPercent: (map['bodyFatPercent'] as num?)?.toDouble(),
  );
}
