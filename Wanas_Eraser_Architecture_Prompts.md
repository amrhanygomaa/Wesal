# Wanas Eraser.ai Architecture Prompts

Project Title: Wanas  
Department: Multimedia - Web Development  
Graduation Project  
Documentation Language: English  
Diagram Style: Professional, academic, clean, suitable for university graduation project documentation.

## Source Findings Used

- The repository is primarily a Flutter application named `riaya_app`, with Android, iOS, web, Windows, Linux, and macOS targets.
- The frontend uses Flutter, Riverpod state management, `AppRiverpod`, shared widgets, role-based dashboards, local secure storage, local notifications, device media/contacts/microphone APIs, and many domain services under `lib/services`.
- The checked-in backend source code is not present in this workspace. Backend architecture is based on `docs/backend-contract.md`, `docs/backend-gap-analysis.md`, and `docs/backend-routes.raw.txt`.
- The documented backend is an external GCP backend exposed at `https://api.helpers-tech.com`, with NestJS-style controllers in the route dump, Cognito authentication, RDS PostgreSQL data storage, S3 presigned upload flows, AI endpoints, notifications, and realtime events.
- No GCP infrastructure-as-code or complete deployment configuration was found in this repository. The GCP diagram prompt below is therefore labeled as a recommended GCP deployment architecture.

---

## Prompt 1

### Diagram Name

Wanas Application Architecture Diagram

### Eraser.ai Prompt

Create a clean, professional, academic layered application architecture diagram for the Wanas graduation project. Use English labels only. Use a clear top-to-bottom layered layout with grouped boxes, simple icons where useful, and arrows showing data flow. Do not invent components that are not listed below. If a component is not listed, do not add it.

Diagram title: "Wanas Application Architecture"

Use these layers and components:

1. User Roles Layer
   - Elderly Resident
   - Family Member
   - Nurse
   - Social Specialist
   - Admin / Facility Management
   - Volunteer

2. Client Application Layer - Flutter App
   Label this group: "Flutter Client Application"
   Include:
   - Android app as the primary client target
   - Web, iOS, desktop targets as Flutter platform outputs
   - Arabic RTL user interface
   - Riverpod `ProviderScope`
   - MaterialApp entry point
   - Splash and onboarding flow
   - Login, register, admin register, forgot password screens
   - Role-based routing after authentication

3. Presentation and Screen Layer
   Group screens by role:
   - Resident Screens: Home, Medication, Calls, Memories, Activities, Cognitive Games, AI Companion Chat, Voice Messages, SOS Overlay
   - Family Screens: Family Dashboard, Care View, Visits, Billing, Family Bridge Media, Family Activities, Chat with Specialist, Resident ID, Care Report Detail
   - Nurse Screens: Nurse Dashboard, Residents, Resident Detail, Operations, Medical Administration, Medications, Reports, Shift Handoff, Nurse Profile
   - Social Specialist Screens: Assessment, Complaints, KPI, Files and Audit Trail, Activities, Specialist Chats
   - Admin Screens: Admin Dashboard, Admin Home Analytics, Residents Management, Staff Management, Visit Approval, Complaints, Admin Reports, Volunteer Management, AI Warnings, Settings
   - Volunteer Screens: Volunteer Dashboard, Profile, Opportunities, Bookings, Certificates, Ratings
   - Common Screens: Profile, Account Settings, Notifications Center, Cloud Health, Help and Support, Privacy, About Wanas

4. Shared UI Components Layer
   Label this group: "Reusable Flutter Widgets"
   Include:
   - `TaptabaScaffold`
   - `TaptabaDrawer`
   - `BottomNavBar`
   - `TaptabaBell`
   - `DraggableSOS`
   - Accessibility dialog
   - Input fields, role selector, password strength widget
   - Live cloud banners for residents, KPI, medications, notifications, complaints, visits, vitals
   - Modal sheets for create resident, record vitals, submit complaint
   - AI companion chat widgets

5. Client State and Business Logic Layer
   Label this group: "State, Models, and Client Business Logic"
   Include:
   - `AppRiverpod` as the central app state provider
   - App models from `lib/models/app_models.dart`
   - Role, authentication, onboarding, theme, accessibility, upload progress, notification, and sync state
   - Secure local session storage using `FlutterSecureStorage`
   - Local reminders using `flutter_local_notifications`
   - Local device capabilities: contacts, camera/gallery, microphone, text-to-speech, speech-to-text, biometric authentication, PDF generation

