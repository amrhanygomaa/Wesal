# Wanas — Graduation Project Documentation
### وَنَس — توثيق مشروع التخرج

---

<div align="center">

# INTERNATIONAL ACADEMY OF ENGINEERING AND MEDIA SCIENCE
## الأكاديمية الدولية للهندسة وعلوم الإعلام

---

# Wanas — Smart Elderly Care Management System
## وَنَس — نظام إدارة رعاية المسنين الذكي

---

### Graduation Project Documentation
### توثيق مشروع التخرج

---

**Students / الطلاب:**

| Name | الاسم |
|------|-------|
| Amr Hani | عمرو هاني |
| Omar Eid | عمر عيد |
| Shahd Osama | شهد أسامة |
| Farah Mohamed | فرح محمد |

---

**Supervisors / المشرفون:**

| Name | الاسم |
|------|-------|
| Dr. Nabil El Ghamry | د. نبيل الغمري |
| Dr. Amina Fawzy | د. أمينة فوزي |

---

**Department / القسم:** Multimedia — Web Development / الوسائط المتعددة — تطوير الويب

**Academic Year / العام الدراسي:** 2025 / 2026

</div>

---

## Table of Contents / فهرس المحتويات

1. [Abstract / الملخص](#1-abstract)
2. [Introduction / المقدمة](#2-introduction)
3. [Problem Statement / بيان المشكلة](#3-problem-statement)
4. [Project Objectives / أهداف المشروع](#4-project-objectives)
5. [Scope of the Project / نطاق المشروع](#5-scope-of-the-project)
6. [Technologies Used / التقنيات المستخدمة](#6-technologies-used)
7. [System Overview / نظرة عامة على النظام](#7-system-overview)
8. [System Architecture / معمارية النظام](#8-system-architecture)
9. [Project Structure / هيكل المشروع](#9-project-structure)
10. [Features and Functional Requirements / الميزات والمتطلبات الوظيفية](#10-features-and-functional-requirements)
11. [Non-Functional Requirements / المتطلبات غير الوظيفية](#11-non-functional-requirements)
12. [Database Design / تصميم قاعدة البيانات](#12-database-design)
13. [API Documentation / توثيق واجهة برمجة التطبيقات](#13-api-documentation)
14. [Authentication and Authorization / المصادقة والتفويض](#14-authentication-and-authorization)
15. [User Interface Documentation / توثيق واجهة المستخدم](#15-user-interface-documentation)
16. [Main User Workflows / مسارات المستخدم الرئيسية](#16-main-user-workflows)
17. [Algorithms and Business Logic / الخوارزميات ومنطق الأعمال](#17-algorithms-and-business-logic)
18. [Error Handling and Validation / معالجة الأخطاء والتحقق](#18-error-handling-and-validation)
19. [Security Considerations / اعتبارات الأمان](#19-security-considerations)
20. [Testing / الاختبار](#20-testing)
21. [Deployment and Installation Guide / دليل النشر والتثبيت](#21-deployment-and-installation-guide)
22. [Limitations / القيود الحالية](#22-limitations)
23. [Future Enhancements / التحسينات المستقبلية](#23-future-enhancements)
24. [Conclusion / الخاتمة](#24-conclusion)
25. [References / المراجع](#25-references)

---

## 1. Abstract

### English Abstract

Wanas (Arabic: وَنَس, meaning "companionship" or "warmth of company") is a comprehensive smart elderly care management system developed as a cross-platform mobile application using the Flutter framework. The system is designed to serve nursing homes and residential care facilities by digitising, streamlining, and connecting every aspect of elderly care across six distinct user roles: Administrator, Nurse, Elderly Resident, Family Member, Social Specialist, and Volunteer.

The application addresses critical gaps in traditional nursing home management by integrating real-time communication, artificial intelligence, gamification, medication tracking, visit scheduling, social assessment tools, volunteer coordination, and data-driven reporting into a single unified platform. The backend is a RESTful API built with the NestJS framework, deployed on Google Cloud Platform (GCP) EC2, and authenticated through Google Cloud Identity Platform / Firebase Auth with JSON Web Tokens (JWT). Real-time capabilities are delivered via a WebSocket layer using Socket.IO. Data persistence relies on a PostgreSQL relational database, while binary assets are stored in Google Cloud Storage (GCS).

Wanas is designed with a strong emphasis on accessibility, supporting right-to-left (RTL) Arabic text rendering, adjustable font scaling, high-contrast modes, and dark themes. The system's AI companion feature — powered by a server-side language model — allows elderly residents to engage in meaningful conversation, receive personalised health recommendations, and interact with text-to-speech voice output, reducing isolation and improving mental well-being.

This documentation presents the complete technical and functional analysis of Wanas, covering its architecture, data models, API surface, user interface, business logic, security, and deployment strategy.

---

### الملخص العربي

وَنَس هو نظام متكامل وذكي لإدارة رعاية المسنين، تم تطويره بوصفه تطبيقًا للهاتف المحمول متعدد الأنظمة باستخدام إطار عمل Flutter. يستهدف النظام دور رعاية المسنين والمرافق السكنية المتخصصة، ويعمل على رقمنة جميع جوانب الرعاية وتبسيطها وربطها ضمن ستة أدوار مستخدم رئيسية: المدير، والممرض، والمقيم المسن، وعضو الأسرة، والأخصائي الاجتماعي، والمتطوع.

يعالج التطبيق الفجوات الجوهرية في أنظمة إدارة دور الرعاية التقليدية من خلال دمج التواصل الفوري، والذكاء الاصطناعي، وأنظمة التلعيب، وتتبع الأدوية، وجدولة الزيارات، وأدوات التقييم الاجتماعي، وتنسيق التطوع، وإعداد التقارير المبنية على البيانات — كل ذلك في منصة موحدة ومتكاملة.

يُعدّ وَنَس نظامًا أكاديميًا متكاملًا يجمع بين الهندسة البرمجية المتقدمة وتقنيات الذكاء الاصطناعي وقابلية الوصول لذوي الإعاقة، مع مراعاة الاحتياجات الخاصة لكبار السن من حيث الواجهة والتصميم والتفاعل.

---

## 2. Introduction

### English

The global population is ageing at an unprecedented rate. According to the World Health Organization, the number of people aged 60 years and older is expected to double by 2050, reaching approximately 2.1 billion. This demographic shift places enormous pressure on healthcare systems and care facilities, which must simultaneously manage complex medical needs, family communication, regulatory compliance, staff coordination, and the emotional well-being of residents.

Traditional nursing home management systems are typically fragmented — relying on paper-based records, disconnected spreadsheets, or isolated software modules that do not communicate with one another. This fragmentation leads to medication errors, delayed family communication, inadequate social assessment, and reduced transparency in care delivery.

Wanas was conceived and developed as a direct response to these challenges. The name itself reflects the system's core philosophy: "wanas" (وَنَس) in Arabic means the warmth and comfort of company — a feeling of not being alone. This philosophy permeates every feature of the application, from the AI companion that talks to elderly residents, to the voice message system through which family members can send recorded messages, to the gamified activity system that encourages daily engagement and mental stimulation.

This documentation records the full technical realisation of the Wanas system, providing a thorough academic account of its design decisions, implementation details, data models, API contracts, user experience flows, and deployment infrastructure.

---

### المقدمة (عربي)

يشهد العالم شيخوخةً متسارعة غير مسبوقة؛ إذ تتوقع منظمة الصحة العالمية أن يتضاعف عدد الأشخاص الذين تجاوزوا الستين من العمر ليبلغ نحو 2.1 مليار شخص بحلول عام 2050. يضع هذا التحول الديموغرافي ضغطًا هائلًا على منظومات الرعاية الصحية ودور الرعاية، التي يتوجب عليها إدارة احتياجات طبية معقدة وتواصل الأسر ومتابعة الموظفين ورصد الرفاه النفسي للمقيمين — في آنٍ واحد.

جاء مشروع وَنَس استجابةً مباشرة لهذه التحديات؛ فالاسم يحمل في طياته فلسفة المشروع بأسرها: "وَنَس" في اللغة العربية تعني دفء المؤانسة وراحة وجود الآخرين — شعور عدم الوحدة. وهذه الفلسفة تتجلى في كل ميزة من ميزات التطبيق، بدءًا من الرفيق الذكي الذي يتحدث مع المسنين، ومرورًا بنظام الرسائل الصوتية الذي يُتيح لأفراد الأسرة إرسال تسجيلات صوتية، وصولًا إلى نظام الأنشطة المُلعَّبة الذي يحفز المشاركة اليومية والتحفيز العقلي.

---

## 3. Problem Statement

### English

Nursing homes and elder care facilities face a set of interconnected operational and social problems that no single existing tool adequately addresses:

**Operational Problems:**
- Medication administration is often tracked manually, leading to errors, missed doses, and poor adherence documentation.
- Shift handovers between nursing staff are verbal or paper-based, causing loss of critical patient information.
- Care task assignment and completion tracking lack digital audit trails.
- Staff performance monitoring relies on subjective supervisor observation rather than objective data.

**Communication Problems:**
- Family members have no reliable, real-time window into the daily life and health status of their relatives in care.
- Communication between families and social specialists is ad-hoc and poorly documented.
- Elderly residents often feel isolated from their families, especially in facilities that restrict physical visits.

**Social and Psychological Problems:**
- Formal psychological and social assessments (such as Geriatric Depression Scale assessments) are conducted infrequently and documented on paper.
- Volunteers who could significantly improve resident well-being lack a structured platform for engagement, scheduling, and recognition.
- Elderly residents have limited access to engaging activities or cognitive stimulation tools adapted to their abilities.

**Administrative Problems:**
- Facility administrators lack a consolidated dashboard offering real-time operational metrics, KPIs, and AI-generated alerts.
- Resident admission, document management, and billing are managed through disconnected tools.
- Visit approval workflows are manual and slow.

Wanas was designed specifically to solve all of these problems through a single, integrated, role-aware mobile platform.

---

### بيان المشكلة (عربي)

تعاني دور رعاية المسنين من جملة من المشكلات المترابطة التي لا يعالجها أيٌّ من الحلول الحالية بشكل شامل:

- **المشكلات التشغيلية:** يُدار صرف الأدوية يدويًا في الغالب مما يُفضي إلى أخطاء وجرعات فائتة. وتتم إحاطات تسليم المناوبات شفهيًا دون توثيق رقمي.
- **مشكلات التواصل:** لا يملك أفراد الأسرة نافذةً موثوقة وآنية على الحياة اليومية لذويهم داخل دور الرعاية. ويظل التواصل مع الأخصائيين الاجتماعيين غير منتظم وغير موثق.
- **المشكلات الاجتماعية والنفسية:** تُجرى التقييمات النفسية والاجتماعية بصورة متقطعة على ورق، فيما يفتقر المتطوعون إلى منصة منظمة للمشاركة والجدولة والتقدير.
- **المشكلات الإدارية:** يفتقر مديرو المرافق إلى لوحة تحكم موحدة تعرض المقاييس التشغيلية الآنية والتنبيهات المُولَّدة بالذكاء الاصطناعي.

صُمِّم وَنَس تحديدًا لمعالجة كل هذه المشكلات من خلال منصة موحدة واحدة تراعي الأدوار المختلفة.

---

## 4. Project Objectives

### English

#### 4.1 Functional Objectives

1. Provide a dedicated, role-specific mobile interface for each of the six user roles: Administrator, Nurse, Elderly Resident, Family Member, Social Specialist, and Volunteer.
2. Digitise the complete medication management lifecycle — from prescription to administration to adherence reporting.
3. Enable real-time communication between all stakeholders through text chat, voice messages, and video calls.
4. Implement an AI companion for elderly residents offering conversational support, health recommendations, and text-to-speech voice output.
5. Provide a structured social assessment toolkit enabling Social Specialists to conduct and record standardised psychological assessments.
6. Build a volunteer management system with opportunity listings, booking, rating, certification, and document management.
7. Enable families to book and track physical and video visits, receive care reports, and communicate with specialists.
8. Give administrators a real-time dashboard with KPIs, AI-generated alerts, staff performance metrics, and facility configuration tools.
9. Support emergency SOS alerts from elderly residents or nursing staff.
10. Provide a gamified activity and cognitive game system to improve elderly resident engagement and mental well-being.

#### 4.2 Technical Objectives

1. Implement a clean, scalable architecture separating concerns into models, services, providers, and screens.
2. Achieve full RTL Arabic support across all screens and components.
3. Maintain accessibility standards including adjustable font scaling, high-contrast mode, and dark mode.
4. Integrate with a production-grade REST API secured by Google Cloud Identity Platform / Firebase Auth JWT authentication.
5. Implement real-time event delivery via Socket.IO WebSocket connections.
6. Support push notifications via Firebase Cloud Messaging (FCM) and local scheduling.
7. Implement secure local storage for authentication tokens using Flutter Secure Storage.
8. Support biometric authentication (fingerprint / face recognition) as an optional login method.
9. Enable PDF generation and export for care reports.
10. Integrate Google Cloud Storage (GCS) presigned upload for profile images, documents, and media assets.

#### 4.3 Educational Objectives

1. Demonstrate mastery of the Flutter framework and Dart programming language at a production level.
2. Apply the Riverpod state management pattern across a complex, multi-role application.
3. Integrate a NestJS backend with a PostgreSQL database and GCP cloud services.
4. Apply software engineering principles including separation of concerns, single responsibility, and DRY.
5. Demonstrate the integration of AI services into a consumer mobile application.

---

### أهداف المشروع (عربي)

#### الأهداف الوظيفية
- توفير واجهة مخصصة لكل دور من الأدوار الستة مع ميزات فريدة لكل منها.
- رقمنة دورة حياة إدارة الأدوية بالكامل من الوصفة حتى التقرير.
- تمكين التواصل الآني بين جميع الأطراف عبر الدردشة النصية والرسائل الصوتية ومكالمات الفيديو.
- تطبيق رفيق ذكاء اصطناعي للمسنين يوفر الدعم التحادثي والتوصيات الصحية والمخرجات الصوتية.

#### الأهداف التقنية
- بناء معمارية نظيفة وقابلة للتوسع تفصل بين النماذج والخدمات والمزودين والشاشات.
- تحقيق دعم كامل للغة العربية من اليمين إلى اليسار عبر جميع الشاشات.
- التكامل مع واجهة REST API محمية بـ Google Cloud Identity Platform / Firebase Auth.

---

## 5. Scope of the Project

### English

#### 5.1 In Scope

The following capabilities are implemented within the Wanas system:

- **Multi-role mobile application** supporting six user roles on Android and iOS via Flutter.
- **Administrator module** with resident management, staff management, visit approval, AI alert review, volunteer oversight, report generation, and facility settings configuration.
- **Nurse module** with resident list, detailed medical profiles, medication administration logging, care task tracking, shift handoff notes, nursing reports, and inventory awareness.
- **Elderly Resident module** with a simplified home dashboard, medication reminders, family calling, voice message playback, photo/video memory albums, daily activities, cognitive games, and an AI companion.
- **Family Member module** with resident status monitoring, visit booking, care report access, billing overview, chat with social specialist, and media sharing.
- **Social Specialist module** with structured assessment tools, complaint management, resident file management, KPI tracking, and family communication.
- **Volunteer module** with opportunity browsing, booking, attendance, rating, certificate earning, CV/document upload, and a public shareable profile.
- **AI features** including a conversational companion, personalised health recommendations, AI-generated care notes, and text-to-speech voice output.
- **Real-time infrastructure** via Socket.IO WebSocket for live event broadcasting.
- **Push notifications** via Firebase Cloud Messaging and local device scheduling.
- **PDF generation** for nursing care reports exportable to print or file.
- **Biometric authentication** as an optional login method.
- **Accessibility** features including font scaling, dark mode, and high-contrast mode.
- **Google Cloud Storage (GCS) integration** for profile photos, documents, and media uploads.
- **Emergency SOS** alert system with contact notification.

#### 5.2 Out of Scope

The following are explicitly outside the current scope of Wanas:

- **Web browser application** — Wanas is a native mobile application only; no web frontend is included.
- **Wearable device integration** — Smart watches or health monitoring hardware are not supported.
- **Electronic Health Records (EHR) system integration** — No FHIR or HL7 interfaces are implemented.
- **Billing payment gateway** — Financial transactions are tracked but no online payment processing is included.
- **Multi-language support** — The application is Arabic-first; English language localisation is not implemented in this version.
- **Offline-first architecture** — The application requires an active internet connection; no offline data sync is implemented.
- **Third-party video conferencing SDK** — Zoom integration references exist in the codebase but the full Zoom SDK is not bundled.

---

### نطاق المشروع (عربي)

#### داخل النطاق
يشمل نظام وَنَس: تطبيق الهاتف متعدد الأدوار لستة أدوار مستخدم، وحدة المدير مع الإدارة الشاملة، وحدة الممرض لتتبع الأدوية والمهام، وحدة المسن مع الرفيق الذكي والألعاب المعرفية، وحدة الأسرة لمتابعة المقيم وحجز الزيارات، وحدة الأخصائي الاجتماعي للتقييم وإدارة الشكاوى، وحدة المتطوع للفرص والحجوزات والشهادات، والبنية التحتية للزمن الفعلي عبر Socket.IO.

#### خارج النطاق
لا يشمل النظام حاليًا: تطبيق ويب، تكامل أجهزة قابلة للارتداء، بوابة دفع إلكتروني، دعم اللغة الإنجليزية كاملًا، أو معمارية عمل دون اتصال بالإنترنت.

---

## 6. Technologies Used

### English

The Wanas system is built on a modern, carefully selected technology stack spanning the mobile client, backend API, cloud infrastructure, and third-party services.

#### 6.1 Frontend / Mobile Client

| Technology | Version | Purpose | Where Used |
|---|---|---|---|
| **Flutter** | 3.x | Cross-platform mobile framework | Entire mobile application |
| **Dart** | ≥3.0.0 | Programming language | All application logic |
| **Flutter Riverpod** | ^2.5.1 | State management | `lib/providers/app_riverpod.dart` |
| **Material Design 3** | Built-in | UI component system | All screens and widgets |
| **Cairo Font** | 8 weights | Arabic typography (200–900) | `pubspec.yaml` font assets |
| **flutter_localizations** | SDK | RTL Arabic rendering, locale | `main.dart`, app-wide |
| **flutter_animate** | ^4.5.0 | Declarative animations | Dashboard transitions, effects |
| **shimmer** | ^3.0.0 | Loading skeleton screens | Data-loading states |
| **lottie** | ^3.1.0 | JSON-based vector animations | Splash screen, onboarding, empty states |
| **flutter_native_splash** | ^2.4.0 | Native splash screen generation | `pubspec.yaml` splash config |

#### 6.2 Networking and Real-Time

| Technology | Version | Purpose | Where Used |
|---|---|---|---|
| **http** | any | HTTP REST API client | `lib/services/api_client.dart` |
| **socket_io_client** | ^2.0.3+1 | WebSocket (Socket.IO) real-time events | `lib/services/realtime_service.dart` |

#### 6.3 Authentication and Security

| Technology | Version | Purpose | Where Used |
|---|---|---|---|
| **Google Cloud Identity Platform / Firebase Auth** | Cloud service | User pool, identity management, JWT issuance | `lib/services/auth_service.dart` |
| **flutter_secure_storage** | ^10.0.0 | Encrypted local storage for JWT tokens | `lib/services/api_client.dart` |
| **local_auth** | ^2.3.0 | Biometric authentication (fingerprint/face) | `lib/services/biometric_service.dart` |

#### 6.4 Notifications

| Technology | Version | Purpose | Where Used |
|---|---|---|---|
| **firebase_core** | ^3.6.0 | Firebase SDK initialisation | `lib/main.dart` |
| **firebase_messaging** | ^15.1.3 | Firebase Cloud Messaging push notifications | `lib/services/push_notification_service.dart` |
| **flutter_local_notifications** | ^17.1.2 | Local device notification scheduling | `lib/services/notification_service.dart` |
| **timezone** | ^0.9.4 | Timezone-aware notification scheduling | `lib/services/notification_service.dart` |

#### 6.5 Media and File Handling

| Technology | Version | Purpose | Where Used |
|---|---|---|---|
| **image_picker** | ^1.0.7 | Camera / gallery image selection | Profile photos, media sharing |
| **photo_manager** | ^3.9.0 | Device photo library access | `lib/screens/elderly/memories_screen.dart` |
| **photo_manager_image_provider** | ^2.2.0 | Efficient device photo display | Memory albums |
| **file_picker** | 8.1.7 | General file selection dialog | Document uploads, CV |
| **record** | ^6.2.1 | Audio recording | Voice message recording |
| **audioplayers** | ^6.4.0 | Audio playback | Voice message playback |
| **path_provider** | ^2.1.5 | File system path resolution | Temp/document directories |

#### 6.6 AI and Accessibility

| Technology | Version | Purpose | Where Used |
|---|---|---|---|
| **flutter_tts** | ^4.2.0 | Text-to-speech output | AI companion voice output |
| **speech_to_text** | ^7.3.0 | Voice command / speech recognition | AI companion voice input |

#### 6.7 Documents and Utilities

| Technology | Version | Purpose | Where Used |
|---|---|---|---|
| **pdf** | ^3.12.0 | Programmatic PDF generation | Nursing care report export |
| **printing** | ^5.14.3 | PDF preview and print dialogs | Report printing |
| **url_launcher** | ^6.3.2 | Open URLs, make phone calls, send SMS | Emergency contacts, links |
| **flutter_contacts** | 1.1.9 | Device contacts access | Family member import |
| **permission_handler** | ^11.3.1 | Runtime permission management | Camera, microphone, storage |

#### 6.8 Backend Infrastructure

| Technology | Purpose | Details |
|---|---|---|
| **NestJS** | Backend REST API framework | TypeScript, modular architecture |
| **PostgreSQL** | Relational database | Primary data store for all entities |
| **Amazon Web Services EC2** | Backend server hosting | Deployed instance running the NestJS API |
| **Google Cloud Identity Platform / Firebase Auth** | Identity and Access Management | User pools, JWT issuance, auth flows |
| **Google Cloud Storage (GCS)** | Object storage | Profile photos, documents, media, reports |
| **Google Cloud Text-to-Speech** | Text-to-speech (server-side) | AI companion speech synthesis (`/ai/speech` endpoint) |
| **Firebase** | Push notification infrastructure | Firebase Cloud Messaging (FCM) project: `raaya-taptaba-app` |
| **Socket.IO** | WebSocket server | Real-time event broadcasting |

---

### التقنيات المستخدمة (عربي)

يعتمد نظام وَنَس على مجموعة تقنيات حديثة ومتكاملة تشمل:

- **Flutter / Dart** كإطار عمل لتطبيق الهاتف متعدد الأنظمة.
- **Riverpod** لإدارة حالة التطبيق بنمط نظيف وقابل للاختبار.
- **NestJS** كإطار عمل للواجهة الخلفية مبنيٍّ بـ TypeScript.
- **PostgreSQL** كقاعدة بيانات علائقية رئيسية.
- **Google Cloud Identity Platform / Firebase Auth** لإدارة الهوية وإصدار رموز JWT.
- **Google Cloud Storage (GCS)** لتخزين الملفات والصور والوثائق.
- **Firebase Cloud Messaging** للإشعارات الفورية.
- **Socket.IO** للاتصال الآني ثنائي الاتجاه.
- **Google Cloud Text-to-Speech** لتحويل النص إلى صوت في ميزة الرفيق الذكي.

---

## 7. System Overview

### English

Wanas is a three-tier client–server system composed of:

1. **Mobile Client (Flutter)** — A cross-platform application distributed to Android and iOS devices. The client handles all user interaction, local state management, UI rendering, and communication with the backend API. Six independent UI sub-systems serve six distinct user roles, each with a tailored navigation structure and feature set.

2. **Backend API (NestJS on Google Compute Engine (GCE))** — A RESTful HTTP API served at `https://api.helpers-tech.com`. It handles business logic, database operations, file storage coordination (via S3 presigned URLs), AI model orchestration, push notification delivery, and real-time event broadcasting. Authentication is enforced at every protected endpoint via JWT bearer tokens issued by Google Cloud Identity Platform / Firebase Auth.

3. **Cloud Services Layer (GCP + Firebase)** — A set of managed cloud services that augment the backend: Google Cloud Identity Platform / Firebase Auth for identity management, Google Cloud Storage (GCS) for binary file storage, Google Cloud Text-to-Speech for speech synthesis, and Firebase Cloud Messaging for push notification delivery.

### Data Flow Summary

```
[User Action on Flutter App]
        │
        ▼
[Riverpod Provider] ─── updates ──▶ [UI Widget Tree]
        │
        ▼
[Service Layer] ─── HTTP / WebSocket ──▶ [NestJS API on Google Compute Engine (GCE)]
                                                │
                              ┌─────────────────┼──────────────────┐
                              ▼                 ▼                  ▼
                      [PostgreSQL DB]    [Google Cloud Storage (GCS) Storage]   [Google Cloud Identity Platform / Firebase Auth]
                                                │
                              ┌─────────────────┘
                              ▼
                      [Firebase FCM] ──▶ [Device Push Notification]
```

### Role Interaction Overview

Every user role in Wanas interacts with a different subset of system features, but the data they interact with is shared and consistent. For example:
- A **Nurse** logs a medication dose → a **Family Member** sees updated adherence data → the **Administrator** sees an alert if adherence drops below threshold → the **AI** incorporates this into its care recommendations.
- A **Family Member** books a visit → the **Administrator** receives an approval request → after approval, the **Elderly Resident** sees the upcoming visit on their dashboard.

---

### نظرة عامة على النظام (عربي)

وَنَس نظام ذو ثلاث طبقات:

- **تطبيق الهاتف (Flutter):** يتعامل مع المستخدم ويعرض الواجهات ويتواصل مع الواجهة الخلفية عبر HTTP وWebSocket.
- **واجهة برمجية خلفية (NestJS على Google Compute Engine (GCE)):** تُنفِّذ منطق الأعمال وتُدير قاعدة البيانات وتُنسِّق خدمات السحابة.
- **طبقة الخدمات السحابية (GCP + Firebase):** تشمل Cognito للهوية، وS3 للتخزين، وPolly للكلام، وFCM للإشعارات.

تتدفق البيانات من فعل المستخدم في التطبيق عبر Riverpod ثم إلى طبقة الخدمات ثم إلى الواجهة البرمجية وقاعدة البيانات، مع ضمان تزامن البيانات بين جميع الأدوار في الوقت الفعلي.

---

## 8. System Architecture

### English

#### 8.1 High-Level Architecture Diagram

```mermaid
graph TB
    subgraph "Mobile Client - Flutter"
        UI[UI Layer\nScreens & Widgets]
        PRV[State Layer\nRiverpod Providers]
        SVC[Service Layer\n35+ Service Classes]
        CFG[Config\nApiConfig]
    end

    subgraph "Backend - NestJS on Google Compute Engine (GCE)"
        AUTH[Auth Module\nCognito + JWT Guard]
        RESI[Residents Module]
        MEDS[Medications Module]
        NURSE[Nursing Module]
        FAMILY[Family Bridge Module]
        VOL[Volunteers Module]
        SOC[Social Module]
        AI[AI Module\nLLM + Polly TTS]
        NOTIF[Notifications Module]
        RT[Real-Time\nSocket.IO Gateway]
    end

    subgraph "Cloud Services"
        COGI[Google Cloud Identity Platform / Firebase Auth\nUser Pool]
        S3[Google Cloud Storage (GCS)\nFile Storage]
        POLLY[Google Cloud Text-to-Speech\nText-to-Speech]
        FCM[Firebase FCM\nPush Notifications]
        PG[(PostgreSQL\nDatabase)]
    end

    UI -->|observe| PRV
    PRV -->|calls| SVC
    SVC -->|HTTPS REST| AUTH
    SVC -->|HTTPS REST| RESI
    SVC -->|HTTPS REST| MEDS
    SVC -->|HTTPS REST| NURSE
    SVC -->|HTTPS REST| FAMILY
    SVC -->|HTTPS REST| VOL
    SVC -->|HTTPS REST| SOC
    SVC -->|HTTPS REST| AI
    SVC -->|HTTPS REST| NOTIF
    SVC -->|WebSocket| RT

    AUTH --> COGI
    AUTH --> PG
    RESI --> PG
    MEDS --> PG
    NURSE --> PG
    FAMILY --> PG
    FAMILY --> S3
    VOL --> PG
    VOL --> S3
    SOC --> PG
    AI --> POLLY
    AI --> PG
    NOTIF --> FCM
    NOTIF --> PG
    RT --> PG
```

#### 8.2 Flutter Application Architecture

Wanas follows a layered architecture within the Flutter codebase:

| Layer | Components | Responsibility |
|---|---|---|
| **Presentation Layer** | `lib/screens/`, `lib/widgets/` | Renders UI, handles user gestures, displays data from providers |
| **State Management Layer** | `lib/providers/app_riverpod.dart` | Holds application state, triggers service calls, notifies UI |
| **Service Layer** | `lib/services/*.dart` (35+ files) | Communicates with backend API and device APIs, returns parsed models |
| **Model Layer** | `lib/models/app_models.dart` | Plain Dart data classes representing all system entities |
| **Configuration Layer** | `lib/config/api_config.dart` | API base URL, Cognito identifiers, environment constants |
| **Theme Layer** | `lib/theme/app_theme.dart` | Colours, typography, spacing, shadows, gradients |

#### 8.3 User Flow Diagram

```mermaid
flowchart TD
    A[App Launch] --> B{First Time?}
    B -->|Yes| C[Onboarding Screen]
    B -->|No| D{Authenticated?}
    C --> D
    D -->|No| E[Login Screen]
    D -->|Yes| F{User Role?}
    E --> G[Registration Screen]
    E --> F
    G --> F

    F -->|مسن - Elderly| H[Elderly Dashboard\nHome · Meds · Calls · Memories · Activities]
    F -->|ممرض - Nurse| I[Nurse Dashboard\nResidents · Meds · Reports · Tasks]
    F -->|أسرة - Family| J[Family Dashboard\nStatus · Visits · Reports · Chat]
    F -->|أخصائي - Specialist| K[Specialist Dashboard\nAssessments · Complaints · Files · KPIs]
    F -->|متطوع - Volunteer| L[Volunteer Dashboard\nOpportunities · Bookings · Ratings · Certs]
    F -->|إدارة - Admin| M[Admin Dashboard\nResidents · Staff · Visits · AI Alerts · Reports]
```

#### 8.4 Database Entity Relationship Overview

```mermaid
erDiagram
    FACILITIES ||--o{ RESIDENTS : houses
    FACILITIES ||--o{ MANAGED_USERS : employs
    RESIDENTS ||--o{ MEDICATIONS : has
    RESIDENTS ||--o{ FAMILY_MEMBERS : linked_to
    RESIDENTS ||--o{ CARE_TASKS : assigned
    RESIDENTS ||--o{ NURSING_NOTES : documented_in
    RESIDENTS ||--o{ COMPLAINTS : subject_of
    RESIDENTS ||--o{ SOCIAL_ASSESSMENTS : evaluated_by
    RESIDENTS ||--o{ AI_RESIDENT_MEMORY : stored_in
    RESIDENTS ||--o{ MEMORIES : has
    MANAGED_USERS ||--o{ HANDOFFS : creates
    MANAGED_USERS ||--o{ STAFF_REVIEWS : receives
    FAMILY_MEMBERS ||--o{ VISITS : books
    FAMILY_MEMBERS ||--o{ BILLING : pays
    MANAGED_USERS ||--o{ VOLUNTEER_BOOKINGS : attends
    MANAGED_USERS ||--o{ VOLUNTEER_CERTIFICATES : earns
    NOTIFICATIONS }o--|| MANAGED_USERS : targets
    VIDEO_CALLS }o--|| RESIDENTS : involves
    MEDICATIONS ||--o{ MEDICATION_DOSES : logged_as
```

---

### معمارية النظام (عربي)

يتبع وَنَس معمارية طبقية واضحة داخل تطبيق Flutter:

- **طبقة العرض:** الشاشات والمكونات التي تعرض البيانات وتتلقى تفاعلات المستخدم.
- **طبقة إدارة الحالة:** مزودو Riverpod الذين يحملون حالة التطبيق وينسقون المكالمات.
- **طبقة الخدمات:** أكثر من 35 فئة خدمة تتواصل مع الواجهة البرمجية الخلفية.
- **طبقة النماذج:** فئات Dart البيانية التي تمثل كيانات النظام.
- **طبقة الإعداد:** ثوابت الواجهة البرمجية وإعدادات Cognito.

على جانب الخلفية، تُنظَّم الوحدات بحسب المجال (المقيمون، الأدوية، التمريض، الأسرة، المتطوعون، الأخصائي، الذكاء الاصطناعي، الإشعارات)، وتتشارك جميعها قاعدة بيانات PostgreSQL واحدة وبنية تحتية سحابية مشتركة.

---

## 9. Project Structure

### English

The project is organised following Flutter conventions with domain-based grouping inside the `lib/` directory.

```
Tbtba-main/
├── lib/
│   ├── main.dart                    # App entry point; routing, theme, session management
│   ├── nav_wrapper.dart             # Bottom-nav wrapper for the Elderly role
│   ├── constants.dart               # App-wide constants and shared utilities
│   ├── firebase_options.dart        # Auto-generated Firebase configuration
│   ├── config/
│   │   └── api_config.dart          # API base URL, Cognito pool/client IDs, timeouts
│   ├── models/
│   │   └── app_models.dart          # All 50+ data model classes (~1,629 lines)
│   ├── providers/
│   │   └── app_riverpod.dart        # Single Riverpod ChangeNotifier (800+ lines)
│   ├── services/                    # 35+ service classes — one per domain
│   │   ├── api_client.dart          # HTTP client with JWT injection and token storage
│   │   ├── auth_service.dart        # Google Cloud Identity Platform / Firebase Auth login / register / refresh / logout
│   │   ├── backend_sync_service.dart     # Full data load snapshot from backend
│   │   ├── backend_mutation_service.dart # Create / update write operations
│   │   ├── realtime_service.dart    # Socket.IO WebSocket connection and event stream
│   │   ├── medications_service.dart # Medication schedules, doses, overdue
│   │   ├── ai_service.dart          # AI chat, recommendations, speech synthesis
│   │   ├── video_call_service.dart  # Video call lifecycle management
│   │   ├── voice_message_service.dart    # Voice recording, upload, playback
│   │   ├── notification_service.dart     # Local notification scheduling
│   │   ├── push_notification_service.dart # Firebase FCM token registration
│   │   ├── complaints_service.dart  # Complaint CRUD and status workflow
│   │   ├── health_service.dart      # Vitals, health alerts, thresholds
│   │   ├── kpi_service.dart         # KPI aggregation and history
│   │   ├── emergency_service.dart   # SOS trigger and emergency contact management
│   │   ├── messages_service.dart    # Chat messages (text, with future media)
│   │   ├── residents_service.dart   # Resident CRUD
│   │   ├── social_service.dart      # Assessments, GDS questions, resident scores
│   │   ├── facility_settings_service.dart # Facility profile, billing, emergency contacts
│   │   ├── pdf_service.dart         # PDF generation for care reports
│   │   ├── profile_image_service.dart    # S3 presigned photo upload / confirm
│   │   ├── resident_document_service.dart # Medical document management
│   │   ├── biometric_service.dart   # Fingerprint / face ID authentication
│   │   └── [15 more service files] # Volunteer, family, admin, progress, preferences, etc.
│   ├── screens/                     # Role-based screen modules
│   │   ├── onboarding/              # Splash and intro tutorial
│   │   ├── auth/                    # Login, register (self and admin), forgot password
│   │   ├── elderly/                 # 9 screens for the Elderly Resident role
│   │   ├── nurse/                   # 9 screens + 2 view tabs for the Nurse role
│   │   ├── family/                  # 7 screens for the Family Member role
│   │   ├── specialist/              # 7 screens + views for the Social Specialist role
│   │   ├── volunteer/               # 6 screens for the Volunteer role
│   │   ├── admin/                   # 12 screens + views for the Administrator role
│   │   ├── common/                  # 9 cross-role screens (profile, settings, about, etc.)
│   │   └── chat/                    # Family–resident text chat screen
│   ├── widgets/                     # Reusable UI components
│   │   ├── ai_companion_chat.dart   # AI chatbot widget (bottom sheet overlay)
│   │   ├── ai_insights_panel.dart   # AI recommendations panel
│   │   ├── bottom_nav_bar.dart      # Role-specific bottom navigation bar
│   │   ├── taptaba_scaffold.dart    # Standard page scaffold (title, back, body)
│   │   ├── draggable_sos.dart       # Floating, draggable emergency SOS button
│   │   ├── live_*.dart              # 10 real-time data banner widgets
│   │   ├── accessibility_dialog.dart # Font scale and contrast settings dialog
│   │   └── [other reusable components]
│   └── theme/
│       └── app_theme.dart           # Complete design system (colours, spacing, shadows, typography)
├── assets/
│   ├── animations/                  # Lottie JSON animation files
│   ├── fonts/                       # Cairo Arabic font (8 weight variants)
│   └── icons/                       # App icons and image assets
├── external/
│   └── raaya-backend/               # Backend NestJS source code (included for reference)
├── docs/                            # Developer documentation
│   ├── backend-contract.md          # API endpoint contract specifications
│   ├── backend-gap-analysis.md      # Frontend/backend alignment analysis
│   └── mock-audit.md                # Mock data audit report
├── pubspec.yaml                     # Flutter dependency manifest
└── README.md                        # Basic project readme
```

#### Key File Descriptions

| File / Folder | Purpose |
|---|---|
| `lib/main.dart` | Bootstraps the app, sets portrait orientation, wraps in `ProviderScope`, routes to splash → onboarding → login → role dashboard |
| `lib/models/app_models.dart` | Single file containing all 50+ Dart data model classes with `copyWith()` methods and computed getters |
| `lib/providers/app_riverpod.dart` | Central Riverpod `ChangeNotifier` managing authentication state, user data, loaded backend data, and accessibility settings |
| `lib/config/api_config.dart` | Configuration constants: API base URL (`https://api.helpers-tech.com`), Cognito region/pool/client, request timeout |
| `lib/theme/app_theme.dart` | Complete design token system: colour palette, spacing scale, border radii, shadow definitions, gradient presets |
| `lib/services/api_client.dart` | `ApiClient` singleton: attaches JWT `Authorization: Bearer` headers, handles token refresh on 401, wraps `http` package |
| `lib/services/backend_sync_service.dart` | `syncBackendData()`: parallel fetching of all data domains into a `BackendSyncSnapshot` |

---

### هيكل المشروع (عربي)

يتبع المشروع بنية Flutter التقليدية مع تجميع بحسب المجال داخل مجلد `lib/`. تشمل المجلدات الرئيسية:

- `models/` — نماذج البيانات (50+ نموذج في ملف واحد).
- `providers/` — إدارة الحالة المركزية بـ Riverpod.
- `services/` — أكثر من 35 خدمة للتواصل مع الواجهة البرمجية وخدمات الجهاز.
- `screens/` — شاشات مُقسَّمة بحسب دور المستخدم (onboarding, auth, elderly, nurse, family, specialist, volunteer, admin, common, chat).
- `widgets/` — مكونات واجهة المستخدم القابلة لإعادة الاستخدام.
- `theme/` — نظام تصميم متكامل بالألوان والمسافات والخطوط.

---

## 10. Features and Functional Requirements

### English

#### 10.1 Authentication and Onboarding

| Feature | Description | Roles | Related Files |
|---|---|---|---|
| Animated Splash Screen | Lottie animation shown on app launch with brand identity | All | `screens/onboarding/splash_screen.dart` |
| First-Run Onboarding | Multi-page tutorial explaining the app to new users | All | `screens/onboarding/onboarding_screen.dart` |
| Email / Password Login | Authenticate via backend Cognito integration returning JWT tokens | All | `screens/auth/login_screen.dart`, `services/auth_service.dart` |
| Self-Registration | Family members and volunteers register themselves | Family, Volunteer | `screens/auth/register_screen.dart` |
| Admin / Facility Registration | Administrator registers the facility and creates the first admin account | Admin | `screens/auth/admin_register_screen.dart` |
| Forgot Password | Email-based password reset via Google Cloud Identity Platform / Firebase Auth | All | `screens/auth/forgot_password_screen.dart` |
| Biometric Login | Optional fingerprint or face ID authentication | All | `services/biometric_service.dart` |
| Session Persistence | JWT stored securely; auto-restored on relaunch | All | `services/api_client.dart`, `flutter_secure_storage` |
| Token Refresh | Automatic JWT refresh before expiry using Cognito Refresh Token | All | `services/auth_service.dart` |
| Facility Search (Guest) | Unauthenticated users can search for and enquire about facilities | Guest | `services/facility_inquiry_service.dart` |

#### 10.2 Elderly Resident Features

| Feature | Description | Input | Output | Related Files |
|---|---|---|---|---|
| Personalised Home Dashboard | Displays greeting, daily points, streak, quick stats, and upcoming activities | Backend sync data | Welcome screen with live data | `screens/elderly/home_screen.dart` |
| Medication Reminders | Lists today's medications with taken/skipped/missed status | Medication schedule from API | Visual adherence tracker | `screens/elderly/medication_screen.dart` |
| Confirm / Skip Medication | Resident confirms taking or skips a dose with reason | Tap action + optional skip reason | Backend dose log updated | `screens/elderly/medication_screen.dart`, `services/medications_service.dart` |
| Family Video / Voice Calls | Browse family contacts and initiate Zoom-based video calls | Family member selection | Video call initiated | `screens/elderly/calls_screen.dart`, `services/video_call_service.dart` |
| Memory Albums | View shared photos and videos uploaded by family | Media from API | Gallery with categories | `screens/elderly/memories_screen.dart` |
| Voice Messages | Play audio messages recorded and sent by family | Voice message list from API | Audio playback | `screens/elderly/voice_messages_playback_screen.dart` |
| Daily Activities | View scheduled group activities with points reward | Activity list from API | Gamified activity list | `screens/elderly/activities_screen.dart` |
| Cognitive Games | Brain training exercises with scoring and feedback | Game interaction | Score + AI feedback | `screens/elderly/cognitive_games_screen.dart` |
| AI Companion Chat | Conversational AI available 24/7 for support and health questions | Text or voice input | AI text + TTS voice reply | `widgets/ai_companion_chat.dart`, `services/ai_service.dart` |
| Gamification System | Points, badges, and streak tracking for activity participation | Completed activities | Badge unlocks, score updates | `services/user_progress_service.dart`, `providers/app_riverpod.dart` |
| Emergency SOS | Draggable floating SOS button triggers an emergency alert | One-tap hold gesture | Emergency alert sent to staff | `widgets/draggable_sos.dart`, `services/emergency_service.dart` |

#### 10.3 Nurse / Care Staff Features

| Feature | Description | Input | Output | Related Files |
|---|---|---|---|---|
| Nurse Dashboard | Shift overview with stats, alerts, pending tasks, and overdue medications | Backend sync snapshot | Multi-tab dashboard | `screens/nurse/nurse_dashboard_screen.dart` |
| Resident List | Full list of facility residents with health status indicators | `/residents` API | Resident cards with status | `screens/nurse/nurse_residents_screen.dart` |
| Resident Medical Profile | Detailed view: medications, vitals, allergies, diagnoses, care notes, doctor visits | Resident ID → API calls | Comprehensive medical file | `screens/nurse/nurse_resident_detail_screen.dart` |
| Medication Administration Log | Record that a specific dose was administered, with timestamp and notes | Dose confirmation tap | POST to `/medications/doses` | `screens/nurse/nurse_medications_screen.dart` |
| Care Task Management | View, complete, reopen, and delete daily care tasks | Task action | PATCH `/care-tasks/:id/complete` | `screens/nurse/views/operations_view.dart` |
| Shift Handoff Notes | Write end-of-shift notes passed to incoming nurse | Text notes + critical cases | POST to `/handoffs` | `screens/nurse/shift_handoff_screen.dart` |
| Nursing Reports | Create care summaries, preview, export to PDF, and send to family | Report form fields | PDF document + API report | `screens/nurse/nurse_reports_screen.dart`, `services/pdf_service.dart` |
| Inventory Awareness | View facility supply levels and flag low-stock items | Inventory list from API | Stock status cards | `screens/nurse/views/medical_admin_view.dart` |

#### 10.4 Family Member Features

| Feature | Description | Input | Output | Related Files |
|---|---|---|---|---|
| Resident Status Dashboard | View resident's daily health, activities, mood, and recent events | Backend sync | Status summary cards | `screens/family/family_dashboard_screen.dart` |
| Visit Booking | Schedule a physical or video visit to the resident | Date, time, visitor details | POST to `/family-bridge/visits` | `screens/family/visit_booking_screen.dart` |
| Care Report Access | Read nursing care reports prepared for the family | Report selection | Full report detail view | `screens/family/care_report_detail_screen.dart` |
| Chat with Social Specialist | Text messaging thread with the assigned social specialist | Text messages | POST to `/messages` | `screens/family/chat_with_specialist_screen.dart` |
| Activity Log | View the resident's completed activities and points | Activity history from API | Timeline of activities | `screens/family/family_activities_screen.dart` |
| Billing Overview | View invoices and payment status | Billing list from API | Bill cards with due/paid status | `screens/family/family_dashboard_screen.dart` |
| Media Sharing | Upload photos and videos for the resident to view | Device gallery/camera | S3 presigned upload → confirmed | `services/family_media_service.dart` |

#### 10.5 Social Specialist Features

| Feature | Description | Input | Output | Related Files |
|---|---|---|---|---|
| Structured Assessments | Administer standardised tools (e.g. GDS, FAMILY scale) | Question responses | Scored assessment record | `screens/specialist/views/assessment_view.dart` |
| Assessment History | Review historical assessment scores and trends per resident | Resident selection | Score trend charts | `screens/specialist/assessment_detailed_screen.dart` |
| Complaint Management | Log, track, escalate, and resolve complaints | Complaint form | Status-tracked complaint with timeline | `screens/specialist/views/complaints_view.dart` |
| Resident File Management | View the comprehensive resident file including social and medical info | Resident selection | Full 65-field resident profile | `screens/specialist/views/files_view.dart` |
| KPI Dashboard | View social care key performance indicators with historical trends | Backend KPIs | Metric cards with trend lines | `screens/specialist/views/kpi_view.dart` |
| Family Chat (Specialist Side) | Respond to family messages about resident care | Text messages | POST to `/messages` | `screens/specialist/specialist_chat_detail_screen.dart` |

#### 10.6 Volunteer Features

| Feature | Description | Input | Output | Related Files |
|---|---|---|---|---|
| Opportunity Browsing | View available volunteer opportunities with details and available slots | Opportunity list from API | Card list with tags and booking CTA | `screens/volunteer/opportunities_view.dart` |
| Session Booking | Book a volunteer opportunity session | Opportunity selection | POST to `/volunteers/bookings` | `screens/volunteer/opportunities_view.dart` |
| Booking Management | View upcoming and past bookings; cancel if needed | Booking list | Booking cards with status | `screens/volunteer/bookings_view.dart` |
| Ratings Received | View ratings and comments given by residents or families | Ratings from API | Star ratings with criteria breakdown | `screens/volunteer/ratings_view.dart` |
| Certificates | View earned achievement certificates; locked ones show progress | Certificate list | Certificate gallery | `screens/volunteer/certificates_view.dart` |
| Profile Management | Edit skills, bio, social links, upload CV and recommendation letter | Profile form | PUT to `/volunteers/profile` | `screens/volunteer/profile_view.dart` |
| Shareable Public Profile | Generate a shareable link to the volunteer's public profile | Tap action | Backend generates public URL via S3 | `services/volunteer_documents_service.dart` |

#### 10.7 Administrator Features

| Feature | Description | Input | Output | Related Files |
|---|---|---|---|---|
| Admin Dashboard Overview | Real-time KPIs: occupancy, medication adherence, active complaints, staff performance | Backend sync | Statistics cards, charts | `screens/admin/views/admin_home_view.dart` |
| Resident Management | Add, view, edit, and deactivate residents; manage medical information | Resident form fields | Full CRUD via API | `screens/admin/views/residents_management_view.dart` |
| Staff Management | Add and manage staff accounts across all roles | Staff form fields | CRUD via `/admin/users` | `screens/admin/views/staff_management_view.dart` |
| Visit Approval | Review pending family visit requests and approve or reject them | Visit request details | PATCH visit status | `screens/admin/views/visit_approval_view.dart` |
| AI Warnings Review | Review AI-generated alerts and recommendations about residents | AI insights from API | Alert cards with rationale | `screens/admin/views/ai_warnings_view.dart` |
| Volunteer Management | Oversee volunteer profiles and assignments | Volunteer list | Management interface | `screens/admin/views/admin_volunteer_view.dart` |
| Reports and Analytics | View facility-level analytics and care reporting history | Date-filtered report data | Charts and exportable summaries | `screens/admin/views/admin_reports_view.dart` |
| Facility Settings | Configure facility profile, billing instructions, emergency contacts | Settings forms | PUT to `/admin/settings/*` | `screens/admin/views/admin_settings_view.dart` |

#### 10.8 Cross-Role Features

| Feature | Description | Roles | Related Files |
|---|---|---|---|
| Profile Management | Edit personal information, upload profile photo | All | `screens/common/profile_screen.dart` |
| Account Settings | Manage password, biometric toggle, notification preferences | All | `screens/common/account_settings_screen.dart` |
| Notification Centre | View history of all received in-app notifications | All | `screens/common/notifications_center_screen.dart` |
| Accessibility Settings | Adjust font size, enable high contrast, toggle dark mode | All | `widgets/accessibility_dialog.dart` |
| Help and Support | FAQ section and support contact | All | `screens/common/help_support_screen.dart` |
| Cloud Health Screen | Backend health check and connection status | All | `screens/common/cloud_health_screen.dart` |

---

### الميزات والمتطلبات الوظيفية (عربي)

يتضمن نظام وَنَس مجموعة شاملة من الميزات الوظيفية المُقسَّمة بحسب دور المستخدم:

- **المسن:** لوحة ترحيب مخصصة، تذكيرات الأدوية مع تتبع الامتثال، مكالمات الأسرة، ألبومات الذكريات، الرسائل الصوتية، الأنشطة اليومية المُلعَّبة، الألعاب المعرفية، الرفيق الذكي بالذكاء الاصطناعي، وزر الطوارئ.
- **الممرض:** لوحة تحكم المناوبة، قائمة المقيمين مع الحالة الصحية، الملف الطبي التفصيلي، تسجيل الجرعات، إدارة مهام الرعاية، مذكرات تسليم المناوبة، وتقارير الرعاية بصيغة PDF.
- **الأسرة:** متابعة حالة المقيم، حجز الزيارات، الاطلاع على تقارير الرعاية، الدردشة مع الأخصائي، مشاركة الوسائط، ومتابعة الفواتير.
- **الأخصائي الاجتماعي:** إجراء التقييمات المعيارية، إدارة الشكاوى، استعراض الملف الشامل للمقيم، ومتابعة مؤشرات الأداء.
- **المتطوع:** تصفح الفرص وحجزها، استعراض التقييمات والشهادات، وإدارة الملف الشخصي مع مشاركة رابط عام.
- **المدير:** لوحة تحكم شاملة بالمقاييس الآنية، إدارة المقيمين والموظفين، اعتماد الزيارات، استعراض تنبيهات الذكاء الاصطناعي، وإعداد إعدادات المرفق.

---

## 11. Non-Functional Requirements

### English

#### 11.1 Performance
- The application must load the main dashboard within 3 seconds on a stable 4G connection.
- Backend API endpoints must respond within 10 seconds (configured as the request timeout in `ApiConfig`).
- The real-time WebSocket connection must re-establish automatically within 5 seconds of disconnection.
- Data synchronisation via `BackendSyncService` parallelises API calls for each domain to minimise total load time.
- Shimmer loading skeletons are displayed during data fetching to maintain perceived performance.

#### 11.2 Security
- All API communication uses HTTPS (TLS 1.2+) to `https://api.helpers-tech.com`.
- JWT access tokens are stored exclusively in `flutter_secure_storage`, which uses the Android Keystore and iOS Keychain.
- JWT tokens are attached to every authenticated API request as `Authorization: Bearer {token}`.
- Authentication is managed through Google Cloud Identity Platform / Firebase Auth, a SOC 2 Type II certified identity service.
- The admin registration endpoint is protected by a server-side secret (`ADMIN_SETUP_SECRET`) to prevent unauthorised facility creation.
- Biometric authentication is available as an optional additional security layer.
- No sensitive data (passwords, tokens) is logged in production.

#### 11.3 Usability
- The application is fully RTL (Right-to-Left) with Arabic as the primary language.
- The Cairo font family (loaded in 8 weights) provides optimal Arabic legibility.
- Font scaling is user-adjustable from 0.9× to 1.5× for accessibility.
- High-contrast mode is available for users with visual impairments.
- Dark mode is supported for low-light environments.
- Touch targets are designed to meet WCAG 2.1 minimum size guidelines (at least 44×44 logical pixels).
- The elderly-facing UI uses simplified navigation, large text, and minimal visual complexity.

#### 11.4 Scalability
- The NestJS backend is stateless and horizontally scalable behind a load balancer.
- PostgreSQL supports vertical scaling and read replicas for increased load.
- Google Cloud Storage (GCS) provides virtually unlimited storage for media and document assets.
- The Riverpod state management architecture cleanly separates concerns, allowing new features to be added without affecting existing modules.

#### 11.5 Maintainability
- The codebase uses a single-responsibility principle: each service file handles exactly one domain.
- All 50+ data models are centralised in `app_models.dart` with `copyWith()` methods for immutable updates.
- The theme system in `app_theme.dart` centralises all design tokens, enabling global style changes from a single file.
- API configuration is centralised in `api_config.dart`, making environment changes (staging vs production) straightforward.

#### 11.6 Reliability
- Failed API requests return structured error messages; the UI shows appropriate empty or error states.
- JWT token refresh is automatic, preventing session expiry from disrupting user workflows.
- The real-time WebSocket reconnects automatically on connection loss.
- Local notification scheduling persists across app restarts using `flutter_local_notifications`.

#### 11.7 Compatibility
- **Android:** Target SDK 34 (Android 14), minimum SDK 21 (Android 5.0 Lollipop).
- **iOS:** Minimum iOS 12.0.
- **Flutter SDK:** Dart ≥3.0.0 — compatible with all current Flutter stable releases.
- **Screen sizes:** Responsive layout works on phones from 360dp to 480dp width; not optimised for tablets.

---

### المتطلبات غير الوظيفية (عربي)

- **الأداء:** تحميل لوحة التحكم خلال 3 ثوانٍ، واستجابة الواجهة البرمجية خلال 10 ثوانٍ، مع موازاة طلبات البيانات لتقليل وقت التحميل.
- **الأمان:** HTTPS لجميع الاتصالات، JWT في تخزين آمن مشفر، Google Cloud Identity Platform / Firebase Auth لإدارة الهوية، وحماية نقطة تسجيل المدير بسر خادم.
- **سهولة الاستخدام:** دعم كامل للعربية RTL، خط Cairo بثمانية أوزان، تحجيم الخط، الوضع عالي التباين، والوضع الداكن.
- **قابلية التوسع:** خلفية NestJS عديمة الحالة وقابلة للتوسع أفقيًا، وPostgreSQL وGoogle Cloud Storage (GCS) لاستيعاب نمو البيانات.
- **قابلية الصيانة:** مبدأ المسؤولية الفردية عبر ملفات الخدمة، وتركيز النماذج والثيمات في ملفات مفردة.
- **التوافق:** Android 5.0+ وiOS 12.0+ مع Flutter SDK الحديث.

---

## 12. Database Design

### English

The backend uses a PostgreSQL relational database. The schema is managed through numbered SQL migration files in the `external/raaya-backend/migrations/` directory. The following documents the key entities derived from the codebase, backend contract analysis, and migration files.

#### 12.1 Core Entities

##### facilities
Represents a registered nursing home or care facility.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK, NOT NULL | Unique facility identifier |
| name | VARCHAR | NOT NULL | Facility display name |
| address | TEXT | | Physical address |
| phone | VARCHAR | | Contact phone number |
| license_number | VARCHAR | | Regulatory license number |
| year_of_est | INTEGER | | Year the facility was established |
| capacity | INTEGER | | Maximum resident capacity |
| location_url | TEXT | | Google Maps or location link |
| logo_url | TEXT | | S3 URL of facility logo |
| created_at | TIMESTAMPTZ | NOT NULL | Creation timestamp |

##### facility_settings
Stores JSONB configuration blocks for each facility.

| Column | Type | Description |
|---|---|---|
| facility_id | UUID | FK → facilities.id |
| facility_profile | JSONB | Name, address, logo, contacts |
| billing_settings | JSONB | Payment instructions, bank account info |
| emergency_contacts | JSONB | Emergency phone numbers and contacts |

##### residents
Core resident profile table.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK, NOT NULL | Unique resident identifier |
| facility_id | UUID | FK → facilities | Owning facility |
| name | VARCHAR | NOT NULL | Full Arabic name |
| name_en | VARCHAR | | English transliteration |
| room_number | VARCHAR | | Assigned room |
| gender | VARCHAR | | Male / Female |
| birth_date | DATE | | Date of birth |
| entry_date | DATE | | Admission date |
| national_id | VARCHAR | | National identification number |
| image_url | TEXT | | S3 profile photo URL |
| blood_type | VARCHAR | | ABO blood group |
| allergies | TEXT[] | | Allergy list |
| chronic_diseases | TEXT[] | | Chronic diagnoses |
| past_surgeries | TEXT | | Surgical history |
| insurance_info | TEXT | | Insurance provider details |
| primary_doctor_name | VARCHAR | | Assigned physician |
| mobility_status | VARCHAR | | Independent / Assisted / Wheelchair / Bedridden |
| assistive_devices | TEXT[] | | Walking aids, hearing aids, etc. |
| cognitive_status | VARCHAR | | Normal / Mild Impairment / Dementia |
| diet_type | VARCHAR | | Regular / Diabetic / Cardiac / Soft |
| food_restrictions | TEXT[] | | Specific restrictions |
| food_preferences | TEXT | | Preferences and notes |
| previous_profession | VARCHAR | | Pre-retirement occupation |
| hobbies | TEXT[] | | Hobbies and interests |
| social_status | VARCHAR | | Married / Widowed / Divorced / Single |
| contract_type | VARCHAR | | Admission contract type |
| emergency_contact_name | VARCHAR | | Next-of-kin name |
| emergency_contact_phone | VARCHAR | | Next-of-kin phone |
| emergency_relation | VARCHAR | | Relationship to resident |
| status | VARCHAR | | Active / Discharged / Deceased |
| created_at | TIMESTAMPTZ | NOT NULL | Record creation time |
| updated_at | TIMESTAMPTZ | | Last update time |

##### managed_users
Represents staff and volunteer user accounts created by the admin.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | UUID | PK | Internal user ID |
| cognito_sub | VARCHAR | UNIQUE | Google Cloud Identity Platform / Firebase Auth user subject ID |
| facility_id | UUID | FK → facilities | Employing facility |
| name | VARCHAR | NOT NULL | Display name |
| email | VARCHAR | UNIQUE, NOT NULL | Login email |
| role | VARCHAR | NOT NULL | nurse / specialist / volunteer / admin |
| specialty | VARCHAR | | Medical specialty (if applicable) |
| shift | VARCHAR | | Morning / Evening / Night |
| phone | VARCHAR | | Contact number |
| image_url | TEXT | | S3 profile photo URL |
| linked_resident_id | UUID | FK → residents | For family members linked to a resident |
| is_active | BOOLEAN | DEFAULT true | Account activation status |
| created_at | TIMESTAMPTZ | NOT NULL | Creation timestamp |

#### 12.2 Medication Management

##### medication_schedules
Defines recurring medication prescriptions.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| resident_id | UUID | FK → residents |
| facility_id | UUID | FK → facilities |
| name | VARCHAR | Medication name |
| dosage | VARCHAR | Dose description (e.g., "1 tablet") |
| time_of_day | VARCHAR | Morning / Afternoon / Evening / Night |
| time_description | VARCHAR | Human-readable time label |
| meal_relation | VARCHAR | Before meal / After meal / With meal |
| created_at | TIMESTAMPTZ | |

##### medication_doses
Logs each individual administration event.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| schedule_id | UUID | FK → medication_schedules |
| resident_id | UUID | FK → residents |
| administered_at | TIMESTAMPTZ | When the dose was given |
| status | VARCHAR | taken / skipped / missed |
| skip_reason | TEXT | Reason if skipped |
| administered_by | UUID | FK → managed_users (nurse) |
| is_elderly_confirmed | BOOLEAN | Whether the resident confirmed intake |

#### 12.3 Care Operations

##### care_tasks
Daily nursing care tasks.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| resident_id | UUID | FK → residents |
| facility_id | UUID | FK → facilities |
| title | VARCHAR | Task name |
| category | VARCHAR | hygiene / nutrition / mobility / medication / other |
| is_completed | BOOLEAN | Completion flag |
| completed_by | UUID | FK → managed_users |
| completed_at | TIMESTAMPTZ | Completion timestamp |
| time | VARCHAR | Scheduled time label |

##### nursing_notes
Freeform nursing care notes.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| resident_id | UUID | FK → residents |
| author_id | UUID | FK → managed_users |
| title | VARCHAR | Short note title |
| content | TEXT | Full note content |
| created_at | TIMESTAMPTZ | |

##### handoffs
Shift-change notes from one nurse to the next.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| facility_id | UUID | FK → facilities |
| nurse_id | UUID | FK → managed_users |
| shift_type | VARCHAR | Morning / Evening / Night |
| notes | TEXT | General handoff notes |
| critical_cases | TEXT[] | Names or notes of critical residents |
| timestamp | TIMESTAMPTZ | |

#### 12.4 Family and Communication

##### family_members
Links a registered family user to a resident.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| resident_id | UUID | FK → residents |
| user_id | UUID | FK → managed_users (cognito_sub) |
| name | VARCHAR | Family member name |
| relation | VARCHAR | Son / Daughter / Spouse / etc. |
| phone_number | VARCHAR | Contact phone |
| email | VARCHAR | Contact email |
| invite_status | VARCHAR | pending / accepted / rejected |
| is_pinned | BOOLEAN | Pinned contact flag |

##### visits
Physical or video visit requests.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| resident_id | UUID | FK → residents |
| family_member_id | UUID | FK → family_members |
| visitor_name | VARCHAR | Full visitor name |
| date | DATE | Visit date |
| time | VARCHAR | Visit time label |
| type | VARCHAR | physical / video |
| status | VARCHAR | pending / approved / rejected / completed |
| zoom_link | TEXT | Video call join URL if approved |
| scheduled_at | TIMESTAMPTZ | |

##### messages
Text chat messages between family and specialists.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| sender_id | UUID | FK → managed_users |
| recipient_id | UUID | FK → managed_users |
| resident_id | UUID | FK → residents (context) |
| body | TEXT | Message content |
| is_read | BOOLEAN | Read status |
| sent_at | TIMESTAMPTZ | |

#### 12.5 Social and Volunteer

##### complaints
Care or service complaints lodged by specialists or families.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| resident_id | UUID | FK → residents |
| facility_id | UUID | FK → facilities |
| title | VARCHAR | Short complaint title |
| category | VARCHAR | care / nutrition / hygiene / behaviour / other |
| priority | VARCHAR | low / medium / high / urgent |
| status | VARCHAR | open / in_progress / resolved / escalated |
| is_escalated | BOOLEAN | Escalation flag |
| timeline | JSONB | Array of step objects {text, time, status} |
| created_at | TIMESTAMPTZ | |

##### social_assessments
Completed social / psychological assessments.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| resident_id | UUID | FK → residents |
| tool_id | UUID | FK → social_assessment_tools |
| specialist_id | UUID | FK → managed_users |
| score | INTEGER | Total assessment score |
| total | INTEGER | Maximum possible score |
| answers | JSONB | Question-answer pairs |
| notes | TEXT | Specialist notes |
| assessed_at | TIMESTAMPTZ | |

##### volunteer_bookings
Volunteer session attendance records.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| opportunity_id | UUID | FK → volunteer_opportunities |
| volunteer_id | UUID | FK → managed_users |
| status | VARCHAR | confirmed / attended / cancelled / pending_rating |
| points | INTEGER | Points awarded for attendance |
| attended_at | TIMESTAMPTZ | |

#### 12.6 AI and Media

##### ai_resident_memory
Persisted AI context memory per resident.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| resident_id | UUID | FK → residents |
| summary | TEXT | AI-generated care summary |
| recommendations | TEXT[] | AI care recommendations |
| warnings | TEXT[] | AI-generated alerts |
| mood_insights | TEXT | Mood analysis |
| source | VARCHAR | Source model identifier |
| status | VARCHAR | active / archived |
| last_updated | TIMESTAMPTZ | |

##### memories
Photo or video moments shared by families or staff.

| Column | Type | Description |
|---|---|---|
| id | UUID | PK |
| resident_id | UUID | FK → residents |
| uploaded_by | UUID | FK → managed_users |
| image_url | TEXT | S3 media URL |
| activity_title | VARCHAR | Associated activity name |
| date | DATE | Memory date |
| appreciations | INTEGER | Like count |

#### 12.7 System Support Tables

| Table | Purpose |
|---|---|
| `notifications` | In-app notification records (title, body, type, target role, is_read) |
| `video_calls` | Video call state (status: initiated/active/ended, zoom_link) |
| `user_preferences` | Per-user UI preferences (theme, font scale, contrast) |
| `user_progress` | Gamification progress (points, streak, badges unlocked) |
| `staff_reviews` | Reviews of staff members by residents or families |
| `billing` | Resident invoices (amount, due date, is_paid) |
| `doctor_visits` | Scheduled doctor appointments |
| `medical_sessions` | PT/nursing/therapy sessions |
| `prescriptions` | Doctor prescription records with S3 image URL |
| `meal_plans` | Dietary plans (AI-generated or manual) |
| `inventory` | Facility supply items with stock levels |
| `volunteer_certificates` | Earned volunteer achievement certificates |
| `volunteer_ratings` | Ratings given to volunteers |
| `facility_inquiries` | Guest inquiries submitted from the login screen |

---

### تصميم قاعدة البيانات (عربي)

تستخدم الخلفية قاعدة بيانات PostgreSQL علائقية مُدارة عبر ملفات ترحيل SQL مُرقَّمة. تشمل الكيانات الرئيسية:

- **facilities:** بيانات المرفق الصحي (الاسم، العنوان، الترخيص، الطاقة الاستيعابية).
- **residents:** الملف الكامل للمقيم (65+ حقلًا يشمل البيانات الطبية والاجتماعية والغذائية).
- **managed_users:** حسابات الموظفين والمتطوعين المُنشَأة من قِبل المدير.
- **medication_schedules + medication_doses:** إدارة الأدوية من الوصفة حتى تسجيل الجرعة.
- **care_tasks + nursing_notes + handoffs:** عمليات التمريض اليومية وتسليم المناوبات.
- **family_members + visits + messages:** تواصل الأسرة وحجز الزيارات.
- **complaints + social_assessments:** عمل الأخصائي الاجتماعي.
- **volunteer_bookings + volunteer_certificates + volunteer_ratings:** نظام المتطوعين.
- **ai_resident_memory + memories:** الذكاء الاصطناعي والوسائط.
- **notifications + video_calls + user_preferences + user_progress:** جداول الدعم.

---

## 13. API Documentation

### English

The Wanas backend exposes a RESTful API at `https://api.helpers-tech.com`. All protected endpoints require a `Authorization: Bearer {jwt_token}` header. The backend uses NestJS with a global `ValidationPipe` (`whitelist: true`, `forbidNonWhitelisted: true`) meaning extra fields in request bodies result in HTTP 400 errors.

#### 13.1 Authentication Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/login` | None | Authenticate with email + password; returns JWT tokens |
| POST | `/auth/register` | None | Self-register as Family or Volunteer role |
| POST | `/auth/register-admin` | Secret header | Register facility admin; requires `ADMIN_SETUP_SECRET` |
| POST | `/auth/forgot-password` | None | Initiate password reset; sends code via email |
| POST | `/auth/confirm-forgot-password` | None | Confirm reset with code + new password |
| GET | `/auth/me` | JWT | Get current authenticated user profile |

**Login Request Body:**
```json
{ "email": "nurse@facility.com", "password": "SecurePass1!" }
```
**Login Response:**
```json
{
  "id_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": { "id": "uuid", "name": "...", "role": "nurse", "facilityId": "uuid" }
}
```

#### 13.2 Resident Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/residents` | JWT | List all residents for the facility |
| GET | `/residents/:id` | JWT | Get a single resident by ID |
| POST | `/residents` | JWT (Admin) | Create a new resident |
| PATCH | `/residents/:id` | JWT (Admin/Nurse) | Update resident fields |
| PUT | `/residents/:id/medical-info` | JWT (Admin/Nurse) | Update resident medical information |
| GET | `/residents/:id/audit-trail` | JWT (Specialist) | Get timestamped change history |
| POST | `/residents/:id/photo/upload` | JWT (Admin) | Get presigned S3 URL for photo upload |
| PATCH | `/residents/:id/photo/confirm` | JWT (Admin) | Confirm photo upload, persist `image_url` |

#### 13.3 Medication Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/medications/schedules` | JWT | List all medication schedules |
| POST | `/medications/schedules` | JWT (Admin/Nurse) | Create a medication schedule |
| GET | `/medications/overdue` | JWT (Nurse) | Get medications past administration time |
| POST | `/medications/doses` | JWT (Nurse) | Log a medication dose administration |
| PATCH | `/medications/doses/:id` | JWT (Nurse) | Update dose status (taken/skipped/missed) |
| GET | `/medications/adherence` | JWT | Get adherence statistics |

#### 13.4 Health and Vitals Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/health` | None | API health check (uptime status) |
| POST | `/health/vitals` | JWT (Nurse) | Record a vital measurement |
| GET | `/health/vitals` | JWT | Get vitals history |
| GET | `/health/alerts` | JWT | Get active health alerts |
| PATCH | `/health/alerts/:id` | JWT (Nurse/Admin) | Acknowledge or resolve an alert |
| GET | `/health/thresholds` | JWT | Get alert threshold settings |
| PUT | `/health/thresholds` | JWT (Admin) | Update alert thresholds |

#### 13.5 Nursing Operations Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET/POST | `/nursing-notes` | JWT (Nurse) | List / create nursing care notes |
| GET/POST | `/handoffs` | JWT (Nurse) | List / create shift handoff records |
| GET/POST | `/care-tasks` | JWT (Nurse/Admin) | List / create care tasks |
| PATCH | `/care-tasks/:id/complete` | JWT (Nurse) | Mark a task as completed |
| PATCH | `/care-tasks/:id/reopen` | JWT (Nurse) | Reopen a completed task |
| DELETE | `/care-tasks/:id` | JWT (Admin) | Delete a care task |
| GET/POST | `/inventory` | JWT | View / add inventory items |
| PATCH | `/inventory/:id/stock` | JWT (Admin/Nurse) | Update stock level |
| GET/POST | `/doctor-visits` | JWT | Doctor appointment records |
| GET/POST | `/medical-sessions` | JWT | Medical / therapy sessions |
| GET/POST | `/prescriptions` | JWT | Prescription records |
| GET/POST | `/meal-plans` | JWT | Dietary plan management |

#### 13.6 Family Bridge and Communication Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/family-members` | JWT | List family members (filter by `residentId`) |
| POST | `/family-members` | JWT (Admin) | Link a family member to a resident |
| GET | `/family-bridge/visits` | JWT | List visit requests |
| POST | `/family-bridge/visits` | JWT (Family) | Book a new visit |
| PATCH | `/family-bridge/visits/:id/status` | JWT (Admin) | Approve or reject a visit |
| GET | `/family-bridge/media` | JWT | List shared media items |
| POST | `/family-bridge/media/upload` | JWT (Family) | Get presigned S3 URL for media upload |
| PATCH | `/family-bridge/media/:id/confirm` | JWT (Family) | Confirm media upload |
| DELETE | `/family-bridge/media/:id` | JWT (Family/Admin) | Delete a media item |
| GET | `/billing` | JWT (Family/Admin) | List resident invoices |
| PATCH | `/billing/:id/pay` | JWT (Family) | Mark an invoice as paid |
| GET/POST | `/messages` | JWT | List / send chat messages |
| GET | `/memories` | JWT | List memory wall items |
| POST | `/memories` | JWT | Create a memory entry |
| PATCH | `/memories/:id/appreciate` | JWT | Add an appreciation (like) |
| DELETE | `/memories/:id` | JWT (Admin) | Remove a memory |

#### 13.7 AI Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/ai/chat` | JWT | Send a message to the AI companion; returns AI response |
| GET | `/ai/recommendations/:residentId` | JWT (Admin/Nurse/Specialist) | Get AI-generated care recommendations for a resident |
| GET/POST | `/ai/memory/:residentId` | JWT | Read or update persistent AI memory for a resident |
| POST | `/ai/speech` | JWT | Text-to-speech synthesis; returns audio stream (Google Cloud Text-to-Speech) |
| POST | `/ai/media/upload` | JWT | Get presigned S3 URL for AI-related media |
| PATCH | `/ai/media/:id/confirm` | JWT | Confirm AI media upload |

**AI Chat Request:**
```json
{ "message": "كيف حالك اليوم؟", "residentId": "uuid" }
```
**AI Chat Response:**
```json
{ "reply": "أنا بخير شكرًا، كيف تشعر أنت اليوم؟", "sentiment": "positive" }
```

#### 13.8 Volunteer Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET/PUT | `/volunteers/profile` | JWT (Volunteer) | Read or update volunteer profile |
| GET | `/volunteers/opportunities` | JWT | List available volunteer opportunities |
| POST | `/volunteers/opportunities` | JWT (Admin) | Create a new opportunity |
| GET | `/volunteers/bookings` | JWT (Volunteer) | List volunteer's bookings |
| POST | `/volunteers/bookings` | JWT (Volunteer) | Book an opportunity |
| PATCH | `/volunteers/bookings/:id` | JWT | Update booking (cancel, confirm attendance) |
| GET | `/volunteers/certificates` | JWT (Volunteer) | List earned certificates |
| GET | `/volunteers/ratings` | JWT (Volunteer) | List received ratings |
| GET/POST | `/volunteers/reviews` | JWT | View / submit volunteer reviews |
| POST | `/volunteers/documents/upload` | JWT (Volunteer) | Get presigned S3 URL for document upload |
| PATCH | `/volunteers/documents/:id/confirm` | JWT (Volunteer) | Confirm document upload |
| POST | `/volunteers/profile/public-link` | JWT (Volunteer) | Generate a public shareable profile URL |
| GET | `/volunteers/profile/public/:slug` | None | View public volunteer profile |

#### 13.9 Social Specialist Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET/POST | `/social/needs` | JWT (Specialist) | Social care needs (complaints) |
| GET | `/social/assessment-tools` | JWT (Specialist) | List available assessment tools |
| GET | `/social/assessment-tools/:id/questions` | JWT (Specialist) | Get questions for an assessment tool |
| GET | `/social/gds-questions` | JWT (Specialist) | Get Geriatric Depression Scale questions |
| GET | `/social/resident-scores` | JWT (Specialist) | Get assessment scores per resident |
| GET/POST | `/social/assessments` | JWT (Specialist) | List / submit completed assessments |
| GET | `/social/kpis` | JWT (Specialist/Admin) | Get social care KPI metrics |
| GET/POST/PATCH | `/complaints` | JWT | Complaint CRUD and status updates |

#### 13.10 Admin Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/admin/users` | JWT (Admin) | Create a managed user (staff) |
| PATCH | `/admin/users/:id` | JWT (Admin) | Update a managed user |
| PATCH | `/admin/users/:id/disable` | JWT (Admin) | Deactivate a user account |
| GET | `/admin/users/:id` | JWT (Admin) | Get managed user detail |
| GET | `/admin/users/:id/reviews` | JWT (Admin) | Get staff performance reviews |
| GET | `/admin/staff-performance` | JWT (Admin) | List staff performance metrics |
| GET/PUT | `/admin/settings/facility-profile` | JWT (Admin) | Read/update facility profile |
| GET/PUT | `/admin/settings/billing` | JWT (Admin) | Read/update billing settings |
| GET/PUT | `/admin/settings/emergency-contacts` | JWT (Admin) | Read/update emergency contacts |
| POST/GET | `/admin/users/:id/photo/upload` | JWT (Admin) | Presigned S3 photo upload for staff |
| PATCH | `/admin/users/:id/photo/confirm` | JWT (Admin) | Confirm staff photo upload |

#### 13.11 Notifications and Real-Time

| Method | Path / Channel | Auth | Description |
|---|---|---|---|
| GET | `/notifications` | JWT | List all notifications for the user |
| POST | `/notifications` | JWT | Create an in-app notification |
| PATCH | `/notifications/:id` | JWT | Mark notification as read |
| DELETE | `/notifications/:id` | JWT | Delete a notification |
| POST | `/notifications/push-tokens` | JWT | Register device FCM token |
| DELETE | `/notifications/push-tokens` | JWT | Unregister FCM token on logout |
| WebSocket | `wss://api.helpers-tech.com` | JWT handshake | Socket.IO real-time event gateway |

---

### توثيق واجهة برمجة التطبيقات (عربي)

تعرض الخلفية واجهة REST API على `https://api.helpers-tech.com`. تتطلب جميع نقاط النهاية المحمية رأس HTTP `Authorization: Bearer {jwt_token}`. تُقسَّم نقاط النهاية بحسب المجال:

- **المصادقة:** تسجيل الدخول، إنشاء الحسابات، استعادة كلمة المرور.
- **المقيمون:** CRUD كامل مع معلومات طبية وسجل التدقيق.
- **الأدوية:** جداول الأدوية وتسجيل الجرعات وإحصاءات الامتثال.
- **الصحة:** قياسات الحيوية والتنبيهات والحدود.
- **عمليات التمريض:** مهام الرعاية، المذكرات، تسليم المناوبات، زيارات الأطباء، خطط الوجبات.
- **الأسرة:** الزيارات، مشاركة الوسائط، الرسائل، الفواتير، ذكريات المقيم.
- **الذكاء الاصطناعي:** محادثة الرفيق، التوصيات، الذاكرة المستمرة، تحويل النص إلى صوت.
- **المتطوعون:** الفرص، الحجوزات، الشهادات، التقييمات، الوثائق، الملف العام.
- **الأخصائي الاجتماعي:** أدوات التقييم، أسئلة GDS، درجات المقيمين، الشكاوى، مؤشرات الأداء.
- **الإدارة:** الموظفون، إعدادات المرفق، أداء الفريق.
- **الإشعارات والزمن الفعلي:** إشعارات التطبيق وSocket.IO WebSocket.

---

## 14. Authentication and Authorization

### English

#### 14.1 Authentication Architecture

Wanas uses a delegated authentication architecture where the backend acts as a proxy to Google Cloud Identity Platform / Firebase Auth:

```
Flutter App → POST /auth/login → NestJS Backend → Google Cloud Identity Platform / Firebase Auth InitiateAuth
                                      ↓
                               Cognito validates credentials
                                      ↓
                               Backend returns: { id_token, refresh_token }
                                      ↓
                          Flutter stores tokens in FlutterSecureStorage
                                      ↓
                          All future requests: Authorization: Bearer {id_token}
```

This design keeps the Cognito `COGNITO_CLIENT_SECRET` on the server, preventing exposure in the mobile client — a critical security requirement as Flutter apps cannot safely embed client secrets.

#### 14.2 JWT Token Structure

Google Cloud Identity Platform / Firebase Auth issues signed JWT tokens. The `id_token` payload contains:

```json
{
  "sub": "cognito-user-uuid",
  "email": "user@facility.com",
  "name": "User Full Name",
  "cognito:groups": ["nurse"],
  "custom:role": "nurse",
  "custom:facilityId": "facility-uuid",
  "custom:linkedResidentId": "resident-uuid",
  "custom:facilityName": "دار الرحمة",
  "iat": 1748000000,
  "exp": 1748003600
}
```

#### 14.3 Token Lifecycle

| Phase | Action | Implementation |
|---|---|---|
| Login | `POST /auth/login` → receive `id_token` + `refresh_token` | `auth_service.dart` |
| Storage | Tokens saved to `FlutterSecureStorage` (Android Keystore / iOS Keychain) | `api_client.dart` |
| Use | Every request adds `Authorization: Bearer {id_token}` header | `api_client.dart` |
| Refresh | Before expiry, `InitiateAuth REFRESH_TOKEN_AUTH` called via Cognito | `auth_service.dart` |
| Logout | `flutter_secure_storage.deleteAll()` + Cognito global sign-out | `auth_service.dart` |

#### 14.4 Role-Based Access Control

Roles are embedded in the JWT `custom:role` claim. The backend guards endpoints by role. The six roles and their permissions:

| Role (Arabic) | Role (English) | Key Permissions |
|---|---|---|
| إدارة | Administrator | Full CRUD on residents, staff, settings; approve visits; view all data |
| ممرض | Nurse | View residents; log medications; create care tasks and notes; shift handoff |
| أخصائي اجتماعي | Social Specialist | Assessments; complaints; resident files; KPIs; family chat |
| أسرة | Family Member | View linked resident; book visits; read reports; family chat; media upload |
| متطوع | Volunteer | View/book opportunities; manage own profile and documents |
| مسن | Elderly Resident | View own dashboard; confirm medications; interact with AI; SOS |

#### 14.5 Biometric Authentication

Biometric authentication is an optional enhancement layered on top of the JWT session:

1. User enables biometric login in Account Settings.
2. The JWT token is preserved in `FlutterSecureStorage`.
3. On subsequent launches, `local_auth` prompts the user for fingerprint or face ID.
4. If biometric passes, the stored token is used directly without re-entering credentials.
5. If biometric fails or is unavailable, the user falls back to email/password.

#### 14.6 Admin Registration Security

A special endpoint `POST /auth/register-admin` is used to bootstrap the first administrator account for a facility. This endpoint requires an `X-Admin-Setup-Secret` header matching the `ADMIN_SETUP_SECRET` environment variable on the backend server. This prevents unauthorised creation of admin accounts.

---

### المصادقة والتفويض (عربي)

يعتمد وَنَس على معمارية مصادقة مُفوَّضة حيث تعمل الخلفية كوكيل بين تطبيق Flutter وخدمة Google Cloud Identity Platform / Firebase Auth:

- يُرسل التطبيق بريد المستخدم وكلمته إلى الخلفية عبر `POST /auth/login`.
- تتحقق الخلفية من الاعتمادات مع Cognito وتُعيد رمز JWT إلى التطبيق.
- يُخزَّن الرمز في `FlutterSecureStorage` المشفر (Keystore على أندرويد، Keychain على iOS).
- يُرفق الرمز بكل طلب API كرأس `Authorization: Bearer`.
- يتجدد الرمز تلقائيًا قبل انتهاء صلاحيته.
- يتضمن رمز JWT معلومات الدور والمرفق، ويستخدمها الخادم لتطبيق قواعد التحكم بالوصول.
- المصادقة البيومترية (بصمة/وجه) طبقة اختيارية إضافية فوق جلسة JWT.

---

## 15. User Interface Documentation

### English

The Wanas UI is built on Material Design 3 with a custom design system defined in `app_theme.dart`. The primary language is Arabic with full RTL rendering enforced globally using `Directionality.rtl`. The Cairo font family is used throughout.

#### 15.1 Design System Summary

| Token Category | Values |
|---|---|
| Primary Colour | #EA580C (Orange 600) |
| AI / Accent Colour | #6366F1 (Indigo 500) |
| Medical Colour | #0369A1 (Sky 700) |
| Success | #059669 (Emerald 600) |
| Warning | #D97706 (Amber 600) |
| Danger | #DC2626 (Red 600) |
| Background | #F8FAFC (Slate 50) |
| Card Background | #FFFFFF |
| Primary Font | Cairo (Arabic), 8 weights |
| Corner Radius | sm:8 · md:12 · lg:16 · xl:24 · xxl:32 |
| Spacing Scale | xs:4 · sm:8 · md:16 · lg:24 · xl:32 · xxl:48 |

#### 15.2 Onboarding and Authentication Screens

| Screen | Purpose | Key Elements |
|---|---|---|
| **Splash Screen** | Brand loading animation | Lottie animation, cream background (#FAF7F2), logo |
| **Onboarding Screen** | First-run tutorial | Multi-page swipeable cards explaining each role |
| **Login Screen** | User authentication | Email field, password field, biometric button, facility inquiry link |
| **Register Screen** | Self-registration (family/volunteer) | Name, email, password, role selector, linked resident ID |
| **Admin Register Screen** | Facility + admin creation | Facility name/address/phone, admin name/email/password |
| **Forgot Password Screen** | Password recovery | Email input, code confirmation, new password |

#### 15.3 Elderly Resident Screens

| Screen | Purpose | Key UI Elements | Navigation |
|---|---|---|---|
| **Home Screen** | Daily overview | Welcome card with name, streak badge, points counter, activity preview, AI companion FAB | Bottom nav: tab 1 |
| **Medication Screen** | Daily medications | Time-grouped medication cards, taken/skip toggle, adherence progress bar | Bottom nav: tab 2 |
| **Calls Screen** | Family video calls | Family member grid cards, online status indicator, video call button | Bottom nav: tab 3 |
| **Memories Screen** | Photo albums | Category tabs (All/Celebrations/Daily), photo grid, upload from family indicator | Bottom nav: tab 4 |
| **Activities Screen** | Daily activities | Activity cards with emoji, points, location, gamified progress | Bottom nav: tab 5 |
| **Cognitive Games Screen** | Brain exercises | Game selection cards, score display, AI feedback panel | Navigated from Home |
| **Voice Messages Playback** | Family audio messages | Message list with play/pause, duration, unread indicator | Navigated from Home |
| **Album Details Screen** | Full album view | Full-screen photo grid, download option | Navigated from Memories |
| **AI Companion** | 24/7 AI chat | Bottom sheet with chat bubbles, voice input mic, TTS play button | FAB on Home Screen |

#### 15.4 Nurse Screens

| Screen | Purpose | Key UI Elements |
|---|---|---|
| **Nurse Dashboard** | Shift overview | Stat cards (residents, medications, tasks), alert banners, overdue medication list |
| **Residents List** | All residents | Search bar, resident cards with room number and health status |
| **Resident Detail** | Full medical file | Tabbed layout: Overview, Medications, Vitals, Care Notes, Doctor Visits, Meal Plan |
| **Medications Screen** | Dose administration | Date-filtered dose list, confirm/skip buttons, adherence percentage |
| **Reports Screen** | Care reporting | Report form, preview button, PDF export, send to family toggle |
| **Shift Handoff** | End-of-shift notes | Text area, critical cases list, timestamp, confirm button |

#### 15.5 Family Member Screens

| Screen | Purpose | Key UI Elements |
|---|---|---|
| **Family Dashboard** | Resident status hub | Status card, health metrics, upcoming visit card, recent reports list, bill summary |
| **Visit Booking** | Schedule visit | Calendar date picker, time slots, visit type toggle (physical/video), visitor name |
| **Care Report Detail** | Read care reports | Formatted report with summary, social notes, recommendations, author info |
| **Chat with Specialist** | Messaging | Chat bubble list, text input, send button, message timestamps |
| **Family Activities** | Resident activities | Activity history timeline with points and badges earned |

#### 15.6 Social Specialist Screens

| Screen | Purpose | Key UI Elements |
|---|---|---|
| **Specialist Dashboard** | Overview hub | Multi-tab: Home, Assessments, Complaints, Files, KPIs |
| **Assessment View** | Run assessments | Tool selector, question-by-question form, score calculator, submit |
| **Assessment Detailed** | View results | Historical score chart, question breakdown, recommendations |
| **Complaints View** | Complaint tracking | Priority-filtered list, status badges, escalation button |
| **Files View** | Resident files | Resident selector, 65-field profile display, audit timeline |
| **KPI View** | Performance metrics | Metric cards with trend arrows and sparkline history charts |
| **Chat List / Detail** | Family messaging | Thread list, conversation view with timestamps |

#### 15.7 Volunteer Screens

| Screen | Purpose | Key UI Elements |
|---|---|---|
| **Volunteer Dashboard** | Main hub | Multi-tab: Dashboard stats, Opportunities, Bookings, Ratings, Certificates |
| **Opportunities View** | Browse work | Opportunity cards with tags, slot availability, hours, booking button |
| **Bookings View** | Manage bookings | Booking cards with status, cancel option, attendance confirmation |
| **Ratings View** | View reviews | Star rating display, criteria breakdown, comment text |
| **Certificates View** | Achievement gallery | Certificate cards, locked state with progress bar |
| **Profile View** | Edit profile | Skills chips, bio text, social links, CV upload, recommendation upload |

#### 15.8 Admin Screens

| Screen | Purpose | Key UI Elements |
|---|---|---|
| **Admin Dashboard** | Facility overview | Multi-tab with stats, KPIs, AI alerts, staff performance |
| **Residents Management** | CRUD residents | Searchable list, add FAB, resident detail / edit / delete |
| **Admin Resident Detail** | Manage one resident | Full profile view, edit form, document uploads, family links |
| **Staff Management** | CRUD staff | Staff cards by role, add form, disable button |
| **Visit Approval** | Process visits | Pending visit cards, approve/reject buttons, approved list |
| **AI Warnings View** | AI alerts | Alert cards with resident name, alert type, AI rationale, confidence score |
| **Admin Reports View** | Analytics | Date filter, stat charts, report history list |
| **Admin Settings View** | Facility config | Facility profile form, billing text editor, emergency contacts manager |

---

### توثيق واجهة المستخدم (عربي)

تُبنى واجهة وَنَس على Material Design 3 مع نظام تصميم مخصص يستخدم خط Cairo العربي بثمانية أوزان وألوانًا واضحة تعكس هوية المشروع:

- **اللون الأساسي:** #EA580C (برتقالي) — للإجراءات الرئيسية.
- **لون الذكاء الاصطناعي:** #6366F1 (نيلي) — للمكونات المرتبطة بالذكاء الاصطناعي.
- **اللون الطبي:** #0369A1 (أزرق سماوي) — للمحتوى الطبي.

تتسم واجهة المسن بالبساطة والوضوح مع نصوص كبيرة وأزرار واضحة. أما واجهة المدير والأخصائي فتحتوي على لوحات تحكم متعددة التبويبات تعرض المقاييس والتنبيهات. تدعم جميع الشاشات اتجاه RTL كاملًا وإعدادات إمكانية الوصول (حجم الخط، التباين العالي، الوضع الداكن).

---

## 16. Main User Workflows

### English

#### 16.1 Elderly Resident: Taking a Medication

```
1. Resident opens Medication Screen (bottom nav tab 2)
2. App displays today's medications grouped by time of day
3. For each medication, resident sees: name, dosage, meal relation, and status
4. Resident taps "Took It" → MedicationsService.logDose(scheduleId, status: 'taken')
5. POST /medications/doses → backend records the dose with timestamp
6. UI updates card to show green "taken" status
7. Adherence percentage recalculates
8. If missed: app shows red "missed" badge; nurse receives an overdue alert
```

#### 16.2 Nurse: Shift Start to Handoff

```
1. Nurse logs in → routed to NurseDashboardScreen
2. Dashboard loads via BackendSyncService.load() — parallel API calls for:
   - Residents list (/residents)
   - Overdue medications (/medications/overdue)
   - Care tasks (/care-tasks)
   - Nursing notes (/nursing-notes)
3. Nurse reviews overdue medications tab — sees who missed what
4. Nurse visits Resident Detail → reviews vitals, allergies, care notes
5. Nurse marks care tasks complete → PATCH /care-tasks/:id/complete
6. Nurse logs medication administration → POST /medications/doses
7. End of shift: Nurse opens Shift Handoff screen
8. Writes notes about critical cases → POST /handoffs
9. Incoming nurse sees the handoff on their dashboard
```

#### 16.3 Family Member: Booking a Visit

```
1. Family member logs in → FamilyDashboardScreen
2. Taps "Book a Visit" button
3. VisitBookingScreen opens with calendar and time slot picker
4. Family selects:
   - Date (calendar widget)
   - Time (available slots)
   - Visit type: Physical / Video
   - Visitor name (auto-filled from profile)
5. Taps Confirm → POST /family-bridge/visits
6. Visit status set to "pending"
7. Admin receives a notification: new visit awaiting approval
8. Admin opens Visit Approval View → reviews visitor details
9. Admin taps Approve → PATCH /family-bridge/visits/:id/status { status: 'approved' }
10. Family member sees visit status update to "Approved" on dashboard
11. If video: zoom_link is included in approval response
```

#### 16.4 Social Specialist: Conducting a GDS Assessment

```
1. Specialist logs in → SocialSpecialistDashboardScreen
2. Navigates to Assessment tab
3. Selects "Geriatric Depression Scale (GDS)" tool
4. App loads questions via GET /social/gds-questions
5. Specialist presents each question to the resident
6. For each question, specialist selects the resident's response
7. App calculates running total score
8. Specialist adds clinical notes in the notes field
9. Taps Submit → POST /social/assessments with:
   { residentId, toolId, score, answers, notes }
10. Backend stores assessment → updates resident score card
11. If score exceeds threshold → AI generates a warning for admin
12. Specialist can view historical scores on AssessmentDetailedScreen
```

#### 16.5 Volunteer: Booking and Attending a Session

```
1. Volunteer logs in → VolunteerDashboardScreen
2. Navigates to Opportunities tab
3. Browses opportunity cards (title, org, date, hours, tags)
4. Taps "Book" → POST /volunteers/bookings { opportunityId }
5. Booking confirmed → appears in Bookings tab with "confirmed" status
6. On session day: volunteer attends
7. Admin marks attendance → PATCH /volunteers/bookings/:id { status: 'attended' }
8. Points are awarded → POST /user-progress/points
9. After session: rating form sent to resident/family
10. Volunteer sees new rating in Ratings tab
11. If sufficient sessions: certificate unlocked → visible in Certificates tab
```

#### 16.6 Administrator: Adding a New Resident

```
1. Admin logs in → AdminDashboardScreen
2. Navigates to Residents Management tab
3. Taps the "+" FAB button
4. Admin Resident Detail form opens (blank)
5. Admin fills in all required fields:
   - Personal information (name, room, DOB, national ID)
   - Medical information (blood type, allergies, diagnoses)
   - Emergency contact details
   - Dietary and mobility information
6. Admin taps Upload Photo → image_picker → S3 presigned upload flow:
   a. POST /residents/:id/photo/upload → receives { uploadUrl, fileKey }
   b. Flutter uploads image binary to S3 directly using the presigned URL
   c. PATCH /residents/:id/photo/confirm → backend saves image_url
7. Admin taps Save → POST /residents with full resident object
8. New resident appears in the resident list
9. Admin then creates login accounts for the resident's family members via staff management
```

#### 16.7 Elderly Resident: Emergency SOS

```
1. Resident feels unsafe or has an emergency
2. Drags the floating SOS button (DraggableSOS widget) to the trigger zone
3. App shows a 3-second confirmation countdown (prevents accidental triggers)
4. On confirm: EmergencyService.triggerSOS() called
5. POST /emergency { triggeredBy: residentId, location: roomNumber, notes: "" }
6. Backend creates emergency alert record
7. Real-time event broadcast via Socket.IO to all nurses and admin
8. Push notification sent via FCM to on-duty staff
9. Emergency contacts from facility settings are alerted
10. Nurse dashboard shows a high-priority alert banner
11. Nurse acknowledges → PATCH /emergency/:id status update
```

---

### مسارات المستخدم الرئيسية (عربي)

- **المسن:** يفتح شاشة الأدوية، يؤكد تناول الدواء أو يتخطاه مع السبب، تُسجَّل الجرعة فورًا وتتحدث نسبة الامتثال.
- **الممرض:** يبدأ المناوبة بمراجعة لوحة التحكم والمقيمين المتأخرين في جرعاتهم، يؤدي مهام الرعاية ويوقعها، وينهي المناوبة بكتابة مذكرة تسليم.
- **الأسرة:** تحجز زيارة → ينتظر الاعتماد من المدير → تستلم الإشعار بالاعتماد وتظهر الزيارة في لوحة التحكم.
- **الأخصائي:** يختار أداة تقييم → يُجري الأسئلة مع المقيم → يحسب الدرجة → يرفع التقرير → يُخطر الذكاء الاصطناعي إذا تجاوز الحد.
- **المتطوع:** يتصفح الفرص → يحجز جلسة → يحضر → يُمنح النقاط والتقييمات → يفتح الشهادات.
- **المدير:** يُضيف مقيمًا جديدًا مع كامل بياناته ويرفع صورته عبر S3 → يظهر المقيم في القائمة فورًا.
- **الطوارئ:** يُفعّل المسن زر SOS → ينتشر التنبيه آنيًا للممرضين والمدير عبر Socket.IO وFCM.

---

## 17. Algorithms and Business Logic

### English

#### 17.1 Gamification — Points, Badges, and Streaks

The gamification system for elderly residents operates as follows:

**Points:**
- Each completed activity awards a configurable number of points (`Activity.pointsReward`).
- When a resident confirms a medication dose, points are awarded via `POST /user-progress/points`.
- Points accumulate and are displayed on the Home Screen dashboard.

**Streaks:**
- A streak increments by 1 for each consecutive day the resident completes at least one activity.
- If a day is missed, the streak resets to 0.
- Streak state is persisted in `user_progress` table and read from `GET /user-progress/me`.

**Badges:**
Four badge definitions are hardcoded in `BadgeDefinition.all`:
1. **Wisdom (حكيم)** — Unlocked when `completedActivities >= 10`.
2. **Friend (صديق)** — Unlocked when `streakDays >= 7`.
3. **Hero (بطل)** — Unlocked when `points >= 500`.
4. **Happiness (سعادة)** — Unlocked when `completedActivities >= 20`.

Badge unlock checking is performed in `app_riverpod.dart` after any points update. Newly unlocked badges trigger a `newlyUnlockedBadge` notification in the UI.

#### 17.2 Medication Adherence Calculation

Adherence is calculated as:

```
adherence_rate = (doses_taken / total_scheduled_doses) × 100
```

- `doses_taken` = count of dose records with `status = 'taken'` in the period.
- `total_scheduled_doses` = count of all scheduled doses in the period.
- Exposed via `GET /medications/adherence`.
- Displayed as a percentage on the Nurse Dashboard and Family Dashboard.
- If adherence drops below a configurable threshold, a health alert is triggered.

#### 17.3 AI Companion Logic

The AI companion (`/ai/chat`) uses a server-side Large Language Model (LLM). The context provided to the model includes:

1. The resident's stored AI memory (`ai_resident_memory` record for the resident).
2. The resident's recent care summary (medications, mood, recent activities).
3. The current conversation history.
4. A system prompt instructing the model to act as a kind, patient Arabic-speaking companion for an elderly person.

The `stripUuids()` utility function in `app_models.dart` removes any UUID patterns from AI-generated text before display, preventing technical identifiers from appearing in user-facing responses.

#### 17.4 AI Health Recommendations

AI recommendations are generated server-side for each resident and stored in `ai_resident_memory`. They are triggered by:
- New assessment results being submitted.
- Medication adherence dropping below threshold.
- Vital measurements exceeding alert thresholds.
- Periodic scheduled re-evaluation.

The `AIInsight` model includes a `confidenceScore` field allowing the admin to judge the reliability of each recommendation. The `residentLabel` getter strips UUIDs from the display name.

#### 17.5 Real-Time Event Broadcasting

The `RealtimeService` maintains a persistent Socket.IO connection. Events are scoped to the facility, ensuring only relevant staff receive updates. Event types include:

- `medication_overdue` — A scheduled dose was not confirmed.
- `sos_triggered` — Emergency alert from a resident.
- `visit_booked` — A family visit request is pending approval.
- `complaint_updated` — A complaint status has changed.
- `assessment_submitted` — A specialist completed an assessment.
- `new_message` — A new chat message was sent.

The `liveEventsFor(eventType)` method in `RealtimeService` returns a filtered `Stream<dynamic>` that UI widgets can listen to via Riverpod providers.

#### 17.6 Assessment Score Calculation

Social assessment tools use a question-response scoring system:

- **Scale-based questions:** Each response option has a numeric value (e.g., 0–4 scale).
- **Binary questions:** Yes/No with assigned score values.
- Total score = sum of all response values.
- Score is compared to predefined thresholds (e.g., GDS score > 10 suggests moderate depression).
- The backend stores the total score, the individual answers as JSONB, and any specialist notes.

#### 17.7 Volunteer Certificate Unlock Logic

Certificates are awarded based on cumulative volunteer performance:
- `VolunteerCertificate.isLocked` is `false` when the required progress threshold is met.
- Progress is expressed as a fraction (e.g., "8/10 sessions attended").
- The `progressInfo` field contains a human-readable label.
- Certificate unlock is evaluated on the backend when `POST /user-progress/points` is called.

---

### الخوارزميات ومنطق الأعمال (عربي)

- **التلعيب:** النقاط تتراكم مع الأنشطة المكتملة وتأكيد الأدوية؛ الانتظام اليومي يبني "السلسلة"؛ الشارات تُفتح عند بلوغ عتبات محددة من النقاط والأنشطة والسلاسل.
- **الامتثال للأدوية:** نسبة = (الجرعات المأخوذة ÷ إجمالي الجرعات المجدولة) × 100، وتُعرض كمقياس رئيسي لأداء الرعاية.
- **الذكاء الاصطناعي:** يُزوَّد نموذج اللغة بذاكرة المقيم المستمرة وملخص الرعاية الحالي ليولد ردودًا سياقية دافئة بالعربية.
- **التوصيات الصحية:** تُولَّد تلقائيًا عند تراجع الامتثال أو تجاوز الحيوية للحدود أو تقديم تقييم جديد.
- **الأحداث الآنية:** Socket.IO يبثّ الأحداث بحسب نطاق المرفق، فيستقبلها فقط الموظفون المعنيون.
- **درجات التقييم:** جمع قيم الإجابات وفق مقياس محدد مسبقًا ومقارنتها بعتبات التنبيه.

---

## 18. Error Handling and Validation

### English

#### 18.1 API Error Handling

The `ApiClient` class implements centralised HTTP error handling:

```dart
// Conceptual structure of error handling in api_client.dart
try {
  final response = await http.post(url, headers: headers, body: body)
    .timeout(ApiConfig.requestTimeout);

  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  } else if (response.statusCode == 401) {
    // Token expired — attempt refresh
    await refreshToken();
    // Retry the original request once
  } else if (response.statusCode == 400) {
    // Backend validation error (whitelist/forbidNonWhitelisted)
    throw ApiException(message: jsonDecode(response.body)['message']);
  } else if (response.statusCode == 404) {
    throw ApiException(message: 'Resource not found');
  } else if (response.statusCode >= 500) {
    throw ApiException(message: 'Server error — please try again');
  }
} on TimeoutException {
  throw ApiException(message: 'Request timed out — check your connection');
} on SocketException {
  throw ApiException(message: 'No internet connection');
}
```

#### 18.2 UI State Handling

Each screen that loads data handles three states:

| State | UI Response |
|---|---|
| **Loading** | Shimmer skeleton cards displayed |
| **Empty** | Empty state illustration with descriptive Arabic message |
| **Error** | Error card with retry button and error description |
| **Success** | Data rendered in role-appropriate UI components |

#### 18.3 Form Validation

Form inputs are validated before API calls:

| Field Type | Validation Rules |
|---|---|
| Email | Must match email regex pattern |
| Password | Minimum 8 characters, must include uppercase, lowercase, and number |
| Required fields | Non-empty check with Arabic error message |
| Phone number | Numeric, minimum 10 digits |
| Date fields | Cannot be future dates for historical records |
| Score fields | Must be within tool-defined range |

A `PasswordStrength` widget provides real-time visual feedback as the user types their password.

#### 18.4 Authentication Error Handling

| Error | Handling |
|---|---|
| Invalid credentials | Inline error message on Login Screen |
| Account disabled | "Your account has been deactivated" message |
| Token expired | Silent background refresh; if refresh fails, redirect to Login |
| Biometric failure | Falls back to email/password login |
| Network unavailable | "No connection" banner shown; last loaded data may be visible |

#### 18.5 Real-Time Disconnection

When the Socket.IO WebSocket disconnects:
1. `RealtimeService` detects the disconnection event.
2. Automatic reconnection is attempted with exponential backoff.
3. While disconnected, the UI continues to function with the last-loaded data.
4. A subtle connection status indicator may be shown.

#### 18.6 Empty States

Specific empty states are designed for each scenario:
- No medications scheduled → "لا توجد أدوية اليوم" (No medications today)
- No activities → "لا توجد أنشطة مجدولة" (No activities scheduled)
- No messages → "لا توجد رسائل بعد" (No messages yet)
- No volunteers → "لا توجد فرص متاحة" (No opportunities available)
- Assessment questions not loaded → "جارٍ إعداد الأسئلة" (Questions being set up) — replaces the previous hardcoded fallback

#### 18.7 Medication Skip Validation

When a nurse or resident skips a dose:
- The UI requires selection of a skip reason from a predefined list.
- The skip reason is validated as non-empty before the API call.
- The skip is logged with `status: 'skipped'` and `skip_reason` in the dose record.

---

### معالجة الأخطاء والتحقق (عربي)

- **أخطاء الشبكة:** تعالجها `ApiClient` مركزيًا مع رسائل عربية واضحة (انتهت المهلة، لا اتصال، خطأ في الخادم).
- **انتهاء الجلسة:** يتجدد رمز JWT تلقائيًا في الخلفية؛ عند الفشل يُعاد توجيه المستخدم لتسجيل الدخول.
- **التحقق من النماذج:** كل حقل إدخال يُتحقق منه قبل الإرسال مع رسائل خطأ بالعربية.
- **الحالات الفارغة:** لكل سيناريو حالة فارغة مصممة بنص عربي وصوري توضيحية.
- **اتصال WebSocket:** إعادة الاتصال تلقائية مع التراجع الأسي؛ يستمر عمل التطبيق بآخر بيانات محملة.
- **تخطي الجرعة:** يتطلب اختيار سبب من قائمة محددة مسبقًا ولا يُقبل فارغًا.

---

## 19. Security Considerations

### English

#### 19.1 Implemented Security Measures

| Area | Measure | Implementation |
|---|---|---|
| Transport | All communication over HTTPS/TLS 1.2+ | `ApiConfig.baseUrl` uses `https://` |
| Token Storage | JWT stored in encrypted native secure storage | `flutter_secure_storage` (Keystore/Keychain) |
| Authentication | Delegated to Google Cloud Identity Platform / Firebase Auth (SOC 2 Type II) | `auth_service.dart` via backend proxy |
| Admin Registration | Server-side secret required | `ADMIN_SETUP_SECRET` env variable |
| Input Validation | Backend rejects unknown fields | NestJS `ValidationPipe (whitelist: true)` |
| Biometric | Optional device-level authentication | `local_auth` package |
| Data Scoping | All queries scoped to `facility_id` from JWT | Backend enforces facility isolation |
| File Uploads | Presigned S3 URLs expire quickly | S3 presigned URL pattern via backend |
| Password Policy | Minimum complexity enforced | Cognito password policy + client validation |

#### 19.2 Suggested Security Improvements

The following improvements are recommended for a production release:

1. **Certificate Pinning:** Implement SSL certificate pinning in the Flutter HTTP client to prevent man-in-the-middle attacks. The `http_certificate_pinning` package or Dio's certificate pinning can be used.

2. **Rate Limiting:** Apply rate limiting on authentication endpoints (`/auth/login`, `/auth/register`) at the NestJS level or via an API gateway to prevent brute-force attacks.

3. **Audit Logging:** Extend the existing audit trail feature to log all sensitive administrative actions (creating/deleting residents, changing settings, approving visits) with actor ID and timestamp.

4. **Environment Separation:** Create distinct Cognito user pools and database instances for staging and production environments, and load them via build flavours in Flutter.

5. **Access Token Lifetime:** Reduce the Cognito ID token expiry from the default 1 hour to 15–30 minutes, with silent refresh handled transparently.

6. **Data Encryption at Rest:** Enable PostgreSQL Transparent Data Encryption or use Google Cloud SQL with encryption enabled for the database volume.

7. **Dependency Scanning:** Integrate dependency vulnerability scanning (e.g., `flutter pub audit`, Snyk) into the CI/CD pipeline to detect vulnerable packages.

8. **Sensitive Data Logging:** Add a lint rule or CI check to prevent `print()` statements that could leak PII data in debug logs.

---

### اعتبارات الأمان (عربي)

**التدابير المُنفَّذة:**
- HTTPS/TLS لجميع الاتصالات بدون استثناء.
- تخزين JWT في مخزن مشفر بالكامل (Keystore على أندرويد، Keychain على iOS).
- مصادقة مُفوَّضة لـ Google Cloud Identity Platform / Firebase Auth المعتمد على معيار SOC 2.
- حماية نقطة تسجيل المدير بسر خادم.
- عزل البيانات بحسب المرفق في كل طلب قاعدة بيانات.
- روابط S3 مؤقتة وموقَّعة مسبقًا لرفع الملفات.

**التحسينات المقترحة:**
- تثبيت شهادة SSL (Certificate Pinning) لمنع هجمات التوسط.
- تقييد معدل الطلبات على نقاط المصادقة.
- تسجيل تدقيق شامل للإجراءات الحساسة.
- فصل بيئات التشغيل (staging/production) في Cognito وقاعدة البيانات.
- تقليص فترة صلاحية رموز الوصول.

---

## 20. Testing

### English

#### 20.1 Current Testing Status

No automated test files are present in the current codebase. The `test/` directory is empty, and no test runner configuration beyond the default `flutter_test` dev dependency is found.

#### 20.2 Recommended Testing Strategy

A comprehensive testing strategy for Wanas should include the following layers:

##### 20.2.1 Unit Testing

Test individual service methods and model logic in isolation.

**Priority targets:**
- `MedicationsService`: test `calculateAdherence()` with edge cases (zero doses, all skipped).
- `BadgeDefinition.isUnlocked`: test each badge threshold condition.
- `stripUuids()` utility: test with strings containing zero, one, or multiple UUIDs.
- `Medication.isMissed` getter: test with various time-of-day values.
- `InventoryItem.isLowStock` getter: test boundary conditions.

**Example test structure:**
```dart
// test/services/medications_service_test.dart
void main() {
  group('Medication adherence', () {
    test('returns 100% when all doses taken', () {
      // arrange
      // act
      // assert
    });
    test('returns 0% when no doses recorded', () { ... });
    test('excludes skipped doses from denominator', () { ... });
  });
}
```

##### 20.2.2 Widget Testing

Test Flutter widget rendering and user interaction flows.

**Priority screens:**
- `LoginScreen`: test form validation errors, password visibility toggle, submit button state.
- `MedicationScreen`: test that medication cards render, taken/skip buttons respond.
- `AccessibilityDialog`: test font scale changes are applied.
- `DraggableSOS`: test that the hold gesture triggers confirmation dialog.

##### 20.2.3 Integration Testing

Test complete user flows from UI interaction to API call.

**Priority flows:**
- Login → Dashboard routing by role.
- Confirm medication dose → API call → UI state update.
- Submit assessment → Score calculated → Record saved.
- Book visit → Pending status → Admin approval → Approved status.

**Tooling:** `integration_test` package (Flutter), Mockito for service mocking.

##### 20.2.4 API Testing

Test backend endpoints independently using Postman or Newman:

```
POST /auth/login
  ✓ Valid credentials return 200 with id_token and refresh_token
  ✓ Invalid password returns 401
  ✓ Unknown email returns 401
  ✓ Missing fields return 400

GET /residents (with valid JWT)
  ✓ Returns array of resident objects
  ✓ Each object contains required fields (id, name, roomNumber, status)
  ✓ Returns 401 without Authorization header

POST /medications/doses
  ✓ Valid payload returns 201
  ✓ Extra fields return 400 (whitelist enforcement)
  ✓ Missing scheduleId returns 400
```

##### 20.2.5 User Acceptance Testing (UAT)

Manual testing with real users representing each role:

| Test Scenario | Role | Expected Result |
|---|---|---|
| Complete full daily medication routine | Elderly Resident | All doses marked, adherence shows 100% |
| Assign and complete 5 care tasks | Nurse | Tasks show completed, dashboard count updates |
| Book visit, receive admin approval | Family Member | Visit shows "Approved" with time details |
| Conduct GDS assessment and submit | Social Specialist | Score stored, historical chart updated |
| Book volunteer session, receive rating | Volunteer | Booking confirmed, rating visible after session |
| Add new resident with photo | Administrator | Resident appears in list with photo |

##### 20.2.6 Accessibility Testing

- Verify TalkBack (Android) and VoiceOver (iOS) correctly announce all UI elements.
- Test font scale at 1.5× multiplier — ensure no text overflow or clipping.
- Test high-contrast mode — all text must maintain contrast ratio ≥ 4.5:1.
- Test RTL layout on both Android and iOS to detect any LTR rendering bugs.

---

### الاختبار (عربي)

لا توجد اختبارات مُؤتمَتة في الكود البرمجي الحالي. يُوصى بتطبيق استراتيجية اختبار شاملة تشمل:

- **اختبارات الوحدة (Unit Tests):** لاختبار دوال الخدمات ومنطق النماذج بمعزل عن الشبكة.
- **اختبارات المكونات (Widget Tests):** لاختبار عرض الشاشات واستجابة المكونات لتفاعلات المستخدم.
- **اختبارات التكامل (Integration Tests):** لاختبار المسارات الكاملة من الواجهة إلى الواجهة البرمجية.
- **اختبارات الواجهة البرمجية (API Tests):** عبر Postman لاختبار كل نقطة نهاية بسيناريوهات متعددة.
- **اختبار قبول المستخدم (UAT):** مع ممثلين حقيقيين لكل دور للتحقق من تحقق الهدف الوظيفي.
- **اختبار إمكانية الوصول:** تشغيل TalkBack وVoiceOver، واختبار حجم الخط والتباين العالي واتجاه RTL.

---

## 21. Deployment and Installation Guide

### English

#### 21.1 Prerequisites

| Requirement | Version | Purpose |
|---|---|---|
| Flutter SDK | 3.x (stable) | Mobile framework |
| Dart SDK | ≥3.0.0 | Language runtime (bundled with Flutter) |
| Android Studio | 2023.1+ | Android build tools and emulator |
| Xcode | 15+ (macOS only) | iOS build tools (for iOS deployment) |
| Git | Any | Version control |
| Node.js | 18+ | Backend development |
| PostgreSQL | 14+ | Database (for local backend) |

#### 21.2 Mobile Application Setup

**Step 1 — Clone the repository:**
```bash
git clone <repository-url>
cd Tbtba-main
```

**Step 2 — Install Flutter dependencies:**
```bash
flutter pub get
```

**Step 3 — Generate native splash screen:**
```bash
dart run flutter_native_splash:create
```

**Step 4 — Configure the API endpoint:**

Edit `lib/config/api_config.dart`:
```dart
// For local development (Android emulator):
static const String baseUrl = 'http://10.0.2.2:3000';

// For local development (iOS simulator):
static const String baseUrl = 'http://localhost:3000';

// For production:
static const String baseUrl = 'https://api.helpers-tech.com';
```

**Step 5 — Configure Firebase:**
- Place the `google-services.json` file in `android/app/`.
- For iOS, place `GoogleService-Info.plist` in `ios/Runner/`.

**Step 6 — Run the application:**
```bash
# On Android emulator or connected device:
flutter run

# For release build:
flutter build apk --release

# For iOS (macOS only):
flutter build ios --release
```

#### 21.3 Backend Setup (Local Development)

The backend source is located in `external/raaya-backend/`.

**Step 1 — Navigate to backend directory:**
```bash
cd external/raaya-backend
```

**Step 2 — Install dependencies:**
```bash
npm install
```

**Step 3 — Set up environment variables:**

Create a `.env` file:
```env
DATABASE_URL=postgresql://username:password@localhost:5432/wanas_db
JWT_SECRET=your-jwt-secret
COGNITO_REGION=us-east-1
COGNITO_USER_POOL_ID=us-east-1_WQgMPSADf
COGNITO_CLIENT_ID=ifk56gi2vp5jn4tshvp96vn06
COGNITO_CLIENT_SECRET=your-cognito-client-secret
ADMIN_SETUP_SECRET=your-admin-setup-secret
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
AWS_S3_BUCKET=your-s3-bucket-name
AWS_REGION=us-east-1
FIREBASE_PROJECT_ID=raaya-taptaba-app
```

**Step 4 — Run database migrations:**
```bash
npm run migration:run
```

**Step 5 — Seed initial data (if available):**
```bash
npm run seed
```

**Step 6 — Start the development server:**
```bash
npm run start:dev
```

The backend will be available at `http://localhost:3000`.

#### 21.4 Android Release Signing

For Android release builds, configure signing in `android/key.properties`:
```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=your-key-alias
storeFile=path/to/your/keystore.jks
```

#### 21.5 Production Deployment

The production backend is deployed on **Google Compute Engine (GCE)** and served at `https://api.helpers-tech.com`.

**Deployment steps (for backend updates):**
1. SSH into the EC2 instance.
2. Pull the latest code from the repository.
3. Run `npm run migration:run` for any new migrations.
4. Restart the NestJS process via PM2: `pm2 restart wanas-api`.

**Mobile app distribution:**
- Android: Build `.aab` release file → upload to Google Play Console.
- iOS: Build `.ipa` → upload to App Store Connect via Xcode or Transporter.

#### 21.6 Environment Variables Reference

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `COGNITO_REGION` | Yes | GCP region (e.g., `us-east-1`) |
| `COGNITO_USER_POOL_ID` | Yes | Cognito User Pool ID |
| `COGNITO_CLIENT_ID` | Yes | Cognito App Client ID |
| `COGNITO_CLIENT_SECRET` | Yes | Cognito App Client Secret |
| `ADMIN_SETUP_SECRET` | Yes | Secret for admin registration endpoint |
| `AWS_ACCESS_KEY_ID` | Yes | GCP IAM access key (S3, Polly) |
| `AWS_SECRET_ACCESS_KEY` | Yes | GCP IAM secret key |
| `AWS_S3_BUCKET` | Yes | S3 bucket name for file storage |
| `AWS_REGION` | Yes | GCP region for S3 and Polly |

---

### دليل النشر والتثبيت (عربي)

**متطلبات التشغيل المحلي:**
- Flutter SDK 3.x مع Dart ≥3.0.0.
- Android Studio للبناء على أندرويد، وXcode (macOS) للبناء على iOS.
- Node.js 18+ وPostgreSQL 14+ لتشغيل الخلفية محليًا.

**خطوات إعداد التطبيق:**
1. استنساخ المستودع وتثبيت التبعيات بـ `flutter pub get`.
2. تعديل عنوان الواجهة البرمجية في `api_config.dart`.
3. وضع ملفات Firebase (`google-services.json`).
4. تشغيل التطبيق بـ `flutter run`.

**خطوات إعداد الخلفية:**
1. تثبيت التبعيات بـ `npm install`.
2. إنشاء ملف `.env` بالمتغيرات البيئية المطلوبة.
3. تشغيل الترحيلات بـ `npm run migration:run`.
4. تشغيل الخادم بـ `npm run start:dev`.

**النشر على الإنتاج:**
الخلفية مُنشَرة على Google Compute Engine (GCE) وتُدار بـ PM2. التطبيق المحمول يُوزَّع عبر متجر Google Play وApp Store Connect.

---

## 22. Limitations

### English

The following limitations exist in the current version of Wanas based on analysis of the actual codebase:

1. **No offline mode:** The application requires an active internet connection. No local caching strategy is implemented for offline data access. If connectivity is lost, users cannot interact with live data.

2. **Single facility per backend instance:** The current architecture ties the backend to a single facility's Cognito user pool configuration. Multi-facility support across different organisations would require architectural changes.

3. **Text-only chat (no media in messages):** The backend's `SendMessageDto` currently only accepts `body`, `recipientId`, and `residentId`. Photo and file attachments in chat are noted in the backend gap analysis as planned but not yet implemented.

4. **Zoom integration not fully bundled:** The codebase references Zoom-based video calls and the data model stores `zoomLink` values, but the Zoom SDK is not included in the `pubspec.yaml` dependencies. Video calling relies on launching an external Zoom URL.

5. **No tablet optimisation:** The UI layouts are designed for phone screen sizes (360–480dp width). Tablets may display stretched or awkward layouts.

6. **English localisation absent:** The application is Arabic-only. There is no i18n (internationalisation) infrastructure for adding additional languages.

7. **No web frontend:** Wanas is a mobile-only application. Administrative tasks can only be performed through the mobile app, which may be less ergonomic for complex administrative workflows that would benefit from a web dashboard.

8. **Automated tests not implemented:** No unit, widget, or integration tests exist in the codebase. This creates risk for regression when changes are made.

9. **PDF generation is local only (fallback):** When the backend PDF export endpoint is unavailable, the app falls back to local PDF generation. The local-generated PDF may lack the facility logo and full metadata available on the server.

10. **Cognitive games are limited:** The current cognitive games module provides a basic set of exercises. No adaptive difficulty or clinical validation of the game design is documented.

---

### القيود الحالية (عربي)

بناءً على تحليل الكود البرمجي الفعلي، توجد القيود التالية في الإصدار الحالي من وَنَس:

1. **لا وضع دون اتصال:** يتطلب التطبيق اتصالًا نشطًا بالإنترنت في جميع الأوقات.
2. **مرفق واحد لكل نسخة:** البنية الحالية مرتبطة بمرفق واحد لكل نسخة من الخلفية.
3. **الدردشة نصية فقط:** لا يدعم البريد الخلفي حاليًا مرفقات الوسائط في الرسائل.
4. **تكامل Zoom غير مكتمل:** مكالمات الفيديو تعتمد على رابط Zoom خارجي وليس SDK مدمجًا.
5. **لا دعم للأجهزة اللوحية:** التصاميم محسَّنة للهواتف فقط.
6. **عربية فقط:** لا تُوفَّر بنية تحتية للتعريب لدعم لغات إضافية.
7. **تطبيق محمول فقط:** لا توجد واجهة ويب للإدارة.
8. **لا اختبارات مُؤتمَتة:** غياب الاختبارات يُشكّل خطر الانحدار عند التعديل.
9. **توليد PDF محلي:** في غياب استجابة الخادم يُولَّد PDF محلي قد يفتقر لبيانات المرفق الكاملة.
10. **ألعاب معرفية محدودة:** المجموعة الحالية من الألعاب محدودة ودون تكيّف في مستوى الصعوبة.

---

## 23. Future Enhancements

### English

The following enhancements are realistic and professionally recommended for future versions of Wanas:

#### 23.1 Technical Enhancements

1. **Offline-First Architecture:** Implement a local SQLite cache using `drift` or `isar` to allow the application to function without connectivity, syncing when the connection is restored.

2. **Full Zoom SDK Integration:** Replace the URL-based video call approach with a native Zoom SDK integration for in-app video calling without requiring users to install a separate application.

3. **Rich Chat Media:** Extend the backend messages module to support image, audio, and document attachments in the specialist–family chat.

4. **Automated Testing Suite:** Implement unit tests, widget tests, and integration tests to achieve at least 70% code coverage before any production release.

5. **Web Dashboard for Administrators:** Build a complementary Next.js or React web application that gives administrators a more ergonomic desktop interface for complex management tasks.

6. **Multi-Language Support:** Add Arabic, English, and French localisation using the `intl` package and Flutter's Localizations infrastructure.

7. **Tablet Layout Support:** Implement adaptive layouts using `LayoutBuilder` to display two-column layouts on larger screens.

8. **Wearable Integration:** Integrate with Apple Watch and Wear OS for vital monitoring alerts and medication reminder delivery.

#### 23.2 Clinical Enhancements

1. **HL7 FHIR Integration:** Implement a FHIR-compliant API interface to allow Wanas to exchange data with hospital EHR systems, enabling seamless care continuity for residents transitioning from hospital to nursing home.

2. **Expanded Cognitive Assessment Library:** Add validated clinical tools such as the Mini-Mental State Examination (MMSE) and Montreal Cognitive Assessment (MoCA) to the assessment toolkit.

3. **Vital Monitoring IoT Integration:** Connect to smart bed sensors, pulse oximeters, and blood pressure cuffs to automatically log vitals without manual nurse entry.

4. **Predictive Health Analytics:** Apply machine learning to historical vital and medication adherence data to predict deterioration events, enabling proactive rather than reactive care.

5. **Adaptive Cognitive Games:** Introduce difficulty scaling based on the resident's performance history and cognitive assessment scores.

#### 23.3 Social and Community Enhancements

1. **Volunteer Community Portal:** Build a public-facing web portal where volunteers can discover and join facilities without requiring an admin invitation.

2. **Family Group Chat:** Allow multiple family members linked to the same resident to communicate in a shared group chat thread.

3. **Memory Book Generation:** Auto-generate a printable or PDF "life story book" from the resident's memory album and recorded AI conversations.

4. **Social Activity Leaderboard:** Introduce an anonymous, positive-focused leaderboard among residents to encourage friendly participation competition.

5. **Telehealth Integration:** Allow doctors to conduct virtual consultations recorded in the system, with notes automatically populated to the resident's medical profile.

---

### التحسينات المستقبلية (عربي)

#### التحسينات التقنية
- معمارية العمل دون اتصال مع مزامنة لاحقة (SQLite محلي).
- تكامل Zoom SDK كامل لمكالمات فيديو داخل التطبيق.
- دعم الوسائط في رسائل الدردشة.
- مجموعة اختبارات مُؤتمَتة شاملة.
- لوحة تحكم ويب للمدير.
- دعم لغات متعددة (عربي، إنجليزي، فرنسي).
- تصاميم متكيفة للأجهزة اللوحية.

#### التحسينات السريرية
- تكامل FHIR مع أنظمة السجلات الصحية الإلكترونية.
- أدوات تقييم معيارية إضافية (MMSE، MoCA).
- ربط أجهزة قياس الحيوية الذكية لتسجيل تلقائي.
- تحليلات تنبؤية بالذكاء الاصطناعي لرصد التدهور الصحي المبكر.

#### التحسينات الاجتماعية
- بوابة عامة للمتطوعين.
- دردشة جماعية لأفراد الأسرة.
- كتاب ذكريات مُولَّد تلقائيًا.
- لوحة شرف إيجابية تشجيعية بين المقيمين.
- تكامل الاستشارات الطبية عن بُعد.

---

## 24. Conclusion

### English

Wanas represents a significant achievement in the application of modern software engineering to the domain of elderly care. Over the course of this graduation project, the team successfully designed and implemented a comprehensive, production-oriented mobile system that addresses real-world challenges faced by nursing homes, elderly residents, their families, and care staff.

The system demonstrates mastery across multiple technology domains: cross-platform mobile development with Flutter, state management with Riverpod, cloud authentication with Google Cloud Identity Platform / Firebase Auth, real-time communication with Socket.IO, AI companion integration, push notification delivery via Firebase, and secure file handling with Google Cloud Storage (GCS). The six-role architecture — Administrator, Nurse, Elderly Resident, Family Member, Social Specialist, and Volunteer — reflects a deep understanding of the human ecosystem within a care facility and the importance of providing each stakeholder with tools tailored precisely to their responsibilities and needs.

Beyond the technical achievements, Wanas embodies a human-centred design philosophy. The elderly-facing interface was designed with accessibility at its core: large Arabic text, simplified navigation, a conversational AI companion, and an emergency SOS system. These features speak to the project's deeper mission — not merely to digitise administrative processes, but to genuinely improve the quality of life of the people at the heart of the system: the elderly residents themselves.

The project also reflects the team's growth as software engineers. Navigating the complexity of a full-stack system with 75+ screens, 35+ service classes, 50+ data models, a deployed production backend, and cloud infrastructure represents the kind of real-world engineering challenge that prepares graduates for the demands of the technology industry.

Future versions of Wanas have the potential to become a commercially viable product. The recommended enhancements — offline support, HL7 FHIR integration, predictive health analytics, and a web dashboard — would position Wanas as a comprehensive Digital Care Management Platform suitable for deployment across the healthcare sector in the Arab world and beyond.

The team is grateful for the guidance of Dr. Nabil El Ghamry and Dr. Amina Fawzy, whose supervision provided both technical direction and the academic framework that shaped this project into a cohesive, well-documented graduation work worthy of the International Academy of Engineering and Media Science.

---

### الخاتمة (عربي)

يمثّل مشروع وَنَس إنجازًا علميًا وتقنيًا متكاملًا يعكس عمق الفهم والاستثمار العملي لتقنيات الهندسة البرمجية الحديثة في خدمة فئة إنسانية تستحق العناية — كبار السن.

على مدار هذا المشروع، تمكّن الفريق من تصميم وبناء نظام متكامل متعدد الأدوار يُعالج تحديات حقيقية تواجه دور رعاية المسنين، ويجمع بين التقنيات الأكثر حداثةً: تطوير تطبيق محمول متعدد الأنظمة بـ Flutter، وإدارة الحالة بـ Riverpod، ومصادقة سحابية بـ Google Cloud Identity Platform / Firebase Auth، واتصال آني بـ Socket.IO، ودمج رفيق ذكاء اصطناعي محادث، وإشعارات فورية عبر Firebase، وتخزين آمن للملفات بـ Google Cloud Storage (GCS).

لكن الإنجاز الأعمق يكمن في الفلسفة الإنسانية التي تجمع هذا كله: "وَنَس" ليس مجرد تطبيقًا لإدارة المرافق الصحية، بل هو مشروع يضع المسن في قلب كل قرار تصميمي — من واجهة مبسّطة تراعي احتياجاته البصرية والمعرفية، إلى رفيق ذكي يؤنسه، إلى زر طوارئ يُطمئنه أنه ليس وحيدًا.

يُشكّل هذا المشروع منطلقًا قابلًا للتطوير نحو منصة تجارية متكاملة لإدارة الرعاية الرقمية في العالم العربي. والفريق يُعرب عن عميق امتنانه للمشرفَيْن الكريمَيْن الدكتور نبيل الغمري والدكتورة أمينة فوزي، اللذَيْن أرسَيا الإطار الأكاديمي والتوجيه التقني الذي حوّل هذا المشروع إلى عمل علمي منهجي يليق بالأكاديمية الدولية للهندسة وعلوم الإعلام.

---

## 25. References

### English

#### Frameworks and Languages

1. Google. (2024). *Flutter — Build apps for any screen.* https://flutter.dev
2. Google. (2024). *Dart programming language.* https://dart.dev
3. Riverpod Authors. (2024). *Riverpod — A reactive caching and data-binding framework.* https://riverpod.dev

#### Backend and Cloud

4. NestJS Authors. (2024). *NestJS — A progressive Node.js framework.* https://nestjs.com
5. Amazon Web Services. (2024). *Amazon Cognito — User authentication and authorisation.* https://aws.amazon.com/cognito/
6. Amazon Web Services. (2024). *Google Cloud Storage (GCS) — Object storage.* https://aws.amazon.com/s3/
7. Amazon Web Services. (2024). *Amazon Polly — Text-to-speech service.* https://aws.amazon.com/polly/
8. PostgreSQL Global Development Group. (2024). *PostgreSQL documentation.* https://www.postgresql.org/docs/

#### Mobile Technologies

9. Google. (2024). *Firebase Cloud Messaging.* https://firebase.google.com/docs/cloud-messaging
10. Socket.IO Authors. (2024). *Socket.IO documentation.* https://socket.io/docs/
11. Hive Developers. (2024). *flutter_secure_storage.* https://pub.dev/packages/flutter_secure_storage
12. Baseflow. (2024). *permission_handler.* https://pub.dev/packages/permission_handler
13. flutter_local_notifications Contributors. (2024). *flutter_local_notifications.* https://pub.dev/packages/flutter_local_notifications

#### UI and Accessibility

14. Material Design. (2024). *Material Design 3 — Design guidelines.* https://m3.material.io
15. Google Fonts. (2024). *Cairo font family.* https://fonts.google.com/specimen/Cairo
16. W3C. (2018). *Web Content Accessibility Guidelines (WCAG) 2.1.* https://www.w3.org/TR/WCAG21/

#### Standards and Healthcare

17. World Health Organization. (2022). *Ageing and health.* https://www.who.int/news-room/fact-sheets/detail/ageing-and-health
18. Sheikh, J. I., & Yesavage, J. A. (1986). Geriatric Depression Scale (GDS): Recent evidence and development of a shorter version. *Clinical Gerontologist, 5*(1–2), 165–173.
19. HL7 International. (2023). *FHIR — Fast Healthcare Interoperability Resources.* https://www.hl7.org/fhir/

#### Software Engineering

20. Martin, R. C. (2008). *Clean Code: A Handbook of Agile Software Craftsmanship.* Prentice Hall.
21. Fowler, M. (2018). *Refactoring: Improving the Design of Existing Code* (2nd ed.). Addison-Wesley.
22. OWASP Foundation. (2023). *OWASP Mobile Application Security Verification Standard (MASVS).* https://owasp.org/www-project-mobile-app-security/

---

*Document generated for academic submission — International Academy of Engineering and Media Science — Academic Year 2025/2026*

*تم إعداد هذه الوثيقة لأغراض التقديم الأكاديمي — الأكاديمية الدولية للهندسة وعلوم الإعلام — العام الدراسي 2025/2026*



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
