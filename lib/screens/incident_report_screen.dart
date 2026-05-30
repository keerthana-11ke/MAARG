import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/incident_provider.dart';

class IncidentReportScreen extends ConsumerWidget {
  const IncidentReportScreen({super.key});

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
                  pw.Text('Location Details: Latitude: ${state.evidenceLatitude ?? "N/A"}, Longitude: ${state.evidenceLongitude ?? "N/A"}'),
                  pw.SizedBox(height: 8),
                  pw.Text('Family Notified: ${state.familyNotified ? "Yes (${state.familyMemberName ?? ''})" : "No"}'),
                  pw.SizedBox(height: 8),
                  pw.Text('Volunteer Welfare Status: ${state.debriefFeeling == 'okay' ? "😊 Okay" : (state.debriefFeeling == 'shaken' ? "😟 A bit shaken" : (state.debriefFeeling == 'support' ? "🆘 Needs support" : "Pending feedback"))}'),
                  pw.SizedBox(height: 24),

                  pw.Text('ACTIONS TAKEN / ROLES CLAIMED', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Bullet(text: 'Activated Emergency Response SOS.'),
                  pw.Bullet(text: 'Monitored Golden Hour target window.'),
                  if (state.familyNotified)
                    pw.Bullet(text: 'Notified family member: ${state.familyMemberName}.'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const darkBg = Color(0xFF0A0A0A);
    const primaryRed = Color(0xFFE53935);
    final state = ref.watch(incidentStateProvider);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Incident Report',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                          Text(
                            state.evidenceIncidentId ?? 'MAARG-2026-CHN-0000',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: primaryRed,
                              letterSpacing: 1.5,
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
                      _buildInfoRow('GPS Coordinates', '${state.evidenceLatitude?.toStringAsFixed(4) ?? "N/A"}, ${state.evidenceLongitude?.toStringAsFixed(4) ?? "N/A"}'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Family Notified', state.familyNotified ? 'Yes (${state.familyMemberName})' : 'No'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Volunteer Welfare Status', state.debriefFeeling == 'okay' ? "😊 Okay" : (state.debriefFeeling == 'shaken' ? "😟 A bit shaken" : (state.debriefFeeling == 'support' ? "🆘 Needs support" : "Pending feedback"))),
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
                        _buildActionBullet('Dispatched safe status link to family'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Disclaimer
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
                          'For official use, contact authorities. Legal protections apply under Good Samaritan Guidelines.',
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
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text(
                      'DOWNLOAD AS PDF',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Home Button
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
                      'BACK TO HOME',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
}
