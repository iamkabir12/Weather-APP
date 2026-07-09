class ForecastModel {
  final DateTime date;
  final double temperature;
  final String condition;
  final String icon;

  ForecastModel({
    required this.date,
    required this.temperature,
    required this.condition,
    required this.icon,
  });

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    return ForecastModel(
      date: DateTime.parse(json['dt_txt']),
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'],
      icon: json['weather'][0]['icon'],
    );
  }
}