6. Client Service Layer
   Label this group: "Flutter Service Layer"
   Include these services:
   - `ApiClient`: shared REST client, JSON headers, Bearer token injection, timeout and error handling
   - `AuthService`: login, self-register, admin registration, forgot password, Cognito refresh, restore session
   - `BackendSyncService`: role-aware data loading and mapping
   - `BackendMutationService`: create, update, delete, and domain mutations
   - Domain services: Residents, Medications, Health, Complaints, Emergency, Messages, Notifications API, Push Notifications, Realtime, Facility Settings, Facility Inquiry, Family Bridge, Family Media, Nursing Reports, Admin Users, KPI, Social, AI, AI Media, Video Calls, Voice Messages, Volunteer Documents, User Preferences, User Progress, Profile Image, Resident Documents, PDF
   - `s3_upload_helper`: HTTP PUT upload to presigned S3 URLs

7. Backend/API Layer
   Label this group: "External GCP Backend API - documented contract"
   Add a note inside the group: "Backend source is not included in this Flutter repository; routes are documented in `/docs`."
   Show it as a NestJS-style REST API because the route dump uses controller decorators.
   Include:
   - API base URL: `https://api.helpers-tech.com`
   - REST controllers/modules:
     - Auth Controller: `/auth/login`, `/auth/register`, `/auth/register-admin`, `/auth/forgot-password`, `/auth/confirm-forgot-password`, `/auth/me`
     - Users/Admin Controllers: `/users/me`, `/users/admin`, `/users/clinical`, `/admin/users`, `/admin/staff-performance`, `/admin/settings`
     - Residents Controller: `/residents`, `/residents/:id`, `/residents/:id/medical-info`, `/residents/:id/audit-trail`, photo/document upload endpoints
     - Family Members Controller: `/family-members`
     - Medications Controller: schedules, doses, overdue doses, adherence
     - Health Controller: vitals, alerts, thresholds
     - Nursing Operations: nursing notes, handoffs, care tasks, inventory, doctor visits, medical sessions, prescriptions, meal plans
     - Social Controller: needs, assessment tools, questions, GDS questions, resident scores, assessments, KPIs
     - Complaints Controller
     - Family Bridge Controller: visits and media upload/confirm/delete
     - Billing Controller
     - Memories Controller
     - Reports Controller: nursing preview, completeness, export, history, settings, send
     - Volunteers Controller: profile, opportunities, bookings, certificates, ratings, reviews, document upload, public profile link
     - Messages Controller: inbox, thread, unread count, mark read, send text message
     - Notifications Controller: notifications and push tokens
     - Video Calls Controller
     - Emergency Controller: SOS, active emergencies, resolve
     - AI Controller: chat, speech, recommendations, memory, media upload, predictive alerts, smart diet, summaries, cognitive game, family update, voice sentiment
     - KPI Controller
     - Activities Controller
     - Voice Messages Controller
     - Facilities Search and Facility Inquiries
   - Middleware/security concepts:
     - Cognito/JWT Bearer authentication
     - Role and facility scoping from Cognito claims
     - Request validation using documented validation rules
     - Protected endpoints for authenticated users

8. Data Layer
   Label this group: "Database Layer - Google Cloud SQL (PostgreSQL)"
   Include logical data domains, not invented physical tables:
   - Users, roles, managed users, staff reviews
   - Facilities, facility profile, emergency contacts, billing settings, facility inquiries
   - Residents, resident medical info, documents, photos, audit trail
   - Family members, visits, media, billing, memories
   - Medication schedules, dose logs, adherence
   - Health vitals, alerts, thresholds
   - Nursing notes, handoffs, care tasks, inventory, doctor visits, medical sessions, prescriptions, meal plans
   - Social needs, assessment tools, questions, assessments, resident scores, complaints
   - Volunteers, opportunities, bookings, certificates, ratings, reviews, documents, public profile links
   - Messages, notifications, push tokens, video calls, emergency alerts
   - AI resident memory and AI media uploads
   - User preferences and user progress

9. External Services Layer
   Label this group: "External Services and Integrations"
   Include:
   - Google Cloud Identity Platform / Firebase Auth User Pool: authentication, roles, JWT tokens, refresh flow
   - Google Cloud Storage (GCS): media, documents, profile photos through presigned upload URLs
   - GCP Bedrock: AI chat, recommendations, summaries, predictive alerts, family updates, cognitive game support
   - Google Cloud Text-to-Speech or backend speech provider: AI speech synthesis
   - Firebase Cloud Messaging: mobile push notifications
   - Socket.IO realtime namespace `/realtime`: live events, notifications, messages, vitals updates, SOS alerts
   - Device integrations: biometric authentication, contacts, camera/gallery, microphone, local notifications, PDF export

Draw these data flows with arrows:

