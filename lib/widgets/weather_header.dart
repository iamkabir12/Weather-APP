import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeatherHeader extends StatelessWidget {
  final String city;
  final String date;
  final String temp;
  final String description;
  final Widget animation;

  const WeatherHeader({
    super.key,
    required this.city,
    required this.date,
    required this.temp,
    required this.description,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          city,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          date,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: animation,
        ),
        Text(
          temp,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          description,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}