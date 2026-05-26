import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../providers/incident_provider.dart';

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  // Hardcoded real Chennai accident hotspots (10 hotspots)
  final List<LatLng> _hotspots = [
    const LatLng(13.0104, 80.2016), // Kathipara Junction
    const LatLng(13.0732, 80.2098), // Koyambedu Roundtana
    const LatLng(13.0094, 80.2131), // Guindy Flyover
    const LatLng(13.0063, 80.2502), // Madhya Kailash Junction
    const LatLng(12.9012, 80.2269), // Sholinganallur Junction (OMR)
    const LatLng(12.9830, 80.2594), // Thiruvanmiyur ECR Junction
    const LatLng(12.9516, 80.1411), // Chromepet GST Road
    const LatLng(12.9229, 80.1217), // Tambaram Junction
    const LatLng(13.0824, 80.2750), // Chennai Central Junction
    const LatLng(13.0494, 80.2111), // Vadapalani Junction
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () {
            ref.read(incidentStateProvider.notifier).clearAll();
            context.go('/');
          },
        ),
        title: const Text(
          'COMMUNITY IMPACT HEATMAP',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header stats banner
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'YOU HELPED MAKE CHENNAI SAFER',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shield_rounded, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '847 incidents reported. 23 lives potentially saved.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Map container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Builder(
                  builder: (context) {
                    final reportedIncidents = ref.watch(incidentStateProvider).reportedIncidents;
                    final List<LatLng> reportedCoordinates = [];
                    for (final inc in reportedIncidents) {
                      reportedCoordinates.add(LatLng(inc.latitude, inc.longitude));
                    }

                    // Build circle markers combining hardcoded hotspots & live incidents
                    final List<CircleMarker> circles = [];
                    for (var spot in _hotspots) {
                      circles.add(
                        CircleMarker(
                          point: spot,
                          color: Colors.orange.withOpacity(0.25),
                          borderColor: Colors.orange.withOpacity(0.6),
                          borderStrokeWidth: 1.5,
                          useRadiusInMeter: true,
                          radius: 500, // 500m radius
                        ),
                      );
                    }

                    for (var rSpot in reportedCoordinates) {
                      circles.add(
                        CircleMarker(
                          point: rSpot,
                          color: primaryColor.withOpacity(0.3),
                          borderColor: primaryColor,
                          borderStrokeWidth: 2,
                          useRadiusInMeter: true,
                          radius: 350,
                        ),
                      );
                    }

                    return FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(13.0827, 80.2707), // Center Chennai
                        initialZoom: 11.8,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                          userAgentPackageName: 'com.keerthana.maarg',
                        ),
                        CircleLayer(circles: circles),
                        MarkerLayer(
                          markers: reportedCoordinates.map<Marker>((LatLng pt) {
                            return Marker(
                              point: pt,
                              width: 50,
                              height: 50,
                              child: const PulsingMarker(),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ),

            // Bottom CTA to return to dashboard
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(incidentStateProvider.notifier).clearAll();
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom pulsing widget for real-time reported incident markers
class PulsingMarker extends StatefulWidget {
  const PulsingMarker({super.key});

  @override
  State<PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outward pulse
            Container(
              width: 40 * _scaleAnimation.value,
              height: 40 * _scaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE53935).withOpacity(_opacityAnimation.value),
              ),
            ),
            // Solid center core
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE53935),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 4,
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