- User Roles -> Flutter Client Application -> Splash/Onboarding/Login -> AuthService -> `POST /auth/login` -> Backend Auth Controller -> Google Cloud Identity Platform / Firebase Auth -> JWT tokens returned -> ApiClient stores tokens in Flutter Secure Storage -> AppRiverpod routes user to role dashboard.
- Flutter role dashboards -> AppRiverpod -> BackendSyncService -> ApiClient -> documented REST API controllers -> Google Cloud SQL (PostgreSQL) -> mapped domain models -> role-specific screens.
- Forms and actions -> BackendMutationService/domain services -> REST API mutation endpoints -> Google Cloud SQL (PostgreSQL) -> refreshed sync data.
- File/media upload flow: Flutter file picker or camera -> upload service -> API presigned upload request -> S3 presigned PUT upload -> API confirm endpoint -> database stores S3 URL/key.
- Push notification flow: Flutter registers FCM token -> `/notifications/push-tokens` -> Backend Notifications Controller -> Firebase Cloud Messaging -> mobile device notification -> App navigation handler.
- Realtime flow: Flutter RealtimeService -> Socket.IO `/realtime` -> backend realtime events -> live banners, notification center, SOS, messages, vitals updates.
- AI flow: AI Companion/AI screens -> AiService -> AI API endpoints -> GCP Bedrock/Polly -> AI response/audio -> Flutter UI.
- SOS workflow: Resident or Nurse SOS control -> EmergencyService -> `/emergency/sos` -> database emergency alert -> realtime SOS event and notification flow -> Nurse/Family/Admin screens.
- Reporting workflow: Nurse/Admin reports screens -> NursingReportsService -> reports endpoints -> RDS data aggregation -> PDF/export or preview response -> Flutter report UI.

Visual style requirements:

- Use a layered architecture diagram with clear horizontal bands.
- Use distinct colors per layer, but keep the palette calm and academic.
- Use professional labels and avoid decorative clutter.
- Use concise labels inside boxes and short arrow labels such as "REST JSON", "Bearer JWT", "Presigned Upload", "Realtime Event", "Push Notification", "Role-Based Routing".
- Clearly group frontend, client services, backend API, database, and external services.
- Add a small annotation: "Backend implementation source is not checked into this workspace; backend modules are based on documented API contract and route dump."
- Do not include Lambda, API Gateway, DynamoDB, MongoDB, or Kubernetes in this app architecture diagram because they are not found in the repository.

### Notes

This diagram fits Wanas because the repository is a Flutter/Riverpod client with role-based dashboards, a central provider, a service-based API integration layer, Google Cloud Identity Platform / Firebase Auth authentication, documented REST backend modules, RDS PostgreSQL data domains, S3 presigned uploads, realtime events, Firebase push notifications, and AI endpoints. The backend implementation is documented but not present in this repository, so the diagram should represent it as an external documented GCP backend API rather than local source code.

---

## Prompt 2

### Diagram Name

GCP Deployment Architecture Wanas

### Eraser.ai Prompt

Create a professional GCP cloud architecture diagram titled "Recommended GCP Deployment Architecture for Wanas". This is a recommended deployment architecture based on the actual Wanas stack. Do not label it as already implemented. Use English labels only. Keep the diagram realistic for a university graduation project and do not overcomplicate it.

Important instruction: The repository does not contain GCP infrastructure-as-code. Show this as "Recommended GCP Deployment Architecture", not as an existing deployed architecture.

Use these architecture groups:

1. Internet Users and Clients
   - Mobile users using the Wanas Flutter Android/iOS app
   - Web users using the Flutter web build
   - User roles: Elderly Resident, Family Member, Nurse, Social Specialist, Admin, Volunteer

2. DNS, TLS, and Edge Layer
   - Amazon Route 53 for domain management
   - GCP Certificate Manager for SSL/TLS certificates
   - Amazon CloudFront for the Flutter web frontend CDN
   - Public API domain such as `api.wanas.edu` or existing API domain `api.helpers-tech.com`

3. Frontend Hosting
   - Google Cloud Storage (GCS) bucket for Flutter web static build files
   - CloudFront distribution in front of the S3 frontend bucket
   - Mobile apps are distributed as installed Flutter apps and call the same backend API
   - Build-time configuration uses `API_BASE_URL`; it is not a secret

4. Network Boundary
   Draw one VPC with:
   - Public subnets across two Availability Zones
   - Private application subnets across two Availability Zones
   - Private database subnets across two Availability Zones
   - Internet Gateway for public ingress
   - NAT Gateway for private backend outbound access
   - Security groups for ALB, EC2 backend, and RDS

5. Backend/API Hosting
   Use EC2 because the project documentation and code comments reference a production backend on EC2 and backend migrations copied to EC2.
   Include:
   - Application Load Balancer in public subnets
   - EC2 instance or small Auto Scaling Group in private application subnets
   - Node.js/NestJS-style Wanas Backend API running on EC2
   - REST API controllers for Auth, Residents, Medications, Health, Nursing, Social, Family Bridge, Billing, Volunteers, Messages, Notifications, Emergency, Reports, AI, Video Calls, KPI
   - Socket.IO realtime endpoint `/realtime`
   - Backend communicates with Google Cloud Identity Platform / Firebase Auth, RDS PostgreSQL, S3, Bedrock/Polly, Firebase Cloud Messaging, and CloudWatch

