# Software Requirements Specification
## Wanas - Smart Elderly Care Management System

<div align="center">

**Project Title:** Wanas  
**Document Title:** Software Requirements Specification  
**Department:** Multimedia - Web Development  
**University:** International Academy of Engineering and Media Science  
**Academic Year:** 2025/2026

**Students**

| Name |
|---|
| Amr Hani |
| Omar Eid |
| Shahd Osama |
| Farah Mohamed |

**Supervisors**

| Name |
|---|
| Dr. Nabil El Ghamry |
| Dr. Amina Fawzy |

</div>

---

## Document Control

### English

| Field | Value |
|---|---|
| Document name | Wanas Software Requirements Specification |
| File name | `Wanas_Software_Requirements_Specification.md` |
| Version | 1.0 |
| Date | 2026-06-01 |
| Prepared by | Codex, based on repository analysis |
| Reviewed by | Project supervisors and development team |
| Status | Draft for academic review |

### العربية

| البند | القيمة |
|---|---|
| اسم الوثيقة | وثيقة مواصفات متطلبات البرمجيات لنظام ونس |
| اسم الملف | `Wanas_Software_Requirements_Specification.md` |
| الإصدار | 1.0 |
| التاريخ | 2026-06-01 |
| أعدها | Codex بناء على تحليل المستودع البرمجي |
| يراجعها | المشرفون وفريق المشروع |
| الحالة | مسودة للمراجعة الأكاديمية |

---

## Table of Contents

