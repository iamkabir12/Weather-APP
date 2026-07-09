class HourlyModel {
  final DateTime time;
  final double temperature;
  final String condition;
  final String icon;

  HourlyModel({
    required this.time,
    required this.temperature,
    required this.condition,
    required this.icon,
  });

  factory HourlyModel.fromJson(Map<String, dynamic> json) {
    return HourlyModel(
      time: DateTime.parse(json['dt_txt']),
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'],
      icon: json['weather'][0]['icon'],
    );
  }
}