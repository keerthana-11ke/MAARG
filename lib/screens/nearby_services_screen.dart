import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/services_provider.dart';
import '../providers/incident_provider.dart';
import '../models/hospital_log.dart';
import '../repositories/services_repository.dart';

class NearbyServicesScreen extends ConsumerWidget {
  const NearbyServicesScreen({super.key});

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('Could not launch phone call for $phoneNumber');
    }
  }

  Color _getStatusColor(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.idle:
        return Colors.grey;
      case DispatchStatus.notified:
        return Colors.orange;
      case DispatchStatus.responding:
        return Colors.blue;
      case DispatchStatus.arrived:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.idle:
        return Icons.hourglass_empty;
      case DispatchStatus.notified:
        return Icons.notifications_active;
      case DispatchStatus.responding:
        return Icons.local_shipping;
      case DispatchStatus.arrived:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentState = ref.watch(incidentStateProvider);
    final servicesAsync = ref.watch(nearbyServicesProvider);
    final primaryRed = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Services'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(nearbyServicesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Live Ambulance Tracker (if active incident exists)
                  if (incidentState.activeIncident != null &&
                      incidentState.hospitalLogs.isNotEmpty) ...[
                    const Text(
                      'LIVE DISPATCH TRACKER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...incidentState.hospitalLogs.map((log) {
                      final statusColor = _getStatusColor(log.status);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor.withOpacity(0.15),
                            ),
                            child: Icon(
                              _getStatusIcon(log.status),
                              color: statusColor,
                            ),
                          ),
                          title: Text(
                            log.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${log.distance.toStringAsFixed(1)} km away • ${log.contactNumber}'),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  log.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.call, color: primaryRed),
                            onPressed: () => _makeCall(log.contactNumber),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                  ],

                  // Section 2: General Emergency Services List
                  const Text(
                    'NEARBY EMERGENCY DEPOTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  servicesAsync.when(
                    data: (services) {
                      if (services.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('No services found in range.'),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final service = services[index];
                          IconData serviceIcon;
                          Color iconColor;

                          switch (service.type) {
                            case ServiceType.hospital:
                              serviceIcon = Icons.local_hospital_rounded;
                              iconColor = primaryRed;
                              break;
                            case ServiceType.police:
                              serviceIcon = Icons.local_police_rounded;
                              iconColor = Colors.blue;
                              break;
                            case ServiceType.fire:
                              serviceIcon = Icons.local_fire_department_rounded;
                              iconColor = Colors.orange;
                              break;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: iconColor.withOpacity(0.1),
                                child: Icon(serviceIcon, color: iconColor),
                              ),
                              title: Text(
                                service.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                '${service.calculatedDistance?.toStringAsFixed(2) ?? 'N/A'} km away • ${service.phone}',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                              ),
                              trailing: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _makeCall(service.phone),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: primaryRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.call, color: primaryRed, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'CALL',
                                          style: TextStyle(
                                            color: primaryRed,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('Error loading services: $err'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
