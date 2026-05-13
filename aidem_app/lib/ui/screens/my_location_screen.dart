import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/gps_service.dart';
import '../widgets/location_card.dart';
import '../widgets/tactical_container.dart';

class MyLocationScreen extends StatelessWidget {
  final GpsCoordinates currentCoords;
  final List<GpsCoordinates> history;

  const MyLocationScreen({
    super.key,
    required this.currentCoords,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: "Copy coordinates",
            onPressed: () {
              // Copy current coords to clipboard
            },
          ),
        ],
      ),
      body: AidemBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: LocationCard(coords: currentCoords),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: SectionLabel(label: "Position Log"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final fix = history[index];
                  return _buildLogItem(fix);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(GpsCoordinates fix) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            "${fix.timestamp.hour}:${fix.timestamp.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(
              color: AppColors.accentBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "${fix.latitude.toStringAsFixed(5)}, ${fix.longitude.toStringAsFixed(5)}",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Monospace',
                fontSize: 13,
              ),
            ),
          ),
          Text(
            "${fix.altitude?.toInt() ?? 0}m",
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