6. Authentication and Authorization
   - Amazon Cognito User Pool in `us-east-1`
   - Cognito App Client
   - Cognito groups/custom claims for roles and facility scoping
   - Backend validates JWT Bearer tokens
   - Flutter stores returned tokens in secure storage
   - Refresh token flow uses Cognito `InitiateAuth` refresh flow

7. Database Layer
   - Amazon RDS for PostgreSQL in private database subnets
   - Multi-AZ optional for higher availability
   - Automated backups enabled
   - Logical database domains: users, facilities, residents, health vitals, medications, nursing operations, social assessments, complaints, family bridge, billing, memories, volunteers, reports, messages, notifications, video calls, emergency alerts, user preferences, user progress, AI memory

8. File and Media Storage
   - Private Google Cloud Storage (GCS) uploads bucket
   - Stored objects: resident documents, profile photos, family media, AI media uploads, volunteer documents, voice messages
   - Backend creates presigned upload URLs
   - Client uploads directly to S3 with HTTP PUT
   - Client calls backend confirm endpoint after upload
   - S3 bucket policy blocks public write access
   - Optional CloudFront distribution for controlled media delivery if public/media viewing URLs are required

9. AI and Speech Services
   - Amazon Bedrock for AI chat, recommendations, summaries, predictive alerts, family updates, cognitive game support
   - Amazon Polly or backend speech provider for text-to-speech audio
   - Backend service layer calls Bedrock/Polly; clients never call Bedrock directly

10. Notifications and Realtime Communication
   - Firebase Cloud Messaging as an external notification provider
   - Backend stores FCM tokens and sends push notifications through FCM
   - Socket.IO realtime connection from Flutter app to backend `/realtime`
   - Realtime event types: notifications, messages, vitals updates, SOS alerts

11. Secrets, Configuration, and IAM
   - GCP Secrets Manager or Systems Manager Parameter Store for:
     - Database connection string
     - Cognito client secret if used by backend
     - `ADMIN_SETUP_SECRET`
     - S3 bucket names
     - Bedrock/Polly configuration
     - Firebase service credentials
     - JWT and environment-specific backend settings
   - IAM role attached to EC2 backend with least-privilege access to S3, Cognito admin APIs, Bedrock/Polly, CloudWatch, and Secrets Manager/Parameter Store
   - Separate frontend build-time variables from backend secrets

12. Monitoring and Operations
   - Amazon CloudWatch Logs for backend application logs
   - CloudWatch Metrics and Alarms for EC2, ALB, RDS, and application errors
   - CloudWatch Agent on EC2
   - RDS automated backups and retention
   - GitHub Actions CI currently runs Flutter tests; deployment pipeline can be added later for frontend build upload and backend deployment

Draw these request flows with arrows:

- Web request flow: User Browser -> Route 53 -> CloudFront -> S3 Flutter Web Hosting -> Flutter app loads -> API calls go to API domain.
- Mobile request flow: Mobile Flutter App -> API domain -> Route 53 -> ACM TLS -> Application Load Balancer -> EC2 NestJS Backend.
- Authentication flow: Flutter App -> `POST /auth/login` on backend -> Cognito User Pool -> backend returns JWT/access/refresh tokens -> Flutter Secure Storage -> authenticated REST requests with Bearer JWT.
- API data flow: Flutter App -> ALB -> EC2 Backend API -> RDS PostgreSQL in private subnet -> response back to Flutter.
- File upload flow: Flutter App -> backend upload request -> backend returns S3 presigned URL -> Flutter PUT upload directly to S3 -> Flutter confirm request -> backend stores S3 key/URL in RDS.
- AI flow: Flutter AI Companion -> backend AI endpoints -> Amazon Bedrock/Polly -> AI response/audio -> backend -> Flutter.
- Push flow: Flutter registers FCM token -> backend notifications endpoint -> token stored in RDS -> backend sends notification to Firebase Cloud Messaging -> FCM delivers to mobile device.
- Realtime flow: Flutter Socket.IO connection -> ALB/EC2 backend `/realtime` -> realtime events returned to dashboards and notification widgets.
- Emergency flow: Resident SOS -> backend `/emergency/sos` -> RDS emergency alert -> realtime SOS event and FCM push -> Nurse/Family/Admin clients.

Security and diagram constraints:

- Show public resources: Route 53, CloudFront, S3 frontend origin through CloudFront, ALB, Internet Gateway.
- Show private resources: EC2 backend, RDS PostgreSQL, private S3 uploads bucket, Secrets Manager/Parameter Store.
- Show security groups:
  - ALB Security Group allows HTTPS from internet.
  - Backend Security Group allows traffic only from ALB to the API port.
  - RDS Security Group allows PostgreSQL only from backend security group.
  - S3 uploads bucket is private and accessed through presigned URLs.
