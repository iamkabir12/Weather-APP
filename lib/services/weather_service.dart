import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/air_quality_model.dart';
import '../models/forecast_model.dart';
import '../models/hourly_model.dart';

class WeatherService {
  final String apiKey = "YOUR_API_KEY";

  /// Current weather by city
  Future<Map<String, dynamic>> getWeather(String city) async {
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'q': city,
      'appid': apiKey,
      'units': 'metric',
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 404) {
      throw Exception("No city found for \"$city\"");
    }

    throw Exception("Unable to load weather. Please try again.");
  }

  /// Current weather by GPS
  Future<Map<String, dynamic>> getWeatherByLocation(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'appid': apiKey,
      'units': 'metric',
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception("Unable to load weather for your location.");
  }

  /// 5-Day Forecast
  Future<List<ForecastModel>> getFiveDayForecast(String city) async {
    final response = await _getForecastResponse(city);

    if (response.statusCode != 200) {
      throw Exception("Failed to load forecast");
    }

    final json = jsonDecode(response.body);

    final List forecastList = json['list'];

    final List<ForecastModel> forecast = forecastList
        .map((item) => ForecastModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final List<ForecastModel> dailyForecast = [];

    for (final item in forecast) {
      if (item.date.hour == 12) {
        dailyForecast.add(item);
      }
    }

    return dailyForecast;
  }

  /// 24-Hour Forecast
  Future<List<HourlyModel>> getHourlyForecast(String city) async {
    final response = await _getForecastResponse(city);

    if (response.statusCode != 200) {
      throw Exception("Failed to load hourly forecast");
    }

    final json = jsonDecode(response.body);

    final List list = json['list'];

    return list
        .take(8)
        .map((item) => HourlyModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Air Quality Index (AQI)
  Future<AirQualityModel> getAirQuality(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/air_pollution', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'appid': apiKey,
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Failed to load air quality");
    }

    final json = jsonDecode(response.body);

    return AirQualityModel.fromJson(json['list'][0]);
  }

  Future<List<String>> getCitySuggestions(String query) async {
    if (query.trim().length < 2) return [];

    final uri = Uri.https('api.openweathermap.org', '/geo/1.0/direct', {
      'q': query.trim(),
      'limit': '5',
      'appid': apiKey,
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) return [];

    final List results = jsonDecode(response.body) as List;
    final suggestions = <String>{};

    for (final item in results) {
      final map = item as Map<String, dynamic>;
      final name = map['name']?.toString();
      final country = map['country']?.toString();

      if (name == null || name.isEmpty) continue;
      suggestions.add(country == null ? name : '$name, $country');
    }

    return suggestions.toList();
  }

  Future<http.Response> _getForecastResponse(String city) {
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/forecast', {
      'q': city,
      'appid': apiKey,
      'units': 'metric',
    });

    return http.get(uri);
  }
}
