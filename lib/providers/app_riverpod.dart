import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للوصول إلى الملفات (مثل الخطوط)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart'; // نماذج البيانات المستخدمة في التطبيق
// مكتبة إدارة التصاريح
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // مكتبة التخزين الآمن
import 'package:flutter_contacts/flutter_contacts.dart'; // مكتبة جهات الاتصال
import 'package:url_launcher/url_launcher.dart'; // مكتبة تشغيل الروابط والمكالمات
import 'package:photo_manager/photo_manager.dart'; // مكتبة إدارة الصور
import 'package:image_picker/image_picker.dart'; // مكتبة اختيار الصور من المعرض
// للتعامل مع ملفات الصور المختارة
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../config/api_config.dart';
import '../services/notification_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/backend_sync_service.dart';
import '../services/realtime_service.dart';
import '../services/push_notification_service.dart';
import '../services/facility_settings_service.dart';
import '../services/emergency_service.dart';
import '../services/ai_service.dart';
import '../services/video_call_service.dart';
import '../services/voice_message_service.dart';
import '../services/user_progress_service.dart';
import '../services/backend_mutation_service.dart';
import '../services/social_service.dart';
import '../services/medications_service.dart';
import '../services/health_service.dart';
import '../services/user_preferences_service.dart';
import '../services/complaints_service.dart';
import '../services/ai_media_service.dart';
import '../services/messages_service.dart';

final appRiverpod = ChangeNotifierProvider((ref) => AppRiverpod());

class AppRiverpod extends ChangeNotifier {
  int selectedIndex = 0;
  int currentAdminTabIndex = 0;

  void refreshState() {
    notifyListeners();
  }

  void setAdminTabIndex(int index) {
    currentAdminTabIndex = index;
    notifyListeners();
  }

  String facilityName = ''; // اسم المنشأة من AWS
  String managerName = ''; // اسم المدير من AWS
  String splashStatus = ''; // حالة التحميل للعرض في شاشة البداية
  Set<String> earnedBadgeIds = {}; // معرّفات الأوسمة التي فتحها المسن
  BadgeDefinition? newlyUnlockedBadge; // آخر وسام انفتح — يُمسح بعد عرض الاحتفال

  void scheduleMedicationReminders(NotificationService service) {
    for (var med in medications) {
      if (!med.isTaken &&
          med.scheduledTime != null &&
          med.scheduledTime!.isAfter(DateTime.now())) {
        service.scheduleNotification(
          id: med.id.hashCode,
          title: 'موعد دواء 💊',
          body: 'حان موعد تناول ${med.name} (${med.dosage})',
          scheduledDate: med.scheduledTime!,
          payload: 'medical',
        );
      }
    }
  }

  String currentRole = ''; // الدور الحالي للمستخدم بعد تسجيل الدخول من AWS
  bool hasSeenOnboarding = false; // هل شاهد المستخدم شاشات الترحيب؟
  bool isAuthenticated = false; // هل المستخدم مسجل دخوله؟
  bool isInitialized = false; // هل تم تحميل البيانات من الذاكرة؟
  double fontScaleFactor = 1.0; // حجم الخط المختار لسهولة القراءة
  bool isHighContrast = false; // تفعيل وضع التباين العالي
  bool isDarkMode = false; // تفعيل الوضع الليلي
  bool isBiometricEnabled = false; // تفعيل تسجيل الدخول البيومتري

  final _storage = const FlutterSecureStorage(); // إنشاء كائن التخزين الآمن
  bool isRefreshingSession = false;
  String selectedAdminDateFilter = 'اليوم';
  DateTime? _sessionExpiry;

  AppAccount? currentAccount; // الحساب الحالي المسجل دخوله

  // --- إدارة الحسابات (Account Management) ---
  List<AppAccount> accounts = [];

  // دالة لتحديث بيانات الحساب الحالي
  void updateCurrentAccount(AppAccount updatedAccount) {
    currentAccount = updatedAccount;
    // تحديث في القائمة العامة أيضاً
    final idx = accounts.indexWhere((a) => a.email == updatedAccount.email);
    if (idx != -1) {
      accounts[idx] = updatedAccount;
    }
    notifyListeners();
  }

