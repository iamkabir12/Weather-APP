import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/air_quality_model.dart';
import '../models/forecast_model.dart';
import '../models/hourly_model.dart';
import '../services/favorite_service.dart';
import '../services/weather_service.dart';
import '../utils/weather_animation.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/favorite_button.dart';
import '../widgets/forecast_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/hourly_card.dart';
import '../widgets/weather_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const String _recentSearchesKey = 'recent_searches';

  final WeatherService _weatherService = WeatherService();
  final FavoriteService _favoriteService = FavoriteService();

  late final AnimationController _controller;

  bool _isLoading = false;
  bool _useFahrenheit = false;
  bool _isFavorite = false;
  String? _error;
  String _activeCity = 'Kathmandu';

  Map<String, dynamic>? _weather;
  AirQualityModel? _airQuality;
  List<ForecastModel> _forecast = [];
  List<HourlyModel> _hourlyForecast = [];
  List<String> _favorites = [];
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _loadSavedState();
    _loadCurrentLocationWeather();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await _favoriteService.getFavorites();

    if (!mounted) return;
    setState(() {
      _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
      _favorites = favorites;
    });
  }

  Future<void> _loadWeather(String city, {bool rememberSearch = true}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await _weatherService.getWeather(city);
      await _loadWeatherBundle(weather, rememberSearch: rememberSearch);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWeatherBundle(
    Map<String, dynamic> weather, {
    bool rememberSearch = true,
  }) async {
    final city = weather['name'].toString();
    final coordinates = weather['coord'] as Map<String, dynamic>;

    final forecast = await _weatherService.getFiveDayForecast(city);
    final hourly = await _weatherService.getHourlyForecast(city);
    final airQuality = await _weatherService.getAirQuality(
      (coordinates['lat'] as num).toDouble(),
      (coordinates['lon'] as num).toDouble(),
    );

    final favorites = await _favoriteService.getFavorites();
    if (rememberSearch) await _saveRecentSearch(city);

    if (!mounted) return;
    setState(() {
      _weather = weather;
      _activeCity = city;
      _forecast = forecast;
      _hourlyForecast = hourly;
      _airQuality = airQuality;
      _favorites = favorites;
      _isFavorite = favorites.contains(city);
      _isLoading = false;
      _error = null;
    });
  }

  Future<void> _loadCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _loadWeather(_activeCity, rememberSearch: false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _loadWeather(_activeCity, rememberSearch: false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final weather = await _weatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      await _loadWeatherBundle(weather, rememberSearch: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRecentSearch(String city) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [
      city,
      ..._recentSearches.where(
        (item) => item.toLowerCase() != city.toLowerCase(),
      ),
    ].take(6).toList();

    await prefs.setStringList(_recentSearchesKey, updated);
    if (mounted) setState(() => _recentSearches = updated);
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    if (mounted) setState(() => _recentSearches = []);
  }

  Future<void> _toggleFavorite() async {
    final city = _weather?['name']?.toString();
    if (city == null) return;

    if (_isFavorite) {
      await _favoriteService.removeFavorite(city);
    } else {
      await _favoriteService.addFavorite(city);
    }

    final favorites = await _favoriteService.getFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _isFavorite = favorites.contains(city);
    });
  }

  Future<void> _refresh() async {
    if (_weather == null) {
      await _loadCurrentLocationWeather();
    } else {
      await _loadWeather(_activeCity, rememberSearch: false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.toLowerCase().contains('socket')) {
      return 'You appear to be offline. Check your connection and try again.';
    }
    return message;
  }

  double _displayTemp(num value) {
    final celsius = value.toDouble();
    return _useFahrenheit ? (celsius * 9 / 5) + 32 : celsius;
  }

  String _temp(num value) => '${_displayTemp(value).round()}°';

  String get _unitLabel => _useFahrenheit ? 'F' : 'C';

  String _windDirection(num? degrees) {
    if (degrees == null) return 'N/A';
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees % 360) / 45).round() % 8;
    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImage = _weather == null
        ? 'assets/backgrounds/clouds.jpg'
        : getWeatherBackground(
            _weather!['weather'][0]['main'].toString(),
            _weather!['weather'][0]['icon'].toString(),
          );

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: Colors.black87,
                  backgroundColor: Colors.white,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  CustomSearchBar(
                                    recentSearches: _recentSearches,
                                    onClearHistory: _clearSearchHistory,
                                    onSuggestions:
                                        _weatherService.getCitySuggestions,
                                    onSearch: (city) => _loadWeather(city),
                                  ),
                                  const SizedBox(height: 18),
                                  _buildTopActions(),
                                  const SizedBox(height: 18),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: _buildContent(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _weather == null) {
      return const _LoadingDashboard(key: ValueKey('loading'));
    }

    if (_error != null && _weather == null) {
      return _ErrorState(
        key: const ValueKey('error'),
        message: _error!,
        onRetry: _refresh,
      );
    }

    if (_weather == null) {
      return _EmptyState(
        key: const ValueKey('empty'),
        onRetry: _loadCurrentLocationWeather,
      );
    }

    return _buildDashboard(key: const ValueKey('dashboard'));
  }

  Widget _buildTopActions() {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionChip(
                icon: Icons.my_location,
                label: 'Current location',
                onTap: _loadCurrentLocationWeather,
              ),
              _ActionChip(
                icon: Icons.refresh,
                label: 'Refresh',
                onTap: _refresh,
              ),
              _ActionChip(
                icon: Icons.thermostat,
                label: '°$_unitLabel',
                onTap: () {
                  setState(() => _useFahrenheit = !_useFahrenheit);
                },
              ),
            ],
          ),
        ),
        if (_weather != null)
          FavoriteButton(isFavorite: _isFavorite, onPressed: _toggleFavorite),
      ],
    );
  }

  Widget _buildDashboard({Key? key}) {
    final weather = _weather!;
    final main = weather['main'] as Map<String, dynamic>;
    final info = weather['weather'][0] as Map<String, dynamic>;
    final wind = weather['wind'] as Map<String, dynamic>;
    final clouds = weather['clouds'] as Map<String, dynamic>?;
    final sunrise = DateTime.fromMillisecondsSinceEpoch(
      (weather['sys']['sunrise'] as int) * 1000,
    );
    final sunset = DateTime.fromMillisecondsSinceEpoch(
      (weather['sys']['sunset'] as int) * 1000,
    );
    final updated = DateTime.fromMillisecondsSinceEpoch(
      (weather['dt'] as int) * 1000,
    );

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          _InlineNotice(message: _error!),
          const SizedBox(height: 16),
        ],
        _buildHeroCard(weather, main, info, updated),
        const SizedBox(height: 18),
        _buildFavorites(),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Weather Details',
          trailing: 'Updated ${DateFormat('hh:mm a').format(updated)}',
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width > 680 ? 3 : 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.28,
          children: [
            WeatherCard(
              icon: Icons.water_drop,
              title: 'Humidity',
              value: '${main['humidity']}%',
            ),
            WeatherCard(
              icon: Icons.air,
              title: 'Wind',
              value: '${(wind['speed'] as num).toStringAsFixed(1)} m/s',
            ),
            WeatherCard(
              icon: Icons.explore,
              title: 'Direction',
              value: _windDirection(wind['deg'] as num?),
            ),
            WeatherCard(
              icon: Icons.thermostat,
              title: 'Feels Like',
              value: _temp(main['feels_like'] as num),
            ),
            WeatherCard(
              icon: Icons.visibility,
              title: 'Visibility',
              value:
                  '${((weather['visibility'] as num) / 1000).toStringAsFixed(1)} km',
            ),
            WeatherCard(
              icon: Icons.speed,
              title: 'Pressure',
              value: '${main['pressure']} hPa',
            ),
            WeatherCard(
              icon: Icons.cloud,
              title: 'Cloud Cover',
              value: '${clouds?['all'] ?? 0}%',
            ),
            WeatherCard(
              icon: Icons.water,
              title: 'Sea Level',
              value: '${main['sea_level'] ?? main['pressure']} hPa',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: WeatherCard(
                icon: Icons.wb_sunny,
                title: 'Sunrise',
                value: DateFormat('hh:mm a').format(sunrise),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: WeatherCard(
                icon: Icons.nightlight_round,
                title: 'Sunset',
                value: DateFormat('hh:mm a').format(sunset),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildAirQuality(),
        const SizedBox(height: 30),
        const _SectionTitle(title: 'Next 24 Hours'),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _hourlyForecast.length,
            itemBuilder: (context, index) {
              return HourlyCard(hourly: _hourlyForecast[index]);
            },
          ),
        ),
        const SizedBox(height: 30),
        const _SectionTitle(title: '5-Day Forecast'),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _forecast.length,
            itemBuilder: (context, index) {
              return ForecastCard(forecast: _forecast[index]);
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildHeroCard(
    Map<String, dynamic> weather,
    Map<String, dynamic> main,
    Map<String, dynamic> info,
    DateTime updated,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 560;

          final summary = Column(
            crossAxisAlignment: wide
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(
                weather['name'].toString(),
                textAlign: wide ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 18),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _displayTemp(main['temp'] as num)),
                duration: const Duration(milliseconds: 700),
                builder: (context, value, child) {
                  return Text(
                    '${value.round()}°$_unitLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Text(
                info['description'].toString().toUpperCase(),
                textAlign: wide ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'H:${_temp(main['temp_max'] as num)}  L:${_temp(main['temp_min'] as num)}  Feels ${_temp(main['feels_like'] as num)}',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated ${DateFormat('hh:mm a').format(updated)}',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          );

          final animation = SizedBox(
            height: wide ? 210 : 170,
            child: Lottie.asset(
              getWeatherAnimation(
                info['main'].toString(),
                info['icon'].toString(),
              ),
              fit: BoxFit.contain,
            ),
          );

          if (!wide) {
            return Column(children: [animation, summary]);
          }

          return Row(
            children: [
              Expanded(child: summary),
              const SizedBox(width: 18),
              Expanded(child: animation),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavorites() {
    if (_favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Favorite Cities'),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _favorites.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final city = _favorites[index];
              return _ActionChip(
                icon: Icons.favorite,
                label: city,
                onTap: () => _loadWeather(city),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAirQuality() {
    final airQuality = _airQuality;
    if (airQuality == null) return const SizedBox.shrink();

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Air Quality: ${airQuality.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'AQI ${airQuality.aqi}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: airQuality.aqi / 5,
              minHeight: 8,
              color: _aqiColor(airQuality.aqi),
              backgroundColor: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _MetricPill(label: 'PM2.5', value: airQuality.pm25),
              _MetricPill(label: 'PM10', value: airQuality.pm10),
              _MetricPill(label: 'NO2', value: airQuality.no2),
              _MetricPill(label: 'O3', value: airQuality.o3),
            ],
          ),
        ],
      ),
    );
  }

  Color _aqiColor(int value) {
    switch (value) {
      case 1:
        return Colors.greenAccent;
      case 2:
        return Colors.lightGreenAccent;
      case 3:
        return Colors.amberAccent;
      case 4:
        return Colors.orangeAccent;
      default:
        return Colors.redAccent;
    }
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final double value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(1)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String message;

  const _InlineNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          height: index == 0 ? 260 : 120,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 54),
          const SizedBox(height: 16),
          const Text(
            'Weather unavailable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          const Icon(Icons.search, color: Colors.white, size: 50),
          const SizedBox(height: 16),
          const Text(
            'Search for a city',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the search bar or your current location to load live weather.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.my_location),
            label: const Text('Use location'),
          ),
        ],
      ),
    );
  }
}
