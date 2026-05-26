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

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
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
  ],
);
