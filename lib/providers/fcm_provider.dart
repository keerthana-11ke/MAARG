import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FcmState {
  final String? token;
  final String? lastMessageTitle;
  final String? lastMessageBody;
  final String? lastMessageIncidentId;
  final bool hasNotification;

  FcmState({
    this.token,
    this.lastMessageTitle,
    this.lastMessageBody,
    this.lastMessageIncidentId,
    this.hasNotification = false,
  });

  FcmState copyWith({
    String? token,
    String? lastMessageTitle,
    String? lastMessageBody,
    String? lastMessageIncidentId,
    bool? hasNotification,
  }) {
    return FcmState(
      token: token ?? this.token,
      lastMessageTitle: lastMessageTitle ?? this.lastMessageTitle,
      lastMessageBody: lastMessageBody ?? this.lastMessageBody,
      lastMessageIncidentId: lastMessageIncidentId ?? this.lastMessageIncidentId,
      hasNotification: hasNotification ?? this.hasNotification,
    );
  }
}

class FcmNotifier extends Notifier<FcmState> {
  @override
  FcmState build() {
    return FcmState(token: 'mock_offline_token');
  }

  void simulateBystanderRelayAfterDelay(String incidentId) {
    Future.delayed(const Duration(seconds: 3), () {
      state = FcmState(
        token: 'mock_offline_token',
        lastMessageTitle: '⚠️ Bystanders responding',
        lastMessageBody: '2 bystanders responding nearby',
        lastMessageIncidentId: incidentId,
        hasNotification: true,
      );
    });
  }

  void dismissNotification() {
    state = state.copyWith(hasNotification: false);
  }
}

final fcmProvider = NotifierProvider<FcmNotifier, FcmState>(FcmNotifier.new);
