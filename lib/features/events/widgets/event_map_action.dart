// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event_model.dart';
import '../services/location_service.dart';

/// Reusable UI action component for Event Details screen.
///
/// Behavior:
/// - If the event has valid GPS coordinates, renders an "Open in Maps" action.
/// - If the event lacks coordinates, renders nothing ([SizedBox.shrink]).
/// - Generates the external map URL using [LocationService.getMapsUrl].
/// - Attempts direct external application launch via [url_launcher].
/// - If launching fails or throws, gracefully executes clipboard fallback.
/// - Prevents duplicate rapid taps while launch is in progress.
class EventMapAction extends StatefulWidget {
  final EventModel event;
  final LocationService locationService;
  final Future<bool> Function(String url)? urlLauncher;
  final void Function(String url)? onOpenMaps;

  EventMapAction({
    super.key,
    required this.event,
    LocationService? locationService,
    this.urlLauncher,
    this.onOpenMaps,
  }) : locationService = locationService ?? LocationService();

  @override
  State<EventMapAction> createState() => _EventMapActionState();
}

class _EventMapActionState extends State<EventMapAction> {
  bool _isLaunching = false;

  /// Default production launcher using url_launcher with external application mode.
  static Future<bool> _defaultUrlLauncher(String url) async {
    final uri = Uri.parse(url);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleFallback(String mapsUrl) async {
    try {
      await Clipboard.setData(ClipboardData(text: mapsUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open map app directly. Link copied to clipboard: $mapsUrl',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open map application or copy link.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleOpenMaps(String mapsUrl) async {
    if (_isLaunching) return; // Prevent repeated rapid taps

    setState(() {
      _isLaunching = true;
    });

    bool success = false;
    try {
      if (widget.onOpenMaps != null) {
        widget.onOpenMaps!(mapsUrl);
        return;
      }

      final launcher = widget.urlLauncher ?? _defaultUrlLauncher;
      try {
        success = await launcher(mapsUrl);
      } catch (_) {
        success = false;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }

    if (!success && mounted) {
      _handleFallback(mapsUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Strictly do not display map actions for events without coordinates
    if (!widget.event.hasCoordinates) {
      return const SizedBox.shrink();
    }

    final mapsUrl = widget.locationService.getMapsUrl(
      widget.event.latitude!,
      widget.event.longitude!,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.map_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.locationName.isNotEmpty
                        ? widget.event.locationName
                        : 'Event Location',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'GPS: ${widget.event.coordinatesDisplay}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              key: const Key('open_in_maps_button'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              icon: _isLaunching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.open_in_new, size: 16),
              label: Text(_isLaunching ? 'Opening...' : 'Open in Maps'),
              onPressed: _isLaunching ? null : () => _handleOpenMaps(mapsUrl),
            ),
          ],
        ),
      ),
    );
  }
}
