String getWeatherAnimation(String condition, String icon) {
  final isNight = icon.endsWith('n');

  if (isNight) {
    return 'assets/animations/night.json';
  }

  switch (condition.toLowerCase()) {
    case 'clear':
      return 'assets/animations/sunny.json';

    case 'clouds':
      return 'assets/animations/cloudy.json';

    case 'rain':
    case 'drizzle':
      return 'assets/animations/rain.json';

    case 'snow':
      return 'assets/animations/snow.json';

    case 'thunderstorm':
      return 'assets/animations/thunder.json';

    default:
      return 'assets/animations/broken.json';
  }
}

String getWeatherBackground(String condition, String icon) {
  final isNight = icon.endsWith('n');

  if (isNight) {
    return 'assets/backgrounds/Night.jpg';
  }

  switch (condition.toLowerCase()) {
    case 'clear':
      return 'assets/backgrounds/sunny.jpg';

    case 'clouds':
      return 'assets/backgrounds/clouds.jpg';

    case 'rain':
    case 'drizzle':
      return 'assets/backgrounds/rain.jpg';

    case 'snow':
      return 'assets/backgrounds/snow.jpg';

    case 'thunderstorm':
      return 'assets/backgrounds/thunderstorm.jpg';

    default:
      return 'assets/backgrounds/clouds.jpg';
  }
}