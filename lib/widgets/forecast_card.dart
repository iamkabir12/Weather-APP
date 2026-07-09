import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../models/forecast_model.dart';
import '../utils/weather_animation.dart';

class ForecastCard extends StatelessWidget {
  final ForecastModel forecast;

  const ForecastCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 18,
),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            DateFormat('EEE').format(forecast.date),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(
            height: 70,
            child: Lottie.asset(
              getWeatherAnimation(
                forecast.condition,
                forecast.icon,
              ),
            ),
          ),

          Text(
            "${forecast.temperature.round()}°",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            forecast.condition,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}