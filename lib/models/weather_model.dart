class WeatherModel {
  final String city;
  final double temperature;
  final String description;
  final String condition;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final int visibility;

  WeatherModel({
    required this.city,
    required this.temperature,
    required this.description,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      city: json['name'],
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      condition: json['weather'][0]['main'],
      icon: json['weather'][0]['icon'],
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      pressure: json['main']['pressure'],
      visibility: json['visibility'],
    );
  }
}