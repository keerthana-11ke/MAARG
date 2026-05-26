import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident.dart';
import '../models/bystander_role.dart';
import '../models/hospital_log.dart';
import '../repositories/incident_repository.dart';
import 'auth_provider.dart';
import 'fcm_provider.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return MockIncidentRepository();
});

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

  IncidentState({
    this.activeIncident,
    this.isActivating = false,
    this.roles = const [],
    this.hospitalLogs = const [],
    this.reportedIncidents = const [],
    this.lastActiveIncidentId,
    this.debriefStep = 0,
    this.chosenFeelings = const [],
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
    );
  }
}

class IncidentNotifier extends Notifier<IncidentState> {
  StreamSubscription<Incident?>? _incidentSub;
  StreamSubscription<List<BystanderRole>>? _rolesSub;
  StreamSubscription<List<HospitalLog>>? _logsSub;

  @override
  IncidentState build() {
    ref.onDispose(() {
      _cancelSubscriptions();
    });
    return IncidentState();
  }

  IncidentRepository get _repository => ref.read(incidentRepositoryProvider);

  Future<void> triggerSOS(double latitude, double longitude) async {
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
      
      // 3. Set the active incident and start listening
      state = state.copyWith(
        activeIncident: () => incident,
        isActivating: false,
        lastActiveIncidentId: incident.id,
        reportedIncidents: list,
        debriefStep: 0,
        chosenFeelings: const [],
      );

      _startListening(incident.id);

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

  void _startListening(String incidentId) {
    _cancelSubscriptions();

    _incidentSub = _repository.listenToIncident(incidentId).listen((incident) {
      if (incident == null || incident.status == IncidentStatus.resolved) {
        // If incident got resolved from backend, transition to debrief
        resolveActiveIncident();
      } else {
        state = state.copyWith(activeIncident: () => incident);
      }
    });

    _rolesSub = _repository.listenToRoles(incidentId).listen((roles) {
      state = state.copyWith(roles: roles);
    });

    _logsSub = _repository.listenToHospitalLogs(incidentId).listen((logs) {
      // Sort logs by distance
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

  void clearAll() {
    _cancelSubscriptions();
    state = IncidentState(
      reportedIncidents: state.reportedIncidents,
    );
  }
}

final incidentStateProvider = NotifierProvider<IncidentNotifier, IncidentState>(IncidentNotifier.new);
