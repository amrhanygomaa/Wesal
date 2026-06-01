import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/app_models.dart';
import 'api_client.dart';

class BackendSyncSnapshot {
  final List<SpecialistResidentFile>? residentFiles;
  final List<Resident>? residents;
  final List<Medication>? medications;
  final List<Activity>? activities;
  final List<ActivitySession>? activitySessions;
  final List<SocialSpecialistComplaint>? complaints;
  final List<FamilyVisit>? familyVisits;
  final List<FamilyBill>? familyBills;
  final List<MemoryMoment>? memoryMoments;
  final List<MemoryItem>? memories;
  final List<VoiceMessage>? voiceMessages;
  final List<CareTask>? careTasks;
  final List<InventoryItem>? inventoryItems;
  final List<DoctorVisit>? doctorVisits;
  final List<MealPlan>? mealPlans;
  final Map<String, String>? mealPlanIdsByResidentName;
  final List<MedicalSession>? medicalSessions;
  final List<MedicalPrescription>? medicalPrescriptions;
  final List<VolunteerOpportunity>? volunteerOpportunities;
  final List<VolunteerBooking>? volunteerBookings;
  final List<VolunteerCertificate>? volunteerCertificates;
  final List<VolunteerRating>? volunteerRatings;
  final List<VolunteerReview>? volunteerReviews;
  final VolunteerProfile? volunteerProfile;
  final List<TaptabaNotification>? notifications;
  final List<NursingNote>? nursingNotes;
  final List<ShiftHandoff>? handoffs;
  final List<SocialSpecialistNeed>? socialNeeds;
  final List<SocialSpecialistAssessmentTool>? socialAssessmentTools;
  final List<SocialSpecialistResidentScore>? socialResidentScores;
  final List<StaffPerformance>? staffPerformance;
  final List<SentReport>? sentReports;
  final CareReport? careReportPreview;
  final String? primaryResidentId;
  final String? primaryResidentName;
  final List<FamilyHealthMetric>? familyHealthMetrics;
  final List<FamilyMember>? familyMembers;
  final List<AssessmentHistoricalEntry>? assessmentHistory;

  const BackendSyncSnapshot({
    this.residentFiles,
    this.residents,
    this.medications,
    this.activities,
    this.activitySessions,
    this.complaints,
    this.familyVisits,
    this.familyBills,
    this.memoryMoments,
    this.memories,
    this.voiceMessages,
    this.careTasks,
    this.inventoryItems,
    this.doctorVisits,
    this.mealPlans,
    this.mealPlanIdsByResidentName,
    this.medicalSessions,
    this.medicalPrescriptions,
    this.volunteerOpportunities,
    this.volunteerBookings,
    this.volunteerCertificates,
    this.volunteerRatings,
    this.volunteerReviews,
    this.volunteerProfile,
    this.notifications,
    this.nursingNotes,
    this.handoffs,
    this.socialNeeds,
    this.socialAssessmentTools,
    this.socialResidentScores,
    this.staffPerformance,
    this.sentReports,
    this.careReportPreview,
    this.primaryResidentId,
    this.primaryResidentName,
    this.familyHealthMetrics,
    this.familyMembers,
    this.assessmentHistory,
  });
}

class BackendSyncService {
  BackendSyncService._();
  static final BackendSyncService instance = BackendSyncService._();
  static const Duration _softRequestTimeout = Duration(seconds: 6);

