import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/activation_screen.dart';
import '../screens/nearby_services_screen.dart';
import '../screens/guidance_screen.dart';
import '../screens/role_assignment_screen.dart';
import '../screens/good_samaritan_screen.dart';
import '../screens/debrief_screen.dart';
import '../screens/responder_screen.dart';
import '../screens/heatmap_screen.dart';
import '../screens/family_status_screen.dart';
import '../screens/emergency_guide_screen.dart';
import '../screens/incident_report_screen.dart';
import '../screens/emergency_profile_screen.dart';
import '../screens/qr_scan_screen.dart';
import '../screens/onboarding_screen.dart';

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) {
        final name = state.uri.queryParameters['name'];
        final contact = state.uri.queryParameters['contact'];
        final blood = state.uri.queryParameters['blood'];
        final conditions = state.uri.queryParameters['conditions'];
        final allergies = state.uri.queryParameters['allergies'];
        return HomeScreen(
          scannedName: name,
          scannedContact: contact,
          scannedBlood: blood,
          scannedConditions: conditions,
          scannedAllergies: allergies,
        );
      },
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) {
        final name = state.uri.queryParameters['name'];
        final contact = state.uri.queryParameters['contact'];
        final blood = state.uri.queryParameters['blood'];
        final conditions = state.uri.queryParameters['conditions'];
        final allergies = state.uri.queryParameters['allergies'];
        return HomeScreen(
          scannedName: name,
          scannedContact: contact,
          scannedBlood: blood,
          scannedConditions: conditions,
          scannedAllergies: allergies,
        );
      },
    ),
    GoRoute(
      path: '/emergency-profile',
      builder: (context, state) => const EmergencyProfileScreen(),
    ),
    GoRoute(
      path: '/activation',
      builder: (context, state) => const ActivationScreen(),
    ),
    GoRoute(
      path: '/nearby-services',
      builder: (context, state) => const NearbyServicesScreen(),
    ),
    GoRoute(
      path: '/guidance',
      builder: (context, state) => const GuidanceScreen(),
    ),
    GoRoute(
      path: '/role-assignment',
      builder: (context, state) => const RoleAssignmentScreen(),
    ),
    GoRoute(
      path: '/good-samaritan',
      builder: (context, state) => const GoodSamaritanScreen(),
    ),
    GoRoute(
      path: '/debrief',
      builder: (context, state) => const DebriefScreen(),
    ),
    GoRoute(
      path: '/responder/:incidentId',
      builder: (context, state) {
        final incidentId = state.pathParameters['incidentId'] ?? '';
        return ResponderScreen(incidentId: incidentId);
      },
    ),
    GoRoute(
      path: '/heatmap',
      builder: (context, state) => const HeatmapScreen(),
    ),
    GoRoute(
      path: '/family-status',
      builder: (context, state) {
        final name = state.uri.queryParameters['name'] ?? 'Family Member';
        final hospital = state.uri.queryParameters['hospital'] ?? 'Nearest Hospital';
        return FamilyStatusScreen(name: name, hospital: hospital);
      },
    ),
    GoRoute(
      path: '/emergency-guide',
      builder: (context, state) => const EmergencyGuideScreen(),
    ),
    GoRoute(
      path: '/incident-report',
      builder: (context, state) => const IncidentReportScreen(),
    ),
    GoRoute(
      path: '/qr-scan',
      builder: (context, state) => const QrScanScreen(),
    ),
  ],
);

