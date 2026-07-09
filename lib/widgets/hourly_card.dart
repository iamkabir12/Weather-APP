import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/hourly_model.dart';

class HourlyCard extends StatelessWidget {
  final HourlyModel hourly;

  const HourlyCard({
    super.key,
    required this.hourly,
  });

  IconData _getIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;

      case 'clouds':
        return Icons.cloud;

      case 'rain':
      case 'drizzle':
        return Icons.grain;

      case 'snow':
        return Icons.ac_unit;

      case 'thunderstorm':
        return Icons.flash_on;

      default:
        return Icons.cloud;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('ha').format(hourly.time),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          Icon(
            _getIcon(hourly.condition),
            color: Colors.white,
            size: 32,
          ),

          Text(
            "${hourly.temperature.round()}°",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}