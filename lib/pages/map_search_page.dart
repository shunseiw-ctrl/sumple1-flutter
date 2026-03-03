import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/config/maps_config.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_spacing.dart';
import '../core/router/route_paths.dart';
import '../core/extensions/build_context_extensions.dart';
import '../core/services/analytics_service.dart';
import '../core/services/location_service.dart';
import '../core/utils/logger.dart';
import '../presentation/widgets/cached_image.dart';

class MapSearchPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialJobs;

  const MapSearchPage({super.key, this.initialJobs});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  Map<String, dynamic>? _selectedJob;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('map_search');
    _buildMarkers();
  }

  void _buildMarkers() {
    final jobs = widget.initialJobs ?? [];
    final markers = <Marker>{};

    for (final job in jobs) {
      final data = job['data'] as Map<String, dynamic>? ?? {};
      final docId = job['docId'] as String? ?? '';
      final lat = _parseDouble(data['latitude']);
      final lng = _parseDouble(data['longitude']);

      if (lat == null || lng == null) continue;

      markers.add(Marker(
        markerId: MarkerId(docId),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: data['title']?.toString() ?? '',
          snippet: data['location']?.toString() ?? '',
        ),
        onTap: () {
          setState(() {
            _selectedJob = {'data': data, 'docId': docId};
          });
        },
      ));
    }

    setState(() => _markers = markers);
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          MapsConfig.markerZoom,
        ),
      );
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      Logger.error('Failed to get current location', tag: 'MapSearchPage', error: e);
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final jobs = widget.initialJobs ?? [];
    final hasJobs = jobs.any((j) {
      final data = j['data'] as Map<String, dynamic>? ?? {};
      return _parseDouble(data['latitude']) != null && _parseDouble(data['longitude']) != null;
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.appColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.mapSearch_title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: !hasJobs
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: context.appColors.textHint),
                  const SizedBox(height: 16),
                  Text(context.l10n.mapSearch_noJobs, style: TextStyle(color: context.appColors.textSecondary)),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(MapsConfig.defaultLat, MapsConfig.defaultLng),
                    zoom: MapsConfig.defaultZoom,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController.complete(controller);
                  },
                  onTap: (_) {
                    setState(() => _selectedJob = null);
                  },
                ),

                // 現在地ボタン
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'map_location_btn',
                    backgroundColor: context.appColors.surface,
                    onPressed: _moveToCurrentLocation,
                    child: Icon(Icons.my_location, color: context.appColors.primary),
                  ),
                ),

                // 下部カード
                if (_selectedJob != null) _buildBottomCard(),
              ],
            ),
    );
  }

  Widget _buildBottomCard() {
    final data = _selectedJob!['data'] as Map<String, dynamic>;
    final docId = _selectedJob!['docId'] as String;
    final title = data['title']?.toString() ?? context.l10n.mapSearch_noTitle;
    final location = data['location']?.toString() ?? context.l10n.mapSearch_notSet;
    final price = data['price']?.toString() ?? '0';
    final imageUrl = data['imageUrl']?.toString();

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: AppCachedImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: 72,
                    height: 72,
                  ),
                ),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.appColors.primaryPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.construction, color: context.appColors.primary, size: 32),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: context.appColors.textHint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.mapSearch_pricePerDay(price),
                    style: AppTextStyles.salary.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                context.push(RoutePaths.jobDetailPath(docId), extra: data);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(context.l10n.mapSearch_details),
            ),
          ],
        ),
      ),
    );
  }
}
