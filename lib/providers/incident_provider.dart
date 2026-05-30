import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident.dart';
import '../models/bystander_role.dart';
import '../models/hospital_log.dart';
import '../repositories/incident_repository.dart';
import '../repositories/services_repository.dart';
import 'auth_provider.dart';
import 'fcm_provider.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return MockIncidentRepository();
});

class Volunteer {
  final String name;
  final double distance;
  final String role; // 'First Aid', 'Traffic', 'Caller'
  final String status; // 'Responding', 'Accepted'
  final String eta; // '2 mins', '4 mins', '6 mins'

  Volunteer({
    required this.name,
    required this.distance,
    required this.role,
    required this.status,
    required this.eta,
  });

  Volunteer copyWith({
    String? name,
    double? distance,
    String? role,
    String? status,
    String? eta,
  }) {
    return Volunteer(
      name: name ?? this.name,
      distance: distance ?? this.distance,
      role: role ?? this.role,
      status: status ?? this.status,
      eta: eta ?? this.eta,
    );
  }
}

class IncidentState {
  final Incident? activeIncident;
  final bool isActivating;
  final List<BystanderRole> roles;
  final List<HospitalLog> hospitalLogs;
  final List<Incident> reportedIncidents;
  
  // Debrief flow state
  final String? lastActiveIncidentId;
  final int debriefStep; // 0: Vent, 1: Acknowledge, 2: Breathe
  final List<String> chosenFeelings;
  final String? debriefFeeling;

  // New Evidence & Calm Mode details
  final String? evidenceIncidentId;
  final DateTime? evidenceTimestamp;
  final double? evidenceLatitude;
  final double? evidenceLongitude;
  final String? evidencePhotoPath;
  final String? evidenceChosenRole;
  
  final String? familyMemberName;
  final bool familyNotified;

  final List<Volunteer> volunteers;
  final String? volunteerNotification;

  // New victim-specific / bystander flow fields
  final String? evidenceAreaName;
  final String? victimName;
  final String? victimBloodGroup;
  final String? victimMedical;
  final String? victimEmergencyContactPhone;
  final bool isVictimFlow;
  final bool noQrAvailable;
  final String? nearestHospitalName;
  final String? nearestHospitalDistance;

  // New volunteer banner states
  final String? activeBannerVolunteer;
  final bool showPermanentVolunteerCount;

  IncidentState({
    this.activeIncident,
    this.isActivating = false,
    this.roles = const [],
    this.hospitalLogs = const [],
    this.reportedIncidents = const [],
    this.lastActiveIncidentId,
    this.debriefStep = 0,
    this.chosenFeelings = const [],
    this.debriefFeeling,
    this.evidenceIncidentId,
    this.evidenceTimestamp,
    this.evidenceLatitude,
    this.evidenceLongitude,
    this.evidencePhotoPath,
    this.evidenceChosenRole,
    this.familyMemberName,
    this.familyNotified = false,
    this.volunteers = const [],
    this.volunteerNotification,
    this.evidenceAreaName,
    this.victimName,
    this.victimBloodGroup,
    this.victimMedical,
    this.victimEmergencyContactPhone,
    this.isVictimFlow = false,
    this.noQrAvailable = false,
    this.nearestHospitalName,
    this.nearestHospitalDistance,
    this.activeBannerVolunteer,
    this.showPermanentVolunteerCount = false,
  });

