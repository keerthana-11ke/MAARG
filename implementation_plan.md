# MAARG (Emergency Response Assistant) Implementation Plan

MAARG is a Flutter-based emergency response assistant designed to help bystanders react quickly and effectively during medical emergencies. This document details the architectural choices, screen UI designs, Firebase schema, and the implementation steps.

## User Review Required

> [!IMPORTANT]
> **Firebase Project Provisioning:**
> Since Firebase CLI is not available in the current terminal environment, we will write complete, robust Firebase service integrations but structure them with an abstract repository pattern.
> - The app will automatically attempt Firebase initialization.
> - If Firebase configuration files are missing, or initialization fails, the app will transparently switch to **Mock Repositories** that emulate live database operations (using in-memory simulated states, real timer triggers, etc.).
> - This guarantees that the app builds and runs out-of-the-box on Windows/Desktop/Web/Emulators for review without needing immediate Firebase setup, while being production-ready for live deployment.

> [!NOTE]
> **Location Access:**
> To get real GPS coordinates, we will use the `geolocator` package. If permissions are denied, the app will gracefully fall back to default mockup coordinates (e.g., center of New Delhi) and show a warning badge, preventing crashes.

## Proposed System Architecture

We will implement a clean, layered architecture:
1. **Data Layer (`models/` & `repositories/`)**:
   - Data models for `Incident`, `BystanderRole`, `HospitalLog`.
   - Abstract interfaces: `AuthRepository`, `IncidentRepository`, `ServicesRepository`.
   - Implementations: `Firebase*` versions and `Mock*` versions.
2. **State Layer (`providers/`)**:
   - Riverpod state providers for managing active incident lifecycle, location updates, and authentication.
3. **Routing Layer (`router/`)**:
   - `GoRouter` configuration defining the routes for all 7 screens.
4. **Presentation Layer (`screens/` & `widgets/`)**:
   - Beautiful, Material 3 layouts using custom primary red (`#E53935`), charcoal/dark themes for visual contrast, and interactive animations.

---

## Proposed Changes

We will create a new Flutter project in the workspace root `c:\Users\Keerthana\MAARG` and structure it as follows:

### 1. Configuration & Dependencies
#### [NEW] [pubspec.yaml](file:///c:/Users/Keerthana/MAARG/pubspec.yaml)
Add packages:
- `flutter_riverpod` (State management)
- `go_router` (Routing)
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` (Firebase suite)
- `geolocator` (GPS coordinates)
- `url_launcher` (For direct phone calls to emergency services)
- `uuid` (For generating local IDs)

---

### 2. Data Models & Repositories
#### [NEW] [incident.dart](file:///c:/Users/Keerthana/MAARG/lib/models/incident.dart)
Incident model representing a created emergency:
- `id`, `latitude`, `longitude`, `createdAt`, `status` (active/resolved), `assignedRoles`

#### [NEW] [bystander_role.dart](file:///c:/Users/Keerthana/MAARG/lib/models/bystander_role.dart)
Bystander assignment model:
- `id`, `incidentId`, `roleType` (Call, Traffic, Assist), `status` (assigned, completed)

#### [NEW] [hospital_log.dart](file:///c:/Users/Keerthana/MAARG/lib/models/hospital_log.dart)
Log model tracking hospital notification:
- `id`, `name`, `distance`, `contactNumber`, `status` (notified, responding, arrived)

---

### 3. State Providers
#### [NEW] [auth_provider.dart](file:///c:/Users/Keerthana/MAARG/lib/providers/auth_provider.dart)
Handles anonymous Firebase Auth, falling back to mock sign-in if Firebase is unavailable.
#### [NEW] [location_provider.dart](file:///c:/Users/Keerthana/MAARG/lib/providers/location_provider.dart)
Tracks live GPS using `geolocator`.
#### [NEW] [incident_provider.dart](file:///c:/Users/Keerthana/MAARG/lib/providers/incident_provider.dart)
Coordinates active incident activation, bystander role selection, and post-incident debriefing flow.
#### [NEW] [services_provider.dart](file:///c:/Users/Keerthana/MAARG/lib/providers/services_provider.dart)
Stores lists of nearby hospitals, police stations, and fire engines, computing distances dynamically based on current GPS coordinates.

---

### 4. Router & Main Entry
#### [NEW] [app_router.dart](file:///c:/Users/Keerthana/MAARG/lib/router/app_router.dart)
Defines routes using `GoRouter`:
- `/` -> HomeScreen
- `/activation` -> ActivationScreen
- `/nearby-services` -> NearbyServicesScreen
- `/guidance` -> GuidanceScreen
- `/role-assignment` -> RoleAssignmentScreen
- `/good-samaritan` -> GoodSamaritanScreen
- `/debrief` -> DebriefScreen

#### [NEW] [main.dart](file:///c:/Users/Keerthana/MAARG/lib/main.dart)
Initializes app and widgets, sets up the Material 3 theme (Primary: `#E53935`), handles Riverpod `ProviderScope`.

