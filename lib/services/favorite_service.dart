import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String key = "favorite_cities";

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getStringList(key) ?? [];
  }

  Future<void> addFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();

    final cities = prefs.getStringList(key) ?? [];

    if (!cities.contains(city)) {
      cities.add(city);
      await prefs.setStringList(key, cities);
    }
  }

  Future<void> removeFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();

    final cities = prefs.getStringList(key) ?? [];

    cities.remove(city);

    await prefs.setStringList(key, cities);
  }

  Future<bool> isFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();

    final cities = prefs.getStringList(key) ?? [];

    return cities.contains(city);
  }
}