- Do not include Lambda, API Gateway, ECS/Fargate, DynamoDB, DocumentDB, or Kubernetes because the current project does not show a serverless, containerized, NoSQL, MongoDB-compatible, or Kubernetes architecture.
- Keep the layout clean and academic. Use GCP service icons, grouped VPC/subnet boundaries, clear labels, and directional arrows.
- Add a note box: "Recommended architecture based on Flutter client, documented NestJS-style backend API, Google Cloud Identity Platform / Firebase Auth, RDS PostgreSQL, S3 presigned uploads, Bedrock/Polly AI services, Firebase Cloud Messaging, and Socket.IO realtime. GCP IaC was not found in the repository."

### Notes

This GCP architecture is realistic for Wanas because the app already expects an GCP-hosted REST backend, Cognito authentication, RDS PostgreSQL, S3 presigned uploads, AI services, push notifications, and realtime communication. EC2 is chosen for backend hosting because the repository documentation and code comments reference an EC2-hosted backend, while the frontend can be hosted simply as a Flutter web build on S3 and CloudFront. The design avoids unnecessary serverless, container, and NoSQL services that are not supported by the current codebase.

---

## Prompt 3

### Diagram Name

Wanas Database ERD

### Eraser.ai Prompt

Create a professional Entity Relationship Diagram (ERD) titled "Wanas — Database Entity Relationship Diagram" for a university graduation project. Use English labels only. Use a clean, academic layout with clearly separated entity boxes, attribute lists inside each box, and labeled relationship lines showing cardinality (one-to-one, one-to-many). Do not invent tables that are not listed below.

Use these entities and their key attributes:

**FACILITIES**
- id (PK)
- name
- address
- phone
- emergency_contacts
- billing_settings

**MANAGED_USERS** (staff and app users: Nurse, Social Specialist, Admin, Volunteer, Family Account)
- id (PK)
- facility_id (FK → FACILITIES)
- cognito_sub
- name
- email
- role (enum: nurse, social_specialist, admin, volunteer, family)
- image_url
- is_active

**RESIDENTS**
- id (PK)
- facility_id (FK → FACILITIES)
- name
- room_number
- birth_date
- gender
- image_url
- medical_info (embedded: allergies, diagnoses, blood_type, emergency_contact)

**FAMILY_MEMBERS**
- id (PK)
- resident_id (FK → RESIDENTS)
- managed_user_id (FK → MANAGED_USERS, nullable — for app-linked family)
- name
- phone
- relationship
- is_pinned

**MEDICATION_SCHEDULES**
- id (PK)
- resident_id (FK → RESIDENTS)
- medication_name
- dosage
- frequency
- scheduled_times (array)
- is_active

**MEDICATION_DOSES**
- id (PK)
- schedule_id (FK → MEDICATION_SCHEDULES)
- nurse_id (FK → MANAGED_USERS)
- status (enum: pending, taken, skipped, missed)
- administered_at
- notes

**HEALTH_VITALS**
- id (PK)
- resident_id (FK → RESIDENTS)
- recorded_by (FK → MANAGED_USERS)
- type (enum: blood_pressure, pulse, temperature, oxygen, weight)
- value
- unit
- recorded_at
- alert_triggered

**CARE_TASKS**
- id (PK)
- resident_id (FK → RESIDENTS)
- assigned_to (FK → MANAGED_USERS)
- title
- description
- status (enum: pending, in_progress, complete)
- due_at
- completed_at

**NURSING_NOTES**
- id (PK)
- resident_id (FK → RESIDENTS)
- nurse_id (FK → MANAGED_USERS)
- content
- type (enum: general, handoff, incident)
- created_at

**HANDOFFS**
- id (PK)
- facility_id (FK → FACILITIES)
- from_nurse_id (FK → MANAGED_USERS)
- summary
- created_at

**VISITS**
- id (PK)
- resident_id (FK → RESIDENTS)
- family_member_id (FK → FAMILY_MEMBERS)
- scheduled_date
- status (enum: pending, approved, rejected, completed)
- type (enum: in_person, virtual)

**COMPLAINTS**
- id (PK)
- resident_id (FK → RESIDENTS)
- reported_by (FK → MANAGED_USERS)
- title
- description
- priority (enum: low, medium, high)
- status (enum: open, in_progress, resolved)
- created_at

**SOCIAL_ASSESSMENTS**
- id (PK)
- resident_id (FK → RESIDENTS)
- specialist_id (FK → MANAGED_USERS)
- tool_name
- score
- answers (JSON)
- completed_at