---

### 5. Screen Layouts
#### [NEW] [home_screen.dart](file:///c:/Users/Keerthana/MAARG/lib/screens/home_screen.dart)
- Displays an emergency-themed interface with high contrast.
- Large, pulsating Red SOS Button (`#E53935`) that triggers the emergency sequence.
- Location Status Chip showing current GPS coordinates or "Acquiring..."
- Clean app branding (MAARG Logo & description).
- Access to "First Aid Guidance" and "Good Samaritan Law" reference cards.

#### [NEW] [activation_screen.dart](file:///c:/Users/Keerthana/MAARG/lib/screens/activation_screen.dart)
- Triggered by the SOS button.
- Displays a spinning indicator simulating dispatch & incident creation in Firestore.
- Shows live GPS coordinates.
- Provides a countdown / cancel option.
- Automatically transitions to the dashboard/role-assignment screen once activated.

#### [NEW] [nearby_services_screen.dart](file:///c:/Users/Keerthana/MAARG/lib/screens/nearby_services_screen.dart)
- Displays emergency service providers sorted by calculated distance.
- Each service shows a status (e.g., "Ready", "Dispatched") and a phone icon button that triggers a dialer launch.

#### [NEW] [guidance_screen.dart](file:///c:/Users/Keerthana/MAARG/lib/screens/guidance_screen.dart)
- Features step-by-step decision tree cards:
  - **Conscious Patient**: Check breathing, check bleeding, position comfortably.
  - **Unconscious Patient**: CPR guidelines, Recovery position.
  - **Unclear Status**: Check responsiveness instruction (Shake & Shout).
- Accordion component detailing critical **"What NOT to do"** list (e.g., don't crowd, don't move spinal injury patients, don't force liquids down unconscious throats).

#### [NEW] [role_assignment_screen.dart](file:///c:/Users/Keerthana/MAARG/lib/screens/role_assignment_screen.dart)
- bystander assignment board.
- 3 selectable roles:
  1. **Call Facilitator**: Stays on call with emergency services, updates coordinates.
  2. **Traffic Controller**: Clears path for the ambulance, directs traffic.
  3. **First Responder Assistant**: Helps with patient care / chest compressions.
- Visually shows role status and selection.

#### [NEW] [good_samaritan_screen.dart](file:///c:/Users/Keerthana/MAARG/lib/screens/good_samaritan_screen.dart)
- Informational screen detailing protection laws (e.g., Section 134A of the Motor Vehicles Act / Good Samaritan protection).
- Dismiss button returning to the previous screen.

#### [NEW] [debrief_screen.dart](file:///c:/Users/Keerthana/MAARG/lib/screens/debrief_screen.dart)
- 3-step emotional debrief:
  1. **Vent**: Checkboxes or feelings selection (anxious, overwhelmed, relieved).
  2. **Acknowledge**: Gratitude and validation note for acting as a savior.
  3. **Deep Breath**: Visual pulsing breathing guide (inhale, hold, exhale).

---

## Verification Plan

### Automated Tests
- We will execute `flutter test` to ensure there are no syntax errors or breaking library conflicts.
- Build the web/windows client or run it via emulator to check compilation correctness.

### Manual Verification
- Launch the application and test the SOS trigger sequence.
- Verify GPS location simulation works correctly.
- Test role selection, navigation flow (moving back and forth between lists, guidance, and home).
- Confirm the accordion behaves correctly.
