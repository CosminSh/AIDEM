import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/gps_service.dart';
import 'tactical_container.dart';

class LocationCard extends StatelessWidget {
  final GpsCoordinates coords;

  const LocationCard({super.key, required this.coords});

  @override
  Widget build(BuildContext context) {
    return TacticalContainer(
      padding: const EdgeInsets.all(20.0),
      showGlow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.success, size: 20),
              SizedBox(width: 8),
              Text(
                "Current Location (Offline)",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCoordRow(
            "Decimal",
            "${coords.latitude.toStringAsFixed(6)}, ${coords.longitude.toStringAsFixed(6)}",
          ),
          const Divider(color: AppColors.border, height: 24),
          _buildCoordRow("DMS", coords.toDms()),
          const Divider(color: AppColors.border, height: 24),
          _buildCoordRow(
            "Altitude",
            "${coords.altitude?.toStringAsFixed(1) ?? '---'} m",
          ),
        ],
      ),
    );
  }

  Widget _buildCoordRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            letterSpacing: 0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontFamily: 'Monospace', // Ensure coordinates are easy to read
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
