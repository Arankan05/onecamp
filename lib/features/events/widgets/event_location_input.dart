// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../controllers/event_controller.dart';

/// Reusable UI component for entering event location details.
///
/// Features:
/// - Manual text input for human-readable venue/location name.
/// - "Use Current Location" action triggering device GPS retrieval.
/// - Visual progress indicator during asynchronous coordinate fetching.
/// - Coordinate confirmation badge with action to explicitly clear coordinates.
/// - Human-friendly error banner with direct link to system settings if permanently denied.
class EventLocationInput extends StatelessWidget {
  final EventController controller;
  final TextEditingController? locationTextController;

  const EventLocationInput({
    super.key,
    required this.controller,
    this.locationTextController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Manual Venue Name Input
        TextFormField(
          controller: locationTextController,
          initialValue: locationTextController == null
              ? controller.locationName
              : null,
          decoration: const InputDecoration(
            labelText: 'Venue / Location Name *',
            hintText: 'e.g., Main Auditorium, Lecture Hall 3, Sports Complex',
            prefixIcon: Icon(Icons.place_outlined),
            helperText: 'Manually specify the venue or building name',
          ),
          onChanged: (val) => controller.setLocationName(val),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter a venue or location name';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        // 2. Action: Use Current Location / Progress State
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('use_current_location_button'),
                icon: controller.isLoadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  controller.isLoadingLocation
                      ? 'Acquiring GPS...'
                      : (controller.hasCoordinates
                            ? 'Update Current GPS'
                            : 'Use Current Location'),
                ),
                onPressed: controller.isLoadingLocation
                    ? null
                    : () async {
                        await controller.useCurrentLocation();
                      },
              ),
            ),
          ],
        ),

        // 3. Error Banner (if retrieval failed)
        if (controller.locationErrorMessage != null) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('location_error_banner'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.error),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.locationErrorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => controller.clearLocationError(),
                      tooltip: 'Dismiss',
                    ),
                  ],
                ),
                if (controller.locationErrorMessage!.contains('Settings') ||
                    controller.locationErrorMessage!.contains('settings')) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text(
                      'Open App Settings',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => controller.openAppSettings(),
                  ),
                ],
              ],
            ),
          ),
        ],

        // 4. Coordinates Confirmation Badge
        if (controller.hasCoordinates) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('coordinates_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade600),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Coordinates: ${controller.coordinatesDisplay}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        'Coordinates will be saved with this event.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('clear_coordinates_button'),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear Coordinates',
                  onPressed: () => controller.clearCoordinates(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