  Future<BackendSyncSnapshot> load({
    String? preferredResidentId,
    bool requireResidentScope = false,
    String? role,
  }) async {
    final normalizedRole = role?.trim() ?? '';
    final loadAll = normalizedRole.isEmpty;
    final isResident = normalizedRole == 'مسن';
    final isFamily = normalizedRole == 'أسرة';
    final isNurse = normalizedRole == 'ممرض';
    final isSpecialist = normalizedRole == 'أخصائي اجتماعي';
    final isAdmin = normalizedRole == 'إدارة';
    final isVolunteer = normalizedRole == 'متطوع';

    final loadResidentCore =
        loadAll || isResident || isFamily || isNurse || isSpecialist || isAdmin;
    final loadResidentWellness = loadAll || isResident || isFamily;
    final loadMedicationData = loadAll || isResident || isFamily || isNurse;
    final loadActivitiesData =
        loadAll || isResident || isSpecialist || isNurse || isFamily;
    final loadFamilyData = loadAll || isResident || isFamily;
    final loadNursingData = loadAll || isNurse || isAdmin;
    final loadSocialData = loadAll || isSpecialist;
    final loadVolunteerData = loadAll || isVolunteer || isAdmin;
    final loadReportsData = loadAll || isNurse || isAdmin;
    final loadNotificationsData = loadAll ||
        isResident ||
        isFamily ||
        isNurse ||
        isSpecialist ||
        isAdmin ||
        isVolunteer;

    Future<List<Map<String, dynamic>>?> listWhen(
      bool condition,
      String path, {
      Map<String, dynamic>? query,
    }) {
      return condition ? _list(path, query: query) : Future.value(null);
    }

    Future<Map<String, dynamic>?> mapWhen(bool condition, String path) {
      return condition ? _map(path) : Future.value(null);
    }

    final residentsJson = loadResidentCore
        ? await _list('/residents', query: {'status': 'active'})
        : null;
    final residentMap = _residentNameMap(residentsJson);
    final linkedFamilyMembersJson =
        requireResidentScope && _s(preferredResidentId).isEmpty
            ? await _list('/family-members/me')
            : null;
    final linkedResidentIds = linkedFamilyMembersJson
            ?.map((item) => _s(item['residentId']))
            .where((id) => id.isNotEmpty)
            .toList() ??
        const <String>[];
    final linkedResidentId =
        linkedResidentIds.isEmpty ? null : linkedResidentIds.first;
    final requestedResidentId = _s(preferredResidentId).isNotEmpty
        ? _s(preferredResidentId)
        : linkedResidentId;
    final primaryResidentId = _resolvePrimaryResidentId(
      residentsJson,
      requestedResidentId,
      requireResidentScope: requireResidentScope,
    );
    // Admin, nurse, and specialist need the full resident list for their
    // management screens. Only family/resident roles scope to a single resident.
    final shouldScopeList = primaryResidentId != null &&
        (isResident || isFamily || requireResidentScope);
    final scopedResidentsJson = shouldScopeList
        ? residentsJson
            ?.where((item) => _s(item['id']) == primaryResidentId)
            .toList()
        : requireResidentScope
            ? <Map<String, dynamic>>[]
            : residentsJson;
    final scopedResidentQuery =
        primaryResidentId == null ? null : {'residentId': primaryResidentId};

    final noScopedResident = primaryResidentId == null && requireResidentScope;
    final vitalsFuture = noScopedResident
        ? Future<List<Map<String, dynamic>>?>.value(<Map<String, dynamic>>[])
        : listWhen(
            loadResidentWellness,
            '/health/vitals',
            query: scopedResidentQuery,
          );
    final familyMembersFuture = primaryResidentId == null
        ? Future<List<Map<String, dynamic>>?>.value(
            requireResidentScope || isResident
                ? <Map<String, dynamic>>[]
                : null,
          )
        : listWhen(
            loadFamilyData,
            '/family-members',
            query: {'residentId': primaryResidentId},
          );
    final medicationSchedulesFuture = listWhen(
        loadMedicationData, '/medications/schedules',
        query: (isResident || isFamily) ? scopedResidentQuery : null);
    final medicationDoseLogsFuture = listWhen(
        loadMedicationData, '/medications/doses',
        query: (isResident || isFamily) ? scopedResidentQuery : null);
    final overdueDosesFuture = listWhen(
        loadMedicationData, '/medications/overdue',
        query: (isResident || isFamily) ? scopedResidentQuery : null);
    final activitiesFuture = listWhen(loadActivitiesData, '/activities');
    final complaintsFuture = listWhen(loadSocialData || isAdmin, '/complaints');
    final visitsFuture = noScopedResident
        ? Future<List<Map<String, dynamic>>?>.value(<Map<String, dynamic>>[])
        : listWhen(
            loadFamilyData,
            '/family-bridge/visits',
            query: scopedResidentQuery,
          );
    final familyBridgeMediaFuture = noScopedResident
        ? Future<List<Map<String, dynamic>>?>.value(<Map<String, dynamic>>[])
        : listWhen(
            loadFamilyData,
            '/family-bridge/media',
            query: {
              if (primaryResidentId != null) 'residentId': primaryResidentId,
              'status': 'confirmed',
            },
          );
    final billsFuture = noScopedResident
        ? Future<List<Map<String, dynamic>>?>.value(<Map<String, dynamic>>[])
        : listWhen(loadFamilyData, '/billing', query: scopedResidentQuery);
    final memoriesFuture = listWhen(loadFamilyData, '/memories');
    final voiceMessagesFuture = listWhen(loadFamilyData, '/voice-messages');
    final careTasksFuture = listWhen(loadNursingData, '/care-tasks');
    final inventoryFuture = listWhen(loadNursingData, '/inventory');
    final doctorVisitsFuture = listWhen(loadNursingData, '/doctor-visits');
    final mealPlansFuture = listWhen(loadNursingData, '/meal-plans');
    final sessionsFuture =
        listWhen(loadNursingData || isResident, '/medical-sessions');
    final prescriptionsFuture =
        listWhen(loadNursingData || isResident, '/prescriptions');
    final opportunitiesFuture =
        listWhen(loadVolunteerData, '/volunteers/opportunities');
    final bookingsFuture = listWhen(loadVolunteerData, '/volunteers/bookings');
    final certificatesFuture =
        listWhen(loadVolunteerData, '/volunteers/certificates');
    final ratingsFuture = listWhen(loadVolunteerData, '/volunteers/ratings');
    final reviewsFuture = listWhen(loadVolunteerData, '/volunteers/reviews');
    final profileFuture = mapWhen(loadVolunteerData, '/volunteers/profile');
    final notificationUserId =
        loadNotificationsData ? await _notificationUserId() : null;
    final notificationsJson = notificationUserId == null
        ? null
        : await _list('/notifications/$notificationUserId');
    final nursingNotesFuture = listWhen(loadNursingData, '/nursing-notes');
    final handoffsFuture = listWhen(loadNursingData, '/handoffs');
    final socialNeedsFuture = listWhen(loadSocialData, '/social/needs');
    final socialToolsFuture =
        listWhen(loadSocialData, '/social/assessment-tools');
    final socialScoresFuture =
        listWhen(loadSocialData, '/social/resident-scores');
    final staffPerformanceFuture =
        listWhen(isAdmin, '/admin/staff-performance');
    final sentReportsFuture =
        listWhen(loadReportsData, '/reports/nursing/history');
    final careReportFuture =
        mapWhen(loadReportsData || isFamily, '/reports/nursing/preview');
    final assessmentHistoryFuture = listWhen(
      loadSocialData || isResident,
      '/social/assessments',
      query:
          primaryResidentId != null ? {'residentId': primaryResidentId} : null,
    );

    final vitalsJson = await vitalsFuture;
    var familyMembersJson = await familyMembersFuture;
    if ((loadAll || isAdmin) &&
        familyMembersJson == null &&
        scopedResidentsJson != null &&
        scopedResidentsJson.isNotEmpty) {
      familyMembersJson = await _familyMembersForResidents(scopedResidentsJson);
    }
    final medicationSchedulesJson = await medicationSchedulesFuture;
    final medicationDoseLogsJson = await medicationDoseLogsFuture;
    final overdueDosesJson = await overdueDosesFuture;
    final activitiesJson = await activitiesFuture;
    final complaintsJson = await complaintsFuture;
    final visitsJson = await visitsFuture;
    final familyBridgeMediaJson = await familyBridgeMediaFuture;
    final billsJson = await billsFuture;
    final memoriesJson = await memoriesFuture;
    final voiceMessagesJson = await voiceMessagesFuture;
    final careTasksJson = await careTasksFuture;
    final inventoryJson = await inventoryFuture;
    final doctorVisitsJson = await doctorVisitsFuture;
    final mealPlansJson = await mealPlansFuture;
    final sessionsJson = await sessionsFuture;
    final prescriptionsJson = await prescriptionsFuture;
    final opportunitiesJson = await opportunitiesFuture;
    final bookingsJson = await bookingsFuture;
    final certificatesJson = await certificatesFuture;
    final ratingsJson = await ratingsFuture;
    final reviewsJson = await reviewsFuture;
    final profileJson = await profileFuture;
    final nursingNotesJson = await nursingNotesFuture;
    final handoffsJson = await handoffsFuture;
    final socialNeedsJson = await socialNeedsFuture;
    final socialToolsJson = await socialToolsFuture;
    final socialScoresJson = await socialScoresFuture;
    final staffPerformanceJson = await staffPerformanceFuture;
    final sentReportsJson = await sentReportsFuture;
    final careReportJson = await careReportFuture;
    final assessmentHistoryJson = await assessmentHistoryFuture;

    final familyMembers =
        familyMembersJson?.map(_familyMemberFromJson).toList();
    final familyMembersByResidentId = <String, List<FamilyMember>>{};
    for (final member in familyMembers ?? const <FamilyMember>[]) {
      final residentId = member.residentId;
      if (residentId == null || residentId.isEmpty) continue;
      familyMembersByResidentId
          .putIfAbsent(residentId, () => <FamilyMember>[])
          .add(member);
    }

    return BackendSyncSnapshot(
      residentFiles: scopedResidentsJson
          ?.map((j) => _residentFileFromJson(j).copyWith(
                familyMembers: familyMembersByResidentId[_s(j['id'])] ??
                    const <FamilyMember>[],
              ))
          .toList(),
      residents: scopedResidentsJson?.map(_residentFromJson).toList(),
      primaryResidentId: primaryResidentId,
      primaryResidentName:
          primaryResidentId == null ? null : residentMap[primaryResidentId],
      medications: _medicationsFromJson(
        medicationSchedulesJson,
        medicationDoseLogsJson,
        overdueDosesJson,
        residentMap,
      ),
      activities: activitiesJson?.map(_activityFromJson).toList(),
      activitySessions:
          activitiesJson?.map((e) => _activitySessionFromJson(e)).toList(),
      complaints: complaintsJson
          ?.map((e) => _complaintFromJson(e, residentMap))
          .toList(),
      familyVisits: visitsJson?.map(_familyVisitFromJson).toList(),
      familyBills: billsJson?.map(_familyBillFromJson).toList(),
      memoryMoments: [
        ...?memoriesJson?.map((e) => _memoryMomentFromJson(e, residentMap)),
        ...?familyBridgeMediaJson
            ?.map((e) => _memoryMomentFromFamilyMedia(e, residentMap)),
      ],
      memories: [
        ...?memoriesJson?.map(_memoryItemFromJson),
        ...?familyBridgeMediaJson?.map(_memoryItemFromFamilyMedia),
      ],
      voiceMessages: voiceMessagesJson?.map(_voiceMessageFromJson).toList(),
      careTasks:
          careTasksJson?.map((e) => _careTaskFromJson(e, residentMap)).toList(),
      inventoryItems: inventoryJson?.map(_inventoryItemFromJson).toList(),
      doctorVisits: doctorVisitsJson
          ?.map((e) => _doctorVisitFromJson(e, residentMap))
          .toList(),
      mealPlans:
          mealPlansJson?.map((e) => _mealPlanFromJson(e, residentMap)).toList(),
      mealPlanIdsByResidentName: _mealPlanIdMap(mealPlansJson, residentMap),
      medicalSessions: sessionsJson
          ?.map((e) => _medicalSessionFromJson(e, residentMap))
          .toList(),
      medicalPrescriptions: prescriptionsJson
          ?.map((e) => _medicalPrescriptionFromJson(e, residentMap))
          .toList(),
      volunteerOpportunities:
          opportunitiesJson?.map(_volunteerOpportunityFromJson).toList(),
      volunteerBookings: bookingsJson?.map(_volunteerBookingFromJson).toList(),
      volunteerCertificates:
          certificatesJson?.map(_volunteerCertificateFromJson).toList(),
      volunteerRatings: ratingsJson?.map(_volunteerRatingFromJson).toList(),
      volunteerReviews: reviewsJson?.map(_volunteerReviewFromJson).toList(),
      volunteerProfile:
          profileJson == null ? null : _volunteerProfileFromJson(profileJson),
      notifications: notificationsJson?.map(_notificationFromJson).toList(),
      nursingNotes: nursingNotesJson
          ?.map((e) => _nursingNoteFromJson(e, residentMap))
          .toList(),
      handoffs: handoffsJson?.map(_handoffFromJson).toList(),
      socialNeeds: socialNeedsJson?.map(_socialNeedFromJson).toList(),
      socialAssessmentTools:
          socialToolsJson?.map(_socialAssessmentToolFromJson).toList(),
      socialResidentScores:
          socialScoresJson?.map(_socialResidentScoreFromJson).toList(),
      staffPerformance: staffPerformanceJson
          ?.map(_staffPerformanceFromJson)
          .toList()
          .where((staff) => _isValidStaff(staff))
          .toList(),
      sentReports: sentReportsJson?.map(_sentReportFromJson).toList(),
      careReportPreview:
          careReportJson == null ? null : _careReportFromJson(careReportJson),
      familyHealthMetrics: primaryResidentId == null && requireResidentScope
          ? const []
          : _familyHealthMetricsFromVitals(vitalsJson),
      familyMembers: familyMembers,
      assessmentHistory:
          assessmentHistoryJson?.map(_assessmentHistoryEntryFromJson).toList(),
    );
  }