**VOLUNTEER_OPPORTUNITIES**
- id (PK)
- facility_id (FK → FACILITIES)
- title
- description
- date
- hours
- tags (array)
- slots_available

**VOLUNTEER_BOOKINGS**
- id (PK)
- opportunity_id (FK → VOLUNTEER_OPPORTUNITIES)
- volunteer_id (FK → MANAGED_USERS)
- status (enum: pending, confirmed, attended, cancelled)
- attended_at

**AI_RESIDENT_MEMORY**
- id (PK)
- resident_id (FK → RESIDENTS, unique)
- summary
- recommendations
- warnings
- mood
- updated_at

**NOTIFICATIONS**
- id (PK)
- user_id (FK → MANAGED_USERS)
- type
- title
- body
- is_read
- created_at

**VIDEO_CALLS**
- id (PK)
- resident_id (FK → RESIDENTS)
- initiated_by (FK → MANAGED_USERS)
- status (enum: initiated, active, ended)
- started_at
- ended_at

**USER_PREFERENCES**
- id (PK)
- user_id (FK → MANAGED_USERS, unique)
- theme (enum: light, dark)
- font_scale
- high_contrast

Draw these relationships with cardinality labels:

- FACILITIES ||--o{ MANAGED_USERS : "employs"
- FACILITIES ||--o{ RESIDENTS : "houses"
- FACILITIES ||--o{ VOLUNTEER_OPPORTUNITIES : "offers"
- RESIDENTS ||--o{ FAMILY_MEMBERS : "linked to"
- RESIDENTS ||--o{ MEDICATION_SCHEDULES : "prescribed"
- RESIDENTS ||--o{ HEALTH_VITALS : "has"
- RESIDENTS ||--o{ CARE_TASKS : "assigned"
- RESIDENTS ||--o{ NURSING_NOTES : "documented in"
- RESIDENTS ||--o{ COMPLAINTS : "subject of"
- RESIDENTS ||--o{ SOCIAL_ASSESSMENTS : "evaluated by"
- RESIDENTS ||--o{ VISITS : "receives"
- RESIDENTS ||--|| AI_RESIDENT_MEMORY : "has one"
- MEDICATION_SCHEDULES ||--o{ MEDICATION_DOSES : "logged as"
- FAMILY_MEMBERS ||--o{ VISITS : "books"
- MANAGED_USERS ||--o{ HANDOFFS : "creates"
- MANAGED_USERS ||--o{ MEDICATION_DOSES : "administers"
- MANAGED_USERS ||--o{ NURSING_NOTES : "writes"
- MANAGED_USERS ||--o{ CARE_TASKS : "assigned to"
- MANAGED_USERS ||--o{ COMPLAINTS : "reports"
- MANAGED_USERS ||--o{ SOCIAL_ASSESSMENTS : "conducts"
- MANAGED_USERS ||--o{ VOLUNTEER_BOOKINGS : "attends"
- MANAGED_USERS ||--o{ NOTIFICATIONS : "receives"
- MANAGED_USERS ||--o{ VIDEO_CALLS : "initiates"
- MANAGED_USERS ||--|| USER_PREFERENCES : "has one"
- VOLUNTEER_OPPORTUNITIES ||--o{ VOLUNTEER_BOOKINGS : "booked by"

Visual style requirements:

- **Layout: Landscape (wide horizontal canvas).** Arrange entity groups left-to-right across the canvas. Do NOT stack all entities vertically. Spread the 19 entities across the full width so relationship lines do not overlap.
- Suggested horizontal grouping (left to right):
  - Far left: FACILITIES
  - Left-center: MANAGED_USERS, USER_PREFERENCES
  - Center-top: RESIDENTS, FAMILY_MEMBERS, AI_RESIDENT_MEMORY
  - Center: MEDICATION_SCHEDULES, MEDICATION_DOSES, HEALTH_VITALS
  - Center-right: NURSING_NOTES, CARE_TASKS, HANDOFFS
  - Right-center: COMPLAINTS, SOCIAL_ASSESSMENTS, VISITS, VIDEO_CALLS
  - Far right: VOLUNTEER_OPPORTUNITIES, VOLUNTEER_BOOKINGS, NOTIFICATIONS
- Use a standard ERD layout with entity boxes that have a header row (entity name) and attribute rows below.
- Mark primary keys with "PK" and foreign keys with "FK".
- Use calm, academic colors — one color per domain group:
  - Blue: FACILITIES, MANAGED_USERS, USER_PREFERENCES
  - Green: RESIDENTS, FAMILY_MEMBERS, AI_RESIDENT_MEMORY
  - Orange: MEDICATION_SCHEDULES, MEDICATION_DOSES, HEALTH_VITALS
  - Purple: NURSING_NOTES, CARE_TASKS, HANDOFFS
  - Red: COMPLAINTS, SOCIAL_ASSESSMENTS
  - Teal: VISITS, VIDEO_CALLS, NOTIFICATIONS
  - Yellow: VOLUNTEER_OPPORTUNITIES, VOLUNTEER_BOOKINGS
- Use crow's foot notation for cardinality on relationship lines.
- Keep the diagram clean — do not add extra entities, comments, or decorative elements beyond what is listed.
- Title: "Wanas — Database Entity Relationship Diagram"
- Add a small note: "Database: Google Cloud SQL (PostgreSQL). Schema managed via SQL migration files."

### Notes

This ERD is derived from the documented API surface, backend contract files, and domain model found in the Flutter client models. The PostgreSQL schema has 20+ tables managed by migration files. FACILITIES is the root entity — all resident, staff, and operational data is scoped to a facility.

---

## Prompt 4

### Diagram Name

Wanas App Screen Flow and Navigation

### Eraser.ai Prompt

Create a professional application screen flow and navigation diagram titled "Wanas — App Screen Flow by Role". Use English labels only. Use a clean left-to-right or top-to-bottom flowchart layout. Group screens by user role using clearly labeled swimlanes or color-coded groups. Use rounded rectangles for screens, diamonds for decision points, and directed arrows for navigation transitions. Do not invent screens that are not listed below.

Use these role groups and screens:

**Group 1 — App Entry (shared)**
Color: Gray
Screens:
- Splash Screen (app launch)
- Onboarding Screen (first-time user only)
- Login Screen
- Register Screen (self-register: Family / Volunteer)
- Admin Register Screen (requires ADMIN_SETUP_SECRET)
- Forgot Password Screen

Entry flow:
Splash → [First time?] → Yes → Onboarding → Login | No → Login
Login → [Role decision diamond] → routes to role dashboard

**Group 2 — Elderly Resident**
Color: Amber/Orange
Entry: Role decision → Elderly Home Screen
Screens:
- Home Screen (main dashboard)
- Medication Screen
- Calls Screen (video calls with family)
- Memories Screen → Album Details Screen → Full Screen Image
- Activities Screen
- Cognitive Games Screen
- AI Companion Chat (embedded in Home or dedicated view)
- Voice Messages Playback Screen
- SOS Overlay (draggable, always on top)
- Notifications Center (common)
- Profile Screen (common)

**Group 3 — Family Member**
Color: Sky Blue
Entry: Role decision → Family Dashboard Screen
Screens:
- Family Dashboard Screen
- Visit Booking Screen
- Family Bridge Screen (media sharing)
- Family Activities Screen
- Chat with Specialist Screen
- Family Resident Chat Screen
- Resident ID Screen
- Care Report Detail Screen
- Billing (embedded in dashboard)
- Notifications Center (common)
- Profile Screen (common)

**Group 4 — Nurse**
Color: Green
Entry: Role decision → Nurse Dashboard Screen
Screens:
- Nurse Dashboard Screen (tabs: Overview, Overdue Meds, Tasks, Alerts)
- Nurse Residents Screen → Nurse Resident Detail Screen (tabs: Medical, Meds, Vitals, Notes, Doctor Visits, Meal Plan)
- Nurse Medications Screen
- Operations View (care tasks, inventory, doctor visits)
- Medical Admin View (prescriptions, medical sessions)
- Nurse Reports Screen
- Shift Handoff Screen
- Nurse Profile Screen
- Notifications Center (common)
- Profile Screen (common)

**Group 5 — Social Specialist**
Color: Purple
Entry: Role decision → Specialist Dashboard Screen (tabs)
Screens:
- Specialist Dashboard Screen
  - Home View (overview)
  - Assessment View → Assessment Detailed Screen
  - Complaints View
  - KPI View
  - Files and Audit Trail View
  - Activities View
- Specialist Chats List Screen → Specialist Chat Detail Screen
- Notifications Center (common)
- Profile Screen (common)

**Group 6 — Admin / Facility Management**
Color: Red/Coral
Entry: Role decision → Admin Dashboard Screen (tabs)
Screens:
- Admin Dashboard Screen
  - Admin Home View (analytics)
  - Residents Management View → Admin Resident Detail Screen
  - Staff Management View → Admin Staff Detail Screen
  - Visit Approval View
  - Complaints View
  - Reports View
  - Volunteer Management View
  - AI Warnings View
  - Settings View (facility profile, billing, emergency contacts)
- Notifications Center (common)
- Profile Screen (common)

**Group 7 — Volunteer**
Color: Yellow/Gold
Entry: Role decision → Volunteer Dashboard Screen (tabs)
Screens:
- Volunteer Dashboard Screen
  - Opportunities View
  - Bookings View
  - Certificates View
  - Ratings View
  - Profile View
- Notifications Center (common)
- Profile Screen (common)

**Group 8 — Common Screens (all roles)**
Color: Light Gray
Screens (reachable from any role via drawer or settings):
- Profile Screen
- Account Settings Screen
- Notifications Center Screen
- Cloud Health Screen
- Help and Support Screen
- Privacy Screen
- About Wanas Screen

Draw these navigation flows with labeled arrows:

- Splash → [First launch?] → Onboarding → Login
- Splash → [Returning user?] → Login
- Login → [role = elderly] → Elderly Home Screen
- Login → [role = family] → Family Dashboard Screen
- Login → [role = nurse] → Nurse Dashboard Screen
- Login → [role = social_specialist] → Specialist Dashboard Screen
- Login → [role = admin] → Admin Dashboard Screen
- Login → [role = volunteer] → Volunteer Dashboard Screen
- Any dashboard → Notifications Center (via bell icon)
- Any dashboard → Profile Screen (via drawer or avatar)
- Any dashboard → Account Settings Screen (from Profile)
- Nurse Residents Screen → Nurse Resident Detail Screen → (back) → Nurse Residents Screen
- Specialist Dashboard Assessment View → Assessment Detailed Screen
- Admin Residents Management View → Admin Resident Detail Screen
- Admin Staff Management View → Admin Staff Detail Screen
- Family Dashboard → Visit Booking Screen → (submit) → Family Dashboard
- Family Dashboard → Care Report Detail Screen
- Memories Screen → Album Details Screen → Full Screen Image
- Specialist Chats List → Specialist Chat Detail Screen
- Family Dashboard → Chat with Specialist Screen
- Any screen → SOS Overlay (Elderly only, always visible)

Visual style requirements:

- Use swimlanes or clearly colored groups per role.
- Use rounded rectangles for all screen nodes.
- Use diamond shapes for branch decision points (First launch? / Role?).
- Use directed arrows with short labels: "tap", "select role", "back", "submit", "push notification", "drawer".
- Keep the layout readable — if the diagram becomes too wide, split into two rows of swimlanes.
- Title: "Wanas — App Screen Flow by Role"
- Add a note: "Navigation is imperative (MaterialPageRoute). No GoRouter or named routes. Role-based routing is handled in AppRiverpod after login."
- Do not add extra screens, flows, or services not listed above.

### Notes

This screen flow is derived from the actual Flutter screen files found under `lib/screens/`. The app uses Flutter's imperative navigation (Navigator.push / MaterialPageRoute) rather than a declarative router. Role assignment after login is handled in `AppRiverpod` based on the JWT role claim returned by the backend. The SOS overlay (`DraggableSOS`) is always rendered on top of the elderly UI stack and is not a separate screen.


## Recent System Updates (June 2026)

### 1. UI/UX Notification System Overhaul
- **Previous Mechanism:** Custom Overlay entries (`_TopAlertOverlay`) which caused `Ticker` stability issues.
- **New Mechanism:** Global `ScaffoldMessenger` Snackbars. All system notifications and alerts are now displayed as animated, professional floating popups.
- **Server Terminology Abstraction:** To improve end-user experience, all technical Google Cloud Identity Platform / Firebase Auth terminology has been abstracted. Any backend authentication or saving alerts now refer to the system simply as the "Server" (السيرفر), hiding GCP complexities from the UI.

### 2. AI Voice Assistant (Companion) Refactoring
- **Interaction Flow:** Removed the explicit "Thinking" (Wait state) visual indicator. The AI now seamlessly auto-deduces when the user has finished speaking by utilizing a 2-second voice activity detection timeout (down from 4 seconds).
- **Interruption Support:** The AI fully supports barge-in. If the user begins speaking while the AI is replying, the system instantly detects the interruption, stops the TTS playback, and resumes listening.
- **Control Interface:** The bottom control bar was simplified. It now features a single, prominent, animated "Mute" button to control the microphone, with the exit/close functionality moved to a cleaner top-right location.

### 3. Family Account Activities Scoping
- **Previous Bug:** Family accounts were unable to view the resident's activities because the API request was rigidly scoped to the `residentId`, while activities are often created as facility-wide events.
- **Resolution:** Modified the backend sync service (`backend_sync_service.dart`) to fetch activities for the Family and Resident roles without appending the `residentId` query parameter, ensuring all relevant facility activities are displayed correctly.


### 4. Cloud Infrastructure Migration to GCP
- **Migration:** The entire backend infrastructure has been migrated from AWS to Google Cloud Platform (GCP).
- **Services Replaced:** Cognito was replaced with Google Cloud Identity Platform/Firebase Auth, S3 with Google Cloud Storage, RDS with Cloud SQL, and EC2 with Google Compute Engine.
- **Authentication:** Service account credentials (`google-service-account.json`) are now used for secure backend communication with GCP services.