  IncidentState copyWith({
    Incident? Function()? activeIncident,
    bool? isActivating,
    List<BystanderRole>? roles,
    List<HospitalLog>? hospitalLogs,
    List<Incident>? reportedIncidents,
    String? lastActiveIncidentId,
    int? debriefStep,
    List<String>? chosenFeelings,
    String? debriefFeeling,
    String? evidenceIncidentId,
    DateTime? evidenceTimestamp,
    double? evidenceLatitude,
    double? evidenceLongitude,
    String? evidencePhotoPath,
    String? evidenceChosenRole,
    String? familyMemberName,
    bool? familyNotified,
    List<Volunteer>? volunteers,
    String? volunteerNotification,
    String? evidenceAreaName,
    String? victimName,
    String? victimBloodGroup,
    String? victimMedical,
    String? victimEmergencyContactPhone,
    bool? isVictimFlow,
    bool? noQrAvailable,
    String? nearestHospitalName,
    String? nearestHospitalDistance,
    String? activeBannerVolunteer,
    bool? showPermanentVolunteerCount,
  }) {
    return IncidentState(
      activeIncident: activeIncident != null ? activeIncident() : this.activeIncident,
      isActivating: isActivating ?? this.isActivating,
      roles: roles ?? this.roles,
      hospitalLogs: hospitalLogs ?? this.hospitalLogs,
      reportedIncidents: reportedIncidents ?? this.reportedIncidents,
      lastActiveIncidentId: lastActiveIncidentId ?? this.lastActiveIncidentId,
      debriefStep: debriefStep ?? this.debriefStep,
      chosenFeelings: chosenFeelings ?? this.chosenFeelings,
      debriefFeeling: debriefFeeling ?? this.debriefFeeling,
      evidenceIncidentId: evidenceIncidentId ?? this.evidenceIncidentId,
      evidenceTimestamp: evidenceTimestamp ?? this.evidenceTimestamp,
      evidenceLatitude: evidenceLatitude ?? this.evidenceLatitude,
      evidenceLongitude: evidenceLongitude ?? this.evidenceLongitude,
      evidencePhotoPath: evidencePhotoPath ?? this.evidencePhotoPath,
      evidenceChosenRole: evidenceChosenRole ?? this.evidenceChosenRole,
      familyMemberName: familyMemberName ?? this.familyMemberName,
      familyNotified: familyNotified ?? this.familyNotified,
      volunteers: volunteers ?? this.volunteers,
      volunteerNotification: volunteerNotification ?? this.volunteerNotification,
      evidenceAreaName: evidenceAreaName ?? this.evidenceAreaName,
      victimName: victimName ?? this.victimName,
      victimBloodGroup: victimBloodGroup ?? this.victimBloodGroup,
      victimMedical: victimMedical ?? this.victimMedical,
      victimEmergencyContactPhone: victimEmergencyContactPhone ?? this.victimEmergencyContactPhone,
      isVictimFlow: isVictimFlow ?? this.isVictimFlow,
      noQrAvailable: noQrAvailable ?? this.noQrAvailable,
      nearestHospitalName: nearestHospitalName ?? this.nearestHospitalName,
      nearestHospitalDistance: nearestHospitalDistance ?? this.nearestHospitalDistance,
      activeBannerVolunteer: activeBannerVolunteer ?? this.activeBannerVolunteer,
      showPermanentVolunteerCount: showPermanentVolunteerCount ?? this.showPermanentVolunteerCount,
    );
  }
}

class IncidentNotifier extends Notifier<IncidentState> {
  StreamSubscription<Incident?>? _incidentSub;
  StreamSubscription<List<BystanderRole>>? _rolesSub;
  StreamSubscription<List<HospitalLog>>? _logsSub;
  final List<Timer> _activeTimers = [];

  void _cancelTimers() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  @override
  IncidentState build() {
    ref.onDispose(() {
      _cancelSubscriptions();
      _cancelTimers();
    });
    return IncidentState();
  }

  IncidentRepository get _repository => ref.read(incidentRepositoryProvider);