  // دالة لاختيار صورة البروفايل
  Future<void> pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && currentAccount != null) {
      final updatedAccount = currentAccount!.copyWith(imageUrl: image.path);
      updateCurrentAccount(updatedAccount);
    }
  }

  // دالة للمدير لإنشاء حسابات جديدة عبر AWS.
  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createManagedUser(
        email: email,
        fullName: name,
        role: role,
        temporaryPassword: password,
      );
    });
    if (synced) {
      unawaited(syncBackendData());
    }
    return synced;
  }

  // دالة للتسجيل الذاتي (للمتطوعين والأهالي) عبر AWS Cognito.
  Future<void> selfRegister({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final facilityId = _registrationFacilityId();
    if (facilityId.isEmpty) {
      throw ApiException(
        400,
        'لا يوجد FACILITY_ID مضبوط للتسجيل الذاتي على AWS',
      );
    }

    await AuthService.instance.register(
      email: email,
      password: password,
      name: name,
      role: _selfRegistrationRole(role),
      facilityId: facilityId,
    );
    backendSyncError = null;
    notifyListeners();
  }

  // دالة تسجيل المدير مع بيانات المنشأة عبر AWS.
  Future<void> registerAdmin({
    required String name,
    required String email,
    required String password,
    required String facilityName,
    required String facilityAddress,
    required List<String> amenities,
    String? facilityYearOfEst,
    String? facilityCapacity,
    String? facilityLicenseNumber,
    String? facilityLocationUrl,
  }) async {
    final setupSecret = ApiConfig.adminRegistrationSecret.trim();
    if (setupSecret.isEmpty) {
      throw ApiException(
        400,
        'ADMIN_REG_SECRET غير مضبوط، لا يمكن تسجيل مدير منشأة على AWS',
      );
    }

    await AuthService.instance.registerAdmin(
      name: name,
      email: email,
      password: password,
      facilityId: _facilityIdForAdminRegistration(
        email: email,
        licenseNumber: facilityLicenseNumber,
      ),
      setupSecret: setupSecret,
      facilityName: facilityName,
      facilityAddress: facilityAddress,
      licenseNumber: facilityLicenseNumber,
      facilityYearOfEst: facilityYearOfEst,
      facilityCapacity: facilityCapacity,
      facilityLocationUrl: facilityLocationUrl,
    );

    this.facilityName = facilityName;
    managerName = name;
    backendSyncError = null;

    notifyListeners();
  }

  // ربط عائلة بمسن
  Future<void> linkFamilyToResident(
      String residentId, String familyEmail) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createFamilyMemberForEmail(
        residentId: residentId,
        email: familyEmail,
      );
    });
    if (!synced) return;
    final idx = residentFiles.indexWhere((r) => r.id == residentId);
    if (idx != -1) {
      final r = residentFiles[idx];
      residentFiles[idx] = SpecialistResidentFile(
        id: r.id,
        name: r.name,
        nameEn: r.nameEn,
        room: r.room,
        status: r.status,
        lastUpdate: r.lastUpdate,
        categories: r.categories,
        initials: r.initials,
        phone: r.phone,
        age: r.age,
        familyMembers: r.familyMembers,
        familyEmail: familyEmail, // الحقل الجديد للربط
        bloodType: r.bloodType,
        chronicDiseases: r.chronicDiseases,
        allergies: r.allergies,
        insuranceInfo: r.insuranceInfo,
        mobilityStatus: r.mobilityStatus,
        assistiveDevices: r.assistiveDevices,
        cognitiveStatus: r.cognitiveStatus,
        dietType: r.dietType,
        foodRestrictions: r.foodRestrictions,
        foodPreferences: r.foodPreferences,
        previousProfession: r.previousProfession,
        hobbies: r.hobbies,
        socialStatus: r.socialStatus,
        uploadedDocuments: r.uploadedDocuments,
      );
      notifyListeners();
    }
    unawaited(syncBackendData());
  }

  void updateResidentSocialHistory({
    required String residentId,
    required String previousProfession,
    required String socialStatus,
    required List<String> hobbies,
  }) {
    final idx = residentFiles.indexWhere((r) => r.id == residentId);
    if (idx == -1) return;
    final r = residentFiles[idx];
    residentFiles[idx] = SpecialistResidentFile(
      id: r.id,
      name: r.name,
      nameEn: r.nameEn,
      room: r.room,
      status: r.status,
      lastUpdate: r.lastUpdate,
      categories: r.categories,
      initials: r.initials,
      phone: r.phone,
      age: r.age,
      familyMembers: r.familyMembers,
      familyEmail: r.familyEmail,
      bloodType: r.bloodType,
      chronicDiseases: r.chronicDiseases,
      allergies: r.allergies,
      insuranceInfo: r.insuranceInfo,
      mobilityStatus: r.mobilityStatus,
      assistiveDevices: r.assistiveDevices,
      cognitiveStatus: r.cognitiveStatus,
      dietType: r.dietType,
      foodRestrictions: r.foodRestrictions,
      foodPreferences: r.foodPreferences,
      previousProfession: previousProfession,
      hobbies: hobbies,
      socialStatus: socialStatus,
      uploadedDocuments: r.uploadedDocuments,
    );
    notifyListeners();
  }

  void addDocumentToResident(String residentId, String documentUrl) {
    final idx = residentFiles.indexWhere((r) => r.id == residentId);
    if (idx == -1) return;
    final r = residentFiles[idx];
    final updated = List<String>.from(r.uploadedDocuments ?? [])..add(documentUrl);
    residentFiles[idx] = SpecialistResidentFile(
      id: r.id,
      name: r.name,
      nameEn: r.nameEn,
      room: r.room,
      status: r.status,
      lastUpdate: r.lastUpdate,
      categories: r.categories,
      initials: r.initials,
      phone: r.phone,
      age: r.age,
      familyMembers: r.familyMembers,
      familyEmail: r.familyEmail,
      bloodType: r.bloodType,
      chronicDiseases: r.chronicDiseases,
      allergies: r.allergies,
      insuranceInfo: r.insuranceInfo,
      mobilityStatus: r.mobilityStatus,
      assistiveDevices: r.assistiveDevices,
      cognitiveStatus: r.cognitiveStatus,
      dietType: r.dietType,
      foodRestrictions: r.foodRestrictions,
      foodPreferences: r.foodPreferences,
      previousProfession: r.previousProfession,
      hobbies: r.hobbies,
      socialStatus: r.socialStatus,
      uploadedDocuments: updated,
    );
    notifyListeners();
  }

  AppRiverpod() {
    _loadAuthState(); // تحميل حالة الدخول عند بدء تشغيل المزود
  }

  // تحميل بيانات الدخول والجلسة من التخزين الآمن
  Future<void> _loadAuthState() async {
    splashStatus = 'جاري التحقق من هويتك...';
    notifyListeners();

    final auth = await _storage.read(key: 'isAuthenticated');
    final role = await _storage.read(key: 'currentRole');
    final onboarding = await _storage.read(key: 'hasSeenOnboarding');
    final expiryStr = await _storage.read(key: 'sessionExpiry');

    if (auth == 'true') {
      try {
        final user = await AuthService.instance.restoreSession();
        if (user == null) {
          await _storage.delete(key: 'isAuthenticated');
          await _storage.delete(key: 'currentRole');
          await _storage.delete(key: 'userEmail');
          await _storage.delete(key: 'sessionExpiry');
        } else {
          if (expiryStr != null) {
            _sessionExpiry = DateTime.tryParse(expiryStr);
          }
          _applyBackendUser(
            email: user.email,
            role: role ?? user.arabicRole,
            userId: user.userId,
            facilityId: user.facilityId,
            name: user.name,
            linkedResidentId: user.linkedResidentId,
            facilityName: user.facilityName,
          );

          splashStatus = 'جاري تحميل بياناتك...';
          notifyListeners();

          // حمّل الأوسمة أولاً قبل sync البيانات لتجنب إعادة إطلاقها
          await _loadEarnedBadges();

          // انتظر sync البيانات (حد أقصى 8 ثوانٍ) + تهيئة الإشعارات بالتوازي
          await Future.wait<void>([
            syncBackendData().timeout(
              const Duration(seconds: 8),
              onTimeout: () {},
            ),
            PushNotificationService.instance.init(),
          ]).catchError((_) => <void>[]);
        }
      } catch (e) {
        isAuthenticated = false;
        currentRole = '';
        currentAccount = null;
        backendSyncError = e.toString();
        await AuthService.instance.logout();
        await _storage.delete(key: 'isAuthenticated');
        await _storage.delete(key: 'currentRole');
        await _storage.delete(key: 'userEmail');
        await _storage.delete(key: 'sessionExpiry');
      }
    }

    if (onboarding == 'true') hasSeenOnboarding = true;

    final biometric = await _storage.read(key: 'isBiometricEnabled');
    if (biometric == 'true') isBiometricEnabled = true;

    splashStatus = 'جاهز!';
    isInitialized = true;
    notifyListeners();
  }

  /// يُعيد تفعيل آخر جلسة محفوظة (يُستدعى بعد نجاح التحقق البيومتري)
  Future<bool> restoreLastSession() async {
    try {
      final user = await AuthService.instance.restoreSession();
      if (user == null) return false;
      _applyBackendUser(
        email: user.email,
        role: user.arabicRole,
        userId: user.userId,
        facilityId: user.facilityId,
        name: user.name,
        linkedResidentId: user.linkedResidentId,
        facilityName: user.facilityName,
      );
      unawaited(syncBackendData());
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // حفظ الدور في الذاكرة لتجنب الخروج عند الريلود
  Future<void> setAndSaveRole(String role) async {
    currentRole = role;
    await _storage.write(key: 'currentRole', value: role);
    notifyListeners();
  }

  // أداة اختبار داخلية لإنهاء الجلسة محلياً والتحقق من مسار التجديد الحقيقي.
  void simulateSessionExpiry() {
    _sessionExpiry = DateTime.now().subtract(const Duration(minutes: 1));
    notifyListeners();
  }

  // التحقق من صحة الجلسة وتجديدها إذا لزم الأمر
  Future<bool> checkAndRefreshSession() async {
    if (!isAuthenticated || _sessionExpiry == null) return true;

    // إذا كانت الجلسة منتهية أو ستنتهي خلال دقيقة
    if (_sessionExpiry!.isBefore(DateTime.now())) {
      if (isRefreshingSession) return false;

      isRefreshingSession = true;
      notifyListeners();

      try {
        final user = await AuthService.instance.refreshSession();
        if (user == null) {
          await logout();
          return false;
        }
        _applyBackendUser(
          email: user.email,
          role: user.arabicRole,
          userId: user.userId,
          facilityId: user.facilityId,
          name: user.name,
          linkedResidentId: user.linkedResidentId,
          facilityName: user.facilityName,
          clearExistingData: false,
        );
        _sessionExpiry = DateTime.now().add(const Duration(hours: 1));
        await _storage.write(
            key: 'sessionExpiry', value: _sessionExpiry!.toIso8601String());
        backendSyncError = null;
        isRefreshingSession = false;
        notifyListeners();
        return true;
      } catch (e) {
        backendSyncError = e.toString();
        isRefreshingSession = false;
        await logout();
        return false;
      }
    }
    return true;
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    unawaited(_syncUserPreferences());
    notifyListeners();
  }

  // تحديث فلتر التاريخ للوحة تحكم المدير وإعادة بناء المؤشرات المحملة من AWS.
  void updateAdminDateFilter(String filter) {
    selectedAdminDateFilter = filter;
    // ملاحظة: هنا يمكن إضافة استدعاء للـ API لتحديث قائمة الإحصائيات (adminStats)
    // بناءً على التاريخ المختار (اليوم مقابل الشهر الماضي مثلاً)
    notifyListeners(); // إشعار كافة واجهات المدير بضرورة إعادة البناء بالبيانات الجديدة
  }

  // Offline Mode State
  List<PendingAssessment> pendingAssessments = [];
  bool isSyncing = false;

  void addPendingAssessment(PendingAssessment assessment) {
    pendingAssessments.add(assessment);
    notifyListeners();
  }

  Future<void> syncAssessments() async {
    if (pendingAssessments.isEmpty) return;
    isSyncing = true;
    notifyListeners();

    final remaining = <PendingAssessment>[];
    for (final assessment in List<PendingAssessment>.from(pendingAssessments)) {
      final residentId = _residentIdForName(assessment.residentName);
      if (residentId == null) {
        backendSyncError =
            'لا يوجد residentId من AWS للتقييم الخاص بـ ${assessment.residentName}';
        remaining.add(assessment);
        continue;
      }

      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.createSocialAssessment(
          residentId: residentId,
          scores: _pendingAssessmentScores(assessment),
          needsIntervention: false,
          notes: assessment.notes,
        );
      });
      if (!synced) {
        remaining.add(assessment);
      }
    }

    pendingAssessments = remaining;
    isSyncing = false;
    notifyListeners();

    if (pendingAssessments.isEmpty) {
      unawaited(syncBackendData());
    }
  }

  // Shift Handoff State
  List<ShiftHandoff> handoffs = [];

  Future<void> submitHandoff(ShiftHandoff h) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createHandoff(h);
    });
    if (!synced) return;
    handoffs.insert(0, h);
    notifyListeners();
    unawaited(syncBackendData());
  }

  // Real Notification State
  List<TaptabaNotification> notifications = [];

  List<TaptabaNotification> get filteredNotifications {
    return notifications
        .where((n) => n.targetRole == currentRole || n.targetRole == 'all')
        .toList();
  }

  bool get hasNewNotification => filteredNotifications.any((n) => !n.isRead);

  void triggerNotification(
      {required String title,
      required String body,
      String type = 'admin',
      String targetRole = 'all'}) {
    final newNotif = TaptabaNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      time: 'الآن',
      type: type,
      targetRole: targetRole,
    );
    notifications.insert(0, newNotif);
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void markAllFilteredNotificationsAsRead() {
    for (var n in notifications) {
      if (n.targetRole == currentRole || n.targetRole == 'all') {
        n.isRead = true;
      }
    }
    notifyListeners();
  }

  void clearNotifications() {
    notifications.clear();
    notifyListeners();
  }

  // Nursing Notes State
  List<NursingNote> nursingNotes = [];

  Future<void> addNursingNote(NursingNote note) async {
    final residentId = _residentIdForName(note.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من AWS لملاحظة ${note.residentName}';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createNursingNote(
        residentId: residentId,
        note: note,
      );
    });
    if (!synced) return;
    nursingNotes.insert(0, note);
    notifyListeners();
    unawaited(syncBackendData());
  }

  List<NursingNote> getNotesForResident(String residentName) {
    return nursingNotes.where((n) => n.residentName == residentName).toList();
  }

  // Resident Medical Info State
  List<ResidentMedicalInfo> residentMedicalInfos = [];

  ResidentMedicalInfo getMedicalInfo(String residentName) {
    return residentMedicalInfos.firstWhere(
      (info) => info.residentName == residentName,
      orElse: () => ResidentMedicalInfo(residentName: residentName),
    );
  }

  Future<void> updateMedicalInfo(ResidentMedicalInfo newInfo) async {
    final residentId = _residentIdForName(newInfo.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من AWS للملف الطبي الخاص بـ ${newInfo.residentName}';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.upsertMedicalInfo(
        residentId: residentId,
        info: newInfo,
      );
    });
    if (!synced) return;
    final index = residentMedicalInfos
        .indexWhere((info) => info.residentName == newInfo.residentName);
    if (index != -1) {
      residentMedicalInfos[index] = newInfo;
    } else {
      residentMedicalInfos.add(newInfo);
    }
    notifyListeners();
    unawaited(syncBackendData());
  }

  // عملية تسجيل الدخول وحفظ البيانات آمنياً مع ضبط موعد انتهاء الجلسة (US-SmartLogin)
  // تسجيل الدخول عبر الـ Backend الحقيقي (AWS Cognito)
  // يستخدمه LoginScreen بعد نجاح AuthService.login()
  String? backendUserId;
  String? backendFacilityId;
  String? backendResidentId;
  bool isBackendSyncing = false;
  DateTime? lastBackendSyncAt;
  String? backendSyncError;

  // Messages inbox — loaded on demand for Family and Resident roles
  List<BackendMessageThreadSummary> messageInbox = [];
  bool isLoadingInbox = false;

  Future<void> loadMessageInbox() async {
    if (isLoadingInbox) return;
    isLoadingInbox = true;
    notifyListeners();
    try {
      messageInbox = await MessagesService.instance.inbox();
    } catch (_) {
      // silently fail — inbox is non-critical
    } finally {
      isLoadingInbox = false;
      notifyListeners();
    }
  }

  // Upload progress state — used by any screen that uploads files to S3
  bool isUploadingFile = false;
  double uploadProgress = 0.0;
  String? uploadError;

  void setUploadState({
    required bool uploading,
    double progress = 0.0,
    String? error,
  }) {
    isUploadingFile = uploading;
    uploadProgress = progress;
    uploadError = error;
    notifyListeners();
  }
  Future<void>? _backendSyncFuture;
  Map<String, String> mealPlanIdsByResidentName = {};

  Map<String, String> emergencyContacts = {};
  FacilityBillingSettings? billingSettings;
  FacilityProfileSettings? facilityProfileSettings;

  String? get billingPaymentInstructions {
    final settings = billingSettings;
    if (settings == null || settings.isEmpty) return null;
    return settings.displayText;
  }

  Future<void> loadEmergencyContacts() async {
    try {
      final settings =
          await FacilitySettingsService.instance.emergencyContacts();
      emergencyContacts = settings.toPhoneMap();
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadBillingSettings() async {
    try {
      billingSettings =
          await FacilitySettingsService.instance.billingSettings();
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadFacilityProfileSettings() async {
    try {
      final profile = await FacilitySettingsService.instance.facilityProfile();
      facilityProfileSettings = profile;
      if (profile.facilityName != null) {
        facilityName = profile.facilityName!;
      }
      if (currentAccount != null) {
        currentAccount = currentAccount!.copyWith(
          facilityName: profile.facilityName,
          facilityAddress: profile.address,
          facilityPhone: profile.phone,
          facilityEmail: profile.email,
          licenseNumber: profile.licenseNumber,
          facilityYearOfEst: profile.facilityYearOfEst,
          facilityCapacity: profile.facilityCapacity,
          facilityLocationUrl: profile.facilityLocationUrl,
        );
      }
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateFacilityProfileSettings({
    required AppAccount account,
    required String facilityName,
    required String facilityAddress,
    String? facilityPhone,
    String? facilityEmail,
    String? licenseNumber,
    String? facilityYearOfEst,
    String? facilityCapacity,
    String? facilityLocationUrl,
  }) async {
    try {
      final profile =
          await FacilitySettingsService.instance.updateFacilityProfile(
        facilityName: facilityName,
        address: facilityAddress,
        phone: facilityPhone,
        email: facilityEmail,
        licenseNumber: licenseNumber,
        facilityYearOfEst: facilityYearOfEst,
        facilityCapacity: facilityCapacity,
        facilityLocationUrl: facilityLocationUrl,
      );
      facilityProfileSettings = profile;
      final updated = account.copyWith(
        facilityName: profile.facilityName ?? facilityName,
        facilityAddress: profile.address ?? facilityAddress,
        facilityPhone: profile.phone ?? facilityPhone,
        facilityEmail: profile.email ?? facilityEmail,
        licenseNumber: profile.licenseNumber ?? licenseNumber,
        facilityYearOfEst: profile.facilityYearOfEst ?? facilityYearOfEst,
        facilityCapacity: profile.facilityCapacity ?? facilityCapacity,
        facilityLocationUrl: profile.facilityLocationUrl ?? facilityLocationUrl,
      );
      updateCurrentAccount(updated);
      this.facilityName = updated.facilityName ?? this.facilityName;
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void _applyBackendUser({
    required String email,
    required String role,
    required String userId,
    required String facilityId,
    String? name,
    String? linkedResidentId,
    String? facilityName,
    bool clearExistingData = true,
  }) {
    isAuthenticated = true;
    currentRole = role;
    backendUserId = userId;
    backendFacilityId = facilityId;
    if (_looksLikeBackendId(linkedResidentId)) {
      backendResidentId = linkedResidentId;
    }
    if (clearExistingData) {
      _clearBackendCollections();
    }

    final idx = accounts.indexWhere((a) => a.email == email);
    if (idx != -1) {
      currentAccount = accounts[idx].copyWith(
        name: name?.isNotEmpty == true ? name : null,
        role: role,
        facilityName: facilityName,
        linkedResidentId:
            _looksLikeBackendId(linkedResidentId) ? linkedResidentId : null,
      );
      accounts[idx] = currentAccount!;
    } else {
      currentAccount = AppAccount(
        email: email,
        name: name?.isNotEmpty == true ? name! : email.split('@').first,
        role: role,
        password: '',
        facilityName: facilityName,
        linkedResidentId:
            _looksLikeBackendId(linkedResidentId) ? linkedResidentId : null,
      );
      accounts.add(currentAccount!);
    }

    managerName = currentAccount!.name;
    if (currentAccount!.facilityName != null) {
      facilityName = currentAccount!.facilityName!;
    }

    currentUser = User(
      name: currentAccount!.name,
      points: clearExistingData ? 0 : currentUser.points,
      streakDays: clearExistingData ? 0 : currentUser.streakDays,
      completedActivities:
          clearExistingData ? 0 : currentUser.completedActivities,
    );
    _startRealtime();
  }

  void _startRealtime() {
    RealtimeService.instance.connect();
    _realtimeSub ??= RealtimeService.instance
        .liveEventsFor({'resident_audit', 'residents'}).listen((event) {
      final residentId = event['residentId']?.toString() ?? '';
      if (residentId.isEmpty) {
        residentAuditTrails = {};
      } else {
        residentAuditTrails =
            Map<String, List<Map<String, dynamic>>>.from(residentAuditTrails)
              ..remove(residentId);
      }
      notifyListeners();
    });
  }

  Future<void> markBackendAuthenticated({
    required String email,
    required String role,
    required String userId,
    required String facilityId,
    String? name,
    String? linkedResidentId,
    String? facilityName,
  }) async {
    _applyBackendUser(
      email: email,
      role: role,
      userId: userId,
      facilityId: facilityId,
      name: name,
      linkedResidentId: linkedResidentId,
      facilityName: facilityName,
    );
    _sessionExpiry = DateTime.now().add(const Duration(hours: 1));

    await _storage.write(key: 'isAuthenticated', value: 'true');
    await _storage.write(key: 'currentRole', value: role);
    await _storage.write(key: 'userEmail', value: email);
    await _storage.write(
        key: 'sessionExpiry', value: _sessionExpiry!.toIso8601String());

    notifyListeners();
    // حمّل الأوسمة أولاً ثم ابدأ sync لتجنب إعادة إطلاق أوسمة مكتسبة مسبقاً
    unawaited(_loadEarnedBadges().then((_) => syncBackendData()));
    unawaited(PushNotificationService.instance.init());
  }

  Future<void> syncBackendData() {
    if (_backendSyncFuture != null) return _backendSyncFuture!;
    _backendSyncFuture = _syncBackendDataInternal().whenComplete(() {
      _backendSyncFuture = null;
    });
    return _backendSyncFuture!;
  }

  Future<void> _syncBackendDataInternal() async {
    final token = await AuthService.instance.restoreSession();
    if (token == null) {
      if (isAuthenticated) {
        backendSyncError = 'لا توجد جلسة AWS نشطة';
        notifyListeners();
      }
      return;
    }

    isBackendSyncing = true;
    backendSyncError = null;
    notifyListeners();

    try {
      final snapshot = await BackendSyncService.instance.load(
        preferredResidentId:
            _looksLikeBackendId(backendResidentId) ? backendResidentId : null,
        requireResidentScope: currentRole == 'أسرة',
        role: currentRole,
      );
      _applyBackendSnapshot(snapshot);
      lastBackendSyncAt = DateTime.now();
    } catch (e) {
      backendSyncError = e.toString();
    } finally {
      isBackendSyncing = false;
      notifyListeners();
    }

    if (_looksLikeBackendId(backendResidentId)) {
      unawaited(refreshAiInsightFromBackend());
    }

    unawaited(refreshUserProgress());
    unawaited(refreshUserPreferences());

    if (currentRole == 'مسن' || currentRole == 'أسرة') {
      unawaited(refreshActiveVideoCalls());
    }
    if (currentRole == 'مسن') {
      unawaited(checkMedicationAdherence());
    }
    if (currentRole == 'ممرض' ||
        currentRole == 'إدارة' ||
        currentRole == 'أخصائي اجتماعي') {
      unawaited(refreshActiveEmergencies());
    }
    if (currentRole == 'أخصائي اجتماعي') {
      unawaited(loadGdsQuestions());
    }
    if (currentRole == 'إدارة') {
      unawaited(loadEmergencyContacts());
      unawaited(loadBillingSettings());
      unawaited(loadFacilityProfileSettings());
    }
  }

  void _applyBackendSnapshot(BackendSyncSnapshot snapshot) {
    backendResidentId = currentRole == 'أسرة'
        ? snapshot.primaryResidentId
        : snapshot.primaryResidentId ?? backendResidentId;
    if (snapshot.primaryResidentName != null &&
        currentRole == 'مسن' &&
        snapshot.primaryResidentName!.isNotEmpty) {
      currentUser.name = snapshot.primaryResidentName!;
      if (currentAccount != null) {
        currentAccount = currentAccount!.copyWith(
          name: snapshot.primaryResidentName,
          linkedResidentId: snapshot.primaryResidentId,
        );
      }
    }
    if (currentRole == 'أسرة' &&
        currentAccount != null &&
        snapshot.primaryResidentId != null) {
      currentAccount = currentAccount!.copyWith(
        linkedResidentId: snapshot.primaryResidentId,
      );
    }

    if (snapshot.residentFiles != null) {
      // Deduplicate by id — backend may return duplicate rows
      final seen = <String>{};
      residentFiles = snapshot.residentFiles!
          .where((r) => r.id.isNotEmpty && seen.add(r.id))
          .toList();
    }
    if (snapshot.medications != null) {
      medications = snapshot.medications!;
    }
    if (snapshot.activities != null) {
      activities = snapshot.activities!;
    }
    if (snapshot.activitySessions != null) {
      activitySessions = snapshot.activitySessions!;
    }
    if (snapshot.complaints != null) {
      socialComplaints = snapshot.complaints!;
    }
    if (snapshot.familyVisits != null) {
      familyVisits = snapshot.familyVisits!;
    }
    if (snapshot.familyBills != null) {
      familyBills = snapshot.familyBills!;
    }
    if (snapshot.memoryMoments != null) {
      memoryMoments = snapshot.memoryMoments!;
    }
    if (snapshot.memories != null) {
      memoriesList = snapshot.memories!;
    }
    if (snapshot.voiceMessages != null) {
      voiceMessagesList = snapshot.voiceMessages!;
    }
    if (snapshot.careTasks != null) {
      careTasks = snapshot.careTasks!;
    }
    if (snapshot.inventoryItems != null) {
      inventoryItems = snapshot.inventoryItems!;
    }
    if (snapshot.doctorVisits != null) {
      doctorVisits = snapshot.doctorVisits!;
    }
    if (snapshot.mealPlans != null) {
      mealPlans = snapshot.mealPlans!;
    }
    if (snapshot.mealPlanIdsByResidentName != null) {
      mealPlanIdsByResidentName = snapshot.mealPlanIdsByResidentName!;
    }
    if (snapshot.medicalSessions != null) {
      medicalSessions = snapshot.medicalSessions!;
    }
    if (snapshot.medicalPrescriptions != null) {
      medicalPrescriptions = snapshot.medicalPrescriptions!;
    }
    if (snapshot.volunteerOpportunities != null) {
      volunteerOpportunities = snapshot.volunteerOpportunities!;
    }
    if (snapshot.volunteerBookings != null) {
      volunteerBookings = snapshot.volunteerBookings!;
    }
    if (snapshot.volunteerCertificates != null) {
      volunteerCertificates = snapshot.volunteerCertificates!;
    }
    if (snapshot.volunteerRatings != null) {
      volunteerRatings = snapshot.volunteerRatings!;
    }
    if (snapshot.volunteerReviews != null) {
      volunteerReviews = snapshot.volunteerReviews!;
    }
    if (snapshot.volunteerProfile != null) {
      volunteerProfile = snapshot.volunteerProfile!;
    }
    if (snapshot.notifications != null) {
      notifications = snapshot.notifications!;
    }
    if (snapshot.nursingNotes != null) {
      nursingNotes = snapshot.nursingNotes!;
    }
    if (snapshot.handoffs != null) {
      handoffs = snapshot.handoffs!;
    }
    if (snapshot.socialNeeds != null) {
      socialNeeds = snapshot.socialNeeds!;
    }
    if (snapshot.socialAssessmentTools != null) {
      socialAssessmentTools = snapshot.socialAssessmentTools!;
    }
    if (snapshot.socialResidentScores != null) {
      final seenScores = <String>{};
      socialResidentScores = snapshot.socialResidentScores!
          .where((s) => s.id.isNotEmpty && seenScores.add(s.id))
          .toList();
    }
    if (snapshot.staffPerformance != null) {
      staffPerformanceList = snapshot.staffPerformance!;
    }
    if (snapshot.sentReports != null) {
      sentReports = snapshot.sentReports!;
    }
    if (snapshot.careReportPreview != null) {
      careReports = [snapshot.careReportPreview!];
    }
    if (snapshot.familyHealthMetrics != null) {
      familyHealthMetrics = snapshot.familyHealthMetrics!;
    }
    if (snapshot.familyMembers != null) {
      familyMembersList = snapshot.familyMembers!;
    }
    if (snapshot.assessmentHistory != null &&
        snapshot.assessmentHistory!.isNotEmpty) {
      assessmentHistory = snapshot.assessmentHistory!;
    }

    if (currentRole == 'مسن' && companionChatHistory.isEmpty) {
      final name = currentAccount?.name.isNotEmpty == true
          ? currentAccount!.name
          : (snapshot.primaryResidentName ?? 'صديقنا');
      companionChatHistory.add(CompanionMessage(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        text: 'مرحباً بك يا $name! أنا رفيقك الذكي، كيف تشعر اليوم؟ ✨',
        isFromAI: true,
        timestamp: DateTime.now(),
      ));
    }

    if (residentFiles.isNotEmpty) {
      residentMedicalInfos = residentFiles.map((r) {
        final meds = medications
            .where((m) => m.residentName == r.name)
            .map((m) => '${m.name} ${m.dosage}'.trim())
            .toList();
        return ResidentMedicalInfo(
          residentName: r.name,
          medications: meds,
          allergies: r.allergies ?? const [],
          chronicDiseases: r.chronicDiseases ?? const [],
        );
      }).toList();
    }
  }

  void _applyUserProgress(BackendUserProgress progress) {
    currentUser = User(
      name: currentUser.name,
      points: progress.points,
      streakDays: progress.streakDays,
      completedActivities: progress.completedActivities,
    );
    _checkAndUnlockBadges();
  }

  Future<void> refreshUserProgress() async {
    if (AuthService.instance.currentUser == null) return;
    try {
      final progress = await UserProgressService.instance.getMe();
      _applyUserProgress(progress);
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  List<BackendVideoCall> callHistory = [];
  bool isLoadingCallHistory = false;

  Future<void> loadCallHistory() async {
    if (isLoadingCallHistory) return;
    isLoadingCallHistory = true;
    notifyListeners();
    try {
      callHistory = await VideoCallService.instance.history(
        userId: (backendUserId?.isNotEmpty == true) ? backendUserId : null,
      );
    } catch (_) {
      callHistory = [];
    } finally {
      isLoadingCallHistory = false;
      notifyListeners();
    }
  }

  Map<String, List<Map<String, dynamic>>> residentAuditTrails = {};
  final Set<String> loadingAuditTrailResidentIds = {};

  Future<void> loadAuditTrail(String residentId, {bool force = false}) async {
    if (residentId.isEmpty ||
        (!force && residentAuditTrails.containsKey(residentId)) ||
        loadingAuditTrailResidentIds.contains(residentId)) {
      return;
    }
    loadingAuditTrailResidentIds.add(residentId);
    try {
      final res =
          await ApiClient.instance.get('/residents/$residentId/audit-trail');
      if (res is List) {
        residentAuditTrails =
            Map<String, List<Map<String, dynamic>>>.from(residentAuditTrails)
              ..[residentId] = res
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
      } else {
        residentAuditTrails =
            Map<String, List<Map<String, dynamic>>>.from(residentAuditTrails)
              ..[residentId] = [];
      }
    } catch (_) {
      residentAuditTrails =
          Map<String, List<Map<String, dynamic>>>.from(residentAuditTrails)
            ..[residentId] = [];
    } finally {
      loadingAuditTrailResidentIds.remove(residentId);
      notifyListeners();
    }
  }

  Future<void> refreshActiveVideoCalls() async {
    if (AuthService.instance.currentUser == null) return;
    try {
      final calls = await VideoCallService.instance.active();
      if (calls.isEmpty) {
        activeVideoCallId = null;
        activeVideoCallJoinUrl = null;
        isIncomingCall = false;
        isVideoCallActive = false;
        backendSyncError = null;
        notifyListeners();
        return;
      }
      final call = calls.first;
      activeVideoCallId = call.id;
      activeVideoCallJoinUrl = call.joinUrl;
      activeCallerName = call.calleeName?.isNotEmpty == true
          ? call.calleeName!
          : 'مكالمة فيديو';
      activeCallerInitials =
          activeCallerName.isNotEmpty ? activeCallerName.substring(0, 1) : '؟';
      final isOutgoing = call.callerId == backendUserId;
      isIncomingCall = !isOutgoing && call.status == 'ringing';
      isVideoCallActive = call.status == 'accepted' || isOutgoing;
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshUserPreferences() async {
    if (AuthService.instance.currentUser == null) return;
    try {
      final prefs = await UserPreferencesService.instance.getMe();
      _applyUserPreferences(prefs.preferences);
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  void _applyUserPreferences(Map<String, dynamic> prefs) {
    final fontScale = prefs['fontScaleFactor'];
    if (fontScale is num) {
      fontScaleFactor = fontScale.toDouble().clamp(0.8, 1.6);
    }
    final highContrast = prefs['isHighContrast'];
    if (highContrast is bool) isHighContrast = highContrast;
    final darkMode = prefs['isDarkMode'];
    if (darkMode is bool) isDarkMode = darkMode;
    final aiInsights = prefs['isAIInsightsEnabled'];
    if (aiInsights is bool) isAIInsightsEnabled = aiInsights;
    final aiCompanion = prefs['isAICompanionEnabled'];
    if (aiCompanion is bool) isAICompanionEnabled = aiCompanion;
  }

  Map<String, dynamic> _userPreferencesPayload() => {
        'fontScaleFactor': fontScaleFactor,
        'isHighContrast': isHighContrast,
        'isDarkMode': isDarkMode,
        'isAIInsightsEnabled': isAIInsightsEnabled,
        'isAICompanionEnabled': isAICompanionEnabled,
      };

  Future<void> _syncUserPreferences() async {
    if (AuthService.instance.currentUser == null) return;
    try {
      await UserPreferencesService.instance.update(_userPreferencesPayload());
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  bool _looksLikeBackendId(String? id) {
    if (id == null || id.isEmpty) return false;
    return RegExp(r'^[0-9a-fA-F-]{30,}$').hasMatch(id);
  }

  String _registrationFacilityId() {
    final sessionFacilityId = backendFacilityId?.trim() ?? '';
    if (sessionFacilityId.isNotEmpty) return sessionFacilityId;
    return ApiConfig.defaultFacilityId.trim();
  }

  String _selfRegistrationRole(String role) {
    return switch (role) {
      'أسرة' || 'فرد أسرة' => 'Family',
      'متطوع' => 'Volunteer',
      _ => role,
    };
  }

  String _facilityIdForAdminRegistration({
    required String email,
    String? licenseNumber,
  }) {
    final source = (licenseNumber?.trim().isNotEmpty == true
            ? licenseNumber!.trim()
            : email.split('@').first)
        .toLowerCase();
    final normalized = source
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (normalized.isNotEmpty) return normalized;
    return 'facility-${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, double> _pendingAssessmentScores(PendingAssessment assessment) {
    final scores = <String, double>{};
    for (final entry in assessment.scales.entries) {
      scores['scale_${entry.key}'] = entry.value.toDouble();
    }
    for (final entry in assessment.selections.entries) {
      scores['selection_${entry.key}'] = entry.value.toDouble();
    }
    return scores;
  }

  String? _residentIdForName(String residentName) {
    final cleanName = residentName.trim();
    for (final resident in residentFiles) {
      if (resident.name.trim() == cleanName &&
          _looksLikeBackendId(resident.id)) {
        return resident.id;
      }
    }
    return _looksLikeBackendId(backendResidentId) ? backendResidentId : null;
  }

  Future<void> _syncMedicationDose(
    Medication medication,
    String status, {
    String? notes,
  }) async {
    if (AuthService.instance.currentUser == null) return;

    try {
      final parts = medication.id.split('|');
      if (parts.length >= 4 && parts[0] == 'schedule') {
        await MedicationsService.instance.logDose(
          scheduleId: parts[1],
          residentId: parts[2],
          scheduledTime: medication.scheduledTime ?? DateTime.now(),
          status: status,
          notes: notes,
        );
      } else if (parts.length >= 2 && parts[0] == 'dose') {
        await MedicationsService.instance.updateDose(
          doseId: parts[1],
          status: status,
          notes: notes,
        );
      } else {
        return;
      }
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> _syncVitals({
    required String residentName,
    required String bp,
    required String sugar,
    required String temp,
  }) async {
    if (AuthService.instance.currentUser == null) return;
    final residentId = _residentIdForName(residentName);
    if (residentId == null) return;

    final bpParts = _bloodPressureParts(bp);
    try {
      await HealthService.instance.recordVitals(
        residentId: residentId,
        bloodPressureSystolic: bpParts[0],
        bloodPressureDiastolic: bpParts[1],
        bloodGlucose: _firstInt(sugar),
        temperature: _firstDouble(temp),
        notes: 'تم التسجيل من تطبيق طبطبة',
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> _syncComplaintStatus(
    String id,
    String status, {
    String? resolutionNotes,
  }) async {
    if (AuthService.instance.currentUser == null ||
        id.startsWith('comp_') ||
        id.isEmpty) {
      return;
    }

    try {
      await ComplaintsService.instance.updateStatus(
        id: id,
        status: status,
        resolutionNotes: resolutionNotes,
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  String _normaliseDigits(String value) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = value;
    for (var i = 0; i < arabic.length; i++) {
      result = result.replaceAll(arabic[i], '$i');
    }
    return result;
  }

  int? _firstInt(String value) {
    final match = RegExp(r'\d+').firstMatch(_normaliseDigits(value));
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  double? _firstDouble(String value) {
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(_normaliseDigits(value));
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  List<int?> _bloodPressureParts(String value) {
    final matches = RegExp(r'\d+').allMatches(_normaliseDigits(value)).toList();
    return [
      matches.isNotEmpty ? int.tryParse(matches[0].group(0)!) : null,
      matches.length > 1 ? int.tryParse(matches[1].group(0)!) : null,
    ];
  }

  String _backendComplaintCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('food') || category.contains('طعام')) {
      return 'food';
    }
    if (normalized.contains('maintenance') || category.contains('صيانة')) {
      return 'facility';
    }
    if (normalized.contains('communication') || category.contains('تواصل')) {
      return 'communication';
    }
    if (normalized.contains('service') || category.contains('خدمة')) {
      return 'care_quality';
    }
    return 'general';
  }

  Future<bool> _runBackendMutation(Future<void> Function() mutation) async {
    if (AuthService.instance.currentUser == null) {
      backendSyncError = 'لا توجد جلسة AWS نشطة';
      notifyListeners();
      return false;
    }

    try {
      await mutation();
      backendSyncError = null;
      return true;
    } on ApiException catch (e) {
      backendSyncError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String idRaw, String passRaw) async {
    final identifier = idRaw.trim();
    final password = passRaw.trim();

    try {
      final user = await AuthService.instance.login(identifier, password);
      await markBackendAuthenticated(
        email: user.email,
        role: user.arabicRole,
        userId: user.userId,
        facilityId: user.facilityId,
        name: user.name,
        linkedResidentId: user.linkedResidentId,
        facilityName: user.facilityName,
      );
      return true;
    } on ApiException catch (e) {
      backendSyncError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    isAuthenticated = false;
    currentRole = '';
    currentAccount = null;
    _sessionExpiry = null;
    backendUserId = null;
    backendFacilityId = null;
    backendResidentId = null;
    backendSyncError = null;
    lastBackendSyncAt = null;
    isBackendSyncing = false;
    activeVideoCallId = null;
    activeVideoCallJoinUrl = null;
    isVideoCallActive = false;
    isIncomingCall = false;
    earnedBadgeIds = {};
    newlyUnlockedBadge = null;
    _clearTransientBackendState();
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    RealtimeService.instance.disconnect();
    await AuthService.instance.logout();
    unawaited(PushNotificationService.instance.removeToken());

    await _storage.delete(key: 'isAuthenticated');
    await _storage.delete(key: 'currentRole');
    await _storage.delete(key: 'userEmail');
    await _storage.delete(key: 'sessionExpiry');

    notifyListeners();
  }

  void _clearTransientBackendState() {
    backendSyncError = null;
    isBackendSyncing = false;
    mealPlanIdsByResidentName.clear();
    activeEmergencies.clear();
    activeVideoCallId = null;
    activeVideoCallJoinUrl = null;
  }

  void _clearBackendCollections() {
    residentFiles = [];
    residentMedicalInfos = [];
    medications = [];
    activities = [];
    activitySessions = [];
    socialComplaints = [];
    familyVisits = [];
    familyBills = [];
    memoryMoments = [];
    memoriesList = [];
    voiceMessagesList = [];
    careTasks = [];
    inventoryItems = [];
    doctorVisits = [];
    mealPlans = [];
    mealPlanIdsByResidentName.clear();
    medicalSessions = [];
    medicalPrescriptions = [];
    volunteerOpportunities = [];
    volunteerBookings = [];
    volunteerCertificates = [];
    volunteerRatings = [];
    volunteerReviews = [];
    notifications = [];
    nursingNotes = [];
    handoffs = [];
    socialNeeds = [];
    socialAssessmentTools = [];
    socialResidentScores = [];
    staffPerformanceList = [];
    sentReports = [];
    careReports = [];
    familyHealthMetrics = [];
    familyMembersList = [];
    assessmentHistory = [];
  }

  Future<void> completeOnboarding() async {
    hasSeenOnboarding = true;
    await _storage.write(key: 'hasSeenOnboarding', value: 'true');
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    hasSeenOnboarding = false;
    await _storage.delete(key: 'hasSeenOnboarding');
    notifyListeners();
  }

  void updateFontScale(double value) {
    fontScaleFactor = value;
    unawaited(_syncUserPreferences());
    notifyListeners();
  }

  void toggleHighContrast() {
    isHighContrast = !isHighContrast;
    unawaited(_syncUserPreferences());
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    isBiometricEnabled = value;
    await _storage.write(key: 'isBiometricEnabled', value: value.toString());
    if (!value) {
      await _storage.delete(key: 'bio_email');
      await _storage.delete(key: 'bio_pass');
    }
    notifyListeners();
  }

  Future<void> saveBiometricCredentials(String email, String password) async {
    await _storage.write(key: 'bio_email', value: email);
    await _storage.write(key: 'bio_pass', value: password);
  }

  /// يُسجّل الدخول باستخدام الـ credentials المحفوظة للبيومتري
  Future<bool> loginWithBiometric() async {
    final email = await _storage.read(key: 'bio_email');
    final pass = await _storage.read(key: 'bio_pass');
    if (email == null || pass == null || email.isEmpty || pass.isEmpty) {
      return false;
    }
    return login(email, pass);
  }

  // --- ELDERLY / RESIDENT STATE (RE-ADDED) ---
  User currentUser = User(
    name: '',
    points: 0,
    streakDays: 0,
    completedActivities: 0,
  );

  List<Medication> medications = [];

  List<Medication> get missedMedications =>
      medications.where((m) => m.isMissed).toList();

  Future<void> markMedicationAsTaken(String id) async {
    final index = medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      final med = medications[index];
      await _syncMedicationDose(med, 'given');
      if (backendSyncError != null) return;
      medications[index].isTaken = true;

      triggerNotification(
        title: 'تم إعطاء الدواء 💊',
        body: 'الممرض قام بإعطاء ${med.name} لـ ${med.residentName} في موعده.',
        type: 'medical',
        targetRole: 'أهل',
      );

      if (med.isMissed) {
        triggerNotification(
          title: 'معالجة تأخير دواء ⚠️',
          body: 'تم إعطاء الجرعة المتأخرة لـ ${med.residentName}.',
          type: 'admin',
          targetRole: 'مدير',
        );
      }

      notifyListeners();
    }
  }

  List<Activity> activities = [];

  // الحقول والدوال الجديدة لربط الأنشطة المشتركة بين المسن وعائلته
  final Map<String, bool> familyActivityParticipations = {};
  final Map<String, String> familyActivityNotes = {};

  void toggleFamilyParticipation(String activityId) {
    final current = familyActivityParticipations[activityId] ?? false;
    familyActivityParticipations[activityId] = !current;
    notifyListeners();
  }

  void updateFamilyActivityNote(String activityId, String note) {
    familyActivityNotes[activityId] = note;
    notifyListeners();
  }

  bool isFamilyParticipating(String activityId) {
    return familyActivityParticipations[activityId] ?? false;
  }

  String getFamilyActivityNote(String activityId) {
    return familyActivityNotes[activityId] ?? '';
  }

  List<FamilyMember> familyMembersList = [];

  List<VoiceMessage> voiceMessagesList = [];

  bool isVideoCallActive = false;
  bool isIncomingCall = false;
  String? activeVideoCallId;
  String? activeVideoCallJoinUrl;
  String activeCallerName = '';
  String activeCallerInitials = '';
  StreamSubscription<dynamic>? _realtimeSub;
  bool isLoadingSpecialistChat = false;

  bool isAIInsightsEnabled = true;
  bool isLoadingAiInsight = false;
  String aiInsightMode = 'backend';

  Future<void> refreshAiInsightFromBackend({String? residentId}) async {
    final resolvedResidentId = residentId ?? backendResidentId;
    if (resolvedResidentId == null || resolvedResidentId.isEmpty) {
      aiInsightMode = 'error';
      backendSyncError =
          'لا يوجد residentId من AWS لجلب توصية الذكاء الاصطناعي';
      notifyListeners();
      return;
    }
    isLoadingAiInsight = true;
    notifyListeners();
    try {
      final rec =
          await AiService.instance.getRecommendations(resolvedResidentId);

      // Resolve human-readable name and room from the residents list.
      final residentFile = residentFiles
          .where((r) => r.id == resolvedResidentId)
          .firstOrNull;
      final safeName = residentFile?.name.isNotEmpty == true
          ? residentFile!.name
          : (currentUser.name.isNotEmpty ? currentUser.name : 'مقيم');
      final roomNumber = residentFile?.room;

      // Strip any UUID patterns the backend may have included in text fields.
      final safeSummary = stripUuids(rec.summary);
      final safeRationale = stripUuids(rec.rationale);

      if (aiInsights.isNotEmpty) {
        aiInsights[0] = AIInsight(
          id: aiInsights[0].id,
          residentName: aiInsights[0].residentName,
          roomNumber: aiInsights[0].roomNumber ?? roomNumber,
          summary: safeSummary,
          rationale: safeRationale,
          generationDate: DateTime.tryParse(rec.generatedAt) ?? DateTime.now(),
          confidenceScore: 0.85,
        );
      } else {
        aiInsights.add(AIInsight(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          residentName: safeName,
          roomNumber: roomNumber,
          summary: safeSummary,
          rationale: safeRationale,
          generationDate: DateTime.tryParse(rec.generatedAt) ?? DateTime.now(),
        ));
      }
      aiInsightMode = 'bedrock';
      backendSyncError = null;
    } catch (e) {
      aiInsightMode = 'error';
      backendSyncError = e.toString();
    } finally {
      isLoadingAiInsight = false;
      notifyListeners();
    }
  }

  List<AIInsight> aiInsights = [];

  // خريطة لتخزين ملاحظات الذكاء الاصطناعي لكل مقيم (residentId → notes)
  final Map<String, ResidentAINotes> _residentAINotesMap = {};

  ResidentAINotes? getResidentAINotes(String residentId) =>
      _residentAINotesMap[residentId];

  void setResidentAINotes(ResidentAINotes notes) {
    _residentAINotesMap[notes.residentId] = notes;
    notifyListeners();
  }

  bool isAICompanionEnabled = true;
  List<CompanionMessage> companionChatHistory = [];

  bool isEmergencyActive = false;
  bool isEmergencySyncing = false;
  String? currentEmergencyId;
  List<BackendEmergency> activeEmergencies = [];
  String currentMood = '';
  bool isReadingAudio = false;
  String readingText = '';

  List<AssetEntity> deviceGalleryImages = [];

  List<MemoryItem> memoriesList = [];

  // --- Albums Management ---
  List<String> customAlbums = [];
  Map<String, String> albumCovers = {}; // albumName -> assetPath or url

  List<String> get allAlbums {
    return customAlbums;
  }

  void createAlbum(String name) {
    if (!customAlbums.contains(name)) {
      customAlbums.add(name);
      notifyListeners();
    }
  }

  void renameAlbum(String oldName, String newName) {
    if (newName.trim().isEmpty || customAlbums.contains(newName)) return;
    int index = customAlbums.indexOf(oldName);
    if (index != -1) {
      customAlbums[index] = newName;
      for (var item in memoriesList) {
        if (item.category == oldName) {
          item.category = newName;
        }
      }
      if (albumCovers.containsKey(oldName)) {
        albumCovers[newName] = albumCovers.remove(oldName)!;
      }
      notifyListeners();
    }
  }

  void deleteAlbum(String name) {
    customAlbums.remove(name);
    memoriesList.removeWhere((item) => item.category == name);
    albumCovers.remove(name);
    notifyListeners();
  }

  void addPhotoToAlbum(String albumName, String photoPath,
      {String type = 'image'}) {
    final newItem = MemoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: albumName,
      title: 'صورة جديدة',
      date:
          '${DateTime.now().day} / ${DateTime.now().month} / ${DateTime.now().year}',
      type: type,
      assetPath: photoPath,
    );
    memoriesList.insert(0, newItem);
    notifyListeners();
  }

  void setAlbumCover(String albumName, String imagePath) {
    albumCovers[albumName] = imagePath;
    notifyListeners();
  }

  void deleteMemoryItem(String id) {
    memoriesList.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // --- VOLUNTEER STATE ---
  int volunteerHours = 0;
  int volunteerGoal = 50;

  VolunteerProfile volunteerProfile = VolunteerProfile(
    name: '',
    location: '',
    bio: '',
    skills: [],
  );

  List<VolunteerOpportunity> volunteerOpportunities = [];

  List<VolunteerBooking> volunteerBookings = [];

  List<VolunteerCertificate> volunteerCertificates = [];

  List<VolunteerRating> volunteerRatings = [];

  List<VolunteerReview> volunteerReviews = [];

  // --- DYNAMIC QUESTION BANK ---
  Map<String, List<Map<String, dynamic>>> questionBank = {};

  List<Map<String, dynamic>> getQuestionsForTool(String toolId) {
    return questionBank[toolId] ?? const [];
  }

  String selectedSpecialistFilter = 'الكل';
  String residentSearchQuery = '';
  String? selectedHealthStatus;
  String? selectedRoomFilter;
  int selectedFloor = 1;

  List<SocialSpecialistAssessmentTool> socialAssessmentTools = [];

  List<SocialSpecialistNeed> socialNeeds = [];

  List<SocialSpecialistResidentScore> socialResidentScores = [];

  List<SocialSpecialistResidentScore> get filteredResidentScores {
    return socialResidentScores.where((r) {
      final matchQuery = r.name.contains(residentSearchQuery) ||
          r.room.contains(residentSearchQuery);
      final matchStatus = selectedHealthStatus == null ||
          r.healthStatus == selectedHealthStatus;
      final matchRoom =
          selectedRoomFilter == null || r.room == selectedRoomFilter;
      return matchQuery && matchStatus && matchRoom;
    }).toList();
  }

  void setResidentSearch(String query) {
    residentSearchQuery = query;
    notifyListeners();
  }

  void setHealthFilter(String? status) {
    selectedHealthStatus = status;
    notifyListeners();
  }

  List<SocialSpecialistComplaint> socialComplaints = [];

  String _toArabicDigits(int value) {
    return value
        .toString()
        .replaceAll('0', '٠')
        .replaceAll('1', '١')
        .replaceAll('2', '٢')
        .replaceAll('3', '٣')
        .replaceAll('4', '٤')
        .replaceAll('5', '٥')
        .replaceAll('6', '٦')
        .replaceAll('7', '٧')
        .replaceAll('8', '٨')
        .replaceAll('9', '٩');
  }

  List<SocialSpecialistKPI> get socialKPIs {
    double totalSatisfaction = 0;
    int satisfactionCount = 0;
    for (var r in socialResidentScores) {
      if (r.scores.isNotEmpty) {
        double sum = 0;
        r.scores.forEach((key, value) => sum += value);
        totalSatisfaction += (sum / r.scores.length);
        satisfactionCount++;
      }
    }
    int satisfactionRate = satisfactionCount > 0
        ? ((totalSatisfaction / satisfactionCount) * 100).toInt()
        : 0;

    int criticalCases =
        socialResidentScores.where((r) => r.healthStatus == 'critical').length;

    int openComplaints =
        socialComplaints.where((c) => c.status == 'open').length;

    final doneActivities = activities.where((a) => a.status == 'done').length;
    final activityRate = activities.isNotEmpty
        ? ((doneActivities / activities.length) * 100).toInt()
        : 0;

    return [
      SocialSpecialistKPI(
          id: 'k1',
          label: 'معدل الرضا العام',
          value: '${_toArabicDigits(satisfactionRate)}٪',
          trend: '↑ تحسّن ٤٪',
          isPositive: true),
      SocialSpecialistKPI(
          id: 'k2',
          label: 'مشاركة الأنشطة',
          value: '${_toArabicDigits(activityRate)}٪',
          trend: activityRate > 0 ? 'من بيانات AWS' : 'لا توجد بيانات',
          isPositive: activityRate >= 60),
      SocialSpecialistKPI(
          id: 'k3',
          label: 'حالات حرجة',
          value: _toArabicDigits(criticalCases),
          trend: '↑ تحتاج تدخل',
          isPositive: false),
      SocialSpecialistKPI(
          id: 'k4',
          label: 'شكاوى مفتوحة',
          value: _toArabicDigits(openComplaints),
          trend: '← نفس الأسبوع',
          isPositive: true),
    ];
  }

  int get totalResidentsCount => residentFiles.length;
  int get criticalResidentsCount =>
      residentFiles.where((f) => f.status == 'critical').length;
  int get compliancePercentage {
    if (medications.isEmpty) return 100;
    final takenCount = medications.where((m) => m.isTaken).length;
    return ((takenCount / medications.length) * 100).toInt();
  }

  int get unpaidBillsAmount {
    return familyBills
        .where((b) => !b.isPaid)
        .fold(0, (sum, b) => sum + b.amount.toInt());
  }

  int get totalOpenNeeds => socialNeeds.length;
  int get totalOpenComplaints =>
      socialComplaints.where((c) => c.status == 'open').length;
  int get totalPendingAssessments =>
      socialResidentScores.where((r) => r.isUrgent).length;

  double get averageRating {
    if (volunteerRatings.isEmpty) return 0;
    return volunteerRatings.map((r) => r.score).reduce((a, b) => a + b) /
        volunteerRatings.length;
  }

  int get totalReviews => volunteerRatings.length;

  String get topSkill {
    if (volunteerRatings.isEmpty) return '—';
    final allCriteria = <String, List<double>>{};
    for (final r in volunteerRatings) {
      for (final e in r.criteriaScores.entries) {
        allCriteria.putIfAbsent(e.key, () => []).add(e.value);
      }
    }
    if (allCriteria.isEmpty) return '—';
    final avgs = allCriteria.map(
        (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    final best = avgs.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${best.key} ⭐ ${best.value.toStringAsFixed(1)}';
  }

  String get skillNeedsImprovement {
    if (volunteerRatings.isEmpty) return '—';
    final allCriteria = <String, List<double>>{};
    for (final r in volunteerRatings) {
      for (final e in r.criteriaScores.entries) {
        allCriteria.putIfAbsent(e.key, () => []).add(e.value);
      }
    }
    if (allCriteria.isEmpty) return '—';
    final avgs = allCriteria.map(
        (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    final worst = avgs.entries.reduce((a, b) => a.value <= b.value ? a : b);
    return '${worst.key} ${worst.value.toStringAsFixed(1)}';
  }

  List<Medication> get todayMedications => medications;
  Medication? get nextMedication {
    try {
      return medications.firstWhere((m) => !m.isTaken);
    } catch (_) {
      return null;
    }
  }

  int get remainingSecondsToNextMed {
    final next = nextMedication;
    if (next == null || next.scheduledTime == null) return 0;
    final diff = next.scheduledTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  List<FamilyMember> get familyMembers => familyMembersList;

  Future<void> fetchFavoriteContacts() async {
    if (await FlutterContacts.requestPermission()) {
      // جلب جهات الاتصال مع الصور وأرقام الهواتف
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      // جلب جهات الاتصال المفضلة (Starred) فقط
      final favorites = contacts.where((c) => c.isStarred).toList();

      // إذا لم يكن هناك مفضلين، نأخذ أول ٣ جهات اتصال كأمثلة
      final toShow =
          favorites.isNotEmpty ? favorites : contacts.take(3).toList();

      for (var contact in toShow) {
        if (contact.phones.isNotEmpty) {
          final phone = contact.phones.first.number;
          final name = contact.displayName;
          if (!familyMembersList.any((m) => m.phoneNumber == phone)) {
            String memberId = contact.id;
            if (_looksLikeBackendId(backendResidentId)) {
              final backendId = await BackendMutationService.instance
                  .createFamilyMemberFromPhone(
                residentId: backendResidentId!,
                name: name,
                phone: phone,
              );
              if (backendId != null && backendId.isNotEmpty) {
                memberId = backendId;
              }
            }
            familyMembersList.add(FamilyMember(
              id: memberId,
              name: name,
              relation: 'قريب',
              avatarPath: '',
              initials: name.isNotEmpty ? name.substring(0, 1) : '؟',
              phoneNumber: phone,
              isAvailable: true,
            ));
          }
        }
      }
      notifyListeners();
    }
  }

  void toggleFamilyPin(String id) {
    final idx = familyMembersList.indexWhere((m) => m.id == id);
    if (idx != -1) {
      familyMembersList[idx].isPinned = !familyMembersList[idx].isPinned;
      notifyListeners();
    }
  }

  Future<bool> pickAndAddContact() async {
    try {
      if (!await FlutterContacts.requestPermission()) return false;

      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return true;

      final fullContact = await FlutterContacts.getContact(contact.id);
      if (fullContact != null && fullContact.phones.isNotEmpty) {
        final phone = fullContact.phones.first.number;
        final name = fullContact.displayName;
        if (!familyMembersList.any((m) => m.phoneNumber == phone)) {
          String memberId = fullContact.id;
          if (_looksLikeBackendId(backendResidentId)) {
            final backendId = await BackendMutationService.instance
                .createFamilyMemberFromPhone(
              residentId: backendResidentId!,
              name: name,
              phone: phone,
            );
            if (backendId != null && backendId.isNotEmpty) memberId = backendId;
          }
          familyMembersList.add(FamilyMember(
            id: memberId,
            name: name,
            relation: 'قريب',
            avatarPath: '',
            initials: name.isNotEmpty ? name.substring(0, 1) : '؟',
            phoneNumber: phone,
            isAvailable: true,
            isPinned: true,
          ));
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      debugPrint("EXCEPTION: Error in pickAndAddContact: $e");
      return false;
    }
  }

  Future<void> callPhoneNumber(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch dialer for $phone');
    }
  }

  Future<void> launchZoom(String? link) async {
    if (link == null || link.isEmpty) return;

    final Uri url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch Zoom link: $link');
    }
  }

  List<VoiceMessage> get voiceMessages => voiceMessagesList;
  List<MemoryItem> get memories => memoriesList;

  VolunteerImpact get volunteerImpact => VolunteerImpact(
        residentsServed: totalResidentsCount,
        positiveRatings: volunteerRatings.where((r) => r.score >= 4).length,
        totalHours: volunteerHours,
      );

  // --- DETAILED ASSESSMENT STATE ---
  List<AssessmentQuestion> gdsQuestions = [];

  List<AssessmentHistoricalEntry> assessmentHistory = [];
  Future<void> loadGdsQuestions() async {
    try {
      final raw = await SocialService.instance.getGdsQuestions();
      final loaded = raw
          .map((e) => AssessmentQuestion(
                id: (e['id'] ?? '').toString(),
                text: (e['text'] ?? '').toString(),
                type: (e['type'] ?? 'choice').toString(),
                options:
                    (e['options'] as List?)?.map((o) => o.toString()).toList(),
              ))
          .where((q) => q.id.isNotEmpty && q.text.isNotEmpty)
          .toList();
      if (loaded.isNotEmpty) gdsQuestions = loaded;
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadQuestionsForTool(String toolId) async {
    try {
      final raw = await SocialService.instance.getToolQuestions(toolId);
      questionBank = Map<String, List<Map<String, dynamic>>>.from(questionBank)
        ..[toolId] = raw;
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  void setRole(String role) {
    currentRole = role;
    notifyListeners();
  }

  void setIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  List<Activity> getActivitiesForDay(int index) {
    final daysMapping = ['أمس', 'اليوم', 'غداً', 'الأسبوع'];
    String tag = daysMapping[index];
    if (tag == 'الأسبوع') return activities;
    return activities.where((a) => a.dayTag == tag).toList();
  }

  void completeActivity(String id) {
    final idx = activities.indexWhere((a) => a.id == id);
    if (idx != -1) {
      activities[idx].status = 'done';
      notifyListeners();
    }
  }

  Future<void> addActivity(Activity activity) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createActivity(activity);
    });
    if (!synced) return;
    activities.insert(0, activity);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> updateActivity(Activity activity) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateActivity(activity);
    });
    if (!synced) return;
    final index = activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      activities[index] = activity;
      notifyListeners();
    }
    unawaited(syncBackendData());
  }

  Future<void> updateStaff(StaffPerformance staff) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateManagedUser(staff);
    });
    if (!synced) return;
    final index = staffPerformanceList.indexWhere((s) => s.id == staff.id);
    if (index != -1) {
      staffPerformanceList[index] = staff;
      notifyListeners();
    }
    unawaited(syncBackendData());
  }

  Future<void> deleteStaff(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.disableManagedUser(id);
    });
    if (!synced) return;
    staffPerformanceList.removeWhere((s) => s.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> pickAndSetResidentImage(String residentId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      updateResidentImage(residentId, image.path);
    }
  }

  void updateResidentImage(String residentId, String path) {
    final index = residentFiles.indexWhere((r) => r.id == residentId);
    if (index != -1) {
      residentFiles[index] = residentFiles[index].copyWith(imageUrl: path);
      notifyListeners();
    }
  }

  Future<void> pickAndSetStaffImage(String staffId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      updateStaffImage(staffId, image.path);
    }
  }

  void updateStaffImage(String staffId, String path) {
    final index = staffPerformanceList.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      staffPerformanceList[index] =
          staffPerformanceList[index].copyWith(imageUrl: path);
      notifyListeners();
    }
  }

  void elderlyConfirmMedication(String id) {
    final idx = medications.indexWhere((m) => m.id == id);
    if (idx != -1 &&
        !medications[idx].isTaken &&
        !medications[idx].isElderlyConfirmed) {
      medications[idx].isElderlyConfirmed = true;
      medications[idx].isSkipped = false;

      // إرسال تنبيه للممرض لتأكيد الدواء
      triggerNotification(
        title: 'تأكيد دواء 💊',
        body:
            'المقيم أكد تناوله لدواء (${medications[idx].name}). يرجى التأكيد.',
        type: 'medical',
        targetRole: 'ممرض',
      );
      if (backendSyncError != null) return;
      medications[idx].isElderlyConfirmed = true;
      medications[idx].isSkipped = false;

      notifyListeners();
    }
  }

  Future<void> nurseConfirmMedication(String id) async {
    final idx = medications.indexWhere((m) => m.id == id);
    if (idx != -1 && !medications[idx].isTaken) {
      final med = medications[idx];
      await _syncMedicationDose(med, 'given');
      if (backendSyncError != null) return;
      medications[idx].isTaken = true;
      medications[idx].isElderlyConfirmed = true;
      medications[idx].isSkipped = false;
      addPoints(10);

      triggerNotification(
        title: 'إنجاز صحي جديد! 🏆',
        body:
            'والدك أتم أخذ دوائه (${medications[idx].name}) في الموعد وكسب 10 نقاط!',
        type: 'medical',
        targetRole: 'عائلة',
      );

      notifyListeners();
    }
  }

  Future<void> skipMedication(String id, String reason) async {
    final idx = medications.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final med = medications[idx];
      await _syncMedicationDose(med, 'skipped', notes: reason);
      if (backendSyncError != null) return;
      medications[idx].isSkipped = true;
      medications[idx].isTaken = false;
      medications[idx].skipReason = reason;
      notifyListeners();
    }
  }

  List<Medication> getMedicationsForDay(int index) {
    final daysMapping = ['أمس', 'اليوم', 'غداً', 'الأسبوع'];
    String tag = daysMapping[index];
    if (tag == 'الأسبوع') return medications;
    return medications.where((m) => m.dayTag == tag).toList();
  }

  void addPoints(int p, {int completedActivitiesDelta = 1}) {
    final nextStreak = currentUser.streakDays == 0 ? 1 : currentUser.streakDays;
    currentUser = User(
      name: currentUser.name,
      points: currentUser.points + p,
      streakDays: nextStreak,
      completedActivities:
          currentUser.completedActivities + completedActivitiesDelta,
    );
    _checkAndUnlockBadges();
    notifyListeners();

    if (AuthService.instance.currentUser == null) return;
    unawaited(_syncUserPoints(
      p,
      completedActivitiesDelta: completedActivitiesDelta,
      streakDays: nextStreak,
    ));
  }

  void _checkAndUnlockBadges() {
    for (final badge in BadgeDefinition.all) {
      if (!earnedBadgeIds.contains(badge.id) && badge.isUnlocked(currentUser)) {
        earnedBadgeIds.add(badge.id);
        newlyUnlockedBadge = badge;
        unawaited(_saveEarnedBadges());
      }
    }
  }

  void clearBadgeNotification() {
    newlyUnlockedBadge = null;
    notifyListeners();
  }

  Future<void> _loadEarnedBadges() async {
    try {
      final uid = backendUserId ?? '';
      final raw = await _storage.read(key: 'earnedBadges_$uid');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        earnedBadgeIds = list.cast<String>().toSet();
      }
    } catch (_) {}
  }

  Future<void> _saveEarnedBadges() async {
    try {
      final uid = backendUserId ?? '';
      await _storage.write(
        key: 'earnedBadges_$uid',
        value: jsonEncode(earnedBadgeIds.toList()),
      );
    } catch (_) {}
  }

  Future<void> _syncUserPoints(
    int points, {
    required int completedActivitiesDelta,
    int? streakDays,
  }) async {
    try {
      final progress = await UserProgressService.instance.addPoints(
        points: points,
        completedActivitiesDelta: completedActivitiesDelta,
        streakDays: streakDays,
      );
      _applyUserProgress(progress);
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  void toggleAIInsights(bool value) {
    isAIInsightsEnabled = value;
    unawaited(_syncUserPreferences());
    notifyListeners();
  }

  void toggleAICompanion(bool value) {
    isAICompanionEnabled = value;
    unawaited(_syncUserPreferences());
    notifyListeners();
  }

  bool isAiThinking = false;
  String lastAiMode = 'bedrock';

  // Checks for missed medications and triggers alerts for the resident and
  // the nursing team. Called automatically after each sync for resident role.
  Future<void> checkMedicationAdherence() async {
    final missed = medications
        .where((m) => m.isMissed && m.dayTag == 'اليوم')
        .toList();
    if (missed.isEmpty) return;

    final names = missed.map((m) => m.name).join('، ');
    final count = missed.length;

    // Proactive in-app notification for the resident
    triggerNotification(
      title: 'تذكير بالأدوية 💊',
      body: 'لم تأخذ ${count == 1 ? 'دواء' : '$count أدوية'} حتى الآن: $names',
      type: 'health',
      targetRole: 'مسن',
    );

    // Alert nursing team
    triggerNotification(
      title: 'تنبيه التزام الدواء',
      body: 'المقيم ${currentAccount?.name ?? ''} لم يأخذ: $names',
      type: 'health',
      targetRole: 'ممرض',
    );

    // Add proactive AI message to companion chat if it's empty or old
    final lastAiMsg = companionChatHistory
        .where((m) => m.isFromAI)
        .lastOrNull;
    final isRecent = lastAiMsg != null &&
        DateTime.now().difference(lastAiMsg.timestamp).inMinutes < 30;
    if (!isRecent) {
      final residentTitle = (currentAccount?.name ?? '').isNotEmpty
          ? 'أستاذ ${currentAccount!.name.split(' ').first}'
          : 'صديقي';
      companionChatHistory.add(CompanionMessage(
        id: 'ai_med_${DateTime.now().millisecondsSinceEpoch}',
        text: 'مرحباً $residentTitle 😊 حان وقت دوائك! '
            '${count == 1 ? 'دواء $names' : '$count أدوية: $names'}. '
            'هل تحتاج مساعدة؟',
        isFromAI: true,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  Future<String?> sendCompanionMessage(String text,
      {String? mediaPath, String? mediaType, bool voiceMode = false}) async {
    if (text.isEmpty && mediaPath == null) return null;

    // Add user message
    companionChatHistory.add(CompanionMessage(
      id: DateTime.now().toString(),
      text: text,
      isFromAI: false,
      timestamp: DateTime.now(),
      mediaPath: mediaPath,
      mediaType: mediaType,
    ));
    notifyListeners();

    try {
      AiMediaUpload? uploadedMedia;
      if (mediaPath != null && mediaPath.isNotEmpty) {
        uploadedMedia = await AiMediaService.instance.uploadFile(
          filePath: mediaPath,
          residentId: backendResidentId,
        );
      }

      final history = companionChatHistory
          .where((m) => m.text.isNotEmpty)
          .toList()
          .reversed
          .take(6)
          .toList()
          .reversed
          .map((m) => {
                'role': m.isFromAI ? 'assistant' : 'user',
                'content': m.text,
              })
          .toList();
      final effectiveMessage = text.trim().isNotEmpty
          ? text.trim()
          : uploadedMedia == null
              ? ''
              : 'تم رفع ملف للمراجعة باسم ${uploadedMedia.fileName} ونوعه ${uploadedMedia.contentType}. رجاءً أعطني ملاحظة داعمة وآمنة عنه بدون تشخيص طبي.';

      // Build resident context block to include in every message
      final firstName = (currentAccount?.name ?? '').split(' ').first;
      final title = firstName.isNotEmpty ? 'أستاذ $firstName' : 'صديقي';
      final missedMeds = medications
          .where((m) => m.isMissed && m.dayTag == 'اليوم')
          .map((m) => m.name)
          .toList();
      final todayActivities = activities
          .where((a) => a.status == 'coming')
          .take(2)
          .map((a) => '${a.name} الساعة ${a.time}')
          .toList();
      final contextParts = <String>[
        'ناد المقيم دائماً بـ "$title" — لا تستخدم أسماء أكثر ألفة.',
        'أسلوبك: دافئ، محترم، لطيف، لا تبالغ في الألفة.',
        'لو السؤال طبي، دواء، أو تشخيص — وجّه بهدوء للممرضة أو الطبيب.',
        if (missedMeds.isNotEmpty)
          'تنبيه: المقيم لم يأخذ هذه الأدوية اليوم: ${missedMeds.join('، ')}. ذكّره بلطف.',
        if (todayActivities.isNotEmpty)
          'نشاطات اليوم القادمة: ${todayActivities.join(' / ')}.',
      ];
      final contextBlock = contextParts.join(' ');

      final messageForAi = voiceMode
          ? '$contextBlock '
              'أنت مساعد صوتي حي، ردّ بجملة إلى ثلاث جمل بدون قوائم. '
              'كلام المستخدم: $effectiveMessage'
          : '$contextBlock\n\nكلام المقيم: $effectiveMessage';

      final response = await AiService.instance.sendChat(
        message: messageForAi,
        residentName: currentAccount?.name ?? 'صديقنا',
        residentId: backendResidentId,
        language: 'ar-eg',
        conversationHistory: history,
      );

      lastAiMode = response.mode;
      companionChatHistory.add(CompanionMessage(
        id: DateTime.now().toString(),
        text: response.reply,
        isFromAI: true,
        timestamp: DateTime.now(),
      ));

      // Alert nursing team if sentiment indicates distress
      if (response.sentiment == 'negative' || response.sentiment == 'sad') {
        triggerNotification(
          title: 'تنبيه المساعد الذكي',
          body: 'المقيم ${currentAccount?.name ?? ''} قد يحتاج انتباهاً — '
              'المشاعر المرصودة: ${response.sentiment}',
          type: 'health',
          targetRole: 'ممرض',
        );
      }

      notifyListeners();
      return response.reply;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshActiveEmergencies() async {
    if (AuthService.instance.currentUser == null) return;
    try {
      activeEmergencies = await EmergencyService.instance.active();
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> triggerSOS({
    String? message,
    String? type,
    String? location,
  }) async {
    final authUser = AuthService.instance.currentUser;
    final triggeredBy =
        (backendUserId?.isNotEmpty == true ? backendUserId : authUser?.userId)
                ?.trim() ??
            '';

    if (triggeredBy.isEmpty) {
      isEmergencyActive = false;
      isEmergencySyncing = false;
      backendSyncError = 'لا توجد جلسة AWS نشطة لإرسال نداء الطوارئ';
      notifyListeners();
      return;
    }

    isEmergencyActive = true;
    isEmergencySyncing = true;
    notifyListeners();

    try {
      final sos = await EmergencyService.instance.triggerSos(
        triggeredBy: triggeredBy,
        residentId:
            _looksLikeBackendId(backendResidentId) ? backendResidentId : null,
        notes: message ??
            (type == null
                ? 'تم تفعيل نداء طوارئ من التطبيق'
                : 'تم تفعيل نداء طوارئ من التطبيق: $type'),
        location: location ?? currentAccount?.room,
      );
      currentEmergencyId = sos.id;
      activeEmergencies.removeWhere((e) => e.id == sos.id);
      activeEmergencies.insert(0, sos);
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      if (currentEmergencyId == null) {
        isEmergencyActive = false;
      }
    } finally {
      isEmergencySyncing = false;
      notifyListeners();
    }
  }

  Future<void> cancelSOS() async {
    final id = currentEmergencyId;
    if (id != null) {
      await resolveEmergency(id);
    }
    isEmergencyActive = false;
    currentEmergencyId = null;
    notifyListeners();
  }

  Future<void> resolveEmergency(String id) async {
    await _runBackendMutation(() {
      return EmergencyService.instance.resolve(id).then((_) {});
    });
  }

  void handleDeepLink(String route) {
    if (currentRole == 'مسن') {
      switch (route) {
        case 'medication':
          setElderlyTabIndex(1);
          break;
        case 'family_update':
          setElderlyTabIndex(3);
          break;
        case 'calls':
          setElderlyTabIndex(2);
          break;
        case 'activities':
          setElderlyTabIndex(4);
          break;
        default:
          setElderlyTabIndex(0);
      }
    }

    notifyListeners();
  }

  void simulateNotification(String type) {
    handleDeepLink(type);
  }

  void setMood(String mood) {
    currentMood = mood;
    addPoints(5);
    notifyListeners();
  }

  final FlutterTts _tts = FlutterTts();
  bool _ttsInitialized = false;
  final AudioPlayer _companionPlayer = AudioPlayer();
  StreamSubscription<void>? _companionPlayerCompleteSub;

  Future<void> _initTts() async {
    if (_ttsInitialized) return;

    try {
      final arEgAvailable = await _tts.isLanguageAvailable('ar-EG');
      await _tts.setLanguage(arEgAvailable == true ? 'ar-EG' : 'ar');
      await _tts.setSpeechRate(0.34);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.06);

      _tts.setCompletionHandler(() {
        isReadingAudio = false;
        notifyListeners();
      });

      _tts.setErrorHandler((msg) {
        isReadingAudio = false;
        debugPrint("TTS Error: $msg");
        notifyListeners();
      });

      _ttsInitialized = true;
    } catch (e) {
      debugPrint("TTS Initialization failed: $e");
    }
  }

  void startReading(String text) async {
    await _initTts();

    if (text.isEmpty) return;

    readingText = text;
    isReadingAudio = true;
    notifyListeners();

    try {
      await _tts.stop();
      var result = await _tts.speak(text);
      if (result == 0) {
        isReadingAudio = false;
        notifyListeners();
        debugPrint("TTS Speak failed result: 0");
      }
    } catch (e) {
      isReadingAudio = false;
      notifyListeners();
      debugPrint("TTS Speak error: $e");
    }
  }

  Future<void> startCompanionSpeech(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    readingText = cleanText;
    isReadingAudio = true;
    notifyListeners();

    try {
      await _tts.stop();
      await _companionPlayer.stop();
      _companionPlayerCompleteSub ??=
          _companionPlayer.onPlayerComplete.listen((_) {
        isReadingAudio = false;
        notifyListeners();
      });

      try {
        // Ray-style voice: use OpenAI TTS directly when the backend has a key,
        // otherwise the backend falls back to Polly and then device TTS.
        final speech = await AiService.instance.synthesizeSpeech(
          text: cleanText,
          provider: 'openai',
          openAiVoice: 'cedar',
          voiceInstructions:
              'تكلم بالعربية المصرية بصوت مساعد شخصي هادئ وواثق ودافئ، قريب من أسلوب Ray/JARVIS. اجعل النبرة طبيعية، سريعة قليلًا، بدون أداء آلي، وبوقفات قصيرة.',
        );
        final bytes = base64Decode(speech.audioBase64);
        await _companionPlayer
            .play(BytesSource(bytes, mimeType: speech.contentType));
      } catch (backendErr) {
        // fallback: device TTS لو الباك اند فشل
        debugPrint('Backend TTS failed → device TTS fallback: $backendErr');
        _companionPlayerCompleteSub?.cancel();
        _companionPlayerCompleteSub = null;
        await _initTts();
        _tts.setCompletionHandler(() {
          isReadingAudio = false;
          notifyListeners();
        });
        final result = await _tts.speak(cleanText);
        if (result == 0) {
          isReadingAudio = false;
          notifyListeners();
        }
      }
    } catch (e) {
      isReadingAudio = false;
      debugPrint('startCompanionSpeech outer error: $e');
      notifyListeners();
    }
  }

  Future<void> stopReading() async {
    try {
      await _tts.stop();
      await _companionPlayer.stop();
    } catch (_) {}
    isReadingAudio = false;
    notifyListeners();
  }

  String? voiceMessageBanner;

  void clearVoiceMessageBanner() {
    if (voiceMessageBanner != null) {
      voiceMessageBanner = null;
      notifyListeners();
    }
  }

  Future<void> toggleVoiceMessage(String id) async {
    final idx = voiceMessagesList.indexWhere((v) => v.id == id);
    if (idx != -1) {
      voiceMessagesList[idx].isPlaying = !voiceMessagesList[idx].isPlaying;
      if (voiceMessagesList[idx].isUnread) {
        voiceMessagesList[idx].isUnread = false;
      }
      notifyListeners();
    }
  }

  void markVoiceMessageRead(String id) {
    final idx = voiceMessagesList.indexWhere((v) => v.id == id);
    if (idx != -1) {
      voiceMessagesList[idx].isUnread = false;
      notifyListeners();
    }
  }

  void setSelectedSpecialistFilter(String filter) {
    selectedSpecialistFilter = filter;
    notifyListeners();
  }

  void setSelectedRoom(String? room) {
    selectedRoomFilter = room;
    notifyListeners();
  }

  void setSelectedFloor(int floor) {
    selectedFloor = floor;
    notifyListeners();
  }

  String selectedComplaintStatus = 'الكل';
  String complaintSearchQuery = '';

  void setSelectedComplaintStatus(String status) {
    selectedComplaintStatus = status;
    notifyListeners();
  }

  void setComplaintSearchQuery(String query) {
    complaintSearchQuery = query;
    notifyListeners();
  }

  void escalateComplaint(String id) {
    final index = socialComplaints.indexWhere((c) => c.id == id);
    if (index != -1) {
      socialComplaints[index] =
          socialComplaints[index].copyWith(isEscalated: true);
      notifyListeners();
    }
  }

  List<SocialSpecialistNeed> get filteredSocialNeeds {
    if (selectedSpecialistFilter == 'الكل') return socialNeeds;
    return socialNeeds
        .where((n) => n.type == selectedSpecialistFilter)
        .toList();
  }

  List<SocialSpecialistComplaint> get filteredSocialComplaints {
    List<SocialSpecialistComplaint> list = socialComplaints;

    if (currentRole == 'مدير') {
      list = list.where((c) => c.isEscalated).toList();
    }

    if (!selectedComplaintStatus.contains('الكل')) {
      if (selectedComplaintStatus.contains('مفتوحة')) {
        list = list.where((c) => c.status == 'open').toList();
      } else if (selectedComplaintStatus.contains('جاري')) {
        list = list.where((c) => c.status == 'progress').toList();
      } else if (selectedComplaintStatus.contains('مُغلقة')) {
        list = list.where((c) => c.status == 'done').toList();
      }
    }

    if (complaintSearchQuery.isNotEmpty) {
      list = list
          .where((c) =>
              c.title.contains(complaintSearchQuery) ||
              c.residentName.contains(complaintSearchQuery))
          .toList();
    }

    return list;
  }

  List<dynamic> getMemoriesByCategory(String category) {
    List<dynamic> results = [];

    String cleanCategory =
        category.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();

    if (category == 'الكل') {
      results.addAll(memoriesList);
      results.addAll(memoryMoments);
    } else if (cleanCategory == 'أسرة') {
      results.addAll(memoriesList.where((m) => m.category == 'أسرة'));
    } else if (category == '🎬 فيديو' || cleanCategory == 'فيديو') {
      results.addAll(memoriesList.where((m) => m.type == 'video'));
    } else if (cleanCategory == 'المسكن') {
      results.addAll(memoryMoments);
    } else if (cleanCategory == 'رحلات') {
      results.addAll(memoriesList.where((m) => m.category == 'رحلات'));
    } else if (cleanCategory == 'مناسبات') {
      results.addAll(memoriesList.where((m) => m.category == 'مناسبات'));
    } else {
      results.addAll(memoriesList.where((m) => m.category == cleanCategory));
    }
    return results;
  }

  // --- FAMILY STATE ---
  List<FamilyHealthMetric> familyHealthMetrics = [];

  void updateFamilyHealthMetric(String label, double value) {
    final index = familyHealthMetrics.indexWhere((m) => m.label == label);
    if (index != -1) {
      final oldVal = familyHealthMetrics[index].value;
      final history = familyHealthMetrics[index].history;
      familyHealthMetrics[index] = FamilyHealthMetric(
        label: label,
        value: value,
        status: value >= 0.7 ? 'good' : (value >= 0.5 ? 'medium' : 'low'),
        trend: value > oldVal ? 'up' : (value < oldVal ? 'down' : 'stable'),
        history: [...history, value],
      );
      notifyListeners();
    }
  }

  List<FamilyVisit> familyVisits = [];

  List<FamilyBill> familyBills = [];

  // --- SPECIALIST FILES STATE ---
  List<SpecialistResidentFile> residentFiles = [];

  String residentFilesSearchQuery = '';
  String selectedResidentFileCategory = 'الكل';

  void setResidentFilesSearchQuery(String query) {
    residentFilesSearchQuery = query;
    notifyListeners();
  }

  void setSelectedResidentFileCategory(String category) {
    selectedResidentFileCategory = category;
    notifyListeners();
  }

  List<SpecialistResidentFile> get filteredResidentFiles {
    List<SpecialistResidentFile> filtered = residentFiles;

    if (selectedResidentFileCategory != 'الكل') {
      final catMap = {
        'اجتماعي': 'social',
        'نفسي': 'psychological',
        'طبي': 'medical',
        'إداري': 'admin',
      };
      final targetCat = catMap[selectedResidentFileCategory];
      if (targetCat != null) {
        filtered =
            filtered.where((f) => f.categories.contains(targetCat)).toList();
      }
    }

    if (residentFilesSearchQuery.isNotEmpty) {
      filtered = filtered
          .where((f) =>
              f.name.contains(residentFilesSearchQuery) ||
              f.room.contains(residentFilesSearchQuery))
          .toList();
    }

    return filtered;
  }

  // --- NURSE MEDICAL ADMIN STATE ---
  List<MedicalSession> medicalSessions = [];

  List<MedicalPrescription> medicalPrescriptions = [];

  List<Review> reviews = [];

  List<SentReport> sentReports = [];

  Future<void> addMedication(String residentName, Medication med) async {
    final residentId = _residentIdForName(residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من AWS لإضافة دواء لـ $residentName';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createMedicationSchedule(
        residentId: residentId,
        medication: med,
      );
    });
    if (!synced) return;
    medications.insert(0, med);

    triggerNotification(
      title: 'تمت إضافة جرعة دواء جديدة 💊',
      body:
          'قام فريق التمريض بإضافة دواء (${med.name}) لخطة $residentName العلاجية.',
      type: 'medical',
      targetRole: 'عائلة',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> logMedicalSession(MedicalSession session) async {
    final residentId = _residentIdForName(session.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من AWS لتسجيل جلسة ${session.residentName}';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createMedicalSession(
        residentId: residentId,
        session: session,
      );
    });
    if (!synced) return;
    medicalSessions.insert(0, session);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addPrescription(MedicalPrescription p) async {
    final residentId = _residentIdForName(p.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من AWS لإضافة روشتة لـ ${p.residentName}';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createPrescription(
        residentId: residentId,
        prescription: p,
      );
    });
    if (!synced) return;
    medicalPrescriptions.insert(0, p);

    triggerNotification(
      title: 'روشتة طبية جديدة 📄',
      body:
          'تمت إضافة روشتة طبية جديدة لـ ${p.residentName} بواسطة ${p.doctorName}.',
      type: 'medical',
      targetRole: 'عائلة',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  List<CenterOperationalStat> get adminStats {
    final capacity = _firstInt(facilityProfileSettings?.facilityCapacity ??
            currentAccount?.facilityCapacity ??
            '') ??
        0;
    final occupancy =
        capacity > 0 ? (residentFiles.length / capacity) * 100 : 0.0;

    final revenueValue = familyBills
        .where((bill) => bill.isPaid)
        .fold<double>(0.0, (total, bill) => total + bill.amount);

    final revenueStr = revenueValue.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    double satisfactionValue = 0.0;
    if (volunteerRatings.isNotEmpty) {
      satisfactionValue =
          volunteerRatings.map((r) => r.score).reduce((a, b) => a + b) /
              volunteerRatings.length;
    }

    return [
      CenterOperationalStat(
          label: 'نسبة الإشغال',
          value: '${occupancy.toInt()}٪',
          trend: lastBackendSyncAt == null
              ? 'بانتظار مزامنة AWS'
              : 'آخر تحديث من AWS',
          isPositive: occupancy <= 100,
          history: [occupancy / 100]),
      CenterOperationalStat(
          label: selectedAdminDateFilter == 'اليوم'
              ? 'إيرادات اليوم'
              : (selectedAdminDateFilter == 'أسبوع'
                  ? 'إيرادات الأسبوع'
                  : 'إيرادات الشهر'),
          value: '$revenueStr ج.م',
          trend: lastBackendSyncAt == null
              ? 'بانتظار مزامنة AWS'
              : 'من فواتير AWS المدفوعة',
          isPositive: revenueValue > 0,
          history: [revenueValue / 1000]),
      CenterOperationalStat(
          label: 'الحالات الحرجة',
          value: '$criticalResidentsCount',
          trend: criticalResidentsCount > 0 ? 'تحتاج متابعة' : 'لا توجد حالات',
          isPositive: criticalResidentsCount <= 2,
          history: [criticalResidentsCount.toDouble()]),
      CenterOperationalStat(
          label: 'رضا الأهالي',
          value: '${satisfactionValue.toStringAsFixed(1)} / ٥',
          trend: volunteerRatings.isEmpty
              ? 'لا توجد تقييمات من AWS'
              : 'آخر تقييمات AWS',
          isPositive: satisfactionValue >= 3.5,
          history: [satisfactionValue]),
    ];
  }

  List<StaffPerformance> staffPerformanceList = [];

  int get totalStaffCount => staffPerformanceList.length;
  int get activeStaffCount =>
      staffPerformanceList.where((s) => s.status == 'online').length;
  double get averageStaffCompletion {
    if (staffPerformanceList.isEmpty) return 0.0;
    final total = staffPerformanceList
        .map((s) => s.completionRate)
        .reduce((a, b) => a + b);
    return total / staffPerformanceList.length;
  }

  void addStaff(StaffPerformance staff) {
    staffPerformanceList.insert(0, staff);

    triggerNotification(
      title: 'موظف جديد بالمنشأة 📋',
      body: 'تم تسجيل ${staff.name} ضمن الطاقم (${staff.role}).',
      type: 'admin',
      targetRole: 'مدير',
    );

    notifyListeners();
  }

  Future<void> joinOpportunity(String opportunityId) async {
    final idx = volunteerOpportunities.indexWhere((o) => o.id == opportunityId);
    if (idx != -1) {
      final opp = volunteerOpportunities[idx];

      final bookingId = 'book_$opportunityId';
      if (!volunteerBookings.any((b) => b.id == bookingId)) {
        final synced = await _runBackendMutation(() {
          return BackendMutationService.instance
              .createVolunteerBooking(opportunityId);
        });
        if (!synced) return;
        volunteerBookings.insert(
          0,
          VolunteerBooking(
            id: bookingId,
            title: opp.title,
            timeInfo: '${opp.dateInfo} · ${opp.hours} ساعة',
            day: DateTime.now().day + 1,
            month: 'أبريل',
            status: 'confirmed',
            location: opp.org,
            points: opp.points,
          ),
        );

        volunteerOpportunities[idx] = VolunteerOpportunity(
          id: opp.id,
          title: opp.title,
          org: opp.org,
          dateInfo: opp.dateInfo,
          icon: opp.icon,
          tags: opp.tags,
          hours: opp.hours,
          points: opp.points,
          isNew: opp.isNew,
          description: opp.description,
          totalSlots: opp.totalSlots,
          filledSlots: opp.filledSlots + 1,
        );

        triggerNotification(
          title: 'تم الانضمام بنجاح! 🎉',
          body: 'أنت الآن مسجل في "${opp.title}". موعدنا قادماً!',
          type: 'volunteer',
          targetRole: 'متطوع',
        );

        notifyListeners();
        unawaited(syncBackendData());
      }
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance
            .cancelVolunteerBooking(bookingId);
      });
      if (!synced) return;
      final booking = volunteerBookings[idx];
      volunteerBookings[idx] = VolunteerBooking(
        id: booking.id,
        title: booking.title,
        timeInfo: booking.timeInfo,
        day: booking.day,
        month: booking.month,
        status: 'cancelled',
        location: booking.location,
        points: booking.points,
        isUrgent: booking.isUrgent,
        startTime: booking.startTime,
        isRatingRequired: booking.isRatingRequired,
      );
      notifyListeners();
      unawaited(syncBackendData());
    }
  }

  Future<void> confirmAttendance(String bookingId) async {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance
            .confirmVolunteerAttendance(bookingId);
      });
      if (!synced) return;
      final b = volunteerBookings[idx];
      volunteerBookings[idx] = VolunteerBooking(
        id: b.id,
        title: b.title,
        timeInfo: b.timeInfo,
        day: b.day,
        month: b.month,
        status: 'done',
        location: b.location,
        points: b.points,
        isUrgent: false,
        startTime: b.startTime,
        isRatingRequired: true,
      );
      addPoints(b.points);

      triggerNotification(
        title: 'تم تأكيد الحضور! ✅',
        body:
            'شكراً لمساهمتك في "${b.title}". تم إضافة ${b.points} نقطة لحسابك.',
        type: 'volunteer',
        targetRole: 'متطوع',
      );

      notifyListeners();
      unawaited(syncBackendData());
    }
  }

  void submitBookingRating(String bookingId) {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final b = volunteerBookings[idx];
      volunteerBookings[idx] = VolunteerBooking(
        id: b.id,
        title: b.title,
        timeInfo: b.timeInfo,
        day: b.day,
        month: b.month,
        status: b.status,
        location: b.location,
        points: b.points,
        isUrgent: b.isUrgent,
        startTime: b.startTime,
        isRatingRequired: false,
      );
      notifyListeners();
    }
  }

  void saveMedicalVitals({
    required String residentName,
    required String bp,
    required String sugar,
    required String temp,
  }) async {
    await _syncVitals(
      residentName: residentName,
      bp: bp,
      sugar: sugar,
      temp: temp,
    );
    if (backendSyncError != null) return;

    final newSession = MedicalSession(
      id: 's${DateTime.now().millisecondsSinceEpoch}',
      type: 'vitals',
      specialistName: currentAccount?.name ?? 'فريق التمريض',
      time: 'الآن',
      date: 'اليوم',
      notes:
          'تم فحص المؤشرات الحيوية: الضغط ($bp)، السكر ($sugar مجم/دل)، الحرارة ($temp°)',
      residentName: residentName,
    );

    medicalSessions.insert(0, newSession);

    triggerNotification(
      title: 'تم حفظ القراءات 🏥',
      body: 'تم تسجيل العلامات الحيوية لـ $residentName بنجاح.',
      type: 'medical',
    );

    notifyListeners();
  }

  Future<void> addFamilyVisit(FamilyVisit visit) async {
    final residentId = _looksLikeBackendId(backendResidentId)
        ? backendResidentId
        : residentFiles.isNotEmpty
            ? residentFiles.first.id
            : null;
    if (residentId == null || !_looksLikeBackendId(residentId)) {
      backendSyncError = 'لا يوجد residentId من AWS لحجز الزيارة';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.bookVisit(
        residentId: residentId,
        visit: visit,
      );
    });
    if (!synced) return;
    familyVisits.insert(0, visit);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> approveVisit(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.approveVisit(id);
    });
    if (!synced) return;
    final idx = familyVisits.indexWhere((v) => v.id == id);
    if (idx != -1) {
      familyVisits[idx] = familyVisits[idx].copyWith(status: 'upcoming');
      notifyListeners();
    }
    unawaited(syncBackendData());
  }

  Future<void> rejectVisit(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.rejectVisit(id);
    });
    if (!synced) return;
    final idx = familyVisits.indexWhere((v) => v.id == id);
    if (idx != -1) {
      familyVisits[idx] = familyVisits[idx].copyWith(status: 'cancelled');
      notifyListeners();
    }
    unawaited(syncBackendData());
  }

  void sendFamilyMessage(String message, String residentName) {
    // LINK: Family to Specialist
    triggerNotification(
      title: 'رسالة من الأهل 📩',
      body: 'بخصوص $residentName: $message',
      type: 'complaint',
      targetRole: 'أخصائي',
    );
    notifyListeners();
  }

  Future<void> clearUnpaidBills() async {
    final unpaidBills = familyBills.where((b) => !b.isPaid).toList();
    for (final bill in unpaidBills) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.payBill(bill.id);
      });
      if (!synced) return;
    }
    unawaited(syncBackendData());
    notifyListeners();
  }

  Future<void> addSocialNeed(SocialSpecialistNeed need) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createSocialNeed(need);
    });
    if (!synced) return;
    socialNeeds.insert(0, need);

    triggerNotification(
      title: 'احتياج جديد مسجل 🛡️',
      body: 'تم تسجيل احتياج ${need.type} للغرفة ${need.roomNumber}.',
      type: 'specialist',
      targetRole: 'أخصائي',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> updateResident(SpecialistResidentFile resident) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateResident(resident);
    });
    if (!synced) return;
    final index = residentFiles.indexWhere((r) => r.id == resident.id);
    if (index != -1) {
      residentFiles[index] = resident;
      notifyListeners();
    }
    unawaited(syncBackendData());
  }

  Future<void> addResident(SpecialistResidentFile resident) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createResident(resident);
    });
    if (!synced) return;
    residentFiles.insert(0, resident);

    triggerNotification(
      title: 'إضافة مقيم جديد 👥',
      body: 'تم تسجيل ${resident.name} في الغرفة ${resident.room}.',
      type: 'admin',
      targetRole: 'مدير',
    );

    triggerNotification(
      title: 'مقيم جديد تحت الرعاية 🛡️',
      body: 'المقيم ${resident.name} انضم للمسكن في الغرفة ${resident.room}.',
      type: 'social',
      targetRole: 'أخصائي',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  double get medicationComplianceRate {
    if (medications.isEmpty) return 1.0;
    final taken = medications.where((m) => m.isTaken).length;
    return taken / medications.length;
  }

  int get unresolvedComplaintsCount =>
      socialComplaints.where((c) => c.status != 'done').length;

  Future<void> closeComplaint(String id, String resolutionNote) async {
    final idx = socialComplaints.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = socialComplaints[idx];
      await _syncComplaintStatus(
        id,
        'closed',
        resolutionNotes: resolutionNote,
      );
      if (backendSyncError != null) return;

      // Update status and add to timeline
      final updatedTimeline = List<ComplaintStep>.from(c.timeline);
      updatedTimeline.add(ComplaintStep(
        text: 'تم الحل: $resolutionNote',
        time: 'الآن',
        status: 'done',
      ));

      socialComplaints[idx] = SocialSpecialistComplaint(
        id: c.id,
        title: c.title,
        residentName: c.residentName,
        room: c.room,
        date: c.date,
        priority: c.priority,
        status: 'done',
        category: c.category,
        icon: c.icon,
        timeline: updatedTimeline,
      );

      triggerNotification(
        title: 'تم حل شكواكم بنجاح ✅',
        body:
            'بخصوص "${c.title}" لسرير ${c.residentName}. التفاصيل: $resolutionNote',
        type: 'social',
        targetRole: 'أهل',
      );

      notifyListeners();
    }
  }

  int totalCapacity = 50; // السعة الإجمالية للدار

  double get occupancyRate {
    if (totalCapacity == 0) return 0.0;
    return residentFiles.length / totalCapacity;
  }

  String generatePerformanceSummary() {
    final compliance = (medicationComplianceRate * 100).toInt();
    final occupancy = (occupancyRate * 100).toInt();
    return '''
ملخص أداء ${facilityName.isEmpty ? 'المنشأة' : facilityName}
التاريخ: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

1. الإشغال: $occupancy%
2. الالتزام الدوائي: $compliance%
3. الشكاوى المفتوحة: $unresolvedComplaintsCount شكاوى
4. الطاقم النشط: $activeStaffCount من أصل $totalStaffCount موظف

التوصيات: 
- الحفاظ على مستوى الاستجابة السريع للشكاوى.
- تعزيز فترات الراحة للطاقم الطبي لضمان استمرارية الجودة.
''';
  }

  Future<String> exportReport(String format) async {
    if (format == 'pdf') {
      final pdf = pw.Document();
      final now = DateTime.now();
      final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      final dateStr = "${now.day}/${now.month}/${now.year}";

      final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);
      final boldFontData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
      final ttfBold = pw.Font.ttf(boldFontData);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(facilityName,
                            style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900)),
                        pw.Text('تقرير الأداء الإداري والتشغيلي',
                            style: const pw.TextStyle(
                                fontSize: 12, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.PdfLogo(),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                child: pw.Column(
                  children: [
                    _pdfInfoRow('اسم الدار:', facilityName),
                    _pdfInfoRow('اسم المدير المسئول:', managerName),
                    _pdfInfoRow('تاريخ التقرير:', dateStr),
                    _pdfInfoRow('وقت الاستخراج:', timeStr),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text('ملخص مؤشرات الأداء:',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1.5, color: PdfColors.blue100),
              pw.SizedBox(height: 15),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(
                    color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue800),
                cellAlignment: pw.Alignment.centerRight,
                data: <List<String>>[
                  <String>['المؤشر الإحصائي', 'القيمة'],
                  <String>[
                    'نسبة إشغال الأسرة',
                    '${(occupancyRate * 100).toInt()}%'
                  ],
                  <String>[
                    'معدل الالتزام الدوائي',
                    '${(medicationComplianceRate * 100).toInt()}%'
                  ],
                  <String>[
                    'عدد الشكاوى قيد المعالجة',
                    unresolvedComplaintsCount.toString()
                  ],
                  <String>['عدد الموظفين المتواجدين', '$activeStaffCount موظف'],
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Text('التوصيات والإجراءات المطلوبة:',
                  style: pw.TextStyle(
                      fontSize: 15, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _pdfBullet(ttf, 'ضرورة متابعة تحديث بيانات المقيمين الجدد.'),
              _pdfBullet(ttf, 'التأكد من جاهزية مخزون الأدوية للأسبوع القادم.'),
              _pdfBullet(ttf,
                  'مراجعة ملاحظات الأخصائي الاجتماعي بخصوص الحالات الحرجة.'),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('يعتمد من مدير المنشأة',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Text(managerName),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  width: 1, style: pw.BorderStyle.dashed)),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('التوقيع والختم الرسمي',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey)),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.sharePdf(
          bytes: await pdf.save(), filename: 'Taptaba_Report.pdf');
    } else if (format == 'csv' || format == 'excel') {
      final csvBuffer = StringBuffer();
      csvBuffer.write('\uFEFF');
      csvBuffer.writeln('تقرير أداء المنشأة: $facilityName');
      csvBuffer.writeln('المدير المسئول: $managerName');
      csvBuffer.writeln(
          'التاريخ: ${DateTime.now().toLocal().toString().split(' ')[0]}');
      csvBuffer.writeln('');
      csvBuffer.writeln('المؤشر الإحصائي,القيمة');
      csvBuffer.writeln('نسبة الإشغال,${(occupancyRate * 100).toInt()}%');
      csvBuffer.writeln(
          'الالتزام الدوائي,${(medicationComplianceRate * 100).toInt()}%');
      csvBuffer.writeln('الشكاوى المفتوحة,$unresolvedComplaintsCount');
      csvBuffer.writeln('الطاقم النشط,$activeStaffCount');

      final encodedCsv = Uri.encodeComponent(csvBuffer.toString());
      final url = 'data:text/csv;charset=utf-8,$encodedCsv';

      try {
        final uri = Uri.parse(url);
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }

    final dateStrFile =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    final fileName = "Taptaba_Report_$dateStrFile.$format";
    return fileName;
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(label,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // --- MEMORY WALL ---

  List<MemoryMoment> memoryMoments = [];

  Future<void> addMemoryMoment(MemoryMoment moment) async {
    setUploadState(uploading: true, progress: 0.1);
    final residentId = _looksLikeBackendId(moment.residentId)
        ? moment.residentId
        : _residentIdForName(moment.residentName);
    if (residentId == null) {
      setUploadState(
        uploading: false,
        error: 'لا يوجد residentId من AWS لإضافة ذكرى لـ ${moment.residentName}',
      );
      backendSyncError = uploadError;
      notifyListeners();
      return;
    }
    setUploadState(uploading: true, progress: 0.6);
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createMemory(
        residentId: residentId,
        moment: moment,
      );
    });
    if (!synced) {
      setUploadState(uploading: false, error: backendSyncError);
      return;
    }
    setUploadState(uploading: false, progress: 1.0);
    memoryMoments.insert(0, moment);

    triggerNotification(
      title: 'لحظة سعادة جديدة 📸',
      body:
          'والدكم ${moment.residentName} يستمتع بوقته الآن في "${moment.activityTitle}".',
      type: 'social',
      targetRole: 'أهل',
    );

    final newItem = MemoryItem(
      id: 'mem_custom_${DateTime.now().millisecondsSinceEpoch}',
      category: 'أسرة',
      title: moment.activityTitle,
      date: 'اليوم',
      type: 'image',
      assetPath: moment.imageUrl,
    );
    memoriesList.insert(0, newItem);

    notifyListeners();
    unawaited(syncBackendData());
  }

  void deleteMemoryMoment(String id) {
    memoryMoments.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void addAppreciation(String momentId) {
    final idx = memoryMoments.indexWhere((m) => m.id == momentId);
    if (idx != -1) {
      final m = memoryMoments[idx];
      memoryMoments[idx] = MemoryMoment(
        id: m.id,
        residentId: m.residentId,
        residentName: m.residentName,
        imageUrl: m.imageUrl,
        activityTitle: m.activityTitle,
        date: m.date,
        appreciations: m.appreciations + 1,
      );

      triggerNotification(
        title: 'عائلة ${m.residentName} سعيدة! ❤️',
        body:
            'تم استلام "شكراً" من عائلة المقيم بخصوص صورة "${m.activityTitle}".',
        type: 'social',
        targetRole: 'أخصائي',
      );

      notifyListeners();
    }
  }

  int currentElderlyTabIndex = 0;
  void setElderlyTabIndex(int index) {
    currentElderlyTabIndex = index;
    notifyListeners();
  }

  MemoryMoment? get latestMemoryMoment =>
      memoryMoments.isNotEmpty ? memoryMoments.first : null;

  bool hasGalleryPermission = false;

  Future<void> requestGalleryPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    hasGalleryPermission = ps.isAuth;
    if (hasGalleryPermission) {
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(type: RequestType.image);
      if (albums.isNotEmpty) {
        List<AssetEntity> photos =
            await albums[0].getAssetListPaged(page: 0, size: 50);
        deviceGalleryImages = photos;
      }
    }
    notifyListeners();
  }

  void setGalleryPermission(bool val) {
    hasGalleryPermission = val;
    notifyListeners();
  }

  Future<void> updateVolunteerProfile(VolunteerProfile newProfile) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateVolunteerProfile(newProfile);
    });
    if (!synced) return;
    volunteerProfile = newProfile;
    notifyListeners();
  }

  void addVolunteerSkill(String skill) {
    if (!volunteerProfile.skills.contains(skill)) {
      final updatedSkills = List<String>.from(volunteerProfile.skills)
        ..add(skill);
      volunteerProfile = volunteerProfile.copyWith(skills: updatedSkills);
      notifyListeners();
    }
  }

  void removeVolunteerSkill(String skill) {
    final updatedSkills = List<String>.from(volunteerProfile.skills)
      ..remove(skill);
    volunteerProfile = volunteerProfile.copyWith(skills: updatedSkills);
    notifyListeners();
  }

  Future<void> uploadVolunteerDocument(String type, String fileName) async {
    if (type == 'cv') {
      volunteerProfile = volunteerProfile.copyWith(cvFileName: fileName);
    } else if (type == 'recommendation') {
      volunteerProfile =
          volunteerProfile.copyWith(recommendationFileName: fileName);
    }
    await updateVolunteerProfile(volunteerProfile);

    triggerNotification(
      title: 'تم رفع الملف بنجاح 📁',
      body: 'تم تسجيل ملف "$fileName" كـ $type في ملفك الشخصي.',
      type: 'admin',
      targetRole: 'متطوع',
    );

    notifyListeners();
  }

  Future<void> startVideoCall(
    String name,
    String initials, {
    String? calleeId,
    String? residentId,
    String? joinUrl,
  }) async {
    activeCallerName = name;
    activeCallerInitials = initials;
    isVideoCallActive = true;
    isIncomingCall = false;
    notifyListeners();

    if (AuthService.instance.currentUser == null) {
      if ((joinUrl ?? '').isNotEmpty) await launchZoom(joinUrl);
      return;
    }
    try {
      final call = await VideoCallService.instance.start(
        residentId: residentId,
        calleeId: calleeId,
        calleeName: name,
        provider: 'zoom',
        joinUrl: joinUrl,
      );
      activeVideoCallId = call.id;
      activeVideoCallJoinUrl = call.joinUrl;
      backendSyncError = null;
      if ((call.joinUrl ?? '').isNotEmpty) {
        await launchZoom(call.joinUrl);
      }
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  void acceptCall() {
    isVideoCallActive = true;
    isIncomingCall = false;
    notifyListeners();
  }

  void rejectCall() {
    isIncomingCall = false;
    notifyListeners();
  }

  void endVideoCall() {
    isVideoCallActive = false;
    notifyListeners();
  }

  Future<void> sendVoiceMessageFromResident(
    String title, {
    String? audioPath,
    int durationSeconds = 0,
  }) async {
    final residentId = _looksLikeBackendId(backendResidentId)
        ? backendResidentId
        : residentFiles.isNotEmpty
            ? residentFiles.first.id
            : null;
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لإرسال الرسالة الصوتية';
      notifyListeners();
      return;
    }
    try {
      await VoiceMessageService.instance.create(
        residentId: residentId,
        title: title,
        senderType: 'resident',
        filePath: audioPath,
        durationSeconds: durationSeconds,
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return;
    }
    final newMsg = VoiceMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'resident', // Special ID for the resident themselves
      title: title,
      timeDescription: 'الآن',
    );
    voiceMessagesList.insert(0, newMsg);

    // Add points for communicating!
    addPoints(15);

    triggerNotification(
      title: 'تم إرسال الرسالة! 🎙️',
      body: 'رسالتك الصوتية في طريقها لعائلتك الآن.',
      type: 'social',
      targetRole: 'مسن',
    );

    notifyListeners();
  }

  Future<void> sendVoiceMessageFromFamily(
    String title, {
    String? audioPath,
    int durationSeconds = 0,
  }) async {
    final residentId = _looksLikeBackendId(backendResidentId)
        ? backendResidentId
        : residentFiles.isNotEmpty
            ? residentFiles.first.id
            : null;
    if (residentId == null || !_looksLikeBackendId(residentId)) {
      backendSyncError = 'لا يوجد residentId من AWS لإرسال الرسالة الصوتية';
      notifyListeners();
      return;
    }
    try {
      await VoiceMessageService.instance.create(
        residentId: residentId,
        title: title,
        senderType: 'family',
        filePath: audioPath,
        durationSeconds: durationSeconds,
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return;
    }

    voiceMessagesList.insert(
      0,
      VoiceMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'family',
        title: title,
        timeDescription: 'الآن',
        durationSeconds: durationSeconds,
      ),
    );

    triggerNotification(
      title: 'رسالة صوتية من العائلة',
      body: title,
      type: 'family',
      targetRole: 'مسن',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  // --- NURSING OPERATIONS STATE ---
  List<CareTask> careTasks = [];

  List<InventoryItem> inventoryItems = [];

  List<DoctorVisit> doctorVisits = [];

  List<MealPlan> mealPlans = [];

  List<ActivitySession> activitySessions = [];

  // Nursing Operations Methods
  Future<void> toggleCareTask(String id) async {
    final idx = careTasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final shouldComplete = !careTasks[idx].isCompleted;
      final synced = await _runBackendMutation(() {
        return shouldComplete
            ? BackendMutationService.instance.completeCareTask(id)
            : BackendMutationService.instance.reopenCareTask(id);
      });
      if (!synced) return;
      careTasks[idx].isCompleted = shouldComplete;
      notifyListeners();
      unawaited(syncBackendData());
    }
  }

  Future<void> addCareTask(CareTask task) async {
    final residentId = _residentIdForName(task.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من AWS لإضافة مهمة لـ ${task.residentName}';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createCareTask(
        residentId: residentId,
        task: task,
      );
    });
    if (!synced) return;
    careTasks.add(task);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deleteCareTask(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteCareTask(id);
    });
    if (!synced) return;
    careTasks.removeWhere((t) => t.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createInventoryItem(item);
    });
    if (!synced) return;
    inventoryItems.add(item);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deleteInventoryItem(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteInventoryItem(id);
    });
    if (!synced) return;
    inventoryItems.removeWhere((i) => i.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addDoctorVisit(DoctorVisit visit) async {
    final residentId = _residentIdForName(visit.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من AWS لإضافة زيارة طبيب لـ ${visit.residentName}';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createDoctorVisit(
        residentId: residentId,
        visit: visit,
      );
    });
    if (!synced) return;
    doctorVisits.add(visit);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deleteDoctorVisit(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteDoctorVisit(id);
    });
    if (!synced) return;
    doctorVisits.removeWhere((v) => v.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addMealPlan(MealPlan plan) async {
    final residentId = _residentIdForName(plan.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من AWS لإضافة خطة وجبات لـ ${plan.residentName}';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createMealPlan(
        residentId: residentId,
        plan: plan,
      );
    });
    if (!synced) return;
    mealPlans.add(plan);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deleteMealPlan(String residentName) async {
    final id = mealPlanIdsByResidentName[residentName];
    if (id == null || id.isEmpty) {
      backendSyncError = 'لا يوجد mealPlanId من AWS لحذف خطة $residentName';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteMealPlan(id);
    });
    if (!synced) return;
    mealPlans.removeWhere((p) => p.residentName == residentName);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addActivitySession(ActivitySession session) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createActivitySession(session);
    });
    if (!synced) return;
    activitySessions.add(session);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deleteActivitySession(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteActivity(id);
    });
    if (!synced) return;
    activitySessions.removeWhere((s) => s.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deleteMedicalSession(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteMedicalSession(id);
    });
    if (!synced) return;
    medicalSessions.removeWhere((s) => s.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deletePrescription(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deletePrescription(id);
    });
    if (!synced) return;
    medicalPrescriptions.removeWhere((p) => p.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addSentReport(SentReport report) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.sendNursingReport(
        reportType: report.title,
        recipients: [
          if (currentAccount?.email.isNotEmpty == true) currentAccount!.email,
        ],
      );
    });
    if (!synced) return;
    sentReports.insert(0, report);
    notifyListeners();
    unawaited(syncBackendData());
  }

  void addReview(Review review) {
    reviews.insert(0, review);
    notifyListeners();
  }

  Future<void> addHandoff(ShiftHandoff handoff) {
    return submitHandoff(handoff);
  }

  Future<void> updateInventoryStock(String id, int change) async {
    final idx = inventoryItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final newStock = inventoryItems[idx].currentStock + change;
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.updateInventoryStock(
          id: id,
          currentStock: newStock,
        );
      });
      if (!synced) return;
      final newItem = InventoryItem(
        id: inventoryItems[idx].id,
        name: inventoryItems[idx].name,
        category: inventoryItems[idx].category,
        currentStock: newStock,
        minRequired: inventoryItems[idx].minRequired,
        unit: inventoryItems[idx].unit,
      );
      inventoryItems[idx] = newItem;
      notifyListeners();
      unawaited(syncBackendData());
    }
  }

  Future<void> updateMealPlan(MealPlan plan) async {
    final idx =
        mealPlans.indexWhere((p) => p.residentName == plan.residentName);
    final id = mealPlanIdsByResidentName[plan.residentName];
    if (id == null || id.isEmpty) {
      await addMealPlan(plan);
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateMealPlan(
        id: id,
        plan: plan,
      );
    });
    if (!synced) return;
    if (idx != -1) {
      mealPlans[idx] = plan;
    } else {
      mealPlans.add(plan);
    }
    notifyListeners();
    unawaited(syncBackendData());
  }

  // بدء عملية التدخل الاجتماعي وتغيير حالة الشكوى
  Future<void> startIntervention(String id) async {
    final idx = socialComplaints.indexWhere((c) => c.id == id);
    if (idx != -1) {
      await _syncComplaintStatus(id, 'in_progress');
      if (backendSyncError != null) return;
      final updatedTimeline =
          List<ComplaintStep>.from(socialComplaints[idx].timeline);
      updatedTimeline.add(ComplaintStep(
        text: 'بدء التدخل والمتابعة',
        time: 'الآن',
        status: 'progress',
      ));

      socialComplaints[idx] = SocialSpecialistComplaint(
        id: socialComplaints[idx].id,
        title: socialComplaints[idx].title,
        residentName: socialComplaints[idx].residentName,
        room: socialComplaints[idx].room,
        date: socialComplaints[idx].date,
        priority: socialComplaints[idx].priority,
        status: 'progress',
        category: socialComplaints[idx].category,
        icon: socialComplaints[idx].icon,
        timeline: updatedTimeline,
      );

      notifyListeners();
    }
  }

  // حفظ تقييم اجتماعي جديد وتحديث درجات المقيم
  Future<void> saveSocialAssessment({
    required String residentId,
    required Map<String, double> newScores,
    required bool needsIntervention,
    String? notes,
  }) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createSocialAssessment(
        residentId: residentId,
        scores: newScores,
        needsIntervention: needsIntervention,
        notes: notes,
      );
    });
    if (!synced) return;

    final idx = socialResidentScores.indexWhere((r) => r.id == residentId);
    if (idx != -1) {
      final r = socialResidentScores[idx];

      final updatedScores = Map<String, double>.from(r.scores);
      newScores.forEach((key, value) {
        updatedScores[key] = value;
      });

      socialResidentScores[idx] = SocialSpecialistResidentScore(
        id: r.id,
        name: r.name,
        room: r.room,
        date: 'الآن',
        isUrgent: needsIntervention,
        scores: updatedScores,
        initials: r.initials,
        healthStatus: r.healthStatus,
        lastAssessment: DateTime.now(),
      );

      // Add a social notification if urgent
      if (needsIntervention) {
        notifications.insert(
            0,
            TaptabaNotification(
              id: 'soc_${DateTime.now().millisecondsSinceEpoch}',
              title: 'تنبيه تدخل اجتماعي: ${r.name}',
              body: 'المقيم بحاجة لمتابعة عاجلة بناءً على التقييم الأخير.',
              time: 'الآن',
              type: 'social',
              targetRole: 'specialist',
              residentId: residentId,
              isRead: false,
            ));
      }

      notifyListeners();
      unawaited(syncBackendData());
    }
  }

  // خريطة الاحتياجات: تجميع بيانات المقيمين مع حساب لون الحالة بصرياً
  List<Map<String, dynamic>> get needMapData {
    return filteredResidentScores.map((r) {
      // Calculate overall social health
      double avgScore = 0;
      if (r.scores.isNotEmpty) {
        avgScore = r.scores.values.reduce((a, b) => a + b) / r.scores.length;
      }

      Color statusColor;
      if (r.isUrgent || avgScore < 0.4) {
        statusColor = const Color(0xFFef4444); // High Need
      } else if (avgScore < 0.7) {
        statusColor = const Color(0xFFf59e0b); // Medium Need
      } else {
        statusColor = const Color(0xFF10b981); // Stable
      }

      return {
        'id': r.id,
        'name': r.name,
        'room': r.room,
        'color': statusColor,
        'score': avgScore,
        'initials': r.initials,
      };
    }).toList();
  }

  // وضع علامة "تم الحل" على التنبيهات الإدارية
  void resolveNotification(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  // --- MEMORIES METHODS ---
  Future<void> fetchGalleryImages() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps.hasAccess) {
        final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          type: RequestType.image,
        );
        if (paths.isNotEmpty) {
          final List<AssetEntity> entities =
              await paths[0].getAssetListRange(start: 0, end: 50);
          deviceGalleryImages = entities;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching gallery: $e');
    }
  }

  Future<void> pickMemoryImage() async {
    try {
      // استخدام ImagePicker مباشرة فهو يتعامل مع الصلاحيات بشكل أفضل في النسخ الحديثة
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final newItem = MemoryItem(
          id: 'mem_custom_${DateTime.now().millisecondsSinceEpoch}',
          category: 'الاستوديو',
          title: 'ذكرى من الاستوديو',
          date: 'اليوم',
          type: 'image',
          assetPath: image.path,
        );

        memoriesList.insert(0, newItem);
        notifyListeners();

        triggerNotification(
          title: 'تمت إضافة ذكرى جديدة! 📸',
          body: 'ستجدها الآن في صندوق ذكرياتك الجميل.',
          type: 'social',
          targetRole: 'مسن',
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // --- INTEGRATION & CROSS-ROLE REQUESTS ---

  Future<void> submitComplaint(
      String message, String type, String fromRole) async {
    final residentId =
        _looksLikeBackendId(backendResidentId) ? backendResidentId : null;
    try {
      await ComplaintsService.instance.create(
        category: _backendComplaintCategory(type),
        subject: type,
        description: message,
        priority: 'high',
        residentId: residentId,
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return;
    }

    final complaint = SocialSpecialistComplaint(
      id: 'comp_${DateTime.now().millisecondsSinceEpoch}',
      residentName: fromRole == 'مسن' ? currentUser.name : 'أحد أفراد الأسرة',
      room: currentAccount?.room ?? '',
      date: 'اليوم',
      title: type,
      category: 'عام',
      icon: '🚨',
      status: 'open',
      priority: 'high',
      timeline: [ComplaintStep(text: message, time: 'الآن', status: 'pending')],
    );
    socialComplaints.insert(0, complaint);

    triggerNotification(
      title: 'تم إرسال طلبك بنجاح ✅',
      body: 'قام فريقنا باستلام طلبك بخصوص "$type" وسيتم التعامل معه فوراً.',
      type: 'system',
      targetRole: fromRole,
    );
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> requestConsultation(String type) async {
    final residentId =
        _looksLikeBackendId(backendResidentId) ? backendResidentId : null;
    try {
      await ComplaintsService.instance.create(
        category: 'general',
        subject: 'طلب استشارة $type',
        description: 'طلب استشارة مرسل من التطبيق',
        priority: 'medium',
        residentId: residentId,
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return;
    }

    triggerNotification(
      title: 'طلب استشارة مرسل 💬',
      body:
          'تم تحويل طلب الاستشارة الـ $type إلى الفريق المختص، سيتم التواصل معك قريباً.',
      type: 'medical',
      targetRole: 'أسرة',
    );
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addVolunteerOpportunity(VolunteerOpportunity opp) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createVolunteerOpportunity(opp);
    });
    if (!synced) return;
    volunteerOpportunities.insert(0, opp);

    triggerNotification(
      title: 'تم نشر الفرصة بنجاح 🌟',
      body: 'أصبحت فرصة "${opp.title}" متاحة الآن للمتطوعين.',
      type: 'system',
      targetRole: 'إدارة',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> updateVolunteerOpportunity(VolunteerOpportunity opp) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateVolunteerOpportunity(opp);
    });
    if (!synced) return;
    final index = volunteerOpportunities.indexWhere((o) => o.id == opp.id);
    if (index != -1) {
      volunteerOpportunities[index] = opp;
      notifyListeners();
    }
    unawaited(syncBackendData());
  }

  Future<void> rateVolunteerSession(String volunteerId, int ratingScore,
      {String comment = ''}) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createVolunteerReview(
        toName: volunteerId,
        session: comment.isEmpty ? 'جلسة تطوع' : comment,
        score: ratingScore.toDouble(),
      );
    });
    if (!synced) return;

    if (ratingScore == 3) {
      addPoints(15);
    } else if (ratingScore == 2) {
      addPoints(5);
    }

    final review = Review(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      fromRole: 'elderly',
      fromName: currentUser.name,
      toRole: 'volunteer',
      rating: ratingScore.toDouble(),
      comment: comment,
      date: DateTime.now().toString(),
    );
    reviews.insert(0, review);

    triggerNotification(
      title: 'شكراً لتقييمك! 💖',
      body: 'رأيك يهمنا جداً في تحسين جودة الرعاية المقدمة لك.',
      type: 'system',
      targetRole: 'مسن',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  void sendEncouragementMessage(String messageType, {String? text}) {
    String title =
        messageType == 'voice' ? 'رسالة صوتية جديدة 🎤' : 'رسالة من العائلة ✉️';
    String body = messageType == 'voice'
        ? 'عائلتك أرسلت لك رسالة صوتية تشجيعية لسماعها!'
        : (text ?? 'عائلتك أرسلت لك رسالة تشجيعية!');

    triggerNotification(
      title: title,
      body: body,
      type: 'family',
      targetRole: 'مسن',
    );

    // إضافة الذكرى لشاشة الذكريات
    final newItem = MemoryItem(
      id: 'mem_custom_${DateTime.now().millisecondsSinceEpoch}',
      category: 'أسرة',
      title: title,
      date: 'اليوم',
      type: messageType == 'voice' ? 'voice' : 'text',
      assetPath: '',
      content: body,
    );

    memoriesList.insert(0, newItem);

    if (messageType == 'voice') {
      voiceMessagesList.insert(
        0,
        VoiceMessage(
          id: 'v_custom_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'family',
          title: 'رسالة صوتية من العائلة ❤️',
          timeDescription: 'اليوم',
          isUnread: true,
        ),
      );
    }
    notifyListeners();
  }

  void sendMedicationReminder(String medName) {
    String title = 'تذكير بموعد الدواء 💊';
    String body =
        'عائلتك تذكرك بموعد أخذ $medName. نتمنى لك دوام الصحة والعافية!';

    triggerNotification(
      title: title,
      body: body,
      type: 'medical',
      targetRole: 'مسن',
    );

    // إضافة الذكرى لشاشة الذكريات
    final newItem = MemoryItem(
      id: 'mem_med_${DateTime.now().millisecondsSinceEpoch}',
      category: 'صحة',
      title: title,
      date: 'اليوم',
      type: 'text',
      assetPath: '',
      content: body,
    );

    memoriesList.insert(0, newItem);
    notifyListeners();
  }

  Future<void> toggleMedicationTaken(String id) async {
    final index = medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      bool newState = !medications[index].isTaken;
      await _syncMedicationDose(
          medications[index], newState ? 'given' : 'missed');
      if (backendSyncError != null) return;
      medications[index].isTaken = newState;
      medications[index].isElderlyConfirmed = newState;
      notifyListeners();
      unawaited(syncBackendData());
    }
  }

  // --- Specialist Recommendations ---
  List<SpecialistRecommendation> specialistRecommendations = [];

  void addSpecialistRecommendation(SpecialistRecommendation rec) {
    specialistRecommendations.insert(0, rec);
    triggerNotification(
      title: 'توصية نفسية جديدة 🧠',
      body: 'توصية للمقيم ${rec.residentName}: ${rec.content}',
      type: 'medical',
      targetRole: 'ممرض',
    );
    notifyListeners();
  }

  // --- Care Reports ---
  List<CareReport> careReports = [];

  void addCareReport(CareReport report) {
    careReports.insert(0, report);
    triggerNotification(
      title: 'تقرير رعاية جديد 📄',
      body: 'تم إضافة تقرير جديد: ${report.title}',
      type: 'medical',
      targetRole: 'عائلة',
    );
    notifyListeners();
  }

  // --- Specialist Chat ---
  List<ChatMessage> specialistChatHistory = [];

  void sendSpecialistMessage(String text,
      {String? mediaPath, String? mediaType}) {
    specialistChatHistory.add(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromMe: true, // true means from Family
      timestamp: DateTime.now(),
      mediaPath: mediaPath,
      mediaType: mediaType,
    ));
    notifyListeners();
  }

  Future<void> loadSpecialistThread({
    String? otherUserId,
    String? otherUserName,
    String? otherUserRole,
  }) async {
    if (AuthService.instance.currentUser == null) return;
    isLoadingSpecialistChat = true;
    notifyListeners();
  }

  void sendSpecialistReply(String text,
      {String? mediaPath, String? mediaType}) {
    specialistChatHistory.add(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromMe: false, // false means from Specialist
      timestamp: DateTime.now(),
      mediaPath: mediaPath,
      mediaType: mediaType,
    ));
    notifyListeners();
  }

  pw.Widget _pdfBullet(pw.Font font, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 6, left: 8),
            decoration: const pw.BoxDecoration(
                color: PdfColors.black, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(
            child: pw.Text(text,
                style: pw.TextStyle(font: font, fontSize: 11),
                textDirection: pw.TextDirection.rtl),
          ),
        ],
      ),
    );
  }

  // AI Shift Handoff
  Future<String> generateShiftSummary(String residentName) async {
    final notes = getNotesForResident(residentName);
    final tasks = careTasks.where((t) => t.residentName == residentName).toList();
    return await AiService.instance.summarizeShiftHandoff(notes, tasks);
  }

  // Smart Diet Planner
  Future<MealPlan> generateAndSaveMealPlan(String residentName) async {
    final info = getMedicalInfo(residentName);
    final plan = await AiService.instance.generateSmartDiet(info);
    final idx = mealPlans.indexWhere((m) => m.residentName == residentName);
    if (idx != -1) {
      mealPlans[idx] = plan;
    } else {
      mealPlans.add(plan);
    }
    notifyListeners();
    return plan;
  }

  // Predictive Alerts
  List<AIInsight> predictiveAlerts = [];
  Future<void> fetchPredictiveAlerts() async {
    if (backendResidentId != null) {
      predictiveAlerts = await AiService.instance.getPredictiveHealthAlerts(backendResidentId!);
      notifyListeners();
    } else {
      if (residentFiles.isNotEmpty) {
        predictiveAlerts = await AiService.instance.getPredictiveHealthAlerts(residentFiles.first.id);
        notifyListeners();
      }
    }
  }

  // Auto-Generated Family Updates
  String latestFamilyUpdate = "";
  Future<void> fetchFamilyUpdate() async {
    final residentId = _familyUpdateResidentId();
    var generatedUpdate = '';

    if (residentId != null) {
      try {
        generatedUpdate =
            (await AiService.instance.generateFamilyWeeklyUpdate(residentId))
                .trim();
      } catch (_) {
        generatedUpdate = '';
      }
    }

    latestFamilyUpdate = generatedUpdate.isNotEmpty
        ? generatedUpdate
        : _buildLocalFamilyWeeklyUpdate();
    notifyListeners();
  }

  String? _familyUpdateResidentId() {
    if (_looksLikeBackendId(backendResidentId)) return backendResidentId;

    final linkedResidentId = currentAccount?.linkedResidentId;
    if (_looksLikeBackendId(linkedResidentId)) return linkedResidentId;

    for (final resident in residentFiles) {
      if (_looksLikeBackendId(resident.id)) return resident.id;
    }
    return null;
  }

  String _familyUpdateResidentName() {
    final linkedResidentId = currentAccount?.linkedResidentId;
    for (final resident in residentFiles) {
      if (resident.id == linkedResidentId && resident.name.trim().isNotEmpty) {
        return resident.name.trim();
      }
    }

    if (residentFiles.isNotEmpty &&
        residentFiles.first.name.trim().isNotEmpty) {
      return residentFiles.first.name.trim();
    }
    return 'والدك';
  }

  String _metricStatusArabic(String status) {
    switch (status) {
      case 'good':
        return 'ممتاز';
      case 'medium':
        return 'يحتاج متابعة';
      case 'critical':
        return 'يحتاج انتباه';
      default:
        return status.isEmpty ? 'مستقر' : status;
    }
  }

  String _shortFamilyUpdateText(String value, {int maxLength = 100}) {
    final text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trim()}...';
  }

  String _buildLocalFamilyWeeklyUpdate() {
    final residentName = _familyUpdateResidentName();
    final observations = <String>[];

    if (familyHealthMetrics.isNotEmpty) {
      final metrics = familyHealthMetrics.take(4).map((metric) {
        final percent = (metric.value * 100).round();
        return '${metric.label} $percent% (${_metricStatusArabic(metric.status)})';
      }).join('، ');
      observations.add('مؤشرات اليوم: $metrics.');
    }

    final todayMedications =
        medications.where((med) => med.dayTag == 'اليوم').toList();
    if (todayMedications.isNotEmpty) {
      final confirmed = todayMedications
          .where((med) => med.isTaken || med.isElderlyConfirmed)
          .length;
      final missed = todayMedications.where((med) => med.isMissed).length;
      final skipped = todayMedications.where((med) => med.isSkipped).length;
      final details = <String>[
        'تم تأكيد $confirmed من ${todayMedications.length} جرعات اليوم',
        if (missed > 0) '$missed جرعات تحتاج مراجعة',
        if (skipped > 0) '$skipped جرعات تم تجاوزها',
      ];
      observations.add('الأدوية: ${details.join('، ')}.');
    }

    final currentActivities = activities
        .where((activity) =>
            activity.dayTag == 'اليوم' || activity.dayTag == 'الأسبوع')
        .toList();
    if (currentActivities.isNotEmpty) {
      final done = currentActivities
          .where((activity) => activity.status == 'done')
          .length;
      observations.add(
          'الأنشطة: تم إنجاز $done من ${currentActivities.length} نشاط مسجل.');
    }

    if (currentMood.trim().isNotEmpty) {
      observations.add('المزاج المسجل حالياً: ${currentMood.trim()}.');
    }

    if (careReports.isNotEmpty) {
      final report = careReports.first;
      final summary = _shortFamilyUpdateText(report.summary);
      if (summary.isNotEmpty) {
        observations.add('آخر تقرير رعاية: $summary.');
      }
    }

    final nextVisit = familyVisits.cast<FamilyVisit?>().firstWhere(
          (visit) =>
              visit != null &&
              (visit.status == 'pending' || visit.status == 'upcoming'),
          orElse: () => null,
        );
    if (nextVisit != null) {
      observations.add(
          'هناك زيارة عائلية ${nextVisit.status == 'pending' ? 'بانتظار التأكيد' : 'قادمة'} يوم ${nextVisit.date} الساعة ${nextVisit.time}.');
    }

    if (observations.isEmpty) return '';

    return [
      'تحديث هذا الأسبوع عن $residentName:',
      ...observations.take(5).map((item) => '- $item'),
      'الخلاصة: الحالة مستقرة إجمالاً، واستمرار المتابعة اليومية والتواصل مع الفريق يساعد على ملاحظة أي تغير مبكراً.',
    ].join('\n');
  }

  // Cognitive Games
  List<CognitiveGameResult> cognitiveScores = [];
  CognitiveGameResult? _cognitiveGameResult;
  CognitiveGameResult? get cognitiveGameResult => _cognitiveGameResult;

  Future<void> fetchCognitiveGame() async {
    await Future.delayed(const Duration(seconds: 1));
    _cognitiveGameResult = CognitiveGameResult(
      id: 'mock_game_1',
      residentId: backendResidentId ?? 'unknown',
      score: 8,
      feedback: "ذاكرة قوية وانتباه جيد.",
      date: DateTime.now(),
    );
    notifyListeners();
  }

  void saveCognitiveGameResult(CognitiveGameResult result) {
    _cognitiveGameResult = result;
    cognitiveScores.add(result);
    notifyListeners();
  }

  Future<AiChatResponse> sendCognitiveGameInput(String input) async {
    final resId = backendResidentId ?? 'unknown';
    final res = await AiService.instance.playCognitiveGame(resId, input);
    notifyListeners();
    return res;
  }
}
