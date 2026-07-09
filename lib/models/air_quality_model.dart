class AirQualityModel {
  final int aqi;
  final double pm25;
  final double pm10;
  final double no2;
  final double o3;

  AirQualityModel({
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.no2,
    required this.o3,
  });

  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    final components = json['components'];

    return AirQualityModel(
      aqi: json['main']['aqi'],
      pm25: (components['pm2_5'] as num).toDouble(),
      pm10: (components['pm10'] as num).toDouble(),
      no2: (components['no2'] as num).toDouble(),
      o3: (components['o3'] as num).toDouble(),
    );
  }

  String get level {
    switch (aqi) {
      case 1:
        return "Good";
      case 2:
        return "Fair";
      case 3:
        return "Moderate";
      case 4:
        return "Poor";
      case 5:
        return "Very Poor";
      default:
        return "Unknown";
    }
  }
}