  Future<void> triggerSOS({
    required double latitude,
    required double longitude,
    required String incidentId,
    String? photoPath,
    String? familyMemberName,
    bool familyNotified = false,
    String? victimName,
    String? victimBloodGroup,
    String? victimMedical,
    String? victimEmergencyContactPhone,
    bool isVictimFlow = false,
    bool noQrAvailable = false,
    String? areaName,
  }) async {
    state = state.copyWith(isActivating: true);

    try {
      // 1. Sign in anonymously if not already signed in
      final authRepo = ref.read(authRepositoryProvider);
      if (authRepo.currentUserId == null) {
        await authRepo.signInAnonymously();
      }

      // 2. Create the incident
      final incident = await _repository.createIncident(latitude, longitude);
      final list = List<Incident>.from(state.reportedIncidents)..add(incident);
      
      // Calculate nearest hospital details
      String nearestHospital = "Apollo Hospital";
      String nearestHospitalDist = "2 min (1.2 km)";
      try {
        final services = await StaticServicesRepository().getNearbyServices(latitude, longitude);
        final hospitals = services.where((s) => s.type == ServiceType.hospital).toList();
        if (hospitals.isNotEmpty) {
          final firstHosp = hospitals.first;
          nearestHospital = firstHosp.name;
          double distanceInKm = firstHosp.calculatedDistance!;
          int etaMinutes = (distanceInKm / 40 * 60).round();
          nearestHospitalDist = "${etaMinutes} min (${distanceInKm.toStringAsFixed(1)} km)";
        }
      } catch (_) {}

      // 3. Set the active incident and start listening
      state = state.copyWith(
        activeIncident: () => incident,
        isActivating: false,
        lastActiveIncidentId: incident.id,
        reportedIncidents: list,
        debriefStep: 0,
        chosenFeelings: const [],
        evidenceIncidentId: incidentId,
        evidenceTimestamp: DateTime.now(),
        evidenceLatitude: latitude,
        evidenceLongitude: longitude,
        evidencePhotoPath: photoPath,
        familyMemberName: familyMemberName,
        familyNotified: familyNotified,
        volunteers: const [],
        volunteerNotification: null,
        evidenceAreaName: areaName ?? "OMR Sholinganallur, Chennai",
        victimName: victimName,
        victimBloodGroup: victimBloodGroup,
        victimMedical: victimMedical,
        victimEmergencyContactPhone: victimEmergencyContactPhone,
        isVictimFlow: isVictimFlow,
        noQrAvailable: noQrAvailable,
        nearestHospitalName: nearestHospital,
        nearestHospitalDistance: nearestHospitalDist,
      );

      _startListening(incident.id);
      _startVolunteerSimulation();

      // 4. Silently trigger local bystander notification simulation
      try {
        ref.read(fcmProvider.notifier).simulateBystanderRelayAfterDelay(incident.id);
      } catch (fcmError) {
        print('Bystander simulation warning: $fcmError');
      }
    } catch (e) {
      state = state.copyWith(isActivating: false);
      print('SOS Activation failed: $e');
    }
  }

  void _startVolunteerSimulation() {
    _cancelTimers();

    // Ravi: show at 3s
    _activeTimers.add(Timer(const Duration(seconds: 3), () {
      final volunteers = [
        Volunteer(name: 'Ravi', distance: 0.3, role: 'First Aid', status: 'Responding', eta: '2 mins'),
      ];
      state = state.copyWith(
        volunteers: volunteers,
        activeBannerVolunteer: 'Ravi',
      );
    }));

    // Ravi: hide at 7s
    _activeTimers.add(Timer(const Duration(seconds: 7), () {
      if (state.activeBannerVolunteer == 'Ravi') {
        state = state.copyWith(activeBannerVolunteer: null);
      }
    }));

    // Priya: show at 10s (3s gap after Ravi hides at 7s)
    _activeTimers.add(Timer(const Duration(seconds: 10), () {
      final volunteers = [
        Volunteer(name: 'Ravi', distance: 0.3, role: 'First Aid', status: 'Responding', eta: '2 mins'),
        Volunteer(name: 'Priya', distance: 0.8, role: 'Caller', status: 'Accepted', eta: '4 mins'),
      ];
      state = state.copyWith(
        volunteers: volunteers,
        activeBannerVolunteer: 'Priya',
      );
    }));

    // Priya: hide at 14s
    _activeTimers.add(Timer(const Duration(seconds: 14), () {
      if (state.activeBannerVolunteer == 'Priya') {
        state = state.copyWith(activeBannerVolunteer: null);
      }
    }));

    // Karthik: show at 17s (3s gap after Priya hides at 14s)
    _activeTimers.add(Timer(const Duration(seconds: 17), () {
      final volunteers = [
        Volunteer(name: 'Ravi', distance: 0.3, role: 'First Aid', status: 'Responding', eta: '2 mins'),
        Volunteer(name: 'Priya', distance: 0.8, role: 'Caller', status: 'Accepted', eta: '4 mins'),
        Volunteer(name: 'Karthik', distance: 1.2, role: 'Traffic Control', status: 'Responding', eta: '6 mins'),
      ];
      state = state.copyWith(
        volunteers: volunteers,
        activeBannerVolunteer: 'Karthik',
      );
    }));

    // Karthik: hide at 21s, and show permanent banner
    _activeTimers.add(Timer(const Duration(seconds: 21), () {
      if (state.activeBannerVolunteer == 'Karthik') {
        state = state.copyWith(activeBannerVolunteer: null);
      }
      state = state.copyWith(showPermanentVolunteerCount: true);
    }));
  }