  AssessmentHistoricalEntry _assessmentHistoryEntryFromJson(
      Map<String, dynamic> j) {
    return AssessmentHistoricalEntry(
      date: _s(j['date'], fallback: _s(j['createdAt']).split('T').first),
      score: (j['score'] as num?)?.toDouble() ?? 0.0,
      total: _s(j['total'], fallback: '100'),
      trend: _s(j['trend'], fallback: 'stable'),
    );
  }

  FamilyMember _familyMemberFromJson(Map<String, dynamic> j) {
    final name = _s(j['fullName'], fallback: 'قريب');
    final relation = _s(j['relationship'], fallback: 'other');
    final userId = () {
      final v = _s(j['userId'] ?? j['cognitoSub'] ?? j['user_id']);
      return v.isEmpty ? null : v;
    }();
    final email = _s(j['email']);
    final rawInviteStatus = _s(j['inviteStatus'] ?? j['invite_status']);
    final inviteStatus = rawInviteStatus.isNotEmpty
        ? rawInviteStatus
        : email.isEmpty
            ? 'none'
            : userId == null
                ? 'pending'
                : 'confirmed';
    return FamilyMember(
      id: _s(j['id']),
      residentId: _s(j['residentId'] ?? j['resident_id']),
      name: name,
      userId: userId,
      relation: switch (relation.toLowerCase()) {
        'son' => 'ابن',
        'daughter' => 'ابنة',
        'spouse' => 'زوج/ة',
        'brother' => 'أخ',
        'sister' => 'أخت',
        'father' => 'والد',
        'mother' => 'والدة',
        'friend' => 'صديق',
        _ => relation,
      },
      avatarPath: '',
      initials: _initials(name),
      phoneNumber: _s(j['phone'], fallback: ''),
      email: email.isEmpty ? null : email,
      inviteStatus: inviteStatus,
      zoomLink: _s(j['zoomLink']).isEmpty ? null : _s(j['zoomLink']),
      isAvailable: false,
      isPinned: j['isPrimary'] == true,
    );
  }