1. [Introduction](#1-introduction)  
2. [Overall Description](#2-overall-description)  
3. [System Context](#3-system-context)  
4. [User Roles](#4-user-roles)  
5. [Functional Requirements](#5-functional-requirements)  
6. [Non-Functional Requirements](#6-non-functional-requirements)  
7. [External Interface Requirements](#7-external-interface-requirements)  
8. [User Interface Requirements](#8-user-interface-requirements)  
9. [API Requirements](#9-api-requirements)  
10. [Database Requirements](#10-database-requirements)  
11. [Authentication and Authorization Requirements](#11-authentication-and-authorization-requirements)  
12. [Business Rules](#12-business-rules)  
13. [Data Validation Requirements](#13-data-validation-requirements)  
14. [Error Handling Requirements](#14-error-handling-requirements)  
15. [Security Requirements](#15-security-requirements)  
16. [System Workflows](#16-system-workflows)  
17. [Use Cases](#17-use-cases)  
18. [Constraints](#18-constraints)  
19. [Assumptions and Dependencies](#19-assumptions-and-dependencies)  
20. [Acceptance Criteria](#20-acceptance-criteria)  
21. [Recommended Future Requirements](#21-recommended-future-requirements)  
22. [Appendices](#22-appendices)  

---

## 1. Introduction

### 1.1 Purpose

#### English

This Software Requirements Specification (SRS) defines the functional, non-functional, interface, data, security, and workflow requirements for Wanas, a smart elderly care management system developed as a university graduation project. The document is intended to provide a formal academic reference for project evaluation, implementation review, testing, and future development.

The specification is based on direct analysis of the current codebase, including Flutter source files, service classes, models, configuration files, assets, Android and web platform files, package dependencies, and existing documentation in the `docs` directory. The backend implementation source is not present in this workspace; therefore, backend details are documented from the backend contract files and route dump found under `docs/`.

#### العربية

تهدف وثيقة مواصفات متطلبات البرمجيات هذه إلى تعريف المتطلبات الوظيفية وغير الوظيفية ومتطلبات الواجهات والبيانات والأمان ومسارات العمل الخاصة بمشروع ونس، وهو نظام ذكي لإدارة رعاية المسنين تم تطويره بوصفه مشروع تخرج جامعي. تم إعداد الوثيقة لتكون مرجعا أكاديميا رسميا للتقييم والمراجعة والاختبار والتطوير المستقبلي.

تعتمد هذه الوثيقة على تحليل الكود البرمجي الحالي، بما في ذلك ملفات Flutter، وطبقة الخدمات، والنماذج، وملفات الإعداد، والأصول، وملفات المنصات، والاعتماديات، والوثائق الموجودة داخل مجلد `docs`. كود الخادم الخلفي غير موجود داخل مساحة العمل الحالية، لذلك تم توثيق تفاصيل الخلفية اعتمادا على عقود الواجهات وملف مسارات الخادم الموجودين في الوثائق.

### 1.2 Scope of the System

#### English

Wanas is a cross-platform Flutter application for elderly care facilities. It provides role-based interfaces for elderly residents, family members, nurses, social specialists, administrators, and volunteers. The system supports resident management, medication tracking, care tasks, family communication, visit management, social assessments, volunteer coordination, notifications, AI-based assistance, emergency SOS alerts, media/document upload, reporting, and accessibility settings.

The application communicates with an external GCP-hosted backend API at `https://api.helpers-tech.com`. Authentication uses Google Cloud Identity Platform / Firebase Auth and JSON Web Tokens (JWT). Data persistence is documented as Google Cloud SQL (PostgreSQL). Media and documents are uploaded through backend-generated presigned S3 URLs. Push notifications use Firebase Cloud Messaging, and realtime events use Socket.IO.

#### العربية

ونس هو تطبيق متعدد المنصات مبني باستخدام Flutter لخدمة دور رعاية المسنين. يوفر التطبيق واجهات مخصصة حسب الدور لكل من المسن، وعضو الأسرة، والممرض، والأخصائي الاجتماعي، والمدير، والمتطوع. يدعم النظام إدارة المقيمين، وتتبع الأدوية، ومهام الرعاية، وتواصل الأسرة، وإدارة الزيارات، والتقييمات الاجتماعية، وتنسيق المتطوعين، والتنبيهات، والمساعدة المعتمدة على الذكاء الاصطناعي، ونداءات الطوارئ، ورفع الملفات والوسائط، والتقارير، وإعدادات سهولة الوصول.

يتصل التطبيق بواجهة خلفية خارجية مستضافة على GCP بعنوان `https://api.helpers-tech.com`. تعتمد المصادقة على Google Cloud Identity Platform / Firebase Auth وJWT. توثق البيانات على أنها مخزنة في Google Cloud SQL (PostgreSQL)، بينما ترفع الوسائط والملفات من خلال روابط S3 مؤقتة يتم إنشاؤها من الخادم. تستخدم الإشعارات Firebase Cloud Messaging، وتستخدم الأحداث اللحظية Socket.IO.

### 1.3 Intended Audience

#### English

This SRS is intended for:

- University examiners and academic supervisors.
- The Wanas development team.
- Software testers and quality reviewers.
- Future maintainers and developers.
- Cloud, backend, and mobile engineers who may extend the project.
- Documentation reviewers preparing the graduation project book.

#### العربية

تستهدف هذه الوثيقة الفئات التالية:

- لجان التقييم والمشرفين الأكاديميين.
- فريق تطوير مشروع ونس.
- مختبري البرمجيات ومراجعي الجودة.
- المطورين المستقبليين والمسؤولين عن الصيانة.
- مهندسي السحابة والخلفية وتطبيقات الهاتف الذين قد يوسعون المشروع.
- مراجعي التوثيق المسؤولين عن إعداد كتاب مشروع التخرج.

### 1.4 Definitions, Acronyms, and Abbreviations

| Term | Definition |
|---|---|
| SRS | Software Requirements Specification |
| Wanas | Smart elderly care management application |
| Flutter | Cross-platform UI framework used for the client app |
| Riverpod | Flutter state management framework used by the app |
| JWT | JSON Web Token used for authenticated API requests |
| Google Cloud Identity Platform / Firebase Auth | Authentication and user pool service used by the backend |
| Google Cloud SQL | Relational database service documented as PostgreSQL storage |
| Google Cloud Storage (GCS) | Object storage used through presigned upload URLs |
| FCM | Firebase Cloud Messaging for mobile push notifications |
| API | Application Programming Interface |
| SOS | Emergency alert flow for residents or staff |
| RTL | Right-to-left interface direction used for Arabic UI |

### 1.5 References

| Reference | Location |
|---|---|
| Flutter source code | `lib/` |
| Application entry point | `lib/main.dart` |
| Central provider | `lib/providers/app_riverpod.dart` |
| Data models | `lib/models/app_models.dart` |
| API configuration | `lib/config/api_config.dart` |
| Backend contract | `docs/backend-contract.md` |
| Backend gap analysis | `docs/backend-gap-analysis.md` |
| Backend routes dump | `docs/backend-routes.raw.txt` |
| Mock audit | `docs/mock-audit.md` |
| Dependencies | `pubspec.yaml`, `pubspec.lock` |
| Firebase configuration | `firebase.json`, `android/app/google-services.json`, `lib/firebase_options.dart` |
| Android configuration | `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml` |
| CI configuration | `.github/workflows/flutter-ci.yml` |

### 1.6 Document Overview

#### English

The document begins with a system-level description, then defines user roles, functional requirements, non-functional requirements, interfaces, API requirements, database expectations, authentication, business rules, validation, error handling, security, workflows, use cases, constraints, assumptions, acceptance criteria, future recommendations, and appendices.

#### العربية

تبدأ الوثيقة بوصف عام للنظام، ثم تعرض أدوار المستخدمين، والمتطلبات الوظيفية، والمتطلبات غير الوظيفية، ومتطلبات الواجهات، ومتطلبات API، ومتطلبات قاعدة البيانات، والمصادقة، وقواعد العمل، والتحقق من البيانات، ومعالجة الأخطاء، والأمان، ومسارات العمل، وحالات الاستخدام، والقيود، والافتراضات، ومعايير القبول، والتوصيات المستقبلية، والملاحق.

---

## 2. Overall Description

### 2.1 Product Perspective

#### English

Wanas is a mobile-first care management application with a Flutter frontend and an external documented GCP backend. The repository contains the client application and its service integrations. It does not contain the backend implementation source. The backend surface is documented through contract and route files.

The client is organized into:

- `lib/screens`: role-based screens and dashboards.
- `lib/widgets`: reusable UI components.
- `lib/services`: API, authentication, sync, mutation, AI, notification, upload, and domain services.
- `lib/providers`: central Riverpod state provider.
- `lib/models`: client-side domain models.
- `lib/config`: backend and Cognito configuration.
- `assets`: Lottie animations, icons, fonts, and splash assets.
- Platform folders: Android, iOS, web, Windows, Linux, and macOS.

#### العربية

ونس هو تطبيق لإدارة الرعاية يعتمد أساسا على الهاتف المحمول، ويتكون من واجهة Flutter وخلفية GCP موثقة خارجية. يحتوي المستودع على تطبيق العميل وتكاملاته الخدمية، ولا يحتوي على كود الخادم الخلفي نفسه. تم توثيق سطح الخادم الخلفي من خلال ملفات العقود والمسارات.

ينظم العميل إلى شاشات حسب الأدوار، ومكونات واجهة قابلة لإعادة الاستخدام، وخدمات API ومصادقة ومزامنة وذكاء اصطناعي وإشعارات ورفع ملفات، ومزود حالة مركزي، ونماذج بيانات، وملفات إعداد، وأصول بصرية، ومجلدات خاصة بالمنصات المختلفة.

### 2.2 Product Functions

#### English

The major system functions include:

- User authentication and session restoration.
- Role-based routing and dashboards.
- Resident profile and health data management.
- Medication schedule, dose logging, overdue dose, and adherence support.
- Nurse operations, care tasks, inventory, handoff, medical sessions, prescriptions, and reports.
- Social assessment tools, resident scores, social needs, complaints, and specialist files.
- Family bridge features, visits, billing, care reports, media sharing, and messaging.
- Volunteer profile, opportunities, bookings, certificates, ratings, reviews, and document upload.
- AI companion chat, speech, recommendations, predictive alerts, smart diet, family updates, and cognitive games.
- Notifications, push token registration, realtime events, and SOS alerts.
- Accessibility settings such as font scaling, dark mode, high contrast, and biometric authentication.

#### العربية

تشمل الوظائف الرئيسية للنظام المصادقة واستعادة الجلسات، والتوجيه حسب الدور، وإدارة بيانات المقيمين والصحة، وتتبع الأدوية، وعمليات التمريض، والتقييمات الاجتماعية، وخدمات الأسرة، وإدارة المتطوعين، والذكاء الاصطناعي، والإشعارات، والأحداث اللحظية، ونداءات الطوارئ، وإعدادات سهولة الوصول.

### 2.3 User Classes and Characteristics

| User class | Characteristics |
|---|---|
| Elderly Resident | Needs simplified navigation, large readable UI, reminders, companionship, SOS access, memories, calls, and activities. |
| Family Member | Needs visibility into resident status, reports, visits, billing, media sharing, and communication with specialists. |
| Nurse | Needs operational dashboards, medication administration, vitals, resident details, care tasks, handoffs, reports, and emergency handling. |
| Social Specialist | Needs assessment tools, complaints, KPIs, resident files, audit trails, activities, and specialist chat. |
| Admin / Facility Management | Needs global facility overview, staff and resident management, visit approval, reports, settings, volunteers, and AI warnings. |
| Volunteer | Needs profile management, opportunity browsing, booking, certificates, ratings, reviews, and document upload. |

### 2.4 Operating Environment

#### English

The application is built with Flutter and Dart SDK `>=3.0.0 <4.0.0`. It targets Android, iOS, web, and desktop platforms through Flutter project folders. The Android package namespace is `com.raaya.taptaba`. The app uses Arabic RTL layout, Material 3, Cairo font assets, and portrait orientation in the main app.

The production API base URL is configured as `https://api.helpers-tech.com` with compile-time override support through `API_BASE_URL`. Google Cloud Identity Platform / Firebase Auth is configured in `us-east-1` with a documented user pool and app client. Firebase is configured for Android push notifications.

#### العربية

تم بناء التطبيق باستخدام Flutter وDart بإصدار SDK من `3.0.0` حتى أقل من `4.0.0`. يستهدف المشروع أندرويد وiOS والويب وسطح المكتب من خلال مجلدات Flutter القياسية. معرف حزمة أندرويد هو `com.raaya.taptaba`. يعتمد التطبيق على واجهة عربية من اليمين إلى اليسار، وMaterial 3، وخط Cairo، واتجاه عرض طولي.

### 2.5 Design and Implementation Constraints

| Constraint ID | Constraint |
|---|---|
| CON-001 | The client application is implemented in Flutter and Dart. |
| CON-002 | Central application state is currently concentrated in `AppRiverpod`. |
| CON-003 | Backend implementation source is not included in the current workspace. |
| CON-004 | API base URL, Cognito settings, admin registration secret, and default facility ID are configured through `ApiConfig` and compile-time environment values. |
| CON-005 | Arabic RTL UI is the primary interface direction. |
| CON-006 | Mobile push notifications are supported through Firebase Messaging on Android/iOS only. |
| CON-007 | S3 uploads depend on backend-generated presigned URLs. |
| CON-008 | Some backend endpoints are documented as needing deployment or verification in the gap analysis. |

### 2.6 Assumptions and Dependencies

#### English

The system assumes that the external backend API is reachable, Cognito is configured, JWT tokens are valid, Google Cloud SQL and S3 are available, Firebase push configuration is valid for mobile builds, and the user's device grants required permissions such as notifications, camera, contacts, microphone, biometrics, and media access.

#### العربية

يفترض النظام أن الخادم الخلفي الخارجي متاح، وأن Cognito مضبوط، وأن رموز JWT صالحة، وأن خدمات Google Cloud SQL وS3 متاحة، وأن إعدادات Firebase صحيحة للبناء المحمول، وأن جهاز المستخدم يمنح الأذونات المطلوبة مثل الإشعارات والكاميرا وجهات الاتصال والميكروفون والبصمة والوصول للوسائط.

---

## 3. System Context

### English

Wanas consists of a Flutter client application that communicates with a documented external GCP backend. Users interact with role-specific screens. The client uses `ApiClient` to call REST endpoints and attaches Bearer tokens for authenticated requests. Authentication is performed through backend auth endpoints and Google Cloud Identity Platform / Firebase Auth. Backend data is documented as stored in Google Cloud SQL (PostgreSQL). Media and documents are uploaded to Google Cloud Storage (GCS) through presigned URL workflows. Realtime events use Socket.IO, while mobile push notifications use Firebase Cloud Messaging.

```mermaid
flowchart LR
    Users[Users by Role] --> Flutter[Flutter Wanas App]
    Flutter --> State[AppRiverpod State]
    State --> Services[Flutter Service Layer]
    Services --> API[External GCP Backend API]
    API --> Cognito[Google Cloud Identity Platform / Firebase Auth]
    API --> RDS[(Google Cloud SQL (PostgreSQL))]
    API --> S3[(Google Cloud Storage (GCS) Uploads)]
    API --> AI[GCP Bedrock / Speech Services]
    API --> FCM[Firebase Cloud Messaging]
    API --> RT[Socket.IO Realtime]
    RT --> Flutter
    FCM --> Flutter
```

### العربية

يتكون نظام ونس من تطبيق Flutter يتصل بخادم GCP خارجي موثق. يتعامل المستخدمون مع شاشات مخصصة حسب الدور. يستخدم التطبيق `ApiClient` لاستدعاء الواجهات البرمجية وإرفاق رموز Bearer في الطلبات المحمية. تتم المصادقة عبر واجهات الخادم وخدمة Google Cloud Identity Platform / Firebase Auth. توثق البيانات على أنها مخزنة في PostgreSQL على Google Cloud SQL، بينما ترفع الملفات والوسائط إلى S3 عبر روابط مؤقتة. تستخدم الأحداث اللحظية Socket.IO، وتستخدم الإشعارات Firebase Cloud Messaging.

---

## 4. User Roles

### English

The following roles are explicitly found in `main.dart`, `AuthService`, and `AppRiverpod`. Cognito roles are mapped to Arabic UI roles.



#### ROLE-001 - Elderly Resident / `مسن`

- **Description:** Resident using simplified care and companionship UI.
- **Permissions:** View personal dashboard, medications, family calls, memories, activities, AI companion, SOS.
- **Main actions:** Confirm medication, view activities, play cognitive games, receive voice messages, start SOS, use AI companion.
- **Restrictions:** Should only access own resident-scoped data where backend supports resident scoping.

#### ROLE-002 - Family Member / `أسرة`

- **Description:** Relative linked to a resident.
- **Permissions:** View resident status, reports, visits, billing, media, chat.
- **Main actions:** Book visits, view care reports, upload family bridge media, chat with specialist, send reminders/messages.
- **Restrictions:** Family data should be scoped to linked resident.

#### ROLE-003 - Nurse / `ممرض`

- **Description:** Nursing care staff.
- **Permissions:** Access resident lists, vitals, medications, handoffs, reports, care tasks, operations.
- **Main actions:** Record vitals, administer medications, create notes, manage care tasks, generate reports, handle SOS.
- **Restrictions:** Cannot perform admin-only facility management unless backend role permits.

#### ROLE-004 - Social Specialist / `أخصائي اجتماعي`

- **Description:** Specialist responsible for social and psychological follow-up.
- **Permissions:** Access assessment tools, complaints, resident scores, files, KPI, family chats.
- **Main actions:** Conduct assessments, review complaints, manage social needs, view audit trails, communicate with family.
- **Restrictions:** Does not manage global facility users unless granted admin permissions.

#### ROLE-005 - Admin / Facility Management / `إدارة`

- **Description:** Facility manager or administrator.
- **Permissions:** Manage residents, staff, visits, volunteers, reports, settings, AI warnings.
- **Main actions:** Create users, approve visits, manage resident records, configure facility settings, view KPIs.
- **Restrictions:** Must be authenticated as admin; admin registration requires setup secret.

#### ROLE-006 - Volunteer / `متطوع`

- **Description:** Volunteer participant in facility activities.
- **Permissions:** Manage profile, opportunities, bookings, certificates, ratings, documents.
- **Main actions:** Browse opportunities, book sessions, upload CV/recommendation documents, view ratings/certificates.
- **Restrictions:** Cannot access resident medical data unless backend provides a specific volunteer-scoped view.


### العربية

الأدوار الموجودة بوضوح في الكود هي: المسن، الأسرة، الممرض، الأخصائي الاجتماعي، الإدارة، والمتطوع. يتم تحويل أدوار Cognito إلى مسميات عربية داخل التطبيق. لكل دور واجهة وصلاحيات ومسارات استخدام مختلفة، ويجب أن يقتصر الوصول إلى البيانات على النطاق المناسب للدور والمرفق والمقيم المرتبط.

---

## 5. Functional Requirements

### English

The following functional requirements are extracted from implemented screens, services, models, and documented backend routes.



#### FR-001 - Splash and initialization

- **Description:** The system shall show a splash screen while loading local auth state, preferences, onboarding state, and backend session data.
- **User role:** All users
- **Input:** App launch
- **Processing:** Read secure storage, restore Cognito/backend session, initialize push notifications, sync data when authenticated.
- **Output:** Splash status then onboarding/login/dashboard.
- **Priority:** High
- **Related files/modules:** `lib/main.dart`, `lib/providers/app_riverpod.dart`, `lib/screens/onboarding/splash_screen.dart`
- **Acceptance criteria:** App displays splash, then routes correctly based on onboarding and authentication state.

#### FR-002 - Onboarding flow

- **Description:** The system shall show onboarding to users who have not completed it.
- **User role:** All users
- **Input:** First app use
- **Processing:** Check `hasSeenOnboarding` from secure storage.
- **Output:** Onboarding screens or login screen.
- **Priority:** Medium
- **Related files/modules:** `onboarding_screen.dart`, `AppRiverpod`
- **Acceptance criteria:** Completing onboarding stores state and prevents repeated display.

#### FR-003 - User login

- **Description:** The system shall authenticate users through the backend `/auth/login` endpoint and store returned tokens securely.
- **User role:** All roles
- **Input:** Email/identifier and password
- **Processing:** `AuthService.login` sends credentials, parses user/roles/tokens, stores JWT and refresh token.
- **Output:** Authenticated user and role dashboard.
- **Priority:** High
- **Related files/modules:** `auth_service.dart`, `api_client.dart`, `login_screen.dart`, `AppRiverpod`
- **Acceptance criteria:** Valid credentials log in; invalid credentials show an error; tokens are saved in secure storage.

#### FR-004 - Session restoration

- **Description:** The system shall restore a previous session when valid tokens exist.
- **User role:** All roles
- **Input:** Stored JWT/refresh token
- **Processing:** Decode JWT, check expiry, refresh token if needed through Cognito.
- **Output:** Restored authenticated state or logout.
- **Priority:** High
- **Related files/modules:** `auth_service.dart`, `AppRiverpod`
- **Acceptance criteria:** Valid session opens role dashboard; expired invalid session clears auth state.

#### FR-005 - Logout

- **Description:** The system shall allow users to log out and clear authentication state.
- **User role:** All roles
- **Input:** Logout action
- **Processing:** Clear current user, API tokens, local auth keys, push token if applicable.
- **Output:** Login screen or unauthenticated state.
- **Priority:** High
- **Related files/modules:** `AppRiverpod`, `AuthService`, `PushNotificationService`
- **Acceptance criteria:** User cannot access protected screens after logout.

#### FR-006 - Self-registration

- **Description:** The system shall allow family members and volunteers to self-register when a default facility ID is configured.
- **User role:** Family, Volunteer
- **Input:** Name, email, password, role
- **Processing:** Validate facility ID, map role, call `/auth/register`.
- **Output:** Account registration request submitted.
- **Priority:** Medium
- **Related files/modules:** `register_screen.dart`, `auth_service.dart`, `AppRiverpod`, `ApiConfig`
- **Acceptance criteria:** Missing facility ID produces actionable error; valid request reaches backend.

#### FR-007 - Admin registration

- **Description:** The system shall support first admin registration using a setup secret and facility details.
- **User role:** Admin
- **Input:** Admin credentials and facility profile fields
- **Processing:** Read `ADMIN_REG_SECRET`, call `/auth/register-admin`.
- **Output:** Admin and facility setup created by backend.
- **Priority:** High
- **Related files/modules:** `admin_register_screen.dart`, `auth_service.dart`, `ApiConfig`, `AppRiverpod`
- **Acceptance criteria:** Empty setup secret blocks registration; valid data calls backend endpoint.

#### FR-008 - Role-based routing

- **Description:** The system shall route authenticated users to dashboards based on current role.
- **User role:** All roles
- **Input:** Authenticated user role
- **Processing:** Map Cognito/backend role to Arabic UI role.
- **Output:** Correct dashboard screen.
- **Priority:** High
- **Related files/modules:** `main.dart`, `AuthService`, `AppRiverpod`
- **Acceptance criteria:** Nurse, Volunteer, Resident, Specialist, Family, and Admin each land on correct dashboard.

#### FR-009 - Secure API communication

- **Description:** The system shall use one shared REST client that attaches Bearer tokens and handles JSON responses.
- **User role:** All roles
- **Input:** Service request
- **Processing:** Build headers, add token, send HTTP request, decode JSON, throw `ApiException` on error.
- **Output:** Parsed response or user-facing error.
- **Priority:** High
- **Related files/modules:** `api_client.dart`
- **Acceptance criteria:** Authenticated requests include Authorization header; timeouts/network errors are handled.

#### FR-010 - Backend data synchronization

- **Description:** The system shall load role-relevant data from the backend after login or refresh.
- **User role:** All roles
- **Input:** Authenticated session and role
- **Processing:** `BackendSyncService.load` requests residents, vitals, medications, visits, billing, reports, complaints, social, volunteer, and notification data based on role.
- **Output:** App models stored in provider state.
- **Priority:** High
- **Related files/modules:** `backend_sync_service.dart`, `AppRiverpod`
- **Acceptance criteria:** Role dashboards display synchronized backend data or clear empty/error states.

#### FR-011 - Resident management

- **Description:** The system shall allow admin/nurse/specialist views to display residents and allow admin creation/updating through backend mutations.
- **User role:** Admin, Nurse, Specialist
- **Input:** Resident fields, search/filter actions
- **Processing:** Call `/residents` endpoints; map data into `Resident` and `SpecialistResidentFile`.
- **Output:** Resident list/detail screens.
- **Priority:** High
- **Related files/modules:** `residents_service.dart`, `backend_mutation_service.dart`, `residents_management_view.dart`, `nurse_residents_screen.dart`
- **Acceptance criteria:** Resident data loads from API; create/update requests are sent to backend.

#### FR-012 - Medical information management

- **Description:** The system shall support viewing and updating resident medical information where available.
- **User role:** Admin, Nurse
- **Input:** Medical details
- **Processing:** Call `/residents/:id/medical-info` or resident patch endpoints.
- **Output:** Updated resident medical data.
- **Priority:** High
- **Related files/modules:** `backend_mutation_service.dart`, `admin_resident_detail_screen.dart`, `nurse_resident_detail_screen.dart`
- **Acceptance criteria:** Saved medical details are sent to backend and visible after sync.

#### FR-013 - Medication schedules

- **Description:** The system shall load medication schedules, dose logs, overdue doses, and adherence.
- **User role:** Resident, Family, Nurse
- **Input:** Resident scope, date filters, medication actions
- **Processing:** Call medication endpoints and map schedules/doses.
- **Output:** Medication screens, reminders, adherence data.
- **Priority:** High
- **Related files/modules:** `medications_service.dart`, `medication_adherence_service.dart`, `backend_sync_service.dart`
- **Acceptance criteria:** Medication list and dose status reflect backend data.

#### FR-014 - Dose status update

- **Description:** The system shall allow medication dose status changes.
- **User role:** Nurse, Resident where supported
- **Input:** Medication/dose ID and status
- **Processing:** Call `/medications/doses` or dose patch endpoint; refresh backend data.
- **Output:** Updated medication state.
- **Priority:** High
- **Related files/modules:** `medications_service.dart`, `AppRiverpod`, `nurse_medications_screen.dart`, `medication_screen.dart`
- **Acceptance criteria:** Dose can be marked as given/missed/skipped according to UI flow.

#### FR-015 - Local medication reminders

- **Description:** The system shall schedule local reminders for upcoming medications.
- **User role:** Resident
- **Input:** Medication schedule with time
- **Processing:** Use `NotificationService.scheduleNotification`.
- **Output:** Local device notification.
- **Priority:** Medium
- **Related files/modules:** `notification_service.dart`, `AppRiverpod`
- **Acceptance criteria:** Future medication reminders are scheduled locally when notification service is initialized.

#### FR-016 - Vitals recording

- **Description:** The system shall allow nurses to record vitals.
- **User role:** Nurse
- **Input:** Resident ID, heart rate, blood pressure, oxygen, temperature, notes
- **Processing:** Validate required data and call `/health/vitals`.
- **Output:** New vitals record and possible alerts.
- **Priority:** High
- **Related files/modules:** `health_service.dart`, `record_vitals_sheet.dart`
- **Acceptance criteria:** Successful submission stores reading through backend; invalid data shows error.

#### FR-017 - Health alerts

- **Description:** The system shall display and update health alerts.
- **User role:** Nurse, Admin, Family as scoped
- **Input:** Alert list and action
- **Processing:** Call `/health/alerts`, patch alert status.
- **Output:** Alert state updated.
- **Priority:** High
- **Related files/modules:** `health_service.dart`, `backend_sync_service.dart`, live banners
- **Acceptance criteria:** Alerts are visible and can be acknowledged/resolved where UI supports it.

#### FR-018 - Nursing notes

- **Description:** The system shall allow nursing notes to be created and viewed.
- **User role:** Nurse
- **Input:** Resident ID, content, category
- **Processing:** Call `/nursing-notes`.
- **Output:** Note appears in resident/nursing context.
- **Priority:** High
- **Related files/modules:** `backend_mutation_service.dart`, `backend_sync_service.dart`, `nurse_resident_detail_screen.dart`
- **Acceptance criteria:** Notes are persisted and displayed after sync.

#### FR-019 - Shift handoff

- **Description:** The system shall support shift handoff summaries and notes.
- **User role:** Nurse
- **Input:** Handoff summary and related residents/tasks
- **Processing:** Call `/handoffs`; optionally generate AI summary.
- **Output:** Handoff record and summary.
- **Priority:** High
- **Related files/modules:** `shift_handoff_screen.dart`, `backend_mutation_service.dart`, `AiService`
- **Acceptance criteria:** Nurse can create or view handoff information.

#### FR-020 - Care task management

- **Description:** The system shall manage care tasks and completion status.
- **User role:** Nurse, Admin
- **Input:** Task fields and completion action
- **Processing:** Call `/care-tasks`, complete/reopen/delete endpoints.
- **Output:** Updated care task list.
- **Priority:** High
- **Related files/modules:** `backend_mutation_service.dart`, `operations_view.dart`, `backend_sync_service.dart`
- **Acceptance criteria:** Tasks can be created, completed, reopened, and deleted where permitted.

#### FR-021 - Inventory management

- **Description:** The system shall support inventory items and stock updates.
- **User role:** Nurse, Admin
- **Input:** Item fields, stock value
- **Processing:** Call `/inventory` endpoints.
- **Output:** Updated inventory and low-stock alerts.
- **Priority:** Medium
- **Related files/modules:** `backend_mutation_service.dart`, `operations_view.dart`, `backend_sync_service.dart`
- **Acceptance criteria:** Low stock items are displayed and stock updates reach backend.

#### FR-022 - Doctor visits and medical sessions

- **Description:** The system shall support doctor visits, medical sessions, prescriptions, and meal plans.
- **User role:** Nurse, Admin
- **Input:** Medical operational fields
- **Processing:** Call `/doctor-visits`, `/medical-sessions`, `/prescriptions`, `/meal-plans`.
- **Output:** Updated medical operations data.
- **Priority:** Medium
- **Related files/modules:** `backend_mutation_service.dart`, `medical_admin_view.dart`, `backend_sync_service.dart`
- **Acceptance criteria:** Records can be created/read/updated/deleted according to backend support.

#### FR-023 - Nursing reports

- **Description:** The system shall preview, export, configure, send, and view nursing report history.
- **User role:** Nurse, Admin, Family for preview
- **Input:** Report filters/settings
- **Processing:** Call `/reports/nursing/*`; fallback local PDF generation exists.
- **Output:** Report preview/export/history.
- **Priority:** High
- **Related files/modules:** `nursing_reports_service.dart`, `nurse_reports_screen.dart`, `pdf_service.dart`
- **Acceptance criteria:** Reports load from backend; local PDF fallback is available when export fails.

#### FR-024 - Social assessment tools

- **Description:** The system shall load assessment tools and questions from backend.
- **User role:** Social Specialist
- **Input:** Tool ID, resident ID, assessment answers
- **Processing:** Call `/social/assessment-tools`, `/social/assessment-tools/:id/questions`, `/social/assessments`.
- **Output:** Assessment form and saved assessment.
- **Priority:** High
- **Related files/modules:** `social_service.dart`, `assessment_view.dart`, `assessment_detailed_screen.dart`
- **Acceptance criteria:** Questions come from backend; missing questions show setup/empty state.

#### FR-025 - GDS questions

- **Description:** The system shall support GDS question loading from backend.
- **User role:** Social Specialist
- **Input:** Assessment scale
- **Processing:** Call `/social/gds-questions`.
- **Output:** Question set for assessment.
- **Priority:** Medium
- **Related files/modules:** `social_service.dart`, `backend-contract.md`
- **Acceptance criteria:** GDS questions are not hardcoded and depend on backend data.

#### FR-026 - Complaints management

- **Description:** The system shall support complaint creation, listing, and status update.
- **User role:** Family, Resident, Social Specialist, Admin
- **Input:** Complaint category, subject, description, priority
- **Processing:** Call `/complaints`; patch status where permitted.
- **Output:** Complaint record and timeline/status view.
- **Priority:** High
- **Related files/modules:** `complaints_service.dart`, `submit_complaint_sheet.dart`, `complaints_view.dart`
- **Acceptance criteria:** Complaints can be submitted and reviewed through backend.

#### FR-027 - Family bridge visits

- **Description:** The system shall allow families to book visits and admins/staff to approve or reject visits.
- **User role:** Family, Admin
- **Input:** Visit date/time/type/resident
- **Processing:** Call `/family-bridge/visits`, status endpoint.
- **Output:** Visit booking and approval state.
- **Priority:** High
- **Related files/modules:** `family_bridge_service.dart`, `visit_booking_screen.dart`, `visit_approval_view.dart`
- **Acceptance criteria:** Visit appears in family/admin screens and status can be changed where allowed.

#### FR-028 - Family bridge media

- **Description:** The system shall allow family media upload and display confirmed media.
- **User role:** Family, Resident
- **Input:** Image/media file and metadata
- **Processing:** Request presigned upload, PUT to S3, confirm backend record.
- **Output:** Media appears in family bridge/memories.
- **Priority:** High
- **Related files/modules:** `family_media_service.dart`, `family_bridge_screen.dart`, `s3_upload_helper.dart`
- **Acceptance criteria:** Upload completes through S3 and confirmed media is available after sync.

#### FR-029 - Billing overview

- **Description:** The system shall display billing data and payment instructions.
- **User role:** Family, Admin
- **Input:** Resident scope, billing settings
- **Processing:** Call `/billing` and `/admin/settings/billing`.
- **Output:** Bills and facility payment instructions.
- **Priority:** Medium
- **Related files/modules:** `backend_sync_service.dart`, `facility_settings_service.dart`, `family_dashboard_screen.dart`
- **Acceptance criteria:** Billing screen shows backend data or configured empty state.

#### FR-030 - Memories

- **Description:** The system shall display and manage memories.
- **User role:** Resident, Family, Specialist
- **Input:** Memory/media data
- **Processing:** Call `/memories` and family media endpoints.
- **Output:** Resident memory wall/albums.
- **Priority:** Medium
- **Related files/modules:** `backend_sync_service.dart`, `backend_mutation_service.dart`, `memories_screen.dart`
- **Acceptance criteria:** Memories are loaded from backend or media records and displayed in resident UI.

#### FR-031 - Family and specialist messaging

- **Description:** The system shall support text chat and unread counts.
- **User role:** Family, Social Specialist
- **Input:** Recipient ID, message body
- **Processing:** Call `/messages`, `/messages/inbox`, `/messages/thread/:id`, mark-read endpoint.
- **Output:** Message thread and inbox.
- **Priority:** High
- **Related files/modules:** `messages_service.dart`, `chat_with_specialist_screen.dart`, `specialist_chat_detail_screen.dart`
- **Acceptance criteria:** Text messages send successfully; media-only messages are not treated as implemented backend chat media.

#### FR-032 - Video call state

- **Description:** The system shall support creating and updating video call state through backend endpoints.
- **User role:** Family, Resident, Staff
- **Input:** Call participant/room metadata
- **Processing:** Call `/video-calls`, active/history/status endpoints.
- **Output:** Active call state or history.
- **Priority:** Medium
- **Related files/modules:** `video_call_service.dart`, `video_call_overlay.dart`
- **Acceptance criteria:** Active call state can be created/read/updated where backend is available.

#### FR-033 - Voice messages

- **Description:** The system shall support voice message upload and playback.
- **User role:** Family, Resident
- **Input:** Audio file or voice message metadata
- **Processing:** Call `/voice-messages/upload`; upload to S3 if URL returned.
- **Output:** Voice message available for playback.
- **Priority:** Medium
- **Related files/modules:** `voice_message_service.dart`, `voice_messages_playback_screen.dart`
- **Acceptance criteria:** Uploaded voice message is stored and listed through backend.

#### FR-034 - Emergency SOS

- **Description:** The system shall allow SOS alerts and active emergency handling.
- **User role:** Resident, Nurse, Family/Admin as receivers
- **Input:** Resident ID, triggeredBy, location, notes
- **Processing:** Call `/emergency/sos`, list active alerts, resolve alert.
- **Output:** SOS alert, realtime event, notification.
- **Priority:** High
- **Related files/modules:** `emergency_service.dart`, `draggable_sos.dart`, `nav_wrapper.dart`, `nurse_dashboard_screen.dart`
- **Acceptance criteria:** SOS sends supported backend fields and creates visible alert state.

#### FR-035 - Notifications center

- **Description:** The system shall list notifications, mark as read, create where supported, and clear user notifications.
- **User role:** All roles
- **Input:** User ID, notification action
- **Processing:** Call `/notifications` endpoints.
- **Output:** Notification center and bell indicator.
- **Priority:** High
- **Related files/modules:** `notifications_api_service.dart`, `notifications_center_screen.dart`, `taptaba_bell.dart`
- **Acceptance criteria:** Notifications load and read state changes persist through backend.

#### FR-036 - Push token registration

- **Description:** The system shall register and remove FCM tokens.
- **User role:** Mobile users
- **Input:** FCM device token
- **Processing:** Initialize Firebase, request permissions, send token to backend.
- **Output:** Backend push token record.
- **Priority:** High
- **Related files/modules:** `push_notification_service.dart`, `firebase_options.dart`
- **Acceptance criteria:** Token is sent to `/notifications/push-tokens` on supported platforms.

#### FR-037 - Realtime updates

- **Description:** The system shall connect to Socket.IO for live events.
- **User role:** Authenticated users
- **Input:** Facility ID and user ID
- **Processing:** Connect to `/realtime`, subscribe to events.
- **Output:** Live notifications/messages/vitals/SOS updates.
- **Priority:** Medium
- **Related files/modules:** `realtime_service.dart`, live banner widgets
- **Acceptance criteria:** Realtime stream emits events for supported event types.

#### FR-038 - AI companion chat

- **Description:** The system shall provide AI chat for residents.
- **User role:** Resident
- **Input:** Text message, optional context/media
- **Processing:** Call `/ai/chat`; store/display conversation history.
- **Output:** AI response with sentiment/mode/disclaimer.
- **Priority:** High
- **Related files/modules:** `ai_service.dart`, `ai_companion_chat.dart`, `AppRiverpod`
- **Acceptance criteria:** User can send text and receive AI response.

#### FR-039 - AI speech

- **Description:** The system shall support text-to-speech output where backend speech endpoint is available.
- **User role:** Resident
- **Input:** Text and voice configuration
- **Processing:** Call `/ai/speech` or use local TTS where implemented.
- **Output:** Audio/base64 or spoken output.
- **Priority:** Medium
- **Related files/modules:** `ai_service.dart`, `ai_companion_chat.dart`, `flutter_tts`
- **Acceptance criteria:** Voice assistant seamlessly auto-deduces speech completion within 2 seconds without a visual thinking state, featuring a single dedicated mute button for mic control.

#### FR-040 - AI recommendations and alerts

- **Description:** The system shall support AI recommendations, predictive health alerts, smart diet, shift summaries, family updates, cognitive game, and voice sentiment endpoints.
- **User role:** Resident, Nurse, Family, Specialist
- **Input:** Resident ID, notes, tasks, medical info, voice input
- **Processing:** Call relevant `/ai/*` endpoints, with local fallback only where code implements it.
- **Output:** AI-generated recommendation, plan, summary, update, game response, or sentiment.
- **Priority:** Medium
- **Related files/modules:** `ai_service.dart`, `ai_insights_panel.dart`, provider methods
- **Acceptance criteria:** Supported AI screens call backend and show returned results or safe fallback/empty state.

#### FR-041 - Volunteer profile

- **Description:** The system shall display and update volunteer profile information.
- **User role:** Volunteer
- **Input:** Profile fields
- **Processing:** Call `/volunteers/profile`.
- **Output:** Updated volunteer profile.
- **Priority:** High
- **Related files/modules:** `volunteer_dashboard_screen.dart`, `profile_view.dart`, `backend_mutation_service.dart`
- **Acceptance criteria:** Profile data can be loaded and saved through backend.

#### FR-042 - Volunteer opportunities

- **Description:** The system shall list, create, update, delete, and book volunteer opportunities where permitted.
- **User role:** Volunteer, Admin
- **Input:** Opportunity and booking fields
- **Processing:** Call `/volunteers/opportunities`, `/volunteers/bookings`.
- **Output:** Opportunities and bookings.
- **Priority:** High
- **Related files/modules:** `opportunities_view.dart`, `bookings_view.dart`, `backend_mutation_service.dart`
- **Acceptance criteria:** Volunteer can browse/book; admin can manage opportunities where UI permits.

#### FR-043 - Volunteer certificates, ratings, and reviews

- **Description:** The system shall display volunteer certificates, ratings, and reviews and allow reviews where supported.
- **User role:** Volunteer, Admin/Resident where supported
- **Input:** Review/rating data
- **Processing:** Call `/volunteers/certificates`, `/ratings`, `/reviews`.
- **Output:** Ratings/certificates/reviews views.
- **Priority:** Medium
- **Related files/modules:** `certificates_view.dart`, `ratings_view.dart`, `backend_sync_service.dart`
- **Acceptance criteria:** Volunteer dashboard displays backend achievements and feedback.

#### FR-044 - Volunteer documents and public profile link

- **Description:** The system shall upload volunteer documents to S3 and request public profile link generation.
- **User role:** Volunteer
- **Input:** CV/recommendation document file
- **Processing:** Request upload URL, PUT to S3, confirm, call public-link endpoint.
- **Output:** Stored document and public profile URL.
- **Priority:** Medium
- **Related files/modules:** `volunteer_documents_service.dart`, `edit_profile_sheet.dart`, `s3_upload_helper.dart`
- **Acceptance criteria:** Upload uses backend/S3, not local simulation.

#### FR-045 - Profile image upload

- **Description:** The system shall upload resident and staff profile images using presigned S3 flow.
- **User role:** Admin, Staff
- **Input:** Image file
- **Processing:** Request presigned URL, upload to S3, confirm backend.
- **Output:** Updated image URL.
- **Priority:** Medium
- **Related files/modules:** `profile_image_service.dart`, `admin_resident_detail_screen.dart`, `admin_staff_detail_screen.dart`
- **Acceptance criteria:** Backend stores image URL after confirmation.

#### FR-046 - Facility settings

- **Description:** The system shall load/update facility emergency contacts, billing settings, and facility profile.
- **User role:** Admin, Nurse/Family as consumers
- **Input:** Facility setting fields
- **Processing:** Call `/admin/settings/*`.
- **Output:** Settings displayed in dashboards and reports.
- **Priority:** High
- **Related files/modules:** `facility_settings_service.dart`, `admin_settings_view.dart`, `family_dashboard_screen.dart`
- **Acceptance criteria:** Admin can update settings and consumers see configured values after sync.

#### FR-047 - Facility search and inquiry

- **Description:** The system shall allow public facility search and inquiry submission.
- **User role:** Guest / Family prospect
- **Input:** Search filters, inquiry fields
- **Processing:** Call `/facilities/search` and `/facility-inquiries`.
- **Output:** Search results and inquiry record.
- **Priority:** Low
- **Related files/modules:** `facility_inquiry_service.dart`, `login_screen.dart`
- **Acceptance criteria:** Guest inquiry reaches backend instead of mock result.

#### FR-048 - User preferences

- **Description:** The system shall persist user preferences such as accessibility or display settings where supported.
- **User role:** Authenticated users
- **Input:** Preference values
- **Processing:** Call `/user-preferences/me`.
- **Output:** Saved preferences.
- **Priority:** Medium
- **Related files/modules:** `user_preferences_service.dart`, `AppRiverpod`
- **Acceptance criteria:** Preferences are read and updated through backend when available.

#### FR-049 - User progress and gamification

- **Description:** The system shall track points, badges, and progress.
- **User role:** Resident
- **Input:** Points/action data
- **Processing:** Call `/user-progress/me` and `/user-progress/points`; store local earned badge state.
- **Output:** Updated points/badges/progress.
- **Priority:** Medium
- **Related files/modules:** `user_progress_service.dart`, `AppRiverpod`, `activities_screen.dart`
- **Acceptance criteria:** Resident progress updates and badge notifications are shown.

#### FR-050 - Accessibility controls

- **Description:** The system shall allow font scaling, high contrast, dark mode, and optional biometric setting.
- **User role:** All users
- **Input:** Accessibility settings
- **Processing:** Update provider state and persist preferences where supported.
- **Output:** Adjusted UI presentation.
- **Priority:** High
- **Related files/modules:** `accessibility_dialog.dart`, `AppRiverpod`, `biometric_service.dart`
- **Acceptance criteria:** UI reacts to selected accessibility options.

#### FR-051 - Cloud health screen

- **Description:** The system shall display health checks for backend, Cognito, database, and AI endpoints.
- **User role:** Admin/technical users
- **Input:** Refresh action
- **Processing:** Call health/auth/AI/resident endpoints.
- **Output:** Service status cards.
- **Priority:** Low
- **Related files/modules:** `cloud_health_screen.dart`
- **Acceptance criteria:** Status screen reports success/failure for configured services.

#### FR-052 - PDF generation

- **Description:** The system shall generate local PDF reports where implemented.
- **User role:** Nurse, Family
- **Input:** Report data
- **Processing:** Use `pdf` and `printing` packages.
- **Output:** Printable/exportable PDF.
- **Priority:** Medium
- **Related files/modules:** `pdf_service.dart`, `nurse_reports_screen.dart`
- **Acceptance criteria:** PDF can be generated locally when backend export is unavailable.


### العربية

تعرض المتطلبات الوظيفية السابقة الوظائف المنفذة أو المرتبطة بوضوح بالكود والوثائق: المصادقة، استعادة الجلسات، التوجيه حسب الدور، مزامنة البيانات، إدارة المقيمين، الأدوية، الصحة، التمريض، التقارير، التقييمات الاجتماعية، الشكاوى، الأسرة، الزيارات، الفواتير، الذكريات، الرسائل، الطوارئ، الإشعارات، الذكاء الاصطناعي، المتطوعين، رفع الملفات، إعدادات المرفق، وسهولة الوصول. تم استبعاد أي ميزة غير مثبتة في الكود أو الوثائق من المتطلبات المنفذة ووضعها لاحقا ضمن التوصيات المستقبلية عند الحاجة.

---

## 6. Non-Functional Requirements

### English



#### NFR-001 - Performance

- **Description:** The app shall avoid blocking UI while loading backend data.
- **Measurement or acceptance criteria:** Long-running loads display splash/loading/empty/error states; HTTP requests use configured timeout.
- **Priority:** High

#### NFR-002 - Performance

- **Description:** Initial session restore should complete within an acceptable startup period.
- **Measurement or acceptance criteria:** Existing sync timeout is 8 seconds for startup backend sync.
- **Priority:** High

#### NFR-003 - Security

- **Description:** Authentication tokens shall be stored securely on device.
- **Measurement or acceptance criteria:** Tokens are stored using `FlutterSecureStorage`, not plain preferences.
- **Priority:** High

#### NFR-004 - Security

- **Description:** API requests to protected endpoints shall use Bearer JWT authentication.
- **Measurement or acceptance criteria:** `ApiClient` injects Authorization header when auth is enabled.
- **Priority:** High

#### NFR-005 - Security

- **Description:** Admin bootstrapping shall require a setup secret.
- **Measurement or acceptance criteria:** `ADMIN_REG_SECRET` must be configured before admin registration.
- **Priority:** High

#### NFR-006 - Usability

- **Description:** The interface shall support Arabic RTL layout.
- **Measurement or acceptance criteria:** `MaterialApp` locale and `Directionality` use Arabic RTL.
- **Priority:** High

#### NFR-007 - Accessibility

- **Description:** The app shall provide readable UI for elderly users.
- **Measurement or acceptance criteria:** Font scaling, high contrast, dark mode, large resident UI controls, and SOS control are available.
- **Priority:** High

#### NFR-008 - Reliability

- **Description:** Network errors and timeouts shall not crash the app.
- **Measurement or acceptance criteria:** `ApiClient` catches `SocketException` and `TimeoutException` and throws controlled `ApiException`.
- **Priority:** High

#### NFR-009 - Availability

- **Description:** Core live data depends on backend availability.
- **Measurement or acceptance criteria:** App shows empty or error states when backend fails; no full offline-first cache is implemented.
- **Priority:** Medium

#### NFR-010 - Scalability

- **Description:** Backend-facing services shall be modular by domain.
- **Measurement or acceptance criteria:** Service classes exist per major domain under `lib/services`.
- **Priority:** Medium

#### NFR-011 - Maintainability

- **Description:** Shared UI and API concerns shall be separated from screen code.
- **Measurement or acceptance criteria:** Reusable widgets and service classes are separated into `lib/widgets` and `lib/services`.
- **Priority:** Medium

#### NFR-012 - Portability

- **Description:** The Flutter codebase shall support multiple platforms.
- **Measurement or acceptance criteria:** Project includes Android, iOS, web, Windows, Linux, and macOS folders.
- **Priority:** Medium

#### NFR-013 - Compatibility

- **Description:** Push notification logic shall run only on supported platforms.
- **Measurement or acceptance criteria:** Firebase Messaging initialization skips web/unsupported desktop platforms.
- **Priority:** High

#### NFR-014 - Localization

- **Description:** The current product shall prioritize Arabic language and RTL behavior.
- **Measurement or acceptance criteria:** Arabic UI strings and Cairo font are configured.
- **Priority:** High

#### NFR-015 - Observability

- **Description:** Backend and cloud health should be visible to technical/admin users.
- **Measurement or acceptance criteria:** Cloud health screen exists and calls service checks.
- **Priority:** Low

#### NFR-016 - Data Integrity

- **Description:** Mutations should refresh backend data after successful writes.
- **Measurement or acceptance criteria:** Provider calls `syncBackendData()` after many backend mutations.
- **Priority:** Medium

#### NFR-017 - File Upload Safety

- **Description:** File uploads shall use server-generated presigned URLs rather than embedding GCP credentials in the client.
- **Measurement or acceptance criteria:** S3 helper uses presigned URLs returned by backend.
- **Priority:** High

#### NFR-018 - Build Reliability

- **Description:** Continuous integration shall execute Flutter tests.
- **Measurement or acceptance criteria:** `.github/workflows/flutter-ci.yml` runs `flutter pub get` and `flutter test`.
- **Priority:** Medium


### العربية

تركز المتطلبات غير الوظيفية على الأداء، والأمان، وقابلية الاستخدام، والاعتمادية، والتوافر، وقابلية التوسع، وسهولة الصيانة، وقابلية النقل، والتوافق، وسهولة الوصول، والتوطين. يلتزم التطبيق بتخزين آمن للرموز، واتصال API موحد، وواجهة عربية من اليمين إلى اليسار، وإعدادات وصول مناسبة لكبار السن، ومعالجة أخطاء الشبكة، وفصل نسبي بين الشاشات والخدمات والمكونات.

---

## 7. External Interface Requirements

### 7.1 User Interfaces

#### English

The system exposes Flutter screens grouped by role. All screens use Arabic RTL direction. Shared navigation is implemented through `TaptabaScaffold`, `TaptabaDrawer`, role-specific bottom navigation bars, and direct `MaterialPageRoute` navigation for details and sub-screens.

#### العربية

يعرض النظام واجهات Flutter مجمعة حسب الدور. تستخدم الشاشات اتجاه اللغة العربية من اليمين إلى اليسار. يتم تنفيذ التنقل من خلال الهيكل الموحد والقائمة الجانبية وأشرطة التنقل السفلية الخاصة بالأدوار والتنقل المباشر بين الشاشات الفرعية.

### 7.2 Software Interfaces

| Interface | Description | Related files |
|---|---|---|
| Backend REST API | External API at `https://api.helpers-tech.com`. | `api_client.dart`, service classes, `docs/backend-contract.md` |
| Google Cloud Identity Platform / Firebase Auth | Authentication, JWT claims, refresh token flow. | `auth_service.dart`, `api_config.dart` |
| Google Cloud Storage (GCS) | Presigned upload target for media/documents/images. | `s3_upload_helper.dart`, upload services |
| GCP Bedrock / AI backend | AI chat, recommendations, predictive alerts, speech and summaries. | `ai_service.dart` |
| Firebase Cloud Messaging | Push notifications on Android/iOS. | `push_notification_service.dart`, `firebase_options.dart` |
| Socket.IO | Realtime live events. | `realtime_service.dart` |
| Device APIs | Contacts, camera/gallery, media, microphone, local auth, notifications, TTS/STT. | `pubspec.yaml`, provider/widgets/services |

### 7.3 Hardware Interfaces

| Hardware interface | Usage |
|---|---|
| Mobile camera/gallery | Image and media selection for uploads and memories. |
| Microphone | Speech-to-text, voice assistant, audio/voice features. |
| Speaker/audio output | TTS and voice message playback. |
| Biometric sensor | Optional biometric login restoration. |
| Notifications subsystem | Medication reminders, FCM/local notifications. |
| Contacts storage | Family contact support where used. |

### 7.4 Communication Interfaces

| Interface | Protocol |
|---|---|
| Backend REST API | HTTPS JSON |
| Cognito refresh | HTTPS Google Cloud Identity Platform / Firebase Auth API |
| S3 presigned uploads | HTTPS PUT |
| Realtime events | Socket.IO WebSocket/polling |
| Push notifications | Firebase Cloud Messaging |

### العربية

تعتمد واجهات النظام الخارجية على واجهة REST عبر HTTPS، وخدمة Cognito للمصادقة، وS3 لرفع الملفات، وخدمات الذكاء الاصطناعي من خلال الخادم الخلفي، وFirebase للإشعارات، وSocket.IO للأحداث اللحظية، وواجهات الجهاز مثل الكاميرا والميكروفون والبصمة والإشعارات.

---

## 8. User Interface Requirements

### English



#### UI-001 - Splash Screen

- **Purpose:** Display startup/loading state.
- **User role:** All
- **Main UI elements:** Logo, status text, animation.
- **Inputs:** App launch.
- **Outputs:** Transition to onboarding/login/dashboard.
- **Navigation flow:** `main.dart` home resolver.
- **Validation rules:** None.
- **Related file:** `screens/onboarding/splash_screen.dart`

#### UI-002 - Onboarding Screen

- **Purpose:** Introduce app before first use.
- **User role:** All
- **Main UI elements:** Pages, next/complete controls.
- **Inputs:** User navigation.
- **Outputs:** `hasSeenOnboarding` saved.
- **Navigation flow:** Splash -> Onboarding -> Login.
- **Validation rules:** None.
- **Related file:** `screens/onboarding/onboarding_screen.dart`

#### UI-003 - Login Screen

- **Purpose:** Authenticate user and guest facility inquiry.
- **User role:** All/Guest
- **Main UI elements:** Email/password inputs, login button, register navigation, inquiry controls.
- **Inputs:** Credentials/search/inquiry.
- **Outputs:** Auth state or inquiry response.
- **Navigation flow:** Login -> role dashboard.
- **Validation rules:** Required credentials; backend errors displayed.
- **Related file:** `screens/auth/login_screen.dart`

#### UI-004 - Register Screen

- **Purpose:** Self-register family or volunteer users.
- **User role:** Family, Volunteer
- **Main UI elements:** Role selector, name/email/password fields, password strength.
- **Inputs:** Registration fields.
- **Outputs:** Registration request.
- **Navigation flow:** Login -> Register -> Login.
- **Validation rules:** Required facility ID and valid fields.
- **Related file:** `screens/auth/register_screen.dart`

#### UI-005 - Admin Register Screen

- **Purpose:** Bootstrap admin and facility.
- **User role:** Admin
- **Main UI elements:** Admin fields, facility fields, amenities.
- **Inputs:** Admin/facility details.
- **Outputs:** Admin registration request.
- **Navigation flow:** Login/Register path.
- **Validation rules:** Setup secret required through config.
- **Related file:** `screens/auth/admin_register_screen.dart`

#### UI-006 - Forgot Password Screen

- **Purpose:** Start password reset.
- **User role:** All
- **Main UI elements:** Email/code/new password fields.
- **Inputs:** Email, code, new password.
- **Outputs:** Password reset request.
- **Navigation flow:** Login -> Forgot Password.
- **Validation rules:** Required email/code/password.
- **Related file:** `screens/auth/forgot_password_screen.dart`

#### UI-007 - Resident Dashboard

- **Purpose:** Main resident experience.
- **User role:** Elderly Resident
- **Main UI elements:** Home, medication, calls, memories, activities tabs, AI button, SOS.
- **Inputs:** Tab taps, actions.
- **Outputs:** Resident data and interactions.
- **Navigation flow:** Role routing -> `NavWrapper`.
- **Validation rules:** Role must be authenticated resident.
- **Related file:** `nav_wrapper.dart`, `screens/elderly/*`

#### UI-008 - Resident Home

- **Purpose:** Resident overview and quick actions.
- **User role:** Elderly Resident
- **Main UI elements:** Greeting, medication/activity cards, AI and navigation cards.
- **Inputs:** Taps and quick actions.
- **Outputs:** Selected tab/screen.
- **Navigation flow:** Resident dashboard tab.
- **Validation rules:** Data must be scoped.
- **Related file:** `screens/elderly/home_screen.dart`

#### UI-009 - Resident Medication

- **Purpose:** View and confirm medication reminders.
- **User role:** Elderly Resident
- **Main UI elements:** Medication cards, status controls.
- **Inputs:** Medication confirmation.
- **Outputs:** Updated dose state.
- **Navigation flow:** Resident dashboard tab.
- **Validation rules:** Medication ID required.
- **Related file:** `screens/elderly/medication_screen.dart`

#### UI-010 - Resident Calls

- **Purpose:** Family contact and call interface.
- **User role:** Elderly Resident
- **Main UI elements:** Contact cards, video/voice actions.
- **Inputs:** Contact/call action.
- **Outputs:** Call or external link.
- **Navigation flow:** Resident dashboard tab.
- **Validation rules:** Permissions/network required.
- **Related file:** `screens/elderly/calls_screen.dart`

#### UI-011 - Resident Memories

- **Purpose:** View memories, albums, voice messages.
- **User role:** Elderly Resident
- **Main UI elements:** Albums, images, memory cards, voice message links.
- **Inputs:** Album/message selection.
- **Outputs:** Memory detail/playback.
- **Navigation flow:** Resident dashboard tab and details.
- **Validation rules:** Media availability.
- **Related file:** `screens/elderly/memories_screen.dart`

#### UI-012 - Resident Activities

- **Purpose:** Activities and gamification.
- **User role:** Elderly Resident
- **Main UI elements:** Activity cards, badges, progress indicators.
- **Inputs:** Activity selection.
- **Outputs:** Points/badges/progress.
- **Navigation flow:** Resident dashboard tab.
- **Validation rules:** Activity exists.
- **Related file:** `screens/elderly/activities_screen.dart`

#### UI-013 - Cognitive Games

- **Purpose:** Play AI-supported cognitive game.
- **User role:** Elderly Resident
- **Main UI elements:** Game prompts, input, score/feedback.
- **Inputs:** User game input.
- **Outputs:** AI/game result.
- **Navigation flow:** Resident screen navigation.
- **Validation rules:** Input required.
- **Related file:** `screens/elderly/cognitive_games_screen.dart`

#### UI-014 - AI Companion Chat

- **Purpose:** Text/voice AI companion.
- **User role:** Elderly Resident
- **Main UI elements:** Chat bubbles, input, file picker, mic screen.
- **Inputs:** Text/voice/file.
- **Outputs:** AI response and speech.
- **Navigation flow:** AI center button.
- **Validation rules:** Message or media required.
- **Related file:** `widgets/ai_companion_chat.dart`

#### UI-015 - Family Dashboard

- **Purpose:** Family overview and navigation.
- **User role:** Family
- **Main UI elements:** Home, care, visits, billing, reports, chat/media actions.
- **Inputs:** Tab actions and forms.
- **Outputs:** Resident status, visits, bills, reports.
- **Navigation flow:** Role routing -> Family Dashboard.
- **Validation rules:** Linked resident expected.
- **Related file:** `screens/family/family_dashboard_screen.dart`

#### UI-016 - Visit Booking

- **Purpose:** Book visit.
- **User role:** Family
- **Main UI elements:** Date/time/type inputs.
- **Inputs:** Visit details.
- **Outputs:** Visit request.
- **Navigation flow:** Family dashboard -> Visit Booking.
- **Validation rules:** Required visit data.
- **Related file:** `screens/family/visit_booking_screen.dart`

#### UI-017 - Family Bridge

- **Purpose:** Upload and view family media.
- **User role:** Family
- **Main UI elements:** Upload buttons, progress, media cards.
- **Inputs:** File/image/title/type.
- **Outputs:** Media upload state.
- **Navigation flow:** Family dashboard -> Bridge.
- **Validation rules:** Resident link required.
- **Related file:** `screens/family/family_bridge_screen.dart`

#### UI-018 - Family Activities

- **Purpose:** View resident activities.
- **User role:** Family
- **Main UI elements:** Activity cards and filters.
- **Inputs:** Selection/filter.
- **Outputs:** Activity details.
- **Navigation flow:** Family dashboard.
- **Validation rules:** None explicit.
- **Related file:** `screens/family/family_activities_screen.dart`

#### UI-019 - Chat with Specialist

- **Purpose:** Family specialist conversation.
- **User role:** Family
- **Main UI elements:** Thread list/message input.
- **Inputs:** Message body.
- **Outputs:** Sent/received messages.
- **Navigation flow:** Family dashboard -> Chat.
- **Validation rules:** Text required for backend chat.
- **Related file:** `screens/family/chat_with_specialist_screen.dart`

#### UI-020 - Care Report Detail

- **Purpose:** Display care report details.
- **User role:** Family
- **Main UI elements:** Report sections, metrics, recommendations.
- **Inputs:** Report selection.
- **Outputs:** Detailed report.
- **Navigation flow:** Family dashboard -> report detail.
- **Validation rules:** Report exists.
- **Related file:** `screens/family/care_report_detail_screen.dart`

#### UI-021 - Nurse Dashboard

- **Purpose:** Nurse operational home.
- **User role:** Nurse
- **Main UI elements:** Home, residents, operations, medical admin, reports tabs, SOS.
- **Inputs:** Tab/action input.
- **Outputs:** Nurse operational views.
- **Navigation flow:** Role routing -> Nurse Dashboard.
- **Validation rules:** Nurse role required.
- **Related file:** `screens/nurse/nurse_dashboard_screen.dart`

#### UI-022 - Nurse Residents

- **Purpose:** List and filter residents.
- **User role:** Nurse
- **Main UI elements:** Filters, resident cards, detail navigation.
- **Inputs:** Search/filter/tap.
- **Outputs:** Resident list/detail.
- **Navigation flow:** Nurse dashboard tab.
- **Validation rules:** Data loaded.
- **Related file:** `screens/nurse/nurse_residents_screen.dart`

#### UI-023 - Nurse Resident Detail

- **Purpose:** View resident medical detail.
- **User role:** Nurse
- **Main UI elements:** Profile, vitals, notes, medications.
- **Inputs:** Detail actions.
- **Outputs:** Resident detail output.
- **Navigation flow:** Resident list -> Detail.
- **Validation rules:** Resident ID required.
- **Related file:** `screens/nurse/nurse_resident_detail_screen.dart`

#### UI-024 - Nurse Operations

- **Purpose:** Manage tasks, inventory, sessions.
- **User role:** Nurse
- **Main UI elements:** Forms, cards, action buttons.
- **Inputs:** Operational records.
- **Outputs:** Updated operations.
- **Navigation flow:** Nurse dashboard tab.
- **Validation rules:** Required fields per form.
- **Related file:** `screens/nurse/views/operations_view.dart`

#### UI-025 - Medical Administration

- **Purpose:** Medical sessions, visits, prescriptions, meal plans.
- **User role:** Nurse
- **Main UI elements:** Forms and data cards.
- **Inputs:** Medical operation fields.
- **Outputs:** Updated data.
- **Navigation flow:** Nurse dashboard tab.
- **Validation rules:** Resident/doctor fields required as applicable.
- **Related file:** `screens/nurse/views/medical_admin_view.dart`

#### UI-026 - Nurse Medications

- **Purpose:** Medication administration view.
- **User role:** Nurse
- **Main UI elements:** Schedule cards, status controls, filters.
- **Inputs:** Dose status.
- **Outputs:** Updated medication state.
- **Navigation flow:** Nurse dashboard/subscreen.
- **Validation rules:** Dose/medication ID required.
- **Related file:** `screens/nurse/nurse_medications_screen.dart`

#### UI-027 - Nurse Reports

- **Purpose:** Preview/export/send nursing reports.
- **User role:** Nurse
- **Main UI elements:** Report type, preview, export/send controls.
- **Inputs:** Report settings/filters.
- **Outputs:** PDF or backend report.
- **Navigation flow:** Nurse dashboard tab.
- **Validation rules:** Data availability.
- **Related file:** `screens/nurse/nurse_reports_screen.dart`

#### UI-028 - Shift Handoff

- **Purpose:** Manage shift handoff.
- **User role:** Nurse
- **Main UI elements:** Handoff input and task summaries.
- **Inputs:** Notes/tasks.
- **Outputs:** Handoff summary.
- **Navigation flow:** Nurse dashboard action.
- **Validation rules:** Notes or task data.
- **Related file:** `screens/nurse/shift_handoff_screen.dart`

#### UI-029 - Specialist Dashboard

- **Purpose:** Social specialist workspace.
- **User role:** Social Specialist
- **Main UI elements:** Assessment, complaints, KPI, files, activities tabs.
- **Inputs:** Tab/actions.
- **Outputs:** Specialist views.
- **Navigation flow:** Role routing -> Specialist Dashboard.
- **Validation rules:** Specialist role expected.
- **Related file:** `screens/specialist/specialist_dashboard_screen.dart`

#### UI-030 - Assessment View

- **Purpose:** Conduct social assessments.
- **User role:** Social Specialist
- **Main UI elements:** Tool cards, questions, answers.
- **Inputs:** Resident/tool/answers.
- **Outputs:** Assessment record.
- **Navigation flow:** Specialist dashboard tab.
- **Validation rules:** Backend questions required.
- **Related file:** `screens/specialist/views/assessment_view.dart`

#### UI-031 - Complaints View

- **Purpose:** Review and manage complaints.
- **User role:** Social Specialist/Admin
- **Main UI elements:** Complaint list, filters, status actions.
- **Inputs:** Status/action.
- **Outputs:** Complaint status.
- **Navigation flow:** Specialist/Admin dashboards.
- **Validation rules:** Complaint ID required.
- **Related file:** `screens/specialist/views/complaints_view.dart`

#### UI-032 - Specialist Files View

- **Purpose:** Resident file and audit timeline.
- **User role:** Social Specialist
- **Main UI elements:** Resident files, audit trail, documents.
- **Inputs:** Resident selection.
- **Outputs:** File details/timeline.
- **Navigation flow:** Specialist dashboard tab.
- **Validation rules:** Resident ID required.
- **Related file:** `screens/specialist/views/files_view.dart`

#### UI-033 - Admin Dashboard

- **Purpose:** Facility management overview.
- **User role:** Admin
- **Main UI elements:** Home, residents, visits, complaints, staff, reports, volunteers tabs.
- **Inputs:** Tab/actions.
- **Outputs:** Admin views.
- **Navigation flow:** Role routing -> Admin Dashboard.
- **Validation rules:** Admin role required.
- **Related file:** `screens/admin/admin_dashboard_screen.dart`

#### UI-034 - Residents Management

- **Purpose:** Admin resident management.
- **User role:** Admin
- **Main UI elements:** Resident list, create/edit forms.
- **Inputs:** Resident fields.
- **Outputs:** Created/updated resident.
- **Navigation flow:** Admin dashboard tab.
- **Validation rules:** Required resident fields.
- **Related file:** `screens/admin/views/residents_management_view.dart`

#### UI-035 - Staff Management

- **Purpose:** Admin staff accounts.
- **User role:** Admin
- **Main UI elements:** Staff list, account creation, detail navigation.
- **Inputs:** User fields.
- **Outputs:** Managed user account.
- **Navigation flow:** Admin dashboard tab.
- **Validation rules:** Email/name/role/password required.
- **Related file:** `screens/admin/views/staff_management_view.dart`

#### UI-036 - Visit Approval

- **Purpose:** Review visit requests.
- **User role:** Admin
- **Main UI elements:** Visit cards, approve/reject controls.
- **Inputs:** Visit status action.
- **Outputs:** Updated visit status.
- **Navigation flow:** Admin dashboard tab.
- **Validation rules:** Visit ID required.
- **Related file:** `screens/admin/views/visit_approval_view.dart`

#### UI-037 - Admin Reports

- **Purpose:** Administrative and financial reports.
- **User role:** Admin
- **Main UI elements:** Report cards, filters.
- **Inputs:** Date/filter selections.
- **Outputs:** Report summaries.
- **Navigation flow:** Admin dashboard tab.
- **Validation rules:** Data availability.
- **Related file:** `screens/admin/views/admin_reports_view.dart`

#### UI-038 - Volunteer Dashboard

- **Purpose:** Volunteer workspace.
- **User role:** Volunteer
- **Main UI elements:** Profile, opportunities, bookings, certificates, ratings tabs.
- **Inputs:** Tab/actions.
- **Outputs:** Volunteer data.
- **Navigation flow:** Role routing -> Volunteer Dashboard.
- **Validation rules:** Volunteer role required.
- **Related file:** `screens/volunteer/volunteer_dashboard_screen.dart`

#### UI-039 - Volunteer Profile

- **Purpose:** Manage volunteer profile/docs/share.
- **User role:** Volunteer
- **Main UI elements:** Profile fields, upload/share controls.
- **Inputs:** Profile/document file.
- **Outputs:** Saved profile/public link.
- **Navigation flow:** Volunteer dashboard tab.
- **Validation rules:** File required for upload.
- **Related file:** `screens/volunteer/profile_view.dart`, widgets

#### UI-040 - Account/Profile/Common Screens

- **Purpose:** Manage account, accessibility, cloud health, help, privacy, about.
- **User role:** All roles
- **Main UI elements:** Settings/forms/actions.
- **Inputs:** Preferences and profile data.
- **Outputs:** Updated account/preferences/status.
- **Navigation flow:** Drawer/common navigation.
- **Validation rules:** Varies by screen.
- **Related file:** `screens/common/*`, `widgets/taptaba_drawer.dart`


### العربية

تم تحليل شاشات الواجهة حسب الأدوار. يعتمد التطبيق على شاشات مخصصة لكل دور، مع مكونات مشتركة للتنقل والقائمة الجانبية والتنبيهات وإعدادات الوصول. جميع الشاشات الرئيسية عربية الاتجاه وتستخدم عناصر إدخال وعرض مناسبة لسياق المستخدم. يتم التحقق من المدخلات غالبا داخل الشاشات والخدمات، بينما تعتمد بعض القيود على الخادم الخلفي.

---

## 9. API Requirements

### English

The backend source code is not included in the current workspace. API requirements are derived from `docs/backend-contract.md`, `docs/backend-routes.raw.txt`, and service usage in `lib/services`.



#### API-001 - POST `/auth/login`

- **Method:** POST
- **Endpoint / Route:** `/auth/login`
- **Description:** Authenticate user through backend/Cognito.
- **Authentication requirement:** Public
- **Request parameters/body:** Email, password.
- **Response format:** Tokens and user object.
- **Error responses:** 401 invalid credentials; other backend errors.
- **Related file:** `auth_service.dart`

#### API-002 - POST `/auth/register`

- **Method:** POST
- **Endpoint / Route:** `/auth/register`
- **Description:** Self-register family/volunteer user.
- **Authentication requirement:** Public
- **Request parameters/body:** Email, password, name, role, facilityId, optional phone/resident.
- **Response format:** Success status.
- **Error responses:** 409 email used; validation errors.
- **Related file:** `auth_service.dart`

#### API-003 - POST `/auth/register-admin`

- **Method:** POST
- **Endpoint / Route:** `/auth/register-admin`
- **Description:** Register first/admin facility user.
- **Authentication requirement:** Public with setup secret
- **Request parameters/body:** Admin fields, facilityId, setupSecret, facility profile fields.
- **Response format:** Success status.
- **Error responses:** 401 invalid setup secret; 409 conflict.
- **Related file:** `auth_service.dart`

#### API-004 - POST `/auth/forgot-password`

- **Method:** POST
- **Endpoint / Route:** `/auth/forgot-password`
- **Description:** Send reset code.
- **Authentication requirement:** Public
- **Request parameters/body:** Email.
- **Response format:** Success status.
- **Error responses:** 404 not found; 429 rate limit.
- **Related file:** `auth_service.dart`

#### API-005 - POST `/auth/confirm-forgot-password`

- **Method:** POST
- **Endpoint / Route:** `/auth/confirm-forgot-password`
- **Description:** Confirm reset code and password.
- **Authentication requirement:** Public
- **Request parameters/body:** Email, code, newPassword.
- **Response format:** Success status.
- **Error responses:** 400 invalid/expired code.
- **Related file:** `auth_service.dart`

#### API-006 - GET `/auth/me`

- **Method:** GET
- **Endpoint / Route:** `/auth/me`
- **Description:** Validate current authenticated user.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** None.
- **Response format:** Current user.
- **Error responses:** 401 unauthorized.
- **Related file:** `cloud_health_screen.dart`

#### API-007 - GET/POST/PATCH/PUT/DELETE `/residents`, `/residents/:id`, `/residents/:id/medical-info`, `/residents/:id/audit-trail`

- **Method:** GET/POST/PATCH/PUT/DELETE
- **Endpoint / Route:** `/residents`, `/residents/:id`, `/residents/:id/medical-info`, `/residents/:id/audit-trail`
- **Description:** Resident CRUD, medical info, audit trail.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Resident fields, medical fields, query filters.
- **Response format:** Resident objects or audit entries.
- **Error responses:** 400/401/403/404.
- **Related file:** `residents_service.dart`, `backend_mutation_service.dart`

#### API-008 - GET/POST/PATCH/DELETE `/family-members`

- **Method:** GET/POST/PATCH/DELETE
- **Endpoint / Route:** `/family-members`
- **Description:** Manage family/resident links and contacts.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Resident ID, family member fields.
- **Response format:** Family member objects.
- **Error responses:** 400/401/403/404.
- **Related file:** `backend_sync_service.dart`, `backend_mutation_service.dart`

#### API-009 - GET/POST/PATCH `/medications/schedules`, `/medications/doses`, `/medications/overdue`, `/medications/adherence`

- **Method:** GET/POST/PATCH
- **Endpoint / Route:** `/medications/schedules`, `/medications/doses`, `/medications/overdue`, `/medications/adherence`
- **Description:** Medication schedules, dose logs, overdue, adherence.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Resident ID, schedule/dose/status fields.
- **Response format:** Medication/dose/adherence data.
- **Error responses:** 400/401/403/404.
- **Related file:** `medications_service.dart`

#### API-010 - GET/POST/PATCH/PUT `/health/vitals`, `/health/alerts`, `/health/thresholds`

- **Method:** GET/POST/PATCH/PUT
- **Endpoint / Route:** `/health/vitals`, `/health/alerts`, `/health/thresholds`
- **Description:** Vitals, alerts, threshold settings.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Vitals fields, alert status, thresholds.
- **Response format:** Health records/alerts/settings.
- **Error responses:** 400/401/403/404.
- **Related file:** `health_service.dart`

#### API-011 - GET/POST/PATCH/DELETE `/nursing-notes`, `/handoffs`, `/care-tasks`, `/inventory`, `/doctor-visits`, `/medical-sessions`, `/prescriptions`, `/meal-plans`

- **Method:** GET/POST/PATCH/DELETE
- **Endpoint / Route:** `/nursing-notes`, `/handoffs`, `/care-tasks`, `/inventory`, `/doctor-visits`, `/medical-sessions`, `/prescriptions`, `/meal-plans`
- **Description:** Nurse operations.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Domain-specific operation fields.
- **Response format:** Operation records.
- **Error responses:** 400/401/403/404.
- **Related file:** `backend_sync_service.dart`, `backend_mutation_service.dart`

#### API-012 - GET/PATCH/POST `/reports/nursing/preview`, `/reports/nursing/completeness`, `/reports/nursing/export`, `/reports/nursing/history`, `/reports/nursing/settings`, `/reports/nursing/send`

- **Method:** GET/PATCH/POST
- **Endpoint / Route:** `/reports/nursing/preview`, `/reports/nursing/completeness`, `/reports/nursing/export`, `/reports/nursing/history`, `/reports/nursing/settings`, `/reports/nursing/send`
- **Description:** Nursing report preview/export/settings/send/history.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Report filters/settings/recipients.
- **Response format:** Report JSON or export payload.
- **Error responses:** 400/401/403/500.
- **Related file:** `nursing_reports_service.dart`

#### API-013 - GET/POST `/social/needs`, `/social/assessment-tools`, `/social/assessment-tools/:id/questions`, `/social/gds-questions`, `/social/resident-scores`, `/social/assessments`, `/social/kpis`

- **Method:** GET/POST
- **Endpoint / Route:** `/social/needs`, `/social/assessment-tools`, `/social/assessment-tools/:id/questions`, `/social/gds-questions`, `/social/resident-scores`, `/social/assessments`, `/social/kpis`
- **Description:** Social specialist tools and assessments.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Resident ID, tool ID, answers, notes.
- **Response format:** Tools/questions/scores/assessment data.
- **Error responses:** 400/401/403/404.
- **Related file:** `social_service.dart`

#### API-014 - GET/POST/PATCH `/complaints`

- **Method:** GET/POST/PATCH
- **Endpoint / Route:** `/complaints`
- **Description:** Create/list/get/update complaint status.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Complaint subject, category, description, priority, status.
- **Response format:** Complaint object/list.
- **Error responses:** 400/401/403/404.
- **Related file:** `complaints_service.dart`

#### API-015 - GET/POST/PATCH/DELETE `/family-bridge/visits`, `/family-bridge/media`, `/family-bridge/media/upload`, `/family-bridge/media/:id/confirm`

- **Method:** GET/POST/PATCH/DELETE
- **Endpoint / Route:** `/family-bridge/visits`, `/family-bridge/media`, `/family-bridge/media/upload`, `/family-bridge/media/:id/confirm`
- **Description:** Visits and family media.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Visit details, media metadata, upload confirmation.
- **Response format:** Visit/media objects and upload URL.
- **Error responses:** 400/401/403/404.
- **Related file:** `family_bridge_service.dart`, `family_media_service.dart`

#### API-016 - GET/PATCH `/billing`, `/billing/:id/pay`

- **Method:** GET/PATCH
- **Endpoint / Route:** `/billing`, `/billing/:id/pay`
- **Description:** Family billing and payment status.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Resident ID, bill ID.
- **Response format:** Billing records.
- **Error responses:** 400/401/403/404.
- **Related file:** `backend_sync_service.dart`, `backend_mutation_service.dart`

#### API-017 - GET/POST/PATCH/DELETE `/memories`, `/memories/:id/appreciate`

- **Method:** GET/POST/PATCH/DELETE
- **Endpoint / Route:** `/memories`, `/memories/:id/appreciate`
- **Description:** Memory wall management.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Memory content/resident ID.
- **Response format:** Memory records.
- **Error responses:** 400/401/403/404.
- **Related file:** `backend_sync_service.dart`, `backend_mutation_service.dart`

#### API-018 - GET/POST/PATCH/DELETE `/volunteers/profile`, `/volunteers/opportunities`, `/volunteers/bookings`, `/volunteers/certificates`, `/volunteers/ratings`, `/volunteers/reviews`, `/volunteers/documents/upload`, `/volunteers/documents/:id/confirm`, `/volunteers/profile/public-link`

- **Method:** GET/POST/PATCH/DELETE
- **Endpoint / Route:** `/volunteers/profile`, `/volunteers/opportunities`, `/volunteers/bookings`, `/volunteers/certificates`, `/volunteers/ratings`, `/volunteers/reviews`, `/volunteers/documents/upload`, `/volunteers/documents/:id/confirm`, `/volunteers/profile/public-link`
- **Description:** Volunteer module.
- **Authentication requirement:** Bearer JWT, public profile endpoint may be public
- **Request parameters/body:** Volunteer profile, opportunity, booking, document metadata.
- **Response format:** Volunteer data or upload/public link.
- **Error responses:** 400/401/403/404.
- **Related file:** `volunteer_documents_service.dart`, volunteer screens

#### API-019 - GET/POST `/messages`, `/messages/inbox`, `/messages/thread/:otherUserId`, `/messages/unread-count`, `/messages/thread/:otherUserId/read`

- **Method:** GET/POST
- **Endpoint / Route:** `/messages`, `/messages/inbox`, `/messages/thread/:otherUserId`, `/messages/unread-count`, `/messages/thread/:otherUserId/read`
- **Description:** Text messaging.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Recipient ID, resident ID, body.
- **Response format:** Messages/inbox/count.
- **Error responses:** 400/401/403/404.
- **Related file:** `messages_service.dart`

#### API-020 - GET/POST/PATCH/DELETE `/notifications`, `/notifications/:userId`, `/notifications/:id/read`, `/notifications/push-tokens`

- **Method:** GET/POST/PATCH/DELETE
- **Endpoint / Route:** `/notifications`, `/notifications/:userId`, `/notifications/:id/read`, `/notifications/push-tokens`
- **Description:** Notifications and push tokens.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Notification fields, FCM token.
- **Response format:** Notification data/status.
- **Error responses:** 400/401/403/404.
- **Related file:** `notifications_api_service.dart`, `push_notification_service.dart`

#### API-021 - POST/GET/PATCH `/emergency/sos`, `/emergency/active`, `/emergency`, `/emergency/:id/resolve`

- **Method:** POST/GET/PATCH
- **Endpoint / Route:** `/emergency/sos`, `/emergency/active`, `/emergency`, `/emergency/:id/resolve`
- **Description:** Emergency SOS and resolution.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** TriggeredBy, residentId, location, notes, resolution.
- **Response format:** Emergency alert record.
- **Error responses:** 400/401/403/404.
- **Related file:** `emergency_service.dart`

#### API-022 - GET/POST/PATCH `/video-calls`, `/video-calls/active`, `/video-calls/:id/status`, `/video-calls/history`

- **Method:** GET/POST/PATCH
- **Endpoint / Route:** `/video-calls`, `/video-calls/active`, `/video-calls/:id/status`, `/video-calls/history`
- **Description:** Video call state.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Call metadata/status.
- **Response format:** Call object/list.
- **Error responses:** 400/401/403/404.
- **Related file:** `video_call_service.dart`

#### API-023 - GET/POST/PATCH `/ai/chat`, `/ai/speech`, `/ai/recommendations/:residentId`, `/ai/memory/:residentId`, `/ai/media/upload`, `/ai/media/:id/confirm`, `/ai/*` additional documented endpoints

- **Method:** GET/POST/PATCH
- **Endpoint / Route:** `/ai/chat`, `/ai/speech`, `/ai/recommendations/:residentId`, `/ai/memory/:residentId`, `/ai/media/upload`, `/ai/media/:id/confirm`, `/ai/*` additional documented endpoints
- **Description:** AI chat, speech, memory, media, recommendations, summaries, predictive alerts, diet, games.
- **Authentication requirement:** Mixed public/auth based on service method
- **Request parameters/body:** Message, resident ID, media metadata, context data.
- **Response format:** AI response, recommendation, upload URL, summary.
- **Error responses:** 400/401/403/500.
- **Related file:** `ai_service.dart`, `ai_media_service.dart`

#### API-024 - GET/PUT `/admin/settings/emergency-contacts`, `/admin/settings/billing`, `/admin/settings/facility-profile`

- **Method:** GET/PUT
- **Endpoint / Route:** `/admin/settings/emergency-contacts`, `/admin/settings/billing`, `/admin/settings/facility-profile`
- **Description:** Facility settings.
- **Authentication requirement:** Admin Bearer JWT
- **Request parameters/body:** Settings fields.
- **Response format:** Settings object.
- **Error responses:** 400/401/403/404.
- **Related file:** `facility_settings_service.dart`

#### API-025 - GET/POST `/facilities/search`, `/facility-inquiries`

- **Method:** GET/POST
- **Endpoint / Route:** `/facilities/search`, `/facility-inquiries`
- **Description:** Facility search and public inquiry.
- **Authentication requirement:** Public
- **Request parameters/body:** Search filters or inquiry fields.
- **Response format:** Facilities or inquiry result.
- **Error responses:** 400/500.
- **Related file:** `facility_inquiry_service.dart`

#### API-026 - GET/PUT/POST `/user-preferences/me`, `/user-progress/me`, `/user-progress/points`

- **Method:** GET/PUT/POST
- **Endpoint / Route:** `/user-preferences/me`, `/user-progress/me`, `/user-progress/points`
- **Description:** User preferences and progress.
- **Authentication requirement:** Bearer JWT
- **Request parameters/body:** Preference or points data.
- **Response format:** Preferences/progress object.
- **Error responses:** 400/401/403.
- **Related file:** `user_preferences_service.dart`, `user_progress_service.dart`

#### API-027 - GET `/health`

- **Method:** GET
- **Endpoint / Route:** `/health`
- **Description:** Public health check.
- **Authentication requirement:** Public
- **Request parameters/body:** None.
- **Response format:** Health status.
- **Error responses:** Network/server error.
- **Related file:** `cloud_health_screen.dart`


### العربية

لا يحتوي المستودع الحالي على كود الخادم الخلفي، لذلك تم استخراج متطلبات API من وثائق العقود وملف المسارات واستخدام الخدمات داخل تطبيق Flutter. تغطي الواجهات المصادقة، المقيمين، الأسرة، الأدوية، الصحة، عمليات التمريض، التقارير، التقييمات الاجتماعية، الشكاوى، الزيارات، الوسائط، الفواتير، الذكريات، المتطوعين، الرسائل، الإشعارات، الطوارئ، مكالمات الفيديو، الذكاء الاصطناعي، إعدادات المرفق، البحث عن المرافق، تفضيلات المستخدم، وفحص الصحة.

---

## 10. Database Requirements

### English

The actual database schema files are not present in the current workspace. Existing documentation identifies Google Cloud SQL (PostgreSQL) as the database and mentions migrations in backend gap analysis. Therefore, this section documents logical database requirements based on documented backend domains, not verified physical table definitions.



#### DB-001 - Users / Cognito / Managed Users

- **Key fields expected from code/docs:** userId, cognitoSub, email, name, role, facilityId, linkedResidentId, imageUrl, status
- **Relationships:** Belongs to facility; may link to resident
- **Purpose:** Authentication identity and staff/user management.
- **Status:** Documented, physical schema not in workspace

#### DB-002 - Facilities / Facility Settings

- **Key fields expected from code/docs:** facilityId, facilityName, address, licenseNumber, profile JSON, emergency contacts, billing settings
- **Relationships:** Owns users/residents/settings
- **Purpose:** Facility configuration and reporting metadata.
- **Status:** Documented

#### DB-003 - Residents

- **Key fields expected from code/docs:** id, firstName, lastName, room, status, dateOfBirth, medical info, imageUrl
- **Relationships:** Belongs to facility; linked to family, health, medication, notes
- **Purpose:** Core resident profile.
- **Status:** Documented

#### DB-004 - Resident Medical Info

- **Key fields expected from code/docs:** residentId, bloodType, chronicDiseases, allergies, diet, mobility, cognitive status
- **Relationships:** One-to-one/one-to-many with resident
- **Purpose:** Medical profile and care planning.
- **Status:** Documented

#### DB-005 - Documents and Media

- **Key fields expected from code/docs:** id, ownerType, ownerId, fileName, contentType, s3Key, url, status
- **Relationships:** Linked to residents, users, family media, AI media, volunteer docs
- **Purpose:** File storage metadata for S3 uploads.
- **Status:** Documented

#### DB-006 - Family Members

- **Key fields expected from code/docs:** id, residentId, name, email, phone, relationship
- **Relationships:** Linked to resident and user identity
- **Purpose:** Family contacts and resident linking.
- **Status:** Documented

#### DB-007 - Medication Schedules

- **Key fields expected from code/docs:** id, residentId, name, dosage, frequency, scheduledTime, instructions
- **Relationships:** Resident has many schedules
- **Purpose:** Medication planning.
- **Status:** Documented

#### DB-008 - Medication Doses

- **Key fields expected from code/docs:** id, scheduleId, residentId, status, givenAt, notes
- **Relationships:** Linked to schedule/resident
- **Purpose:** Dose logs and adherence.
- **Status:** Documented

#### DB-009 - Health Vitals

- **Key fields expected from code/docs:** id, residentId, heartRate, bloodPressure, oxygenSaturation, temperature, createdAt
- **Relationships:** Linked to resident
- **Purpose:** Vitals history and alerts.
- **Status:** Documented

#### DB-010 - Health Alerts / Thresholds

- **Key fields expected from code/docs:** id, residentId, type, severity, status, threshold values
- **Relationships:** Linked to resident/facility
- **Purpose:** Health alerting.
- **Status:** Documented

#### DB-011 - Nursing Notes

- **Key fields expected from code/docs:** id, residentId, content, category, author, createdAt
- **Relationships:** Linked to resident/user
- **Purpose:** Nursing documentation.
- **Status:** Documented

#### DB-012 - Handoffs

- **Key fields expected from code/docs:** id, shiftType, outgoingNurseId, summary, residentsCovered, pendingTasks
- **Relationships:** Linked to nurse/facility/residents
- **Purpose:** Shift continuity.
- **Status:** Documented

#### DB-013 - Care Tasks

- **Key fields expected from code/docs:** id, residentId, title, dueDate, priority, status
- **Relationships:** Linked to resident/staff
- **Purpose:** Daily care operations.
- **Status:** Documented

#### DB-014 - Inventory

- **Key fields expected from code/docs:** id, name, stock, threshold, unit
- **Relationships:** Facility-owned
- **Purpose:** Supplies and low stock awareness.
- **Status:** Documented

#### DB-015 - Doctor Visits / Medical Sessions / Prescriptions / Meal Plans

- **Key fields expected from code/docs:** id, residentId, provider/doctor, diagnosis/session/plan fields
- **Relationships:** Linked to resident
- **Purpose:** Medical administration.
- **Status:** Documented

#### DB-016 - Reports

- **Key fields expected from code/docs:** id, reportType, generatedAt, recipients, status, summary, settings
- **Relationships:** Linked to facility/residents
- **Purpose:** Nursing reports and exports.
- **Status:** Documented

#### DB-017 - Social Assessment Tools and Questions

- **Key fields expected from code/docs:** id, name, scale, questions
- **Relationships:** Used by assessments
- **Purpose:** Standardized assessment source.
- **Status:** Documented

#### DB-018 - Social Assessments and Resident Scores

- **Key fields expected from code/docs:** id, residentId, toolId, scores, notes, needsIntervention
- **Relationships:** Linked to resident and tool
- **Purpose:** Social/psychological follow-up.
- **Status:** Documented

#### DB-019 - Complaints

- **Key fields expected from code/docs:** id, residentId, subject, category, description, priority, status, timeline
- **Relationships:** Linked to resident/family/specialist
- **Purpose:** Complaint workflow.
- **Status:** Documented

#### DB-020 - Family Visits

- **Key fields expected from code/docs:** id, residentId, requestedBy, date, time, status, type
- **Relationships:** Linked to family/resident
- **Purpose:** Visit scheduling and approval.
- **Status:** Documented

#### DB-021 - Billing

- **Key fields expected from code/docs:** id, residentId, amount, dueDate, status, payment metadata
- **Relationships:** Linked to resident/facility
- **Purpose:** Family billing overview.
- **Status:** Documented

#### DB-022 - Memories

- **Key fields expected from code/docs:** id, residentId, title, type, mediaUrl, content, appreciated
- **Relationships:** Linked to resident/family media
- **Purpose:** Resident memory wall.
- **Status:** Documented

#### DB-023 - Volunteers / Opportunities / Bookings

- **Key fields expected from code/docs:** id, volunteerId, profile fields, opportunity fields, booking status
- **Relationships:** Volunteer to opportunities/bookings
- **Purpose:** Volunteer management.
- **Status:** Documented

#### DB-024 - Volunteer Ratings / Reviews / Certificates

- **Key fields expected from code/docs:** id, volunteerId, score, comment, certificate fields
- **Relationships:** Linked to volunteer
- **Purpose:** Volunteer recognition.
- **Status:** Documented

#### DB-025 - Messages

- **Key fields expected from code/docs:** id, senderId, recipientId, residentId, body, readAt, createdAt
- **Relationships:** User-to-user, optional resident context
- **Purpose:** Family-specialist communication.
- **Status:** Documented

#### DB-026 - Notifications and Push Tokens

- **Key fields expected from code/docs:** id, userId, title, message, type, read, token, platform
- **Relationships:** Linked to users/devices
- **Purpose:** In-app and push notifications.
- **Status:** Documented

#### DB-027 - Video Calls

- **Key fields expected from code/docs:** id, participants, status, joinUrl, residentId, timestamps
- **Relationships:** Linked to users/resident
- **Purpose:** Call state and history.
- **Status:** Documented

#### DB-028 - Emergency Alerts

- **Key fields expected from code/docs:** id, residentId, triggeredBy, location, notes, status, resolvedAt
- **Relationships:** Linked to resident/users
- **Purpose:** SOS and emergency handling.
- **Status:** Documented

#### DB-029 - AI Memory and AI Media

- **Key fields expected from code/docs:** id, residentId, memory, media metadata, s3Key
- **Relationships:** Linked to resident/media
- **Purpose:** Personalized AI context and uploads.
- **Status:** Documented

#### DB-030 - User Preferences and Progress

- **Key fields expected from code/docs:** userId, theme, fontScale, highContrast, points, badges
- **Relationships:** Linked to user
- **Purpose:** Personalization and gamification.
- **Status:** Documented


### العربية

لم يتم العثور على ملفات مخطط قاعدة البيانات الفعلية داخل مساحة العمل الحالية. تشير الوثائق إلى استخدام PostgreSQL على Google Cloud SQL ووجود ترحيلات في مستودع الخلفية غير الموجود هنا. لذلك توثق هذه الفقرة الكيانات المنطقية المتوقعة من الكود والوثائق، وليس التعريفات الفيزيائية المؤكدة للجداول.

---

## 11. Authentication and Authorization Requirements

### English



#### AUTH-001 - Login through backend

- **Description:** The client shall send credentials to `/auth/login`; backend handles Cognito password authentication and returns tokens/user.
- **Related modules:** `auth_service.dart`

#### AUTH-002 - Token storage

- **Description:** The client shall store the ID/access token and refresh token in secure storage.
- **Related modules:** `api_client.dart`, `flutter_secure_storage`

#### AUTH-003 - Bearer token requests

- **Description:** API calls shall include `Authorization: Bearer <token>` for protected endpoints.
- **Related modules:** `api_client.dart`

#### AUTH-004 - Session restoration

- **Description:** The client shall restore sessions from secure token storage and refresh expired tokens when possible.
- **Related modules:** `auth_service.dart`, `AppRiverpod`

#### AUTH-005 - Refresh token flow

- **Description:** The client shall use Cognito `REFRESH_TOKEN_AUTH` against the configured Cognito endpoint when token refresh is required.
- **Related modules:** `auth_service.dart`, `api_config.dart`

#### AUTH-006 - Logout

- **Description:** The client shall clear current user and stored tokens on logout.
- **Related modules:** `AuthService`, `AppRiverpod`

#### AUTH-007 - Role mapping

- **Description:** Cognito/backend roles shall be mapped to Arabic UI roles used for routing.
- **Related modules:** `CognitoUserInfo.arabicRole`

#### AUTH-008 - Admin setup secret

- **Description:** Admin registration shall require `ADMIN_REG_SECRET`.
- **Related modules:** `ApiConfig`, `AuthService.registerAdmin`

#### AUTH-009 - Protected routes

- **Description:** Protected backend endpoints shall require JWT validation.
- **Related modules:** Documented backend contract

#### AUTH-010 - Role and facility scoping

- **Description:** Backend should enforce role and facility scoping based on Cognito claims and facility ID.
- **Related modules:** Documented backend contract


### العربية

تعتمد المصادقة على الخادم الخلفي وGoogle Cloud Identity Platform / Firebase Auth. يرسل التطبيق بيانات الدخول إلى الخادم، ويتلقى رموز JWT ورمز التحديث، ويخزنها في التخزين الآمن. تضيف طبقة `ApiClient` رمز Bearer إلى الطلبات المحمية. تتم استعادة الجلسات من التخزين الآمن، ويتم تحديث الجلسة عبر Cognito عند الحاجة. تتحول الأدوار إلى مسميات عربية داخل التطبيق لاستخدامها في التوجيه. تسجيل المدير الأول يتطلب سرا إعداديا.

---

## 12. Business Rules

### English



#### BR-001 - Onboarding must precede login for first-time users.

- **Condition:** `hasSeenOnboarding` is false.
- **System behavior:** Show onboarding before login.
- **Related module/file:** `main.dart`, `AppRiverpod`

#### BR-002 - Authenticated users are routed by role.

- **Condition:** `isAuthenticated` is true and `currentRole` is set.
- **System behavior:** Show dashboard for Nurse, Volunteer, Resident, Specialist, Family, or Admin.
- **Related module/file:** `main.dart`

#### BR-003 - Self-registration requires a configured facility ID.

- **Condition:** `FACILITY_ID` compile-time value is empty.
- **System behavior:** Block registration with error.
- **Related module/file:** `AppRiverpod.selfRegister`

#### BR-004 - Admin registration requires admin setup secret.

- **Condition:** `ADMIN_REG_SECRET` is empty.
- **System behavior:** Block registration with error.
- **Related module/file:** `AppRiverpod.registerAdmin`

#### BR-005 - API client must attach token for authenticated requests.

- **Condition:** `auth = true` and token exists.
- **System behavior:** Add Bearer token.
- **Related module/file:** `api_client.dart`

#### BR-006 - Expired sessions must be refreshed or cleared.

- **Condition:** JWT expiry is near or past.
- **System behavior:** Call refresh flow or logout.
- **Related module/file:** `auth_service.dart`, `AppRiverpod`

#### BR-007 - Family and resident sync should use resident scope where available.

- **Condition:** Role is family or resident with linked resident.
- **System behavior:** Load scoped resident data.
- **Related module/file:** `backend_sync_service.dart`

#### BR-008 - Medication reminders are scheduled only for future untaken medications.

- **Condition:** Medication is not taken and scheduled time is after now.
- **System behavior:** Schedule local notification.
- **Related module/file:** `AppRiverpod.scheduleMedicationReminders`

#### BR-009 - SOS request must use backend-supported fields.

- **Condition:** SOS triggered.
- **System behavior:** Send `triggeredBy`, `residentId`, `location`, `notes`.
- **Related module/file:** `emergency_service.dart`

#### BR-010 - Media uploads must be confirmed after S3 PUT.

- **Condition:** Presigned upload succeeds.
- **System behavior:** Call confirm endpoint to persist record.
- **Related module/file:** `s3_upload_helper.dart`, upload services

#### BR-011 - Message backend supports text body.

- **Condition:** User sends specialist/family message.
- **System behavior:** Send text payload; unsupported media is not treated as backend chat media.
- **Related module/file:** `messages_service.dart`

#### BR-012 - Missing backend assessment questions must not be replaced with fake questions.

- **Condition:** Assessment questions unavailable.
- **System behavior:** Show empty/setup state.
- **Related module/file:** `social_service.dart`, `mock-audit.md`

#### BR-013 - Role-specific data failures should be visible.

- **Condition:** Backend sync fails.
- **System behavior:** Set `backendSyncError` and show actionable error/empty states.
- **Related module/file:** `AppRiverpod`

#### BR-014 - Push initialization is limited to mobile.

- **Condition:** Platform is web/desktop.
- **System behavior:** Skip Firebase Messaging initialization.
- **Related module/file:** `push_notification_service.dart`

#### BR-015 - Facility settings should come from backend rather than hardcoded business data.

- **Condition:** Settings are needed.
- **System behavior:** Load `/admin/settings/*`.
- **Related module/file:** `facility_settings_service.dart`, docs


### العربية

قواعد العمل الأساسية تشمل: عرض الإعداد الأولي قبل الدخول، التوجيه حسب الدور بعد المصادقة، اشتراط معرف المرفق للتسجيل الذاتي، اشتراط سر الإعداد لتسجيل المدير، إرفاق JWT في الطلبات المحمية، تحديث أو حذف الجلسات المنتهية، تضييق بيانات الأسرة والمسن حسب المقيم، جدولة تذكيرات الأدوية المستقبلية فقط، إرسال نداء الطوارئ بصيغة الخادم المدعومة، تأكيد رفع S3 بعد الإرسال، وعدم استبدال بيانات الخادم الناقصة ببيانات وهمية.

---

## 13. Data Validation Requirements

### English



#### VAL-001 - Login

- **Rule:** Email/identifier and password are required.
- **Error handling / output:** Show login failure or required field feedback.
- **Related files:** `login_screen.dart`, `auth_service.dart`

#### VAL-002 - Registration

- **Rule:** Name, email, password, role, and facility ID are required for self-registration.
- **Error handling / output:** Throw `ApiException` if facility ID missing; backend validates request.
- **Related files:** `register_screen.dart`, `AppRiverpod`

#### VAL-003 - Admin registration

- **Rule:** Admin fields and setup secret are required.
- **Error handling / output:** Block if `ADMIN_REG_SECRET` is empty; backend validates rest.
- **Related files:** `admin_register_screen.dart`, `auth_service.dart`

#### VAL-004 - API response parsing

- **Rule:** Responses must be JSON where expected.
- **Error handling / output:** Non-2xx responses throw `ApiException` with message.
- **Related files:** `api_client.dart`

#### VAL-005 - Resident creation

- **Rule:** Required resident fields must be provided by UI/backend.
- **Error handling / output:** UI validation and backend validation.
- **Related files:** `create_resident_sheet.dart`, `backend_mutation_service.dart`

#### VAL-006 - Vitals

- **Rule:** Resident and vital values must be provided.
- **Error handling / output:** Show submit error if backend rejects or network fails.
- **Related files:** `record_vitals_sheet.dart`, `health_service.dart`

#### VAL-007 - Complaints

- **Rule:** Complaint subject/category/description should not be empty.
- **Error handling / output:** Show backend/API error when invalid.
- **Related files:** `submit_complaint_sheet.dart`, `complaints_service.dart`

#### VAL-008 - Visit booking

- **Rule:** Date, time, and resident context are required.
- **Error handling / output:** Show error or backend rejection.
- **Related files:** `visit_booking_screen.dart`, `family_bridge_service.dart`

#### VAL-009 - File upload

- **Rule:** File path/name/content type must be present; upload URL must be returned.
- **Error handling / output:** Throw `ApiException` when upload URL is missing.
- **Related files:** `ai_media_service.dart`, `family_media_service.dart`, `volunteer_documents_service.dart`, `profile_image_service.dart`

#### VAL-010 - Message sending

- **Rule:** Text message body is required for current backend message support.
- **Error handling / output:** Block or fail media-only unsupported messages.
- **Related files:** `messages_service.dart`, specialist/family chat screens

#### VAL-011 - Assessment

- **Rule:** Resident, tool, and answers are required.
- **Error handling / output:** Empty questions show setup state; backend validates answers.
- **Related files:** `social_service.dart`, assessment screens

#### VAL-012 - Environment config

- **Rule:** API URL and Cognito values must be configured for production environment.
- **Error handling / output:** Defaults used if not overridden; deployment should configure values.
- **Related files:** `api_config.dart`


### العربية

تشمل قواعد التحقق حقول الدخول، وحقول التسجيل، وسر تسجيل المدير، وصيغة استجابات API، وبيانات المقيم، والقياسات الحيوية، والشكاوى، وحجز الزيارات، ورفع الملفات، والرسائل النصية، والتقييمات، وإعدادات البيئة. يعتمد جزء من التحقق على الواجهة، وجزء آخر على الخادم الخلفي.

---

## 14. Error Handling Requirements

### English



#### ERR-001 - Invalid login credentials

- **Expected behavior:** Show clear invalid credentials message and keep user unauthenticated.
- **Related files:** `auth_service.dart`, `login_screen.dart`

#### ERR-002 - Missing admin setup secret

- **Expected behavior:** Prevent admin registration and show configuration error.
- **Related files:** `AppRiverpod.registerAdmin`

#### ERR-003 - Missing self-registration facility ID

- **Expected behavior:** Prevent self-registration and show configuration error.
- **Related files:** `AppRiverpod.selfRegister`

#### ERR-004 - Network disconnected

- **Expected behavior:** Throw controlled `ApiException` with no-internet message.
- **Related files:** `api_client.dart`

#### ERR-005 - Request timeout

- **Expected behavior:** Throw controlled `ApiException` with timeout message.
- **Related files:** `api_client.dart`

#### ERR-006 - Unauthorized API access

- **Expected behavior:** Backend returns 401; client should show error or logout if session invalid.
- **Related files:** `api_client.dart`, `AppRiverpod`

#### ERR-007 - Forbidden action

- **Expected behavior:** Backend returns 403; UI should show error and prevent false success.
- **Related files:** Services/screens

#### ERR-008 - Empty backend data

- **Expected behavior:** Show empty/setup state rather than fake business data.
- **Related files:** `mock-audit.md`, screens

#### ERR-009 - Upload URL missing

- **Expected behavior:** Throw clear upload response error.
- **Related files:** Upload services

#### ERR-010 - S3 upload failure

- **Expected behavior:** Retry up to configured attempts, then throw upload failure.
- **Related files:** `s3_upload_helper.dart`

#### ERR-011 - Firebase unsupported platform

- **Expected behavior:** Skip FCM and log debug message.
- **Related files:** `push_notification_service.dart`

#### ERR-012 - Session restore failure

- **Expected behavior:** Clear local auth state and require login.
- **Related files:** `auth_service.dart`, `AppRiverpod`

#### ERR-013 - AI backend unavailable

- **Expected behavior:** Show backend error or local fallback only where implemented.
- **Related files:** `ai_service.dart`, provider methods

#### ERR-014 - PDF export failure

- **Expected behavior:** Use explicit local PDF fallback where implemented.
- **Related files:** `nursing_reports_service.dart`, `pdf_service.dart`


### العربية

ينبغي أن يتعامل النظام مع أخطاء بيانات الدخول، وغياب إعدادات التسجيل، وانقطاع الشبكة، وانتهاء المهلة، وعدم التصريح، ورفض الصلاحية، وغياب البيانات، وفشل رفع الملفات، وعدم دعم Firebase على بعض المنصات، وفشل استعادة الجلسة، وتعطل خدمات الذكاء الاصطناعي أو تصدير التقارير، من خلال رسائل واضحة وحالات آمنة دون انهيار التطبيق.

---

## 15. Security Requirements

### English



#### SEC-001 - Secure token storage

- **Description:** JWT and refresh tokens shall be stored in `FlutterSecureStorage`.
- **Priority:** High

#### SEC-002 - HTTPS communication

- **Description:** Production API and Cognito requests shall use HTTPS endpoints.
- **Priority:** High

#### SEC-003 - Bearer authentication

- **Description:** Protected API calls shall use Bearer JWT headers.
- **Priority:** High

#### SEC-004 - Role-based authorization

- **Description:** Backend shall authorize access based on role and facility/resident scope.
- **Priority:** High

#### SEC-005 - Admin secret protection

- **Description:** Admin setup secret must not be hardcoded for production builds; it should be supplied as environment configuration.
- **Priority:** High

#### SEC-006 - File upload security

- **Description:** Client shall upload only to backend-issued presigned URLs and confirm uploads through backend.
- **Priority:** High

#### SEC-007 - No GCP secrets in client

- **Description:** GCP credentials and backend secrets shall not be stored in Flutter client code.
- **Priority:** High

#### SEC-008 - Input validation

- **Description:** Backend and client shall validate request bodies to prevent malformed or unsafe data.
- **Priority:** High

#### SEC-009 - Error messages

- **Description:** Errors should be actionable but should not expose sensitive internal details.
- **Priority:** Medium

#### SEC-010 - Firebase token handling

- **Description:** Push tokens shall be registered and removed through authenticated backend endpoints.
- **Priority:** Medium

#### SEC-011 - Biometric login

- **Description:** Biometric authentication should only restore a valid saved session; it should not replace backend authentication.
- **Priority:** Medium

#### SEC-012 - Dependency security

- **Description:** Dependencies should be reviewed before production release.
- **Priority:** Medium

#### SEC-013 - CI safety

- **Description:** Release signing secrets should be loaded from environment variables or gitignored key files.
- **Priority:** High


### العربية

تركز متطلبات الأمان على تخزين الرموز بأمان، واستخدام HTTPS، وإرفاق JWT في الطلبات المحمية، وتطبيق التفويض حسب الدور والمرفق والمقيم، وحماية سر تسجيل المدير، واستخدام روابط S3 المؤقتة، وعدم وضع أسرار GCP داخل العميل، والتحقق من المدخلات، ورسائل الخطأ الآمنة، وإدارة رموز Firebase، واستخدام البصمة لاستعادة جلسة محفوظة فقط، ومراجعة الاعتماديات، وحماية أسرار توقيع الإصدارات.

---

## 16. System Workflows

### English



#### WF-001 - Login and role routing

- **Actor:** Any user
- **Preconditions:** User has valid account.
- **Steps:** Open app; complete onboarding if needed; enter credentials; backend authenticates; tokens saved; role mapped; dashboard opens.
- **Alternative flows:** Existing token restores session without manual login.
- **Error flows:** Invalid login, network failure, expired refresh token.
- **Final result:** User reaches role-specific dashboard.

#### WF-002 - Admin creates managed user

- **Actor:** Admin
- **Preconditions:** Admin authenticated.
- **Steps:** Open staff management; enter name/email/password/role; submit; backend creates user; sync refreshes.
- **Alternative flows:** Admin edits/disables existing user.
- **Error flows:** Validation conflict or unauthorized action.
- **Final result:** Staff user is managed through backend.

#### WF-003 - Nurse records vitals

- **Actor:** Nurse
- **Preconditions:** Nurse authenticated and resident exists.
- **Steps:** Open vitals sheet; select resident; enter readings; submit; backend stores vitals; alerts may be generated.
- **Alternative flows:** Nurse reviews existing vitals.
- **Error flows:** Missing fields, network error, backend validation error.
- **Final result:** Resident vitals updated.

#### WF-004 - Medication administration

- **Actor:** Nurse or Resident
- **Preconditions:** Medication schedule exists.
- **Steps:** Open medication screen; review dose; update status; backend records dose; dashboard refreshes.
- **Alternative flows:** Local reminder prompts resident.
- **Error flows:** Dose ID missing, API failure.
- **Final result:** Medication state updated.

#### WF-005 - Family books visit

- **Actor:** Family Member
- **Preconditions:** Family linked to resident.
- **Steps:** Open visit booking; select date/time/type; submit; backend creates pending visit; admin reviews.
- **Alternative flows:** Family views existing visits.
- **Error flows:** No linked resident, invalid date, backend error.
- **Final result:** Visit request created.

#### WF-006 - Admin approves visit

- **Actor:** Admin
- **Preconditions:** Pending visit exists.
- **Steps:** Open visit approval; choose approve/reject; backend updates status; family view refreshes.
- **Alternative flows:** Admin filters visit list.
- **Error flows:** Unauthorized or missing visit.
- **Final result:** Visit status updated.

#### WF-007 - Family uploads media

- **Actor:** Family Member
- **Preconditions:** Linked resident and selected file.
- **Steps:** Choose file; request upload URL; PUT to S3; confirm backend; sync media.
- **Alternative flows:** Upload text-only memory where supported.
- **Error flows:** Missing upload URL, S3 failure, confirm failure.
- **Final result:** Media appears in family bridge/memories.

#### WF-008 - Social specialist completes assessment

- **Actor:** Social Specialist
- **Preconditions:** Resident and backend questions exist.
- **Steps:** Open assessment tool; load questions; fill answers; submit; backend saves assessment; scores update.
- **Alternative flows:** Empty question state if backend not seeded.
- **Error flows:** Missing questions, validation error.
- **Final result:** Assessment stored.

#### WF-009 - Resident uses AI companion

- **Actor:** Elderly Resident
- **Preconditions:** App online or endpoint available.
- **Steps:** Open AI chat; type/speak message; service calls backend AI; response displayed/spoken.
- **Alternative flows:** Upload media for AI context where supported.
- **Error flows:** AI endpoint error, microphone permission error.
- **Final result:** Resident receives AI support response.

#### WF-010 - SOS emergency

- **Actor:** Resident or Nurse
- **Preconditions:** Authenticated user and backend available.
- **Steps:** Trigger SOS; app sends `/emergency/sos`; backend stores alert; realtime/push notify care team; alert resolved later.
- **Alternative flows:** User cancels global snackbar before final state if supported locally.
- **Error flows:** Network/API failure.
- **Final result:** Emergency alert is visible to responsible roles.

#### WF-011 - Volunteer books opportunity

- **Actor:** Volunteer
- **Preconditions:** Volunteer authenticated and opportunity exists.
- **Steps:** Open opportunities; choose opportunity; book; backend stores booking; profile/bookings update.
- **Alternative flows:** Volunteer cancels booking if supported.
- **Error flows:** Already booked or backend validation error.
- **Final result:** Booking recorded.

#### WF-012 - Generate nursing report

- **Actor:** Nurse/Admin
- **Preconditions:** Report data available.
- **Steps:** Open reports; choose report type; load preview; export/send through backend or local PDF fallback.
- **Alternative flows:** Open report history/settings.
- **Error flows:** Export endpoint failure; local fallback used where implemented.
- **Final result:** Report generated or sent.


### العربية

توضح مسارات العمل الرئيسية كيفية دخول المستخدم وتوجيهه حسب الدور، وكيفية إنشاء المستخدمين، وتسجيل القياسات، وإدارة الأدوية، وحجز الزيارات واعتمادها، ورفع الوسائط، وإجراء التقييمات الاجتماعية، واستخدام الرفيق الذكي، وإرسال نداء الطوارئ، وحجز فرص التطوع، وتوليد التقارير التمريضية.

---

## 17. Use Cases

### English



#### UC-001 - Authenticate user

- **Actor:** Any user
- **Goal:** Access the correct role dashboard.
- **Preconditions:** User account exists.
- **Main flow:** Enter credentials, submit, backend validates, tokens stored, dashboard opens.
- **Alternative flow:** Restore saved session.
- **Postconditions:** User authenticated or shown error.
- **Related requirements:** FR-003, FR-004, FR-008

#### UC-002 - Register family/volunteer

- **Actor:** Family/Volunteer
- **Goal:** Create self-service account.
- **Preconditions:** Facility ID configured.
- **Main flow:** Fill register form, submit, backend creates account.
- **Alternative flow:** User returns to login.
- **Postconditions:** Registration request complete.
- **Related requirements:** FR-006

#### UC-003 - Register admin facility

- **Actor:** Admin
- **Goal:** Bootstrap admin and facility.
- **Preconditions:** Admin setup secret configured.
- **Main flow:** Fill admin/facility form, submit, backend registers admin.
- **Alternative flow:** Correct validation errors.
- **Postconditions:** Admin/facility setup complete.
- **Related requirements:** FR-007

#### UC-004 - Manage resident

- **Actor:** Admin
- **Goal:** Create or update resident record.
- **Preconditions:** Admin authenticated.
- **Main flow:** Open residents management, fill form, save.
- **Alternative flow:** Edit existing resident.
- **Postconditions:** Resident stored.
- **Related requirements:** FR-011, FR-012

#### UC-005 - Record vital signs

- **Actor:** Nurse
- **Goal:** Store resident vital reading.
- **Preconditions:** Resident exists.
- **Main flow:** Open vitals sheet, enter values, submit.
- **Alternative flow:** Correct invalid values.
- **Postconditions:** Vitals stored.
- **Related requirements:** FR-016

#### UC-006 - Administer medication

- **Actor:** Nurse/Resident
- **Goal:** Update dose status.
- **Preconditions:** Medication schedule exists.
- **Main flow:** Open medication view, choose status, submit.
- **Alternative flow:** Local reminder triggers action.
- **Postconditions:** Dose state updated.
- **Related requirements:** FR-013, FR-014

#### UC-007 - Submit complaint

- **Actor:** Family/Resident
- **Goal:** Notify staff of issue.
- **Preconditions:** User authenticated.
- **Main flow:** Open complaint form, enter subject/category/description, submit.
- **Alternative flow:** Cancel form.
- **Postconditions:** Complaint created.
- **Related requirements:** FR-026

#### UC-008 - Conduct assessment

- **Actor:** Social Specialist
- **Goal:** Record social/psychological assessment.
- **Preconditions:** Tool questions available.
- **Main flow:** Select tool/resident, answer questions, submit.
- **Alternative flow:** Show setup state if questions missing.
- **Postconditions:** Assessment stored.
- **Related requirements:** FR-024, FR-025

#### UC-009 - Book visit

- **Actor:** Family
- **Goal:** Schedule a visit.
- **Preconditions:** Linked resident exists.
- **Main flow:** Select visit time/date/type, submit.
- **Alternative flow:** Change selected slot.
- **Postconditions:** Visit request pending.
- **Related requirements:** FR-027

#### UC-010 - Approve visit

- **Actor:** Admin
- **Goal:** Approve or reject pending visit.
- **Preconditions:** Pending visit exists.
- **Main flow:** Open visit approval and change status.
- **Alternative flow:** Reject with reason if supported.
- **Postconditions:** Visit status updated.
- **Related requirements:** FR-027

#### UC-011 - Upload media

- **Actor:** Family/Volunteer/Admin
- **Goal:** Store document/image/media.
- **Preconditions:** File selected and backend returns upload URL.
- **Main flow:** Request upload, upload to S3, confirm.
- **Alternative flow:** Retry upload.
- **Postconditions:** File metadata stored.
- **Related requirements:** FR-028, FR-044, FR-045

#### UC-012 - Send message

- **Actor:** Family/Specialist
- **Goal:** Communicate about resident.
- **Preconditions:** Recipient exists.
- **Main flow:** Open thread, type message, send.
- **Alternative flow:** Mark thread read.
- **Postconditions:** Message stored and visible.
- **Related requirements:** FR-031

#### UC-013 - Trigger SOS

- **Actor:** Resident/Nurse
- **Goal:** Notify care team urgently.
- **Preconditions:** User authenticated.
- **Main flow:** Press/drag SOS, backend creates alert, realtime/push notify.
- **Alternative flow:** Cancel local overlay if accidental.
- **Postconditions:** Alert active until resolved.
- **Related requirements:** FR-034

#### UC-014 - Use AI companion

- **Actor:** Resident
- **Goal:** Receive supportive AI response.
- **Preconditions:** AI endpoint available.
- **Main flow:** Send message, wait for response, view/listen.
- **Alternative flow:** Voice mode with seamless 2-second auto-deduction and dedicated mute button, or media upload.
- **Postconditions:** Conversation updated.
- **Related requirements:** FR-038, FR-039

#### UC-015 - Manage volunteer opportunity

- **Actor:** Admin/Volunteer
- **Goal:** Create or book volunteer work.
- **Preconditions:** Role authenticated.
- **Main flow:** Admin creates opportunity; volunteer books.
- **Alternative flow:** Volunteer cancels booking.
- **Postconditions:** Opportunity/booking updated.
- **Related requirements:** FR-041, FR-042

#### UC-016 - Export report

- **Actor:** Nurse/Admin
- **Goal:** Generate care report.
- **Preconditions:** Report data available.
- **Main flow:** Preview, export or send report.
- **Alternative flow:** Local PDF fallback.
- **Postconditions:** Report file/history created.
- **Related requirements:** FR-023, FR-052


### العربية

تعكس حالات الاستخدام السابقة السيناريوهات الرسمية الأساسية للنظام: المصادقة، التسجيل، إدارة المقيمين، تسجيل القياسات، إدارة الأدوية، إرسال الشكاوى، إجراء التقييمات، حجز واعتماد الزيارات، رفع الملفات، إرسال الرسائل، إرسال نداء الطوارئ، استخدام الرفيق الذكي، إدارة التطوع، وتصدير التقارير.

---

## 18. Constraints

### English

| Constraint type | Constraint |
|---|---|
| Technical | Flutter and Dart are the required frontend stack. |
| Technical | Backend code is not available in the current repository, only contracts and route dumps. |
| Technical | The current app centralizes significant business state in one provider, `AppRiverpod`. |
| Technical | Push notifications require Firebase platform configuration. |
| Technical | S3 uploads require backend presigned URL endpoints. |
| Business | The application is designed for elderly care and nursing home workflows. |
| Business | Roles and facility/resident scope must be respected. |
| Academic | Documentation must be suitable for graduation project review. |
| Time | Some backend endpoints are documented as pending deployment or requiring verification. |
| Platform | Primary UI is mobile and Arabic RTL; web/desktop targets exist but are not the main optimized experience. |
| Security | Production secrets must not be committed to source control. |

### العربية

تشمل القيود استخدام Flutter وDart كواجهة أمامية، وغياب كود الخادم الخلفي من المستودع الحالي، وتركيز جزء كبير من الحالة في `AppRiverpod`، واعتماد الإشعارات على Firebase، واعتماد الرفع على روابط S3 من الخادم، وضرورة احترام الأدوار ونطاق المرفق والمقيم، وكون الوثيقة موجهة لتقييم أكاديمي، وأن الواجهة الأساسية محسنة للهاتف وبالعربية.

---

## 19. Assumptions and Dependencies

### English

| ID | Assumption / Dependency |
|---|---|
| AD-001 | Users have valid accounts created through backend/Cognito flows. |
| AD-002 | Internet connectivity is required for live backend data. |
| AD-003 | `https://api.helpers-tech.com` or configured `API_BASE_URL` is reachable. |
| AD-004 | Google Cloud Identity Platform / Firebase Auth values in `ApiConfig` match the deployed backend/user pool. |
| AD-005 | Backend validates JWT tokens and enforces role/facility scope. |
| AD-006 | Google Cloud SQL (PostgreSQL) stores business data. |
| AD-007 | Google Cloud Storage (GCS) stores media and documents through presigned URLs. |
| AD-008 | Firebase configuration is valid for Android push notifications. |
| AD-009 | Device permissions are granted when needed. |
| AD-010 | Backend AI endpoints are configured for Bedrock/speech services where used. |
| AD-011 | Flutter SDK and platform build tools are installed for development. |
| AD-012 | CI uses Flutter stable and can run tests. |

### العربية

يعتمد النظام على وجود حسابات صالحة، واتصال إنترنت، وتوفر عنوان API، وصحة إعدادات Cognito، وتطبيق التفويض في الخادم، وتوفر RDS وS3 وFirebase، ومنح أذونات الجهاز، وضبط خدمات الذكاء الاصطناعي، وتوفر بيئة Flutter وأدوات البناء.

---

## 20. Acceptance Criteria

### English

| Area | Acceptance criteria |
|---|---|
| Authentication | User can log in, restore a session, refresh a session, and log out securely. |
| Role routing | Each supported role opens the correct dashboard. |
| Resident management | Resident data loads from backend and admin can create/update resident records where permitted. |
| Medications | Medication schedules and dose states are displayed and update correctly. |
| Health | Nurse can record vitals and view alerts. |
| Nursing operations | Care tasks, handoffs, notes, reports, and inventory flows work through backend or show clear errors. |
| Social specialist | Assessment tools, complaints, KPIs, files, and chat flows are available. |
| Family module | Family can view resident status, book visits, see billing/reports, chat, and upload media. |
| Volunteer module | Volunteer can manage profile, browse/book opportunities, view ratings/certificates, and upload documents. |
| AI module | AI companion and documented AI endpoints return responses or safe error/fallback states. |
| Notifications | In-app notifications load; FCM token registration works on supported mobile platforms. |
| Realtime | Socket.IO connection handles supported events without breaking UI. |
| SOS | SOS request creates backend alert and notifies relevant users through realtime/push mechanisms. |
| Accessibility | Font scaling, dark mode, high contrast, and RTL layout work consistently. |
| Documentation | This SRS and export guide are complete, readable, and convertible to DOCX/PDF. |

### العربية

تقبل المنظومة عندما تعمل المصادقة، والتوجيه حسب الدور، وإدارة المقيمين، والأدوية، والصحة، وعمليات التمريض، والتقييمات الاجتماعية، ووحدة الأسرة، ووحدة المتطوعين، والذكاء الاصطناعي، والإشعارات، والأحداث اللحظية، والطوارئ، وإعدادات الوصول، والتوثيق بشكل واضح وآمن وقابل للمراجعة الأكاديمية.

---

## 21. Recommended Future Requirements

### English

The following requirements are recommended future enhancements. They should not be treated as implemented unless added to the codebase later.



#### FTR-001 - Offline-first data cache

- **Description:** Add local database cache and sync queue.
- **Rationale:** Improve reliability during poor connectivity.

#### FTR-002 - Full backend source inclusion or submodule

- **Description:** Include backend code or link it as a submodule.
- **Rationale:** Improve traceability and maintainability.

#### FTR-003 - Formal OpenAPI specification

- **Description:** Generate and version Swagger/OpenAPI docs.
- **Rationale:** Strengthen API testing and documentation.

#### FTR-004 - Automated mapper tests

- **Description:** Add unit tests for every backend-to-model mapper.
- **Rationale:** Reduce regression risk.

#### FTR-005 - Full integration test suite

- **Description:** Add login, resident, medication, SOS, and upload integration tests.
- **Rationale:** Improve release confidence.

#### FTR-006 - Web admin dashboard

- **Description:** Build a desktop web admin dashboard.
- **Rationale:** Make complex admin tasks easier.

#### FTR-007 - Multi-language support

- **Description:** Add English/French localization infrastructure.
- **Rationale:** Expand audience beyond Arabic-only users.

#### FTR-008 - Tablet layouts

- **Description:** Add adaptive tablet UI.
- **Rationale:** Improve clinical/admin usability.

#### FTR-009 - Chat media backend support

- **Description:** Extend messages API for images/audio/documents.
- **Rationale:** Align chat UI ambitions with backend support.

#### FTR-010 - HL7 FHIR integration

- **Description:** Add healthcare interoperability endpoints.
- **Rationale:** Enable integration with hospital systems.

#### FTR-011 - Wearable/IoT vitals

- **Description:** Integrate smart watch or medical device vitals.
- **Rationale:** Reduce manual vitals entry.

#### FTR-012 - Advanced analytics

- **Description:** Add time-series dashboards and predictive deterioration models.
- **Rationale:** Improve proactive care.

#### FTR-013 - Security hardening review

- **Description:** Perform OWASP MASVS and dependency vulnerability review.
- **Rationale:** Prepare for production/commercial deployment.

#### FTR-014 - Infrastructure as code

- **Description:** Add Terraform/CDK/CloudFormation for GCP resources.
- **Rationale:** Make deployment repeatable and auditable.

#### FTR-015 - Disaster recovery plan

- **Description:** Define RDS backups, restore drills, and incident response.
- **Rationale:** Improve operational readiness.


### العربية

تشمل المتطلبات المستقبلية المقترحة دعم العمل دون اتصال، وإدراج كود الخلفية أو ربطه كمستودع فرعي، وإنشاء OpenAPI رسمي، وإضافة اختبارات للمحولات والتكامل، وبناء لوحة إدارة ويب، ودعم لغات متعددة وأجهزة لوحية، ودعم وسائط الدردشة من الخادم، والتكامل الصحي FHIR، وربط الأجهزة القابلة للارتداء، والتحليلات المتقدمة، ومراجعة الأمان، وإضافة البنية التحتية ككود، وخطة استعادة الكوارث.

---

## 22. Appendices

### Appendix A - Glossary

| Term | Meaning |
|---|---|
| Resident | Elderly person receiving care in the facility. |
| Family Bridge | Family-facing features for visits, media, reports, and communication. |
| Social Assessment | Structured evaluation conducted by a social specialist. |
| Presigned URL | Temporary S3 upload URL generated by backend. |
| Realtime Event | Socket.IO event pushed from backend to client. |
| Facility Scope | Restriction of data to the user's care facility. |
| Linked Resident | Resident associated with a family member account. |

### Appendix B - Acronyms

| Acronym | Full form |
|---|---|
| API | Application Programming Interface |
| GCP | Amazon Web Services |
| DOCX | Microsoft Word Open XML Document |
| FCM | Firebase Cloud Messaging |
| JWT | JSON Web Token |
| KPI | Key Performance Indicator |
| PDF | Portable Document Format |
| RDS | Relational Database Service |
| RTL | Right-to-left |
| S3 | Simple Storage Service |
| SRS | Software Requirements Specification |
| UI | User Interface |
| UX | User Experience |

### Appendix C - Project Structure Summary

```text
.
├── lib/
│   ├── config/              API and Cognito configuration
│   ├── models/              Application domain models
│   ├── providers/           Riverpod state provider
│   ├── screens/             Role-based screens
│   ├── services/            REST, auth, sync, uploads, AI, notifications
│   ├── theme/               Theme definitions
│   └── widgets/             Reusable UI components and sheets
├── assets/
│   ├── animations/          Lottie animations
│   ├── fonts/               Cairo font files
│   └── icons/               App and splash icons
├── android/                 Android project and Firebase config
├── ios/                     iOS project
├── web/                     Flutter web target
├── windows/ linux/ macos/   Desktop targets
├── docs/                    Backend contract and audit documents
├── test/                    Flutter test folder
└── .github/workflows/       Flutter CI workflow
```

### Appendix D - Package Dependencies Summary

| Category | Packages |
|---|---|
| Flutter core | `flutter`, `flutter_localizations`, `cupertino_icons` through platform defaults |
| State management | `flutter_riverpod` |
| HTTP/API | `http` |
| Security/session | `flutter_secure_storage`, `local_auth` |
| Permissions/device | `permission_handler`, `flutter_contacts`, `image_picker`, `photo_manager`, `file_picker`, `path_provider` |
| Notifications | `flutter_local_notifications`, `firebase_core`, `firebase_messaging`, `timezone` |
| Realtime | `socket_io_client` |
| AI/audio | `flutter_tts`, `speech_to_text`, `audioplayers`, `record` |
| Documents | `pdf`, `printing` |
| UI/animation | `lottie`, `flutter_animate`, `shimmer` |
| Utilities | `url_launcher` |

### Appendix E - Requirement Traceability Summary

| Module | Main requirements |
|---|---|
| Authentication | FR-003 to FR-008, AUTH-001 to AUTH-010 |
| API Client | FR-009, NFR-003, NFR-008, SEC-001 to SEC-004 |
| Resident Management | FR-011, FR-012 |
| Medications | FR-013 to FR-015 |
| Health and Nursing | FR-016 to FR-023 |
| Social Specialist | FR-024 to FR-026 |
| Family Bridge | FR-027 to FR-033 |
| Emergency | FR-034 |
| Notifications and Realtime | FR-035 to FR-037 |
| AI | FR-038 to FR-040 |
| Volunteers | FR-041 to FR-044 |
| Settings and Accessibility | FR-046, FR-048 to FR-050 |

### Appendix F - Notes on Unclear Items

- Backend implementation source was not found in the current workspace.
- Physical database schema files were not found in the current workspace.
- Some backend endpoints are documented as added in backend patches and may require deployment verification.
- Chat media support is not treated as implemented for the messages backend because documented request support is text-only.
- Full GCP infrastructure deployment files were not found in the repository.

### العربية

تتضمن الملاحق مسرد المصطلحات، والاختصارات، وملخص هيكل المشروع، وملخص الاعتماديات، وتتبع المتطلبات، وملاحظات العناصر غير الواضحة. أهم ملاحظة هي أن كود الخادم الخلفي ومخططات قاعدة البيانات الفيزيائية والبنية التحتية السحابية ككود غير موجودة في مساحة العمل الحالية، ولذلك تم توثيقها على مستوى العقود والمنطق المتوقع فقط.

---

*End of Software Requirements Specification - Wanas - Academic Year 2025/2026*


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