  void dismissActiveBanner() {
    state = state.copyWith(activeBannerVolunteer: null);
  }

  void dismissVolunteerNotification() {
    state = state.copyWith(volunteerNotification: null);
  }

  void notifyFamily(String name) {
    state = state.copyWith(
      familyMemberName: name,
      familyNotified: true,
    );
  }

  void _startListening(String incidentId) {
    _cancelSubscriptions();

    _incidentSub = _repository.listenToIncident(incidentId).listen((incident) {
      if (incident == null || incident.status == IncidentStatus.resolved) {
        resolveActiveIncident();
      } else {
        state = state.copyWith(activeIncident: () => incident);
      }
    });

    _rolesSub = _repository.listenToRoles(incidentId).listen((roles) {
      state = state.copyWith(roles: roles);
    });

    _logsSub = _repository.listenToHospitalLogs(incidentId).listen((logs) {
      logs.sort((a, b) => a.distance.compareTo(b.distance));
      state = state.copyWith(hospitalLogs: logs);
    });
  }

  void _cancelSubscriptions() {
    _incidentSub?.cancel();
    _rolesSub?.cancel();
    _logsSub?.cancel();
  }

  Future<void> claimRole(String roleId) async {
    final incident = state.activeIncident;
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (incident != null && userId != null) {
      await _repository.claimRole(incident.id, roleId, userId);
    }
  }

  Future<void> releaseRole(String roleId) async {
    final incident = state.activeIncident;
    if (incident != null) {
      await _repository.releaseRole(incident.id, roleId);
    }
  }

  Future<void> completeRole(String roleId) async {
    final incident = state.activeIncident;
    if (incident != null) {
      await _repository.completeRole(incident.id, roleId);
    }
  }

  Future<void> resolveActiveIncident() async {
    final incident = state.activeIncident;
    if (incident != null) {
      _cancelSubscriptions();
      _cancelTimers();
      await _repository.resolveIncident(incident.id);
      state = state.copyWith(
        activeIncident: () => null,
        roles: const [],
        hospitalLogs: const [],
      );
    }
  }

  // Debrief methods
  void selectDebriefFeeling(String feeling) {
    final feelings = List<String>.from(state.chosenFeelings);
    if (feelings.contains(feeling)) {
      feelings.remove(feeling);
    } else {
      feelings.add(feeling);
    }
    state = state.copyWith(chosenFeelings: feelings);
  }

  void nextDebriefStep() {
    if (state.debriefStep < 2) {
      state = state.copyWith(debriefStep: state.debriefStep + 1);
    }
  }

  void previousDebriefStep() {
    if (state.debriefStep > 0) {
      state = state.copyWith(debriefStep: state.debriefStep - 1);
    }
  }

  void resetDebrief() {
    state = state.copyWith(
      debriefStep: 0,
      chosenFeelings: const [],
    );
  }

  void setDebriefFeeling(String feeling) {
    state = state.copyWith(debriefFeeling: feeling);
  }

  void setChosenRole(String role) {
    state = state.copyWith(evidenceChosenRole: role);
  }

  void setEvidencePhotoPath(String? path) {
    state = state.copyWith(evidencePhotoPath: path);
  }

  void clearAll() {
    _cancelSubscriptions();
    _cancelTimers();
    state = IncidentState(
      reportedIncidents: state.reportedIncidents,
    );
  }
}

final incidentStateProvider = NotifierProvider<IncidentNotifier, IncidentState>(IncidentNotifier.new);