  Future<List<Map<String, dynamic>>?> _familyMembersForResidents(
    List<Map<String, dynamic>> residents,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (final resident in residents) {
      final residentId = _s(resident['id']);
      if (residentId.isEmpty) continue;
      final members = await _list(
        '/family-members',
        query: {'residentId': residentId},
      );
      if (members == null) continue;
      result.addAll(members);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>?> _list(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await ApiClient.instance
          .get(path, query: query)
          .timeout(_softRequestTimeout);
      if (res is! List) return const [];
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _map(String path) async {
    try {
      final res =
          await ApiClient.instance.get(path).timeout(_softRequestTimeout);
      if (res is! Map) return null;
      return Map<String, dynamic>.from(res);
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<String?> _notificationUserId() async {
    final token = await ApiClient.instance.getToken();
    if (token == null) return null;
    final payload = _decodeJwtPayload(token);
    final sub = _s(payload['sub']);
    return sub.isEmpty ? null : sub;
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return {};
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    try {
      final decoded = utf8.decode(const Base64Decoder().convert(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Map<String, String> _residentNameMap(List<Map<String, dynamic>>? rows) {
    return {
      for (final r in rows ?? const <Map<String, dynamic>>[])
        _s(r['id']): '${_s(r['firstName'])} ${_s(r['lastName'])}'.trim(),
    };
  }

  String? _resolvePrimaryResidentId(
    List<Map<String, dynamic>>? rows,
    String? requestedResidentId, {
    required bool requireResidentScope,
  }) {
    final requested = _s(requestedResidentId);
    if (requested.isNotEmpty) {
      return requested;
    }
    if (requireResidentScope) {
      return null;
    }
    if (rows?.isNotEmpty == true) {
      final id = _s(rows!.first['id']);
      return id.isEmpty ? null : id;
    }
    return null;
  }

  Map<String, String>? _mealPlanIdMap(
    List<Map<String, dynamic>>? rows,
    Map<String, String> residentMap,
  ) {
    if (rows == null) return null;
    return {
      for (final row in rows)
        residentMap[_s(row['residentId'])] ?? _s(row['residentId']):
            _s(row['id']),
    };
  }

  SpecialistResidentFile _residentFileFromJson(Map<String, dynamic> j) {
    final nameEn = '${_s(j['firstName'])} ${_s(j['lastName'])}'.trim();
    // الاسم العربي — يُفضَّل من حقل arabicName أو firstNameAr/lastNameAr
    final nameArFirst = _s(j['firstNameAr'] ?? j['arabicFirstName'] ?? '');
    final nameArLast = _s(j['lastNameAr'] ?? j['arabicLastName'] ?? '');
    final nameAr = '$nameArFirst $nameArLast'.trim();
    final name =
        nameAr.isNotEmpty ? nameAr : (nameEn.isEmpty ? 'مقيم' : nameEn);
    final nickname = _s(j['nickname'] ?? j['preferredName'] ?? '');
    return SpecialistResidentFile(
      id: _s(j['id']),
      name: name,
      nameEn: nameEn.isEmpty ? name : nameEn,
      nickname: nickname.isEmpty ? null : nickname,
      room: _s(j['roomNumber'], fallback: '-'),
      status: _s(j['status'], fallback: 'active') == 'active'
          ? 'updated'
          : _s(j['status']),
      lastUpdate: 'من السيرفر',
      categories: const ['medical', 'social'],
      initials: _initials(name),
      age: _age(_s(j['dateOfBirth'])),
      phone: _s(j['phone'], fallback: ''),
      nationalId: _s(j['nationalId'], fallback: ''),
      gender: _s(j['gender'], fallback: ''),
      emergencyContactName: _s(j['emergencyContactName'], fallback: ''),
      emergencyContactPhone: _s(j['emergencyContactPhone'], fallback: ''),
      emergencyRelation: _s(j['emergencyRelation'], fallback: ''),
      bloodType: _s(j['bloodType'], fallback: 'غير محدد'),
      chronicDiseases: _csv(j['chronicDiseases']),
      allergies: _csv(j['allergies']),
      insuranceInfo: _s(j['insuranceInfo'], fallback: ''),
      primaryDoctorName: _s(j['primaryDoctorName'], fallback: ''),
      mobilityStatus: _s(j['mobilityStatus'], fallback: 'غير محدد'),
      assistiveDevices: _csv(j['assistiveDevices']),
      cognitiveStatus: _s(j['cognitiveStatus'], fallback: ''),
      dietType: _s(j['dietType'], fallback: 'عادي'),
      foodRestrictions: _csv(j['foodRestrictions']),
      foodPreferences: _s(j['foodPreferences'], fallback: ''),
      previousProfession: _s(j['previousProfession'], fallback: ''),
      hobbies: _csv(j['hobbies']),
      socialStatus: _s(j['socialStatus'], fallback: ''),
      uploadedDocuments: const [],
      imageUrl: _s(j['imageUrl'], fallback: ''),
    );
  }

  Resident _residentFromJson(Map<String, dynamic> j) {
    final name = '${_s(j['firstName'])} ${_s(j['lastName'])}'.trim();
    return Resident(
      id: _s(j['id']),
      name: name.isEmpty ? 'مقيم' : name,
      roomNumber: _s(j['roomNumber'], fallback: '-'),
      gender: _s(j['gender'], fallback: 'غير محدد'),
      birthDate: _date(_s(j['dateOfBirth']), fallbackYear: 1945),
      entryDate: _date(_s(j['admissionDate'])),
      nationalId: _s(j['nationalId'], fallback: ''),
      imageUrl: _s(j['imageUrl'], fallback: ''),
      emergencyContactName: _s(j['emergencyContactName'], fallback: 'غير محدد'),
      emergencyContactPhone: _s(j['emergencyContactPhone'], fallback: ''),
      emergencyRelation: _s(j['emergencyRelation'], fallback: ''),
      bloodType: _s(j['bloodType'], fallback: 'غير محدد'),
      allergies: _csv(j['allergies']),
      chronicDiseases: _csv(j['chronicDiseases']),
      insuranceInfo: _s(j['insuranceInfo'], fallback: 'غير محدد'),
      primaryDoctorName: _s(j['primaryDoctorName'], fallback: ''),
      mobilityStatus: _s(j['mobilityStatus'], fallback: 'غير محدد'),
      assistiveDevices: _csv(j['assistiveDevices']),
      cognitiveStatus: _s(j['cognitiveStatus'], fallback: 'غير محدد'),
      dietType: _s(j['dietType'], fallback: 'عادي'),
      foodRestrictions: _csv(j['foodRestrictions']),
      foodPreferences: _s(j['foodPreferences'], fallback: ''),
      previousProfession: _s(j['previousProfession'], fallback: ''),
      hobbies: _csv(j['hobbies']),
      socialStatus: _s(j['socialStatus'], fallback: ''),
      contractType: 'شهري',
    );
  }

  List<Medication>? _medicationsFromJson(
    List<Map<String, dynamic>>? schedules,
    List<Map<String, dynamic>>? doseLogs,
    List<Map<String, dynamic>>? overdue,
    Map<String, String> residentMap,
  ) {
    if (schedules == null && doseLogs == null && overdue == null) return null;
    final meds = <Medication>[];
    final doseLogsBySlot = <String, Map<String, dynamic>>{};
    final representedDoseIds = <String>{};
    for (final row in doseLogs ?? const <Map<String, dynamic>>[]) {
      final keys = _doseSlotKeys(
        _s(row['scheduleId'] ?? row['schedule_id']),
        _dateTime(_s(row['scheduledTime'] ?? row['scheduled_time'])),
      );
      for (final key in keys) {
        doseLogsBySlot.putIfAbsent(key, () => row);
      }
    }
    for (final row in schedules ?? const <Map<String, dynamic>>[]) {
      final times = _listOfStrings(row['scheduledTimes']);
      final effectiveTimes = times.isEmpty ? [''] : times;
      for (final time in effectiveTimes) {
        final scheduleId = _s(row['id']);
        final residentId = _s(row['residentId']);
        final scheduledTime = _todayAt(time);
        final log = doseLogsBySlot[_doseSlotKey(scheduleId, scheduledTime)];
        final logId = log == null ? '' : _s(log['id']);
        final status = log == null ? '' : _s(log['status']);
        final notes = log == null ? '' : _s(log['notes']);
        final isGiven = status == 'given';
        final isSkipped = status == 'skipped';
        final isResidentConfirmed =
            isGiven || (status == 'pending' && _isResidentConfirmedDose(notes));
        if (logId.isNotEmpty) {
          representedDoseIds.add(logId);
        }
        meds.add(Medication(
          id: logId.isNotEmpty
              ? 'dose|$logId|$residentId'
              : 'schedule|$scheduleId|$residentId|$time',
          name: _s(row['medicationName'], fallback: 'دواء'),
          dosage: _s(row['dosage'], fallback: ''),
          timeDescription: time.isEmpty ? _s(row['frequency']) : time,
          timeOfDay: _timeOfDay(time),
          isTaken: isGiven,
          isElderlyConfirmed: isResidentConfirmed,
          isSkipped: isSkipped,
          skipReason: isSkipped ? notes : null,
          residentName: residentMap[residentId],
          scheduledTime: scheduledTime,
          dayTag: 'اليوم',
          mealRelation: () {
            final v = _s(row['mealRelation'] ??
                row['meal_relation'] ??
                row['instructions']);
            return v.isEmpty ? null : v;
          }(),
        ));
      }
    }
    for (final row in overdue ?? const <Map<String, dynamic>>[]) {
      final doseId = _s(row['id']);
      if (representedDoseIds.contains(doseId)) continue;
      final status = _s(row['status']);
      final notes = _s(row['notes']);
      meds.add(Medication(
        id: 'dose|$doseId|${_s(row['residentId'])}',
        name: _s(row['medicationName'], fallback: 'جرعة متأخرة'),
        dosage: _s(row['dosage'], fallback: ''),
        timeDescription: _time(_s(row['scheduledTime'])),
        timeOfDay: _timeOfDay(_time(_s(row['scheduledTime']))),
        isTaken: status == 'given',
        isElderlyConfirmed:
            status == 'given' || _isResidentConfirmedDose(notes),
        isSkipped: status == 'skipped',
        skipReason: status == 'skipped' ? notes : null,
        residentName: residentMap[_s(row['residentId'])] ??
            '${_s(row['firstName'])} ${_s(row['lastName'])}'.trim(),
        scheduledTime: _dateTime(_s(row['scheduledTime'])),
        dayTag: 'اليوم',
      ));
    }
    return meds;
  }

  String? _doseSlotKey(String scheduleId, DateTime? scheduledTime) {
    if (scheduleId.isEmpty || scheduledTime == null) return null;
    final date = _dateOnly(scheduledTime);
    final hour = scheduledTime.hour.toString().padLeft(2, '0');
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    return '$scheduleId|$date|$hour:$minute';
  }

  List<String> _doseSlotKeys(String scheduleId, DateTime? scheduledTime) {
    final primary = _doseSlotKey(scheduleId, scheduledTime);
    if (primary == null || scheduledTime == null) return const [];
    final local = _doseSlotKey(scheduleId, scheduledTime.toLocal());
    return {
      primary,
      if (local != null) local,
    }.toList();
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  bool _isResidentConfirmedDose(String notes) {
    final normalized = notes.toLowerCase();
    return normalized.contains('resident_confirmed_pending_nurse') ||
        normalized.contains('elderly_confirmed') ||
        notes.contains('المقيم أكد');
  }

  Activity _activityFromJson(Map<String, dynamic> j) {
    final start = _dateTime(_s(j['startTime'])) ?? DateTime.now();
    return Activity(
      id: _s(j['id']),
      name: _s(j['title'], fallback: 'نشاط'),
      emoji: '✨',
      location: _s(j['location'], fallback: 'الدار'),
      time: _timeFromDate(start),
      status: start.isBefore(DateTime.now()) ? 'done' : 'coming',
      badges: 'السيرفر',
      pointsReward: 10,
      supervisor: _s(
        j['createdByName'] ?? j['supervisorName'] ?? j['supervisor_name'],
        fallback: '',
      ),
      type: 'نشاط',
    );
  }

  ActivitySession _activitySessionFromJson(Map<String, dynamic> j) {
    return ActivitySession(
      id: _s(j['id']),
      title: _s(j['title'], fallback: 'نشاط'),
      description: _s(j['description'], fallback: ''),
      startTime: _dateTime(_s(j['startTime'])) ?? DateTime.now(),
      location: _s(j['location'], fallback: 'الدار'),
      participants: _listOfStrings(j['participants']),
    );
  }

  SocialSpecialistComplaint _complaintFromJson(
    Map<String, dynamic> j,
    Map<String, String> residentMap,
  ) {
    final status = _s(j['status'], fallback: 'open');
    return SocialSpecialistComplaint(
      id: _s(j['id']),
      title: _s(j['subject'], fallback: 'شكوى'),
      residentName: residentMap[_s(j['residentId'])] ?? _s(j['residentId']),
      room: '',
      date: _dateLabel(_s(j['createdAt'])),
      priority: _s(j['priority'], fallback: 'medium'),
      status: switch (status) {
        'in_progress' => 'progress',
        'resolved' || 'closed' => 'done',
        _ => 'open',
      },
      category: _s(j['category'], fallback: 'service'),
      icon: '📣',
      timeline: [
        ComplaintStep(
          text: 'تم تسجيل الشكوى',
          time: _dateLabel(_s(j['createdAt'])),
          status: 'done',
        ),
        if (status == 'resolved' || status == 'closed')
          ComplaintStep(
            text: _s(j['resolutionNotes'], fallback: 'تمت المعالجة'),
            time: _dateLabel(_s(j['resolvedAt'])),
            status: 'done',
          ),
      ],
    );
  }

  FamilyVisit _familyVisitFromJson(Map<String, dynamic> j) {
    final status = _s(j['status'], fallback: 'pending');
    final rawType = _s(j['visitType'] ?? j['type'] ?? j['notes']);
    final isVideo = rawType.contains('video') ||
        rawType.contains('virtual') ||
        rawType.contains('zoom');
    final zoomRaw = _s(j['zoomLink'] ?? j['zoom_link']);
    final zoomLink = zoomRaw.isEmpty ? null : zoomRaw;
    return FamilyVisit(
      id: _s(j['id']),
      date: _dateLabel(_s(j['visitDate'])),
      time: _s(j['visitTimeStart'], fallback: ''),
      visitorName: _s(j['visitorName'], fallback: 'زائر'),
      status: switch (status) {
        'approved' => 'upcoming',
        'completed' => 'completed',
        'rejected' || 'cancelled' => 'cancelled',
        _ => 'pending',
      },
      type: isVideo ? 'video' : 'physical',
      scheduledAt: _dateTime(_s(j['visitDate'])),
      zoomLink: zoomLink,
    );
  }

  FamilyBill _familyBillFromJson(Map<String, dynamic> j) {
    return FamilyBill(
      id: _s(j['id']),
      title: _s(j['title'], fallback: 'فاتورة'),
      month: _s(j['month'], fallback: ''),
      amount: _double(j['amount']),
      isPaid: j['isPaid'] == true,
      dueDate: _dateLabel(_s(j['dueDate'])),
    );
  }

  MemoryMoment _memoryMomentFromJson(
    Map<String, dynamic> j,
    Map<String, String> residentMap,
  ) {
    final residentId = _s(j['residentId']);
    final imageUrl = _mediaUrlFromJson(j);
    return MemoryMoment(
      id: _s(j['id']),
      residentId: residentId,
      residentName: residentMap[residentId] ?? residentId,
      imageUrl: imageUrl,
      activityTitle: _s(j['activityTitle'], fallback: 'ذكرى من الدار'),
      date: _dateLabel(_s(j['createdAt'])),
      appreciations: _int(j['appreciations']),
    );
  }

  MemoryItem _memoryItemFromJson(Map<String, dynamic> j) {
    final imageUrl = _mediaUrlFromJson(j);
    return MemoryItem(
      id: _s(j['id']),
      category: 'المسكن',
      title: _s(j['activityTitle'], fallback: 'ذكرى من الدار'),
      date: _dateLabel(_s(j['createdAt'])),
      type: imageUrl.isEmpty ? 'text' : 'image',
      assetPath: imageUrl,
    );
  }

  MemoryMoment _memoryMomentFromFamilyMedia(
    Map<String, dynamic> j,
    Map<String, String> residentMap,
  ) {
    final residentId = _s(j['residentId'] ?? j['resident_id']);
    final mediaUrl = _mediaUrlFromJson(j);
    return MemoryMoment(
      id: 'fb_${_s(j['id'])}',
      residentId: residentId,
      residentName: residentMap[residentId] ?? residentId,
      imageUrl: mediaUrl,
      activityTitle: _s(j['caption'], fallback: 'لحظة عائلية'),
      date: _dateLabel(_s(j['createdAt'] ?? j['created_at'])),
      appreciations: 0,
    );
  }

  MemoryItem _memoryItemFromFamilyMedia(Map<String, dynamic> j) {
    final mediaUrl = _mediaUrlFromJson(j);
    return MemoryItem(
      id: 'fb_${_s(j['id'])}',
      category: 'أسرة',
      title: _s(j['caption'], fallback: 'لحظة عائلية'),
      date: _dateLabel(_s(j['createdAt'] ?? j['created_at'])),
      type: mediaUrl.isEmpty ? 'text' : 'image',
      assetPath: mediaUrl,
    );
  }

  String _mediaUrlFromJson(Map<String, dynamic> j) {
    return _s(
      j['imageUrl'] ??
          j['image_url'] ??
          j['mediaUrl'] ??
          j['media_url'] ??
          j['downloadUrl'] ??
          j['download_url'] ??
          j['presignedUrl'] ??
          j['presigned_url'] ??
          j['fileName'] ??
          j['file_name'] ??
          j['url'],
      fallback: '',
    );
  }

  VoiceMessage _voiceMessageFromJson(Map<String, dynamic> j) {
    final recipientName = _s(
      j['recipientName'] ??
          j['recipient_name'] ??
          j['familyMemberName'] ??
          j['family_member_name'],
    );
    final status = _s(
        j['deliveryStatus'] ?? j['delivery_status'] ?? j['status'],
        fallback: 'sent');
    final moderation = _s(
      j['moderationStatus'] ??
          j['moderation_status'] ??
          j['approvalStatus'] ??
          j['approval_status'],
      fallback: status == 'rejected' ? 'rejected' : 'pending',
    );
    return VoiceMessage(
      id: _s(j['id']),
      senderId: _s(j['senderType'], fallback: 'family'),
      title: _s(j['title'], fallback: 'رسالة صوتية'),
      timeDescription: _dateLabel(_s(j['createdAt'])),
      audioUrl: _s(j['audioUrl']).isEmpty ? null : _s(j['audioUrl']),
      durationSeconds: _int(j['durationSeconds']),
      recipientId: _s(j['recipientId'] ?? j['recipient_id']).isEmpty
          ? _s(j['familyMemberId'] ?? j['family_member_id'])
          : _s(j['recipientId'] ?? j['recipient_id']),
      recipientName: recipientName.isEmpty ? null : recipientName,
      deliveryStatus: status.isEmpty ? 'sent' : status,
      moderationStatus: moderation.isEmpty ? 'pending' : moderation,
    );
  }

  CareTask _careTaskFromJson(
    Map<String, dynamic> j,
    Map<String, String> residentMap,
  ) {
    return CareTask(
      id: _s(j['id']),
      residentName: residentMap[_s(j['residentId'])] ?? _s(j['residentId']),
      title: _s(j['title'], fallback: 'مهمة رعاية'),
      category: switch (_s(j['category'])) {
        'personal' => 'شخصية',
        'recreational' => 'ترفيهية',
        _ => 'فندقية',
      },
      isCompleted: j['isCompleted'] == true,
      time: _time(_s(j['scheduledTime'])),
    );
  }

  InventoryItem _inventoryItemFromJson(Map<String, dynamic> j) {
    return InventoryItem(
      id: _s(j['id']),
      name: _s(j['name'], fallback: 'صنف'),
      category: switch (_s(j['category'])) {
        'medications' => 'أدوية',
        'personal' => 'شخصي',
        _ => 'مستلزمات',
      },
      currentStock: _int(j['currentStock']),
      minRequired: _int(j['minRequired']),
      unit: _s(j['unit'], fallback: 'قطعة'),
    );
  }

  DoctorVisit _doctorVisitFromJson(
    Map<String, dynamic> j,
    Map<String, String> residentMap,
  ) {
    return DoctorVisit(
      id: _s(j['id']),
      doctorName: _s(j['doctorName'], fallback: 'طبيب'),
      specialty: _s(j['specialty'], fallback: ''),
      date: _date(_s(j['visitDate'])),
      purpose: _s(j['purpose'], fallback: ''),
      results: _s(j['results'], fallback: ''),
      residentName: residentMap[_s(j['residentId'])] ?? _s(j['residentId']),
    );
  }

  MealPlan _mealPlanFromJson(
    Map<String, dynamic> j,
    Map<String, String> residentMap,
  ) {
    return MealPlan(
      residentName: residentMap[_s(j['residentId'])] ?? _s(j['residentId']),
      breakfast: _s(j['breakfast'], fallback: ''),
      lunch: _s(j['lunch'], fallback: ''),
      dinner: _s(j['dinner'], fallback: ''),
      specialInstructions: _s(j['specialInstructions'], fallback: ''),
    );
  }

  MedicalSession _medicalSessionFromJson(
    Map<String, dynamic> j,
    Map<String, String> residentMap,
  ) {
    return MedicalSession(
      id: _s(j['id']),
      type: _s(j['type'], fallback: 'doctor'),
      specialistName: _s(j['specialistName'], fallback: 'الفريق الطبي'),
      time: _s(j['sessionTime'], fallback: _time(_s(j['sessionDate']))),
      date: _dateLabel(_s(j['sessionDate'])),
      notes: _s(j['notes'], fallback: ''),
      residentName: residentMap[_s(j['residentId'])] ?? _s(j['residentId']),
    );
  }

  MedicalPrescription _medicalPrescriptionFromJson(
    Map<String, dynamic> j,
    Map<String, String> residentMap,
  ) {
    return MedicalPrescription(
      id: _s(j['id']),
      title: _s(j['title'], fallback: 'وصفة طبية'),
      doctorName: _s(j['doctorName'], fallback: 'طبيب'),
      date: _dateLabel(_s(j['prescriptionDate'])),
      residentName: residentMap[_s(j['residentId'])] ?? _s(j['residentId']),
      imagePath: _s(j['fileUrl'], fallback: ''),
    );
  }

  VolunteerOpportunity _volunteerOpportunityFromJson(Map<String, dynamic> j) {
    return VolunteerOpportunity(
      id: _s(j['id']),
      title: _s(j['title'], fallback: 'فرصة تطوع'),
      org: _s(j['org'], fallback: 'دار الرعاية'),
      dateInfo: _s(j['dateInfo'], fallback: ''),
      icon: '🤝',
      tags: _listOfStrings(j['tags']),
      hours: _int(j['hours']),
      description: _s(j['description'], fallback: ''),
      totalSlots: _int(j['totalSlots'], fallback: 1),
      filledSlots: _int(j['filledSlots']),
      points: _int(j['points'], fallback: 10),
    );
  }

  VolunteerBooking _volunteerBookingFromJson(Map<String, dynamic> j) {
    final date = _dateTime(_s(j['createdAt'])) ?? DateTime.now();
    return VolunteerBooking(
      id: _s(j['id']),
      title: _s(j['title'], fallback: 'حجز تطوع'),
      timeInfo: _s(j['timeInfo'], fallback: _dateLabel(_s(j['createdAt']))),
      day: date.day,
      month: '${date.month}',
      status: _s(j['status'], fallback: 'confirmed'),
      location: _s(j['location'], fallback: ''),
      points: _int(j['points'], fallback: 10),
      startTime: date,
    );
  }

  VolunteerCertificate _volunteerCertificateFromJson(Map<String, dynamic> j) {
    final progress = _double(j['progress']);
    return VolunteerCertificate(
      id: _s(j['id']),
      name: _s(j['name'], fallback: 'شهادة تطوع'),
      icon: '🏅',
      date: _dateLabel(_s(j['awardDate'])),
      isLocked: j['isLocked'] == true,
      description: _s(j['description'], fallback: ''),
      progress: progress,
      progressInfo: '${(progress * 100).round()}%',
    );
  }

  VolunteerRating _volunteerRatingFromJson(Map<String, dynamic> j) {
    return VolunteerRating(
      id: _s(j['id']),
      fromName: _s(j['fromName'], fallback: 'مقيم'),
      category: _s(j['category'], fallback: 'عام'),
      score: _double(j['score']),
      comment: _s(j['comment'], fallback: ''),
      date: _dateLabel(_s(j['date'])),
      chips: _listOfStrings(j['chips']),
      criteriaScores: _mapOfDouble(j['criteriaScores']),
    );
  }

  VolunteerReview _volunteerReviewFromJson(Map<String, dynamic> j) {
    return VolunteerReview(
      id: _s(j['id']),
      toName: _s(j['toName'], fallback: 'مقيم'),
      session: _s(j['session'], fallback: 'جلسة تطوع'),
      date: _dateLabel(_s(j['date'])),
      score: _double(j['score']),
      isPending: j['isPending'] == true,
    );
  }

  VolunteerProfile _volunteerProfileFromJson(Map<String, dynamic> j) {
    final links = j['socialLinks'] is Map ? j['socialLinks'] as Map : const {};
    String? optionalString(dynamic value) {
      final text = _s(value, fallback: '');
      return text.isEmpty ? null : text;
    }

    return VolunteerProfile(
      name: _s(j['name'], fallback: 'متطوع'),
      location: _s(j['location'], fallback: ''),
      bio: _s(j['bio'], fallback: ''),
      skills: _listOfStrings(j['skills']),
      linkedinUrl: _s(links['linkedin'], fallback: ''),
      facebookUrl: _s(links['facebook'], fallback: ''),
      instagramUrl: _s(links['instagram'], fallback: ''),
      cvFileName: optionalString(j['cvFileUrl']),
      recommendationFileName: optionalString(j['recommendationFileUrl']),
    );
  }

  TaptabaNotification _notificationFromJson(Map<String, dynamic> j) {
    return TaptabaNotification(
      id: _s(j['id']),
      title: _s(j['message'], fallback: 'إشعار'),
      body: _s(j['message'], fallback: ''),
      time: _dateLabel(_s(j['createdAt'])),
      type: _s(j['type'], fallback: 'system'),
      targetRole: 'all',
      isRead: j['read'] == true,
    );
  }

  NursingNote _nursingNoteFromJson(
    Map<String, dynamic> j,
    Map<String, String> residentMap,
  ) {
    final category = _s(j['category'], fallback: 'routine');
    return NursingNote(
      id: _s(j['id']),
      residentName: residentMap[_s(j['residentId'])] ?? _s(j['residentId']),
      title: switch (category) {
        'medication' => 'ملاحظة دواء',
        'vitals' => 'ملاحظة قياسات',
        'incident' => 'ملاحظة حالة',
        _ => 'ملاحظة تمريض',
      },
      content: _s(j['content'], fallback: ''),
      author: _s(
        j['authorName'] ?? j['author_name'] ?? j['createdByName'],
        fallback: 'فريق التمريض',
      ),
      timestamp: _dateTime(_s(j['createdAt'])) ?? DateTime.now(),
    );
  }

  ShiftHandoff _handoffFromJson(Map<String, dynamic> j) {
    return ShiftHandoff(
      nurseName: _s(
        j['outgoingNurseName'] ?? j['nurseName'] ?? j['nurse_name'],
        fallback: 'ممرض',
      ),
      shiftType: _s(j['shiftType'], fallback: 'morning'),
      notes: _s(j['summary'], fallback: ''),
      timestamp: _dateTime(_s(j['createdAt'])) ??
          _dateTime(_s(j['shiftDate'])) ??
          DateTime.now(),
      criticalCases: [
        ..._listOfStrings(j['residentsCovered']),
        ..._listOfStrings(j['pendingTasks']),
      ],
    );
  }

  SocialSpecialistNeed _socialNeedFromJson(Map<String, dynamic> j) {
    return SocialSpecialistNeed(
      id: _s(j['id']),
      type: _s(j['type'], fallback: 'عام'),
      roomNumber: _s(j['roomNumber'], fallback: ''),
      isUrgent: j['isUrgent'] == true,
      label: _s(j['label'], fallback: ''),
    );
  }

  SocialSpecialistAssessmentTool _socialAssessmentToolFromJson(
    Map<String, dynamic> j,
  ) {
    return SocialSpecialistAssessmentTool(
      id: _s(j['id']),
      name: _s(j['name'], fallback: 'أداة تقييم'),
      subtitle: _s(j['subtitle'], fallback: ''),
      score: _s(j['score'], fallback: ''),
      status: _s(j['status'], fallback: ''),
      icon: _resolveToolIcon(_s(j['icon'], fallback: 'assessment')),
    );
  }

  SocialSpecialistResidentScore _socialResidentScoreFromJson(
    Map<String, dynamic> j,
  ) {
    final firstName = _s(j['firstName'] ?? j['first_name']);
    final lastName = _s(j['lastName'] ?? j['last_name']);
    final fullName =
        firstName.isNotEmpty ? '$firstName $lastName'.trim() : _s(j['name']);
    final name = fullName.isEmpty ? 'مقيم' : fullName;
    final lastAssessment = _dateTime(_s(j['lastAssessment'])) ?? DateTime.now();
    return SocialSpecialistResidentScore(
      id: _s(j['id']),
      name: name,
      initials: _s(j['initials'], fallback: _initials(name)),
      room: _s(j['room'], fallback: ''),
      date: _s(j['date'], fallback: _dateLabel(_s(j['lastAssessment']))),
      scores: _mapOfDouble(j['scores']),
      isUrgent: j['isUrgent'] == true,
      healthStatus: _s(j['healthStatus'], fallback: 'stable'),
      lastAssessment: lastAssessment,
    );
  }

  StaffPerformance _staffPerformanceFromJson(Map<String, dynamic> j) {
    return StaffPerformance(
      id: _s(j['userId'], fallback: _s(j['id'])),
      name: _s(j['name'], fallback: 'عضو فريق'),
      role: _s(j['role'], fallback: ''),
      completionRate: _double(j['completionRate']) / 100,
      lastActive: _s(j['lastActive'], fallback: 'من السيرفر'),
      status: j['isOnline'] == true ? 'online' : 'offline',
      imageUrl: _s(j['imageUrl'], fallback: ''),
    );
  }

  bool _isValidStaff(StaffPerformance staff) {
    // Filter out fake/invalid staff accounts
    // Remove entries where name is empty, contains only placeholder characters, or default text
    final name = staff.name.trim();

    // Check if name is empty or very short
    if (name.isEmpty || name.length < 2) return false;

    // Check if name contains mostly question marks or special placeholder characters
    final questionMarkCount = name.split('').where((c) => c == '?').length;
    if (questionMarkCount > (name.length / 2)) return false;

    // Check if name is default/placeholder text
    if (name == 'عضو فريق' || name == 'من السيرفر' || name.startsWith('????')) {
      return false;
    }

    // Valid staff account
    return true;
  }

  SentReport _sentReportFromJson(Map<String, dynamic> j) {
    final rawType = _s(j['reportType'], fallback: '');
    final createdAt = _s(j['createdAt']);
    final dateStr = _dateLabel(createdAt);
    final titleDate = _fullArabicDateLabel(createdAt);
    final arabicTitle = _reportTypeArabic(rawType, titleDate);
    final icon = _reportTypeIcon(rawType);
    return SentReport(
      id: _s(j['id']),
      icon: icon,
      title: arabicTitle,
      meta: _listOfStrings(j['recipients']).join(', '),
      status: _s(j['status'], fallback: ''),
      date: createdAt.isEmpty ? dateStr : createdAt,
    );
  }

  String _fullArabicDateLabel(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value.isEmpty ? 'من السيرفر' : value;
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  String _reportTypeArabic(String rawType, String date) {
    switch (rawType.toLowerCase()) {
      case 'daily':
        return 'تقرير يومي لتاريخ $date';
      case 'weekly':
        return 'تقرير أسبوعي لتاريخ $date';
      case 'medication':
        return 'تقرير أدوية لتاريخ $date';
      case 'critical':
      case 'critical_alert':
        return 'تنبيه حرج لتاريخ $date';
      default:
        return rawType.isNotEmpty ? '$rawType — $date' : 'تقرير تمريضي — $date';
    }
  }

  String _reportTypeIcon(String rawType) {
    switch (rawType.toLowerCase()) {
      case 'weekly':
        return '📊';
      case 'medication':
        return '💊';
      case 'critical':
      case 'critical_alert':
        return '🚨';
      default:
        return '📋';
    }
  }

  CareReport _careReportFromJson(Map<String, dynamic> j) {
    final notes = _listOfStrings(j['notes']);

    // Parse metrics list of {label, value} objects into "label: value" lines
    final rawMetrics = j['metrics'];
    final metricsLines = <String>[];
    final metricsMap = <String, String>{};
    if (rawMetrics is List) {
      for (final m in rawMetrics) {
        if (m is Map) {
          final label = (m['label'] ?? '').toString();
          final value = (m['value'] ?? '').toString();
          if (label.isNotEmpty) {
            metricsLines.add('$label: $value');
            metricsMap[label] = value;
          }
        }
      }
    }

    // Derive interaction level from medication compliance metric
    final complianceRaw =
        (metricsMap['الالتزام بالأدوية'] ?? '').replaceAll('%', '').trim();
    final compliance = int.tryParse(complianceRaw) ?? -1;
    final interactionLevel = compliance < 0
        ? '—'
        : compliance >= 90
            ? 'ممتاز'
            : compliance >= 70
                ? 'جيد'
                : 'متوسط';

    // Derive mood from critical alerts metric
    final criticalRaw =
        metricsMap['حالات حرجة نشطة'] ?? metricsMap['حالات حرجة'] ?? '0';
    final critical = int.tryParse(criticalRaw.trim()) ?? 0;
    final moodStatus = critical == 0 ? 'مستقر' : 'يحتاج متابعة';

    // Report type label
    final reportType = _s(j['reportType'], fallback: 'daily');
    final authorRole = switch (reportType) {
      'weekly' => 'التقرير الأسبوعي',
      'critical' => 'تنبيه حرج',
      'medications' => 'تقرير الأدوية',
      _ => 'التقرير اليومي',
    };

    return CareReport(
      id: reportType,
      title: _s(j['title'], fallback: 'تقرير رعاية'),
      date: _dateLabel(_s(j['generatedAt'])),
      summary: _s(j['summary'], fallback: ''),
      socialNotes: notes.join('\n'),
      recommendations: metricsLines.join('\n'),
      authorName: 'نظام الرعاية',
      authorRole: authorRole,
      interactionLevel: interactionLevel,
      moodStatus: moodStatus,
    );
  }

  List<FamilyHealthMetric>? _familyHealthMetricsFromVitals(
    List<Map<String, dynamic>>? rows,
  ) {
    if (rows == null || rows.isEmpty) return null;
    // أحدث 3 قراءات
    final recent = rows.reversed.take(3).toList();

    double norm(num? v, double center, double spread) {
      if (v == null) return 0.7;
      return (1.0 - ((v - center).abs() / spread)).clamp(0.0, 1.0);
    }

    String vitalStatus(double v) =>
        v >= 0.7 ? 'good' : (v >= 0.45 ? 'medium' : 'low');

    String vitalTrend(List<double> h) {
      if (h.length < 2) return 'stable';
      final diff = h.last - h.first;
      if (diff > 0.05) return 'up';
      if (diff < -0.05) return 'down';
      return 'stable';
    }

    List<double> vitalHistory(num? Function(Map<String, dynamic>) extract,
        double center, double spread) {
      return recent
          .map((r) => norm(extract(r), center, spread))
          .toList()
          .reversed
          .toList();
    }

    final hrHistory = vitalHistory((r) => r['heartRate'] as num?, 75, 40);
    final o2History =
        vitalHistory((r) => r['oxygenSaturation'] as num?, 97.5, 17.5);
    final tempHistory =
        vitalHistory((r) => r['temperature'] as num?, 36.8, 2.5);
    final bpHistory =
        vitalHistory((r) => r['bloodPressureSystolic'] as num?, 125, 55);

    return [
      FamilyHealthMetric(
        label: 'المزاج العام',
        value: tempHistory.last,
        status: vitalStatus(tempHistory.last),
        trend: vitalTrend(tempHistory),
        history: tempHistory,
      ),
      FamilyHealthMetric(
        label: 'النشاط البدني',
        value: hrHistory.last,
        status: vitalStatus(hrHistory.last),
        trend: vitalTrend(hrHistory),
        history: hrHistory,
      ),
      FamilyHealthMetric(
        label: 'جودة النوم',
        value: o2History.last,
        status: vitalStatus(o2History.last),
        trend: vitalTrend(o2History),
        history: o2History,
      ),
      FamilyHealthMetric(
        label: 'الشهية',
        value: bpHistory.last,
        status: vitalStatus(bpHistory.last),
        trend: vitalTrend(bpHistory),
        history: bpHistory,
      ),
    ];
  }

  // Converts backend icon name strings (e.g. 'family', 'psychology') to the
  // emoji the assessment_view expects, preventing truncated text like "famil".
  String _resolveToolIcon(String raw) {
    if (raw.startsWith('🧠') ||
        raw.startsWith('🤝') ||
        raw.startsWith('🏃') ||
        raw.startsWith('❤️')) {
      return raw; // Already an emoji — pass through
    }
    final lower = raw.toLowerCase();
    if (lower.contains('psych') ||
        lower.contains('mental') ||
        lower.contains('cogni') ||
        lower.contains('brain')) {
      return '🧠';
    }
    if (lower.contains('social') ||
        lower.contains('group') ||
        lower.contains('family') ||
        lower.contains('relation')) {
      return '🤝';
    }
    if (lower.contains('physic') ||
        lower.contains('mobil') ||
        lower.contains('activ') ||
        lower.contains('sport') ||
        lower.contains('exerc')) {
      return '🏃';
    }
    if (lower.contains('health') ||
        lower.contains('vital') ||
        lower.contains('medical') ||
        lower.contains('care')) {
      return '❤️';
    }
    return '📋'; // Generic assessment fallback — renders cleanly
  }

  String _s(Object? value, {String fallback = ''}) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  int _int(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(_s(value)) ?? fallback;
  }

  double _double(Object? value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(_s(value)) ?? fallback;
  }

  List<String> _listOfStrings(Object? value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  List<String> _csv(Object? value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    final text = _s(value);
    if (text.isEmpty) return const [];
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Map<String, double> _mapOfDouble(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, val) => MapEntry(key.toString(), _double(val)));
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'م';
    return parts.take(2).map((p) => String.fromCharCode(p.runes.first)).join();
  }

  int? _age(String? date) {
    final parsed = DateTime.tryParse(date ?? '');
    if (parsed == null) return null;
    final now = DateTime.now();
    var age = now.year - parsed.year;
    if (now.month < parsed.month ||
        (now.month == parsed.month && now.day < parsed.day)) {
      age--;
    }
    return age;
  }

  DateTime _date(String value, {int? fallbackYear}) {
    return DateTime.tryParse(value) ??
        DateTime(fallbackYear ?? DateTime.now().year, 1, 1);
  }

  DateTime? _dateTime(String value) => DateTime.tryParse(value);

  String _dateLabel(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value.isEmpty ? 'من السيرفر' : value;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _time(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return _timeFromDate(parsed);
  }

  String _timeFromDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  DateTime? _todayAt(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _timeOfDay(String value) {
    final hour = int.tryParse(value.split(':').first) ?? 12;
    if (hour < 12) return 'الصباح';
    if (hour < 17) return 'الظهر';
    return 'المساء';
  }
}
