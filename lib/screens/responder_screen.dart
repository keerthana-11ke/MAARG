import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/tts_provider.dart';
import '../providers/incident_provider.dart';
import '../models/bystander_role.dart';

class ResponderScreen extends ConsumerStatefulWidget {
  final String incidentId;

  const ResponderScreen({required this.incidentId, super.key});

  @override
  ConsumerState<ResponderScreen> createState() => _ResponderScreenState();
}

class _ResponderScreenState extends ConsumerState<ResponderScreen> {
  double _incidentLat = 13.0827; // Default Chennai coordinates fallback
  double _incidentLng = 80.2707;
  bool _isLoadingIncident = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIncidentCoordinates();
  }

  Future<void> _loadIncidentCoordinates() async {
    try {
      final active = ref.read(incidentStateProvider).activeIncident;
      if (active != null && active.id == widget.incidentId) {
        setState(() {
          _incidentLat = active.latitude;
          _incidentLng = active.longitude;
          _isLoadingIncident = false;
        });
        return;
      }
      final reported = ref.read(incidentStateProvider).reportedIncidents;
      final matched = reported.firstWhere((inc) => inc.id == widget.incidentId);
      setState(() {
        _incidentLat = matched.latitude;
        _incidentLng = matched.longitude;
        _isLoadingIncident = false;
      });
    } catch (e) {
      // Offline/Mock fallback
      debugPrint('Failed to load incident coordinates, using default fallback: $e');
      setState(() {
        _isLoadingIncident = false;
      });
    }
  }

  Future<void> _handleClaimRole(String roleId, BystanderRoleType roleType) async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      String? userId = authRepo.currentUserId;
      if (userId == null) {
        await authRepo.signInAnonymously();
        userId = authRepo.currentUserId;
      }

      if (userId != null) {
        await ref.read(incidentRepositoryProvider).claimRole(widget.incidentId, roleId, userId);
        ref.read(ttsProvider).speak("Thank you. You have claimed this role.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role claimed successfully! Proceed to coordinates.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to claim role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE53935);
    final repo = ref.watch(incidentRepositoryProvider);
    final authRepo = ref.watch(authRepositoryProvider);
    final userId = authRepo.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'RESPONDER DASHBOARD',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _isLoadingIncident
              ? const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Map showing accident location
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(_incidentLat, _incidentLng),
                              initialZoom: 15.5,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                                userAgentPackageName: 'com.keerthana.maarg',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_incidentLat, _incidentLng),
                                    width: 60,
                                    height: 60,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.location_on_rounded,
                                          color: primaryColor,
                                          size: 36,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            '📍 Location Match: Chennai Hotspot Active Zone',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'NEIGHBORHOOD COORDINATION BOARD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Live Stream of Bystander Roles
                        Expanded(
                          child: StreamBuilder<List<BystanderRole>>(
                            stream: repo.listenToRoles(widget.incidentId),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error loading roles: ${snapshot.error}', style: const TextStyle(color: Colors.grey)),
                                );
                              }
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(color: primaryColor),
                                );
                              }

                              final roles = snapshot.data!;
                              return ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: roles.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final role = roles[index];
                                  return _buildRoleRow(role, userId);
                                },
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => context.go('/'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.08),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'BACK TO HOME',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildRoleRow(BystanderRole role, String? userId) {
    IconData icon;
    Color color;
    String title;
    String description;

    switch (role.roleType) {
      case BystanderRoleType.call:
        icon = Icons.phone_in_talk_rounded;
        color = const Color(0xFFE53935);
        title = '🔴 CALL FACILITATOR';
        description = 'Call 108 ambulance. Stay on the line. Give them exact coordinates.';
        break;
      case BystanderRoleType.traffic:
        icon = Icons.traffic_rounded;
        color = Colors.amber;
        title = '🟡 TRAFFIC CONTROLLER';
        description = 'Stop vehicles. Create a clear path. Wave down approaching cars.';
        break;
      case BystanderRoleType.assist:
        icon = Icons.healing_rounded;
        color = Colors.green;
        title = '🟢 VICTIM ASSISTANT';
        description = 'Stay with the victim. Provide comfort and reassurance.';
        break;
    }

    final isOccupied = role.status == RoleStatus.occupied;
    final isMe = isOccupied && role.userId == userId;
    final displayColor = isMe ? Colors.green.shade800.withOpacity(0.3) : Colors.white.withOpacity(0.02);
    final borderColor = isMe ? Colors.green : Colors.white10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: displayColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isOccupied ? Colors.grey : color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isMe)
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
              else if (isOccupied)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CLAIMED',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _handleClaimRole(role.id, role.roleType),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.15),
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: color.withOpacity(0.5)),
                    ),
                  ),
                  child: const Text(
                    'CLAIM',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: isOccupied ? Colors.grey : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
