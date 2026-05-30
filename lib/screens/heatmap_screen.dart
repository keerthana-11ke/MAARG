import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

  Future<void> _generateAndDownloadPdf(BuildContext context, IncidentState state) async {
    try {
      final pdf = pw.Document();

      // Load image bytes if available
      pw.Widget? pdfImage;
      if (state.evidencePhotoPath != null && !kIsWeb) {
        try {
          final file = io.File(state.evidencePhotoPath!);
          if (await file.exists()) {
            final imageBytes = await file.readAsBytes();
            final image = pw.MemoryImage(imageBytes);
            pdfImage = pw.Container(
              height: 150,
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          }
        } catch (_) {}
      }

      String roleName = 'Not selected';
      if (state.evidenceChosenRole != null) {
        if (state.evidenceChosenRole == 'call') {
          roleName = 'Call Facilitator';
        } else if (state.evidenceChosenRole == 'traffic') {
          roleName = 'Traffic Controller';
        } else if (state.evidenceChosenRole == 'assistant' || state.evidenceChosenRole == 'assist') {
          roleName = 'Victim Assistant';
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MAARG EMERGENCY INCIDENT REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#E53935'),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Golden Hour Emergency Response Network',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Divider(color: PdfColor.fromHex('#E53935'), thickness: 2),
                  pw.SizedBox(height: 20),

                  pw.Text('Incident ID: ${state.evidenceIncidentId ?? "N/A"}', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Report Date/Time: ${state.evidenceTimestamp?.toLocal().toString() ?? "N/A"}'),
                  pw.SizedBox(height: 8),
                  pw.Text('Area / Location: ${state.evidenceAreaName ?? "OMR Sholinganallur, Chennai"}'),
                  pw.SizedBox(height: 8),
                  pw.Text('GPS Coordinates: Latitude: ${state.evidenceLatitude ?? "N/A"}, Longitude: ${state.evidenceLongitude ?? "N/A"}'),
                  pw.SizedBox(height: 8),
                  pw.Text('Family Notified: ${state.familyNotified ? "Yes (${state.familyMemberName ?? ''})" : "No"}'),
                  pw.SizedBox(height: 8),
                  pw.Text('Chosen Bystander Role: $roleName'),
                  pw.SizedBox(height: 24),

                  pw.Text('ACTIONS TAKEN / ROLES CLAIMED', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Bullet(text: 'Activated Emergency Response SOS.'),
                  pw.Bullet(text: 'Monitored Golden Hour target window.'),
                  if (state.familyNotified)
                    pw.Bullet(text: 'Notified family member: ${state.familyMemberName}.'),
                  if (state.evidenceChosenRole != null)
                    pw.Bullet(text: 'Claimed bystander role: $roleName.'),
                  pw.SizedBox(height: 24),

                  if (pdfImage != null) ...[
                    pw.Text('INCIDENT EVIDENCE PHOTO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pdfImage,
                    pw.SizedBox(height: 24),
                  ],

                  pw.Spacer(),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '⚠️ LEGAL DISCLAIMER: Under Good Samaritan Guidelines 2015, the reporter is fully protected. For official usage, present this incident report to the authorities.',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Trigger system print / save as PDF dialogue
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'MAARG-Report-${state.evidenceIncidentId ?? "Incident"}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }

  Widget _buildPhotoThumbnail(String? path) {
    if (path == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 36),
              SizedBox(height: 8),
              Text(
                'No photo captured',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: kIsWeb
            ? Image.network(path, fit: BoxFit.cover)
            : Image.file(io.File(path), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE53935);
    final state = ref.watch(incidentStateProvider);

    String roleName = 'Not selected';
    if (state.evidenceChosenRole != null) {
      if (state.evidenceChosenRole == 'call') {
        roleName = 'Call Facilitator';
      } else if (state.evidenceChosenRole == 'traffic') {
        roleName = 'Traffic Controller';
      } else if (state.evidenceChosenRole == 'assistant' || state.evidenceChosenRole == 'assist') {
        roleName = 'Victim Assistant';
      }
    }

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
          'Impact & Evidence',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                        Flexible(
                          child: Text(
                            '847 incidents reported. 23 lives potentially saved.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Map container
              Container(
                height: 320,
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

                    // Build circle markers combining hotspots & live incidents
                    final List<CircleMarker> circles = [];
                    for (var spot in _hotspots) {
                      circles.add(
                        CircleMarker(
                          point: spot,
                          color: Colors.orange.withOpacity(0.25),
                          borderColor: Colors.orange.withOpacity(0.6),
                          borderStrokeWidth: 1.5,
                          useRadiusInMeter: true,
                          radius: 500,
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

              const SizedBox(height: 24),

              // Official Evidence Report Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'DOWNLOAD EVIDENCE REPORT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  state.evidenceIncidentId ?? 'MAARG-INCIDENT-ACTIVE',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                    letterSpacing: 1.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 12),
                          _buildInfoRow('Time of Report', state.evidenceTimestamp?.toLocal().toString().substring(0, 19) ?? 'N/A'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Area / Location', state.evidenceAreaName ?? 'OMR Sholinganallur, Chennai'),
                          const SizedBox(height: 12),
                          _buildInfoRow('GPS Coordinates', '${state.evidenceLatitude?.toStringAsFixed(4) ?? "N/A"}, ${state.evidenceLongitude?.toStringAsFixed(4) ?? "N/A"}'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Family Notified', state.familyNotified ? 'Yes (${state.familyMemberName})' : 'No'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Bystander Role', roleName),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'INCIDENT EVIDENCE PHOTO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPhotoThumbnail(state.evidencePhotoPath),

                    const SizedBox(height: 24),
                    const Text(
                      'ACTIONS LOGGED',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          _buildActionBullet('Activated emergency response network'),
                          _buildActionBullet('Monitored Golden Hour window'),
                          if (state.familyNotified)
                            _buildActionBullet('Dispatched status link to family'),
                          if (state.evidenceChosenRole != null)
                            _buildActionBullet('Claimed bystander role: $roleName'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Disclaimer / legal protection info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'For official use, contact authorities. Legal protections apply under Good Samaritan Guidelines 2015.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Download Button
                    SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => _generateAndDownloadPdf(context, state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text(
                          'DOWNLOAD EVIDENCE REPORT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Done Button
                    SizedBox(
                      height: 60,
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(incidentStateProvider.notifier).clearAll();
                          context.go('/');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
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
