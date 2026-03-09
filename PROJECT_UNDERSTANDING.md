# ElderL — Complete Project Understanding

> **Last updated:** 2026-03-09
> **Purpose:** Single reference document covering the entire project. Read this before making any changes.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [Architecture](#3-architecture)
4. [File Structure](#4-file-structure)
5. [Data Models & Entities](#5-data-models--entities)
6. [Core Services](#6-core-services)
7. [Feature Modules](#7-feature-modules)
8. [State Management (Riverpod)](#8-state-management-riverpod)
9. [Routing & Navigation](#9-routing--navigation)
10. [Firebase Schema](#10-firebase-schema)
11. [Security Rules](#11-security-rules)
12. [Key Data Flows](#12-key-data-flows)
13. [Common Widgets](#13-common-widgets)
14. [Testing Architecture](#14-testing-architecture)
15. [Critical Implementation Patterns](#15-critical-implementation-patterns)
16. [Known Issues & Gotchas](#16-known-issues--gotchas)

---

## 1. Project Overview

**ElderL** is a Flutter mobile app for coordinating elder care across four user roles:

| Role | Primary Purpose |
|------|----------------|
| **Senior** | Elderly person — checks in daily, triggers emergencies, creates help requests |
| **Caregiver** | Professional — accepts requests, monitors seniors, responds to emergencies |
| **Family** | Relative — links to a senior to monitor their check-ins and activity |
| **Admin** | System admin — approves users, manages all relationships, views analytics |

**Firebase Project:** `elder-care-995b8`
**Realtime Database URL:** `https://elder-care-995b8-default-rtdb.firebaseio.com`
**Platform targets:** Android (primary), iOS, Web
**Version:** 1.0.0

---

## 2. Tech Stack & Dependencies

### Flutter / Dart
- Flutter SDK, Dart language

### Firebase Services Used
| Service | Purpose |
|---------|---------|
| Firebase Auth | User authentication |
| Cloud Firestore | Primary database (users, requests, checkins, messages) |
| Realtime Database | Emergency alerts (low-latency critical) |
| Firebase Messaging | Push notifications (FCM token stored per user) |
| Firebase Storage | Profile images (configured, partially implemented) |
| Firebase Analytics | Basic usage tracking |

### Key Packages (`pubspec.yaml`)
| Package | Purpose |
|---------|---------|
| `flutter_riverpod` / `riverpod_annotation` | State management |
| `firebase_core`, `firebase_auth` | Firebase core + auth |
| `cloud_firestore` | Firestore database |
| `firebase_database` | Realtime Database |
| `firebase_messaging` | Push notifications |
| `firebase_storage` | File storage |
| `go_router` | Declarative routing |
| `geolocator` | GPS location |
| `connectivity_plus` | Network status monitoring |
| `mocktail` | Unit test mocking |

---

## 3. Architecture

### Layered Clean Architecture

```
Presentation Layer
├── Screens (ConsumerWidget / StatefulWidget)
├── Controllers (StateNotifier via Riverpod)
└── Common Widgets (SeniorButton, SeniorTextField, SyncIndicator)

Domain Layer
├── Entities (AppUser, HelpRequest, EmergencyAlert, CheckIn, Message, Conversation)
├── Error Classes (Failure hierarchy)
└── Constants (AppConstants — roles, statuses, collection names)

Data Layer
├── Repositories (per-feature business logic + Firebase operations)
└── Core Services (FirestoreService, RealtimeDbService, LocationService, SyncService)

External Services
├── Firebase (Auth, Firestore, RTDB, Messaging, Storage)
└── Geolocator
```

### Feature-Based Organization

Each feature under `lib/features/{name}/` follows:
```
{feature}/
├── domain/entities/        # Data models
├── data/                   # Repository + data logic
└── presentation/
    ├── controllers/        # Riverpod StateNotifier providers
    └── screens/            # UI widgets
```

---

## 4. File Structure

```
lib/
├── main.dart                          # App entry — Firebase init, persistence config
├── firebase_options.dart              # Firebase project config (all platforms)
├── common_widgets/
│   ├── common_widgets.dart            # Barrel export
│   ├── senior_button.dart             # Large accessible button
│   ├── senior_text_field.dart         # Large accessible input
│   └── sync_indicator.dart            # Cloud sync status widget
├── core/
│   ├── routing/app_router.dart        # GoRouter — auth guards + role routing
│   ├── theme/app_theme.dart           # Senior-friendly Material 3 theme
│   ├── utils/constants.dart           # AppConstants (roles, statuses, collections)
│   ├── errors/failures.dart           # Failure class hierarchy
│   └── services/
│       ├── firestore_service.dart     # Firestore wrapper (add/get/update/delete/stream)
│       ├── realtime_db_service.dart   # RTDB wrapper (multiPathUpdate for emergencies)
│       ├── location_service.dart      # GPS location + permissions
│       └── sync_service.dart          # SyncState machine — connectivity + pending writes
└── features/
    ├── auth/
    │   ├── domain/entities/app_user.dart              # Core user model
    │   ├── data/repositories/auth_repository.dart    # Firebase Auth operations
    │   ├── data/user_repository.dart                  # Firestore user CRUD
    │   └── presentation/
    │       ├── controllers/auth_controller.dart       # AuthState StateNotifier
    │       └── screens/ (login, signup, forgot_password, pending_approval)
    ├── admin/
    │   ├── data/admin_repository.dart
    │   └── presentation/
    │       ├── controllers/admin_controller.dart
    │       └── screens/ (home, user_approval, user_detail, analytics,
    │                      caregivers, seniors, requests, emergencies,
    │                      settings, link_management)
    ├── senior/
    │   └── presentation/screens/senior_home_screen.dart
    ├── caregiver/
    │   ├── data/caregiver_repository.dart
    │   └── presentation/
    │       ├── controllers/caregiver_controller.dart
    │       └── screens/ (home, requests, seniors, history)
    ├── family/
    │   ├── data/family_repository.dart
    │   └── presentation/
    │       ├── controllers/family_controller.dart
    │       └── screens/ (home, checkins, activity)
    ├── checkin/
    │   ├── data/checkin_repository.dart
    │   └── presentation/screens/daily_checkin_screen.dart
    ├── emergency/
    │   ├── data/emergency_repository.dart
    │   └── presentation/screens/emergency_screen.dart
    ├── messaging/
    │   ├── data/messaging_repository.dart
    │   └── presentation/
    │       ├── controllers/messaging_controller.dart
    │       └── screens/ (conversations, chat)
    ├── requests/
    │   ├── data/request_repository.dart
    │   └── presentation/screens/create_request_screen.dart
    ├── profile/
    │   └── presentation/screens/ (profile, edit_profile)
    └── dev/
        └── presentation/screens/create_test_users_screen.dart

test/
├── widget_test.dart
├── core/
│   ├── errors/failures_test.dart
│   └── services/ (sync_state_test, location_data_test, constants_test)
└── features/
    ├── auth/auth_test.dart
    ├── requests/request_test.dart
    ├── emergency/emergency_test.dart
    ├── checkin/checkin_test.dart
    ├── messaging/messaging_test.dart
    └── dataflow/data_pipeline_test.dart
```

---

## 5. Data Models & Entities

### 5.1 AppUser (`lib/features/auth/domain/entities/app_user.dart`)

```dart
class AppUser {
  // Identity
  String uid, email, name, role;
  String? phone, address, avatarUrl, fcmToken;

  // Timestamps
  DateTime? createdAt, lastActiveAt, lastLogin;

  // Approval workflow
  String approvalStatus;        // pending | approved | rejected
  String? approvedBy, approvedAt, rejectionReason;

  // Relationships
  String? linkedSeniorId;              // family → senior
  List<String> linkedFamily;           // senior ← family members
  List<String> assignedSeniors;        // caregiver → seniors
  List<String> assignedCaregivers;     // senior ← caregivers

  // Health/Medical
  DateTime? dateOfBirth;
  String? emergencyContact, emergencyPhone;
  List<String> medicalConditions, allergies;
  String? bloodType, notes;
}
```

**Role helpers:** `isSenior`, `isCaregiver`, `isFamily`, `isAdmin`
**Approval helpers:** `isPending`, `isApproved`, `isRejected`
**Relationship helpers:** `hasLinkedFamily`, `hasAssignedCaregivers`, `isLinkedToSenior`, `hasAssignedSeniors`
**Serialization:** `toMap()`/`fromMap()` for Firestore · `toJson()`/`fromJson()` for REST

> **IMPORTANT:** Always use `toMap()` when writing to Firestore. `toJson()` is for REST/cache only.

### 5.2 HelpRequest (`lib/features/requests/data/request_repository.dart`)

```dart
class HelpRequest {
  String id, seniorId, seniorName, type, description;
  String status;         // pending | accepted | in_progress | completed | cancelled
  String? assignedTo, assignedToName;
  double? latitude, longitude;
  String? address;
  bool isUrgent;
  DateTime? createdAt, updatedAt, completedAt;
}
```

**Status flow:** `pending → accepted → in_progress → completed` (or `cancelled`)

### 5.3 EmergencyAlert (`lib/features/emergency/data/emergency_repository.dart`)

```dart
class EmergencyAlert {
  String id, seniorId, seniorName, status;  // active | responded | resolved | cancelled
  String? seniorPhone, familyContactName, familyContactPhone;
  double? latitude, longitude;
  String? address;
  String? respondedBy, respondedByName;
  int? createdAt, respondedAt, resolvedAt;   // EPOCH MILLISECONDS (RTDB)
}
```

> **IMPORTANT:** Timestamps stored as **epoch milliseconds** in RTDB, not Firestore Timestamps.
> Use `DateTime.fromMillisecondsSinceEpoch(createdAt!)` for conversion.

**Status flow:** `active → responded → resolved` (or `cancelled`)

### 5.4 CheckIn (`lib/features/checkin/data/checkin_repository.dart`)

```dart
class CheckIn {
  String id, seniorId, status;    // ok | missed | pending
  String? message;
  DateTime? checkinTime, createdAt;
}
```

### 5.5 Message & Conversation (`lib/features/messaging/data/messaging_repository.dart`)

```dart
class Message {
  String id, conversationId, senderId, senderName, content;
  String type;         // text | image | location
  DateTime? createdAt;
  bool isRead;
}

class Conversation {
  String id;
  List<String> participantIds;
  Map<String, String> participantNames;
  String? lastMessage, lastSenderId;
  DateTime? lastMessageAt;
  int unreadCount;
  String? relatedRequestId;
}
```

**Helper methods:** `getOtherParticipantName(myId)`, `getOtherParticipantId(myId)`

### 5.6 LocationData (`lib/core/services/location_service.dart`)

```dart
class LocationData {
  double latitude, longitude, accuracy;
  DateTime timestamp;
  String? address;
}
```

---

## 6. Core Services

### 6.1 FirestoreService (`lib/core/services/firestore_service.dart`)

High-level Firestore wrapper:
- `add(collection, data)` — Add document with auto-ID
- `set(collection, id, data)` — Set/overwrite document
- `update(collection, id, data)` — Partial update
- `delete(collection, id)` — Delete document
- `get(collection, id)` — Fetch single document
- `getAll(collection, [filters])` — Fetch collection with optional QueryFilters
- `query(collection, filters, [orderBy, limit])` — Filtered query
- `stream(collection, id)` — Real-time document stream
- `batch()` — Return WriteBatch for atomic multi-doc operations
- `transaction(fn)` — Run Firestore transaction

**QueryFilter helper:**
```dart
QueryFilter(field, operator, value)
// Operators: ==, !=, <, <=, >, >=, array-contains, in, array-contains-any
```

### 6.2 RealtimeDbService (`lib/core/services/realtime_db_service.dart`)

For low-latency emergency operations:
- `push(path, data)` — Append with auto-ID
- `set(path, data)` — Set at path
- `update(path, data)` — Partial update
- `remove(path)` — Delete
- **`multiPathUpdate(updates)`** — Atomic update to multiple paths (critical for emergencies)
- `query(path, [orderBy, limit])` — Fetch with filter
- `stream(path)` — Real-time stream
- `generateKey(path)` — Pre-generate a push ID

### 6.3 LocationService (`lib/core/services/location_service.dart`)

Singleton GPS management:
- `getCurrentLocation()` — Get position (or last known)
- `startLocationUpdates(callback)` — Continuous stream
- `calculateDistance(lat1, lon1, lat2, lon2)` — Haversine distance
- `isWithinRadius(center, point, radiusMeters)` — Geofence check
- Handles permission requests and service enable prompts

### 6.4 SyncService (`lib/core/services/sync_service.dart`)

**SyncState machine:**
```
synced ↔ syncing ↔ pendingSync
         ↕
      offline ↔ error
```

**SyncState fields:**
```dart
SyncStatus status;       // synced | syncing | pendingSync | offline | error
DateTime? lastSyncTime;
String? errorMessage;
int pendingWrites;
bool get isOnline => status != SyncStatus.offline;
bool get hasPendingWrites => pendingWrites > 0;
```

**Behavior:**
- Monitors ConnectivityPlus for network changes
- Reads Firestore document metadata for `hasPendingWrites`
- Periodic sync check every **30 seconds** when online
- Auth-aware: Only activates Firestore listeners when user is authenticated
- Uses `_sync_check` Firestore collection as lightweight probe document

**Actions:**
- `forceSync()` — Manually trigger sync
- `clearCacheAndResync()` — Wipe local cache
- `goOffline()` / `goOnline()` — For testing

---

## 7. Feature Modules

### 7.1 Auth Feature

**AuthRepository** (`lib/features/auth/data/repositories/auth_repository.dart`):
- `signIn(email, password)` — Firebase Auth + fetch Firestore user doc
- `signUp(email, password, AppUser)` — Create Auth account + Firestore user doc
- `signOut()` — Clear auth state
- `getCurrentUser()` — Restore session from Firebase Auth currentUser
- `sendPasswordResetEmail(email)`
- `getUserStream(uid)` — Real-time user doc stream
- `authStateChanges` — Stream<User?> for external sign-outs

**UserRepository** (`lib/features/auth/data/user_repository.dart`):
- `createUser(AppUser)`, `getUser(uid)`, `updateUser(uid, Map)`, `deleteUser(uid)`
- `streamUser(uid)` — Real-time user document
- `getUsersByRole(role)`, `getCaregiversForSenior(seniorId)`, `getFamilyForSenior(seniorId)`
- `updateFcmToken(uid, token)`, `updateLastActive(uid)`

**AuthController** — `StateNotifier<AuthState>`:
```dart
class AuthState {
  bool isLoading;
  bool isAuthenticated;
  AppUser? user;
  String? errorMessage;
}
```
- `_init()` on creation: restores session, listens for external auth changes
- `signIn()`, `signUp()`, `signOut()`
- `refreshUser()` — Re-fetch from Firestore
- `clearError()`

**Approval Workflow:**
- All new users default to `approvalStatus: 'pending'`
- Router redirects pending users to `/pending-approval` screen
- Admin must approve before user can access their role dashboard

### 7.2 Senior Feature

**Screens:** `senior_home_screen.dart`

**Capabilities:**
- View daily check-in status
- Record daily check-in
- Trigger emergency alert
- Create help request
- View assigned caregivers
- View linked family members

### 7.3 Caregiver Feature

**CaregiverRepository** (`lib/features/caregiver/data/caregiver_repository.dart`):
- `assignToSenior(caregiverId, seniorId)` — WriteBatch bidirectional link
- `unassignFromSenior(caregiverId, seniorId)` — WriteBatch removal
- `acceptRequest(requestId, caregiverId, caregiverName)`:
  1. Transaction: verify request is still `pending`, update to `accepted`, set assignee
  2. After transaction: `assignToSenior()` WriteBatch
- `completeRequest(requestId)` — Set status + completedAt
- `getAssignedSeniors(caregiverId)` — Batch fetch (max 10 per whereIn)
- `streamAssignedSeniors(caregiverId)` — Real-time via asyncMap
- `getCompletedRequests(caregiverId)` — History (client-side filtered)
- `getSeniorsWithMissedCheckIn(caregiverId)` — Per-senior date-range query
- `getCaregivers(seniorId)` — All caregivers for a senior

**CaregiverController** — manages request workflow state

**Screens:** home, requests (pending), seniors (assigned), history

### 7.4 Family Feature

**FamilyRepository** (`lib/features/family/data/family_repository.dart`):
- `linkToSenior(familyUserId, seniorEmail)`:
  1. Query by normalized email
  2. Validate: exists + `role == 'senior'`
  3. WriteBatch: set `family.linkedSeniorId` + `arrayUnion` on `senior.linkedFamily`
- `unlinkFromSenior(familyUserId, seniorId)` — WriteBatch both sides
- `getLinkedSenior(seniorId)` — Fetch senior document
- `streamLinkedSenior(seniorId)` — Real-time via asyncMap
- `getSeniorCheckIns(seniorId, [limit=7])` — Last N check-ins
- `getSeniorRequests(seniorId)` — Active requests
- `getFamilyMembers(seniorId)` — All family linked to this senior

**FamilyController** — manages link/unlink state

**Screens:** home, checkins (senior's history), activity (senior's requests)

### 7.5 Admin Feature

**AdminRepository** (`lib/features/admin/data/admin_repository.dart`):

*Queries:*
- `getAllUsers()`, `getUsersByRole(role)`, `getUsersByApprovalStatus(status)`
- `getUsersByRoleAndStatus(role, status)`, `getApprovedUsersByRole(role)`
- `getUsersByIds(ids)` — Batch (pagination for `whereIn` max 10)
- `searchUsers(query)` — Client-side full-text search

*Actions:*
- `approveUser(uid, adminUid)` — Set `approved` + `approvedBy` + `approvedAt`
- `rejectUser(uid, reason)` — Set `rejected` + `rejectionReason`
- `resetToPending(uid)` — Clear approval fields
- `updateUser(uid, Map)`, `deleteUser(uid)`

*Relationships (all WriteBatch atomic):*
- `assignCaregiverToSenior(caregiverId, seniorId)`
- `unassignCaregiverFromSenior(caregiverId, seniorId)`
- `linkFamilyToSenior(familyUserId, seniorId)`
- `unlinkFamilyFromSenior(familyUserId, seniorId)`

*Analytics:*
- `getUserStatistics()` — Count by role + approval status
- `streamPendingUsers()` — Real-time approval queue
- `streamUsersByRole(role)` — Real-time role-based view

**AdminController** — user management actions

**Screens:** home (dashboard), user_approval, user_detail, analytics, caregivers, seniors, requests, emergencies, settings, link_management

### 7.6 Checkin Feature

**CheckInRepository** (`lib/features/checkin/data/checkin_repository.dart`):
- `createCheckIn(CheckIn)` — Record today's check-in
- `getTodayCheckIn(seniorId)` — Date-range query (start/end of day)
- `getCheckInHistory(seniorId, [limit=30])` — Recent history
- `streamTodayCheckIn(seniorId)` — Real-time today's status
- `getMissedCheckIns(seniorId)` — Seniors without check-in today

### 7.7 Emergency Feature

**EmergencyRepository** (`lib/features/emergency/data/emergency_repository.dart`):
- `createEmergency(EmergencyAlert)`:
  - Generates push ID from RTDB
  - Atomic `multiPathUpdate`: writes to both `emergencies/{id}` AND `active_emergencies/{id}`
- `respondToEmergency(id, responderId, responderName)`:
  - Atomic `multiPathUpdate`: updates status field in BOTH paths
- `updateEmergencyStatus(id, status)`:
  - If `resolved/cancelled`: removes from `active_emergencies`, keeps in `emergencies`
  - If other: updates both paths
- `getActiveEmergencies()`, `getEmergenciesForSenior(seniorId)`
- `streamActiveEmergencies()` — Real-time stream from `active_emergencies`
- `enableOfflineSupport()` — Keeps emergency data cached

**Dual-path pattern:**
```
emergencies/{id}         // Full history (read-only after archive)
active_emergencies/{id}  // Live alerts only (removed on resolve)
```

### 7.8 Messaging Feature

**MessagingRepository** (`lib/features/messaging/data/messaging_repository.dart`):
- `getOrCreateConversation(userId1, userId2)`:
  - Query: conversations where `participantIds` array-contains both
  - If exists: return existing ID
  - If not: create new Conversation doc
- `sendMessage(conversationId, Message)`:
  - **WriteBatch (atomic):**
    1. ADD message to `conversations/{id}/messages/{autoId}`
    2. UPDATE conversation: `lastMessage`, `lastSenderId`, `lastMessageAt`
- `markMessagesAsRead(conversationId, userId)`:
  - Query unread messages, filter client-side (senderId != userId), batch `isRead = true`
- `streamMessages(conversationId)` — Ordered by `createdAt` descending
- `streamConversations(userId)` — All conversations for user
- `deleteConversation(id)` — Cascade deletes messages subcollection
- `getUnreadCount(userId)` — Iterate conversations

**MessagingController** — sendMessage, startConversation

**Screens:** conversations (list), chat (messages in thread)

### 7.9 Requests Feature

**RequestRepository** (`lib/features/requests/data/request_repository.dart`):
- `createRequest(HelpRequest)` — Firestore add
- `updateRequestStatus(id, status)` — Single field update
- `assignRequest(id, caregiverId, caregiverName)` — Also triggers bidirectional senior linking
- `getRequestsForSenior(seniorId)`, `getPendingRequests()`
- `streamRequestsForSenior(seniorId)`, `streamPendingRequests()` — Real-time
- `cancelRequest(id)`, `completeRequest(id)`
- `streamAllRequests()` — Admin view

### 7.10 Profile Feature

**Screens:** profile (view), edit_profile (update fields + optional image)

---

## 8. State Management (Riverpod)

### Provider Categories

**Infrastructure Providers:**
```dart
firestoreProvider                  // FirebaseFirestore singleton
realtimeDbProvider                 // FirebaseDatabase singleton
firestoreServiceProvider           // FirestoreService wrapper
realtimeDbServiceProvider          // RealtimeDbService wrapper
locationServiceProvider            // LocationService singleton
syncServiceProvider                // StateNotifierProvider<SyncService, SyncState>
isSyncedProvider                   // derived bool
isOnlineProvider                   // derived bool
```

**Repository Providers:**
```dart
authRepositoryProvider
userRepositoryProvider
requestRepositoryProvider
emergencyRepositoryProvider
checkInRepositoryProvider
messagingRepositoryProvider
familyRepositoryProvider
caregiverRepositoryProvider
adminRepositoryProvider
```

**Controller Providers (StateNotifier):**
```dart
authControllerProvider             // StateNotifierProvider<AuthController, AuthState>
familyLinkControllerProvider
caregiverRequestControllerProvider
adminUserControllerProvider
messagingControllerProvider
```

**Data Providers (Async/Stream):**
```dart
linkedSeniorProvider               // FutureProvider
linkedSeniorStreamProvider         // StreamProvider
seniorCheckInsProvider             // FutureProvider.family<List<CheckIn>, String>
assignedSeniorsProvider            // FutureProvider
pendingRequestsProvider            // FutureProvider
activeEmergenciesStreamProvider    // StreamProvider
conversationsStreamProvider        // StreamProvider
messagesStreamProvider             // StreamProvider.family<List<Message>, String>
userStatisticsProvider             // FutureProvider
```

**UI State Providers:**
```dart
userFilterProvider                 // StateProvider<String> for admin search
```

### Patterns

**Auto-dispose (memory safety):**
```dart
FutureProvider.autoDispose<T>((ref) async { ... })
StreamProvider.autoDispose<T>((ref) { ... })
```

**Parameterized providers:**
```dart
FutureProvider.family<AppUser?, String>((ref, uid) async { ... })
StreamProvider.family<List<Message>, String>((ref, conversationId) { ... })
```

---

## 9. Routing & Navigation

**Router:** GoRouter (`lib/core/routing/app_router.dart`)

### Route Map

| Path | Screen | Access |
|------|--------|--------|
| `/login` | LoginScreen | Public |
| `/signup` | SignupScreen | Public |
| `/forgot-password` | ForgotPasswordScreen | Public |
| `/pending-approval` | PendingApprovalScreen | Pending users |
| `/senior/home` | SeniorHomeScreen | Senior + Admin |
| `/senior/checkin` | DailyCheckinScreen | Senior + Admin |
| `/senior/emergency` | EmergencyScreen | Senior + Admin |
| `/senior/create-request` | CreateRequestScreen | Senior + Admin |
| `/caregiver/home` | CaregiverHomeScreen | Caregiver + Admin |
| `/caregiver/requests` | CaregiverRequestsScreen | Caregiver + Admin |
| `/caregiver/seniors` | CaregiverSeniorsScreen | Caregiver + Admin |
| `/caregiver/history` | CaregiverHistoryScreen | Caregiver + Admin |
| `/family/home` | FamilyHomeScreen | Family + Admin |
| `/family/activity` | FamilyActivityScreen | Family + Admin |
| `/family/checkins` | FamilyCheckinsScreen | Family + Admin |
| `/admin/home` | AdminHomeScreen | Admin only |
| `/admin/users` | UserApprovalScreen | Admin only |
| `/admin/...` | Various admin screens | Admin only |
| `/profile` | ProfileScreen | All authenticated |
| `/edit-profile` | EditProfileScreen | All authenticated |
| `/messages` | ConversationsScreen | All authenticated |
| `/chat` | ChatScreen | All authenticated |
| `/dev/create-users` | CreateTestUsersScreen | Public (dev only) |

### Route Guards

1. **Unauthenticated** → redirect to `/login`
2. **Pending approval** → redirect to `/pending-approval`
3. **Wrong role for route** → redirect to role-appropriate home
4. **Admin** → can access all routes

---

## 10. Firebase Schema

### Firestore Collections

**`users/{uid}`**
```json
{
  "uid": "string",
  "email": "string",
  "name": "string",
  "role": "senior|caregiver|family|admin",
  "approvalStatus": "pending|approved|rejected",
  "approvedBy": "uid|null",
  "approvedAt": "Timestamp|null",
  "rejectionReason": "string|null",
  "phone": "string|null",
  "linkedSeniorId": "uid|null",
  "linkedFamily": ["uid", ...],
  "assignedSeniors": ["uid", ...],
  "assignedCaregivers": ["uid", ...],
  "createdAt": "Timestamp",
  "lastActiveAt": "Timestamp|null",
  "fcmToken": "string|null"
}
```

**`requests/{requestId}`**
```json
{
  "id": "string",
  "seniorId": "uid",
  "seniorName": "string",
  "type": "string",
  "description": "string",
  "status": "pending|accepted|in_progress|completed|cancelled",
  "assignedTo": "uid|null",
  "assignedToName": "string|null",
  "isUrgent": "bool",
  "latitude": "double|null",
  "longitude": "double|null",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp|null",
  "completedAt": "Timestamp|null"
}
```

**`checkins/{checkinId}`**
```json
{
  "id": "string",
  "seniorId": "uid",
  "status": "ok|missed|pending",
  "message": "string|null",
  "checkinTime": "Timestamp",
  "createdAt": "Timestamp"
}
```

**`conversations/{conversationId}`**
```json
{
  "participantIds": ["uid1", "uid2"],
  "participantNames": {"uid1": "Name1", "uid2": "Name2"},
  "lastMessage": "string|null",
  "lastSenderId": "uid|null",
  "lastMessageAt": "Timestamp|null",
  "unreadCount": "int",
  "relatedRequestId": "string|null"
}
```

**`conversations/{conversationId}/messages/{messageId}`**
```json
{
  "conversationId": "string",
  "senderId": "uid",
  "senderName": "string",
  "content": "string",
  "type": "text|image|location",
  "createdAt": "Timestamp",
  "isRead": "bool"
}
```

**`_sync_check/{docId}`** — Lightweight probe document for SyncService

### Realtime Database Paths

**`emergencies/{emergencyId}`** — Full emergency history
```json
{
  "id": "string",
  "seniorId": "uid",
  "seniorName": "string",
  "status": "active|responded|resolved|cancelled",
  "seniorPhone": "string|null",
  "familyContactName": "string|null",
  "familyContactPhone": "string|null",
  "latitude": "double|null",
  "longitude": "double|null",
  "address": "string|null",
  "respondedBy": "uid|null",
  "respondedByName": "string|null",
  "createdAt": 1709000000000,
  "respondedAt": null,
  "resolvedAt": null
}
```

> Note: All timestamps in RTDB are **epoch milliseconds** (int).

**`active_emergencies/{emergencyId}`** — Same structure, removed when resolved
**`presence/{userId}`** — User online presence
**`emergency_history/{userId}/{recordId}`** — Per-user history

---

## 11. Security Rules

### Firestore Rules (`firestore.rules`)

**Helper functions:**
```javascript
isAuthenticated() → request.auth != null
isAdmin() → get('users/' + uid).data.role == 'admin'
isApproved() → get('users/' + uid).data.approvalStatus == 'approved'
isOwner(userId) → request.auth.uid == userId
```

**`users/{uid}` — Key rules:**
- **Read:** Owner OR Admin OR any Approved user (needed for linking/messaging)
- **Create:** Owner only (on signup)
- **Update (owner):** Can update own profile, CANNOT update approval fields
- **Update (admin):** Can update any field including approval fields
- **Update (approved user on others):** Can ONLY update linking fields (`linkedSeniorId`, `linkedFamily`, `assignedSeniors`, `assignedCaregivers`) — needed for atomic WriteBatch
- **Delete:** Admin only

**`requests/{requestId}`:**
- Read: Approved users only
- Create: Approved seniors only
- Update: Approved users or Admin
- Delete: Admin only

**`checkins/{checkinId}`:**
- Read: Approved users only
- Create: Approved seniors only
- Update/Delete: Admin only

**`conversations/{id}` and messages subcollection:**
- Read/Write: Approved participants in `participantIds` or Admin

**`profiles/{userId}`:**
- Read: Owner, Admin, or Approved users
- Create/Update: Owner or Admin
- Delete: Admin only

**`_sync_check/{docId}`:**
- Read: Authenticated
- Write: Admin only

### Realtime Database Rules (`database.rules.json`)

**`emergencies/` and `active_emergencies/`:**
- Read/Write: All authenticated users
- Indexed on: `seniorId`, `status`, `createdAt`

**`emergency_history/{userId}/`:**
- Read/Write: Own records only

**`presence/{userId}`:**
- Read: Any authenticated user
- Write: Own presence only

---

## 12. Key Data Flows

### 12.1 App Startup & Auth Restore

```
main.dart
  → Firebase.initializeApp()
  → Firestore persistence enabled (IndexedDB on web, native on mobile)
  → RTDB persistence enabled
  → SyncService.init()
  → runApp(ProviderScope(child: MyApp()))

MyApp → GoRouter → authControllerProvider created
  → AuthController._init()
    → AuthRepository.getCurrentUser()
      → FirebaseAuth.currentUser → fetch Firestore user doc
    → AuthState.authenticated(user) or .initial()
    → Listen authStateChanges for external sign-outs

GoRouter redirect logic:
  isAuthenticated? → No → /login
  approvalStatus == 'pending'? → /pending-approval
  role == 'senior'? → /senior/home
  role == 'caregiver'? → /caregiver/home
  role == 'family'? → /family/home
  role == 'admin'? → /admin/home
```

### 12.2 Emergency Alert Flow

```
Senior presses emergency button
  → EmergencyRepository.createEmergency(alert)
    → RealtimeDbService.generateKey('emergencies') → id
    → alert.id = id
    → RealtimeDbService.multiPathUpdate({
        'emergencies/$id': alert.toMap(),
        'active_emergencies/$id': alert.toMap()
      })  // ATOMIC - both or neither

Caregiver screen (running)
  → activeEmergenciesStreamProvider watching streamActiveEmergencies()
    → RTDB stream on 'active_emergencies'
    → New alert appears in real-time

Caregiver taps "Respond"
  → EmergencyRepository.respondToEmergency(id, caregiverId, caregiverName)
    → RealtimeDbService.multiPathUpdate({
        'emergencies/$id/respondedBy': caregiverId,
        'emergencies/$id/respondedByName': caregiverName,
        'emergencies/$id/status': 'responded',
        'active_emergencies/$id/respondedBy': caregiverId,
        'active_emergencies/$id/status': 'responded'
      })  // ATOMIC field-level update

Caregiver resolves
  → EmergencyRepository.updateEmergencyStatus(id, 'resolved')
    → RealtimeDbService.multiPathUpdate({
        'emergencies/$id/status': 'resolved',
        'emergencies/$id/resolvedAt': ServerValue.timestamp,
        'active_emergencies/$id': null   // DELETE from active list
      })
```

### 12.3 Help Request Workflow

```
CREATION (Senior):
  CreateRequestScreen → requestRepositoryProvider.createRequest(request)
    → FirestoreService.add('requests', request.toMap())

DISCOVERY (Caregiver):
  CaregiverRequestsScreen → streamPendingRequests()
    → Firestore query: status == 'pending', real-time stream

ACCEPTANCE (Caregiver):
  CaregiverController.acceptRequest(requestId)
    → CaregiverRepository.acceptRequest(requestId, caregiverId, name)
      → firestore.runTransaction((tx) {
          snapshot = tx.get(requestRef)
          if (snapshot.status != 'pending') throw Exception
          tx.update(requestRef, {status: 'accepted', assignedTo: ..., updatedAt: ...})
        })
      → Capture seniorId from snapshot
      → assignToSenior(caregiverId, seniorId):
          WriteBatch:
            caregiver.assignedSeniors += [seniorId]   // arrayUnion
            senior.assignedCaregivers += [caregiverId] // arrayUnion

STATUS PROGRESSION:
  pending → accepted (caregiver accepts)
         → in_progress (caregiver starts work)
         → completed (caregiver finishes)
  pending → cancelled (senior cancels)
```

### 12.4 Family Linking

```
FamilyLinkController.linkToSenior(email)
  → FamilyRepository.linkToSenior(familyUid, email)
    → email = email.toLowerCase().trim()
    → validate '@' in email
    → query users where email == normalized_email, limit 1
    → if not found: throw "Senior not found"
    → if found.role != 'senior': throw "User is not a senior"
    → WriteBatch:
        family user: linkedSeniorId = found.uid
        senior user: linkedFamily = arrayUnion([familyUid])
      → batch.commit()

FamilyLinkController.unlinkFromSenior(seniorId)
  → FamilyRepository.unlinkFromSenior(familyUid, seniorId)
    → WriteBatch:
        family user: linkedSeniorId = null
        senior user: linkedFamily = arrayRemove([familyUid])
      → batch.commit()
```

### 12.5 Messaging

```
START CONVERSATION:
  MessagingController.startConversation(myId, theirId)
    → MessagingRepository.getOrCreateConversation(myId, theirId)
      → Query conversations where participantIds array-contains-all [myId, theirId]
      → If exists: return existing conversationId
      → If not: Firestore.add('conversations', {
          participantIds: [myId, theirId],
          participantNames: {myId: myName, theirId: theirName},
          unreadCount: 0
        })

SEND MESSAGE:
  ChatScreen → MessagingController.sendMessage(convId, content)
    → MessagingRepository.sendMessage(convId, message)
      → WriteBatch:
          1. ADD conversations/$convId/messages/$autoId = message.toMap()
          2. UPDATE conversations/$convId = {
               lastMessage: content,
               lastSenderId: senderId,
               lastMessageAt: FieldValue.serverTimestamp()
             }
        → batch.commit()

MARK READ:
  MessagingRepository.markMessagesAsRead(convId, userId)
    → Query: messages where isRead == false
    → Filter client-side: senderId != userId
    → WriteBatch: update isRead = true for each
```

---

## 13. Common Widgets

### SeniorButton (`lib/common_widgets/senior_button.dart`)
- Large accessible button (20px bold font, 18-24px padding)
- Props: `text`, `onPressed`, `icon`, `isLoading`, `backgroundColor`, `textColor`, `padding`
- Shows `CircularProgressIndicator` when `isLoading: true`
- Use for all primary actions in the app

### SeniorTextField (`lib/common_widgets/senior_text_field.dart`)
- Large accessible input (16-18px font, 18px vertical padding)
- Props: `label`, `hint`, `controller`, `validator`, `keyboardType`, `obscureText`, `maxLines`
- Standard validation pattern support
- Use for all text inputs in the app

### SyncIndicator (`lib/common_widgets/sync_indicator.dart`)
- Displays sync status icon + optional text label
- Color-coded: green (synced), blue (syncing), amber (pending), grey (offline), red (error)
- Tap opens dialog showing:
  - Last sync time
  - Pending changes count
  - Error message (if any)
  - Actions: Reconnect, Sync Now, Close
- Place in AppBar actions of main screens

### Theme (`lib/core/theme/app_theme.dart`)
- Material 3 with senior-friendly sizing
- Body text: 18-36px
- Headlines: 20-46px
- Buttons: 20px font, 12px radius, large padding
- Input fields: 20px vertical padding
- Both light and dark themes provided

---

## 14. Testing Architecture

### Test Structure
```
test/
├── widget_test.dart                         # MaterialApp rendering, basic widgets
├── core/
│   ├── errors/failures_test.dart            # Failure class hierarchy (~18 tests)
│   └── services/
│       ├── sync_state_test.dart             # SyncState model (~25 tests)
│       ├── location_data_test.dart          # LocationData model
│       └── constants_test.dart             # AppConstants validation (~30 tests)
└── features/
    ├── auth/auth_test.dart                  # AppUser entity tests (~80 tests)
    ├── requests/request_test.dart           # HelpRequest tests
    ├── emergency/emergency_test.dart        # EmergencyAlert tests (RTDB types)
    ├── checkin/checkin_test.dart            # CheckIn tests
    ├── messaging/messaging_test.dart        # Message + Conversation tests
    └── dataflow/data_pipeline_test.dart     # Full lifecycle tests (~50 tests)
```

### Testing Approach
- Framework: `flutter_test` + `mocktail`
- **Unit Tests:** Pure model/entity tests — no Firebase required
- **Data Pipeline Tests:** Serialization round-trips, status workflows
- **Widget Tests:** UI rendering, accessibility
- Goal: 250+ tests total

### What Is and Isn't Tested
- ✅ All entity serialization (toMap/fromMap/toJson/fromJson)
- ✅ Status workflows and state transitions
- ✅ Bidirectional relationship consistency
- ✅ Error class hierarchy
- ✅ Constants completeness
- ❌ Actual Firebase calls (no integration tests)
- ❌ Real network operations

---

## 15. Critical Implementation Patterns

### 15.1 Timestamp Handling

| Storage | Format | Write | Read |
|---------|--------|-------|------|
| Firestore (documents) | `Timestamp` | `Timestamp.fromDate(dt)` or `FieldValue.serverTimestamp()` | `timestamp.toDate()` |
| Firestore (JSON export) | ISO8601 string | `dt.toIso8601String()` | `DateTime.tryParse(s)` |
| Realtime Database | epoch int (ms) | `ServerValue.timestamp` | `DateTime.fromMillisecondsSinceEpoch(n)` |

**Universal parser:**
```dart
static DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
```

### 15.2 Atomic Multi-Document Writes

**WriteBatch (Firestore — multiple documents):**
```dart
final batch = firestore.batch();
batch.update(doc1Ref, {'fieldA': value});
batch.update(doc2Ref, {'fieldB': FieldValue.arrayUnion([id])});
await batch.commit();  // Atomic — all or nothing
```

**Transaction (Firestore — read then write):**
```dart
await firestore.runTransaction((transaction) async {
  final snapshot = await transaction.get(docRef);
  if (snapshot['status'] != 'pending') throw Exception('Already taken');
  transaction.update(docRef, {'status': 'accepted', 'assignedTo': uid});
});
```

**Multi-path update (RTDB — cross-path atomic):**
```dart
await realtimeDb.multiPathUpdate({
  'emergencies/$id/status': 'resolved',
  'emergencies/$id/resolvedAt': ServerValue.timestamp,
  'active_emergencies/$id': null,  // null = DELETE
});
```

### 15.3 Batch Fetching (whereIn limit)

Firestore `whereIn` max 10 items:
```dart
Future<List<T>> _batchFetch(List<String> ids) async {
  final results = <T>[];
  for (var i = 0; i < ids.length; i += 10) {
    final batch = ids.sublist(i, min(i + 10, ids.length));
    final snap = await firestore.collection('users')
      .where(FieldPath.documentId, whereIn: batch)
      .get();
    results.addAll(snap.docs.map((d) => T.fromMap(d.data())));
  }
  return results;
}
```

### 15.4 Date Range Query (Start/End of Day)

```dart
final now = DateTime.now();
final startOfDay = DateTime(now.year, now.month, now.day);
final endOfDay = startOfDay.add(const Duration(days: 1));

firestore.collection('checkins')
  .where('seniorId', isEqualTo: seniorId)
  .where('checkinTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
  .where('checkinTime', isLessThan: Timestamp.fromDate(endOfDay))
```

### 15.5 Array Operations (Idempotent)

```dart
// Add (no duplicates)
'linkedFamily': FieldValue.arrayUnion([memberId])

// Remove (safe even if not present)
'linkedFamily': FieldValue.arrayRemove([memberId])
```

### 15.6 Avoiding Composite Index Issues

Firestore requires composite indexes for multi-field ordered queries. Current approach:
- Query by **one field** only
- Filter/sort additional criteria **client-side**
- Example: Query all caregivers, then filter by approvalStatus in Dart

### 15.7 Real-time Streams via asyncMap

For providers that watch a stream and need to fetch related data:
```dart
Stream<AppUser?> streamLinkedSenior(String familyUserId) {
  return firestore.collection('users').doc(familyUserId)
    .snapshots()
    .asyncMap((snapshot) async {
      final seniorId = snapshot.data()?['linkedSeniorId'];
      if (seniorId == null) return null;
      return getLinkedSenior(seniorId);
    });
}
```

---

## 16. Known Issues & Gotchas

### 16.1 Serialization Inconsistency — CRITICAL
> **Always use `toMap()` for Firestore writes, `toJson()` for REST/cache.**
> Mixing them causes type mismatches (Firestore Timestamp vs ISO8601 string).

### 16.2 acceptRequest Race Condition
- **Problem:** Two caregivers could accept the same request simultaneously
- **Fix:** `acceptRequest()` uses a Firestore **transaction** to verify status == 'pending' before accepting. If already taken, throws an exception.
- Caregiver UI should show error "Request already taken"

### 16.3 EmergencyAlert Dynamic Types (RTDB)
- RTDB returns `dynamic` values — doubles may come back as `int`
- `EmergencyAlert.fromMap()` explicitly handles type coercion:
  ```dart
  latitude: (map['latitude'] as num?)?.toDouble()
  ```

### 16.4 whereIn Empty List Guard
- Firestore throws if `whereIn` is called with an empty list
- Always guard: `if (ids.isEmpty) return [];`

### 16.5 Pending Write Detection
- `hasPendingWrites` is metadata from Firestore snapshot
- Only available on document/query snapshots, not computed from local state

### 16.6 Web vs Mobile Persistence
- **Web:** `PersistenceSettings(synchronizeTabs: true)` + IndexedDB
- **Mobile:** `setPersistenceEnabled(true)` (native SQLite)
- Both configured in `main.dart`

### 16.7 signUp Error Masking (Fixed)
- **Old behavior:** If Firestore user doc creation failed after Auth succeeded, signIn would create a placeholder user
- **Fix:** Return null (throw error) if user doc missing; use `toMap()` for Firestore writes

### 16.8 Client-side Search Limitation
- `searchUsers()` in AdminRepository is client-side only
- For large user bases (100k+) this will be slow
- Future: integrate Algolia or Typesense

### 16.9 FCM Token Updates
- `fcmToken` is stored per user but notification sending logic via Cloud Functions
- Token refreshes not fully automated in client code

---

## Summary Quick Reference

| Question | Answer |
|----------|--------|
| Database for most data? | Cloud Firestore |
| Database for emergencies? | Firebase Realtime Database |
| State management? | Riverpod (StateNotifier + FutureProvider/StreamProvider) |
| Navigation? | GoRouter with auth guards |
| Theme approach? | Material 3, senior-friendly (large fonts/buttons) |
| Atomic multi-doc writes? | WriteBatch (Firestore), multiPathUpdate (RTDB) |
| Read-modify-write safety? | Firestore transactions |
| Offline support? | Firestore persistence + SyncService monitoring |
| User approval? | All users start as 'pending', admin approves/rejects |
| Timestamp format in RTDB? | Epoch milliseconds (int), NOT Firestore Timestamp |
| Max items in whereIn? | 10 (batch with pagination for more) |
| Test framework? | flutter_test + mocktail |
