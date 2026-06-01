import '../models/app_models.dart';
import 'api_client.dart';

class BackendMutationService {
  BackendMutationService._();
  static final BackendMutationService instance = BackendMutationService._();

  Future<void> createManagedUser({
    required String email,
    required String fullName,
    required String role,
    String? temporaryPassword,
  }) {
    return ApiClient.instance.post('/admin/users', body: {
      'email': email,
      'fullName': fullName,
      'role': _backendRole(role),
      if (temporaryPassword != null && temporaryPassword.isNotEmpty)
        'temporaryPassword': temporaryPassword,
      'suppressInvite': false,
    });
  }

  Future<void> disableManagedUser(String id) {
    return ApiClient.instance.patch('/admin/users/$id/disable');
  }

  Future<void> updateManagedUser(StaffPerformance staff) {
    return ApiClient.instance.patch('/admin/users/${staff.id}', body: {
      'fullName': staff.name,
      'role': _backendRole(staff.role),
    });
  }

  Future<void> createFamilyMemberForEmail({
    required String residentId,
    String? email,
    String? fullName,
    String relationship = 'عائلة',
  }) {
    final derivedName = fullName?.trim().isNotEmpty == true
        ? fullName!
        : (email != null ? email.split('@').first.trim() : 'فرد العائلة');
    return ApiClient.instance.post('/family-members', body: {
      'residentId': residentId,
      'fullName': derivedName,
      'relationship': relationship,
      if (email != null && email.isNotEmpty) 'email': email,
      'isPrimary': false,
    });
  }

  Future<void> updateFamilyMemberEmail({
    required String memberId,
    required String email,
  }) {
    return ApiClient.instance.patch('/family-members/$memberId', body: {
      'email': email,
    });
  }

  Future<void> deleteFamilyMember(String memberId) {
    return ApiClient.instance.delete('/family-members/$memberId');
  }

  // إنشاء قريب من جهة اتصال الهاتف — يُرجع id الباك اند أو null عند الفشل
  Future<String?> createFamilyMemberFromPhone({
    required String residentId,
    required String name,
    required String phone,
    String relationship = 'family',
  }) async {
    try {
      final res = await ApiClient.instance.post('/family-members', body: {
        'residentId': residentId,
        'fullName': name.trim().isEmpty ? phone : name.trim(),
        'relationship': relationship,
        'phone': phone,
        'isPrimary': false,
      });
      if (res is Map) return res['id']?.toString();
    } catch (_) {}
    return null;
  }

  Future<void> createResident(SpecialistResidentFile resident) {
    final nameParts = resident.name.trim().split(RegExp(r'\s+'));
    return ApiClient.instance.post('/residents', body: {
      'firstName': nameParts.isEmpty ? resident.name : nameParts.first,
      'lastName': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '-',
      'dateOfBirth': _birthDateFromAge(resident.age),
      'gender': 'male',
      'roomNumber': resident.room,
      'admissionDate': _dateOnly(DateTime.now()),
      'status': 'active',
      'notes': resident.categories.join(', '),
    });
  }

  Future<void> updateResident(SpecialistResidentFile resident) {
    final nameParts = resident.name.trim().split(RegExp(r'\s+'));
    return ApiClient.instance.patch('/residents/${resident.id}', body: {
      'firstName': nameParts.isEmpty ? resident.name : nameParts.first,
      'lastName': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '-',
      if (resident.age != null) 'dateOfBirth': _birthDateFromAge(resident.age),
      'roomNumber': resident.room,
      'status': resident.status == 'archived' ? 'discharged' : 'active',
    });
  }

  Future<void> updateMobilityAndCognitive({
    required String residentId,
    required String mobilityStatus,
    required String cognitiveStatus,
  }) {
    return ApiClient.instance.patch('/residents/$residentId', body: {
      'mobilityStatus': mobilityStatus,
      'cognitiveStatus': cognitiveStatus,
    });
  }

  Future<void> updateDiet({
    required String residentId,
    required String dietType,
    required String foodPreferences,
    required List<String> foodRestrictions,
  }) {
    return ApiClient.instance.patch('/residents/$residentId', body: {
      'dietType': dietType,
      'foodPreferences': foodPreferences,
      'foodRestrictions': foodRestrictions,
    });
  }

  Future<void> updateInsurance({
    required String residentId,
    required String insuranceInfo,
    required String primaryDoctorName,
  }) {
    return ApiClient.instance.patch('/residents/$residentId', body: {
      'insuranceInfo': insuranceInfo,
      'primaryDoctorName': primaryDoctorName,
    });
  }

  Future<void> updateSocialHistory({
    required String residentId,
    required String previousProfession,
    required String socialStatus,
    required List<String> hobbies,
  }) {
    return ApiClient.instance.patch('/residents/$residentId', body: {
      'previousProfession': previousProfession,
      'socialStatus': socialStatus,
      'hobbies': hobbies,
    });
  }

  Future<void> updateEmergencyContact({
    required String residentId,
    required String name,
    required String phone,
    required String relation,
  }) {
    return ApiClient.instance.patch('/residents/$residentId', body: {
      'emergencyContactName': name,
      'emergencyContactPhone': phone,
      'emergencyRelation': relation,
    });
  }

  Future<void> updateDateOfBirth({
    required String residentId,
    required DateTime dateOfBirth,
  }) {
    return ApiClient.instance.patch('/residents/$residentId', body: {
      'dateOfBirth': _dateOnly(dateOfBirth),
    });
  }

  Future<void> upsertMedicalInfo({
    required String residentId,
    required ResidentMedicalInfo info,
  }) {
    return ApiClient.instance.put('/residents/$residentId/medical-info', body: {
      'diagnoses': info.chronicDiseases,
      'allergies': info.allergies,
      'chronicConditions': info.chronicDiseases,
    });
  }

  Future<void> createMedicationSchedule({
    required String residentId,
    required Medication medication,
  }) {
    return ApiClient.instance.post('/medications/schedules', body: {
      'residentId': residentId,
      'medicationName': medication.name,
      'dosage': medication.dosage.isEmpty ? 'غير محدد' : medication.dosage,
      'route': 'oral',
      'frequency': 'daily',
      'scheduledTimes': [_hhmm(medication.scheduledTime)],
      'startDate': _dateOnly(DateTime.now()),
      'isActive': true,
      'notes': medication.timeDescription,
    });
  }

  Future<void> createNursingNote({
    required String residentId,
    required NursingNote note,
  }) {
    return ApiClient.instance.post('/nursing-notes', body: {
      'residentId': residentId,
      'content': '${note.title}\n${note.content}',
      'category': 'routine',
    });
  }

  Future<void> createHandoff(ShiftHandoff handoff) {
    return ApiClient.instance.post('/handoffs', body: {
      'incomingNurseId': 'unassigned',
      'shiftDate': _dateOnly(handoff.timestamp),
      'shiftType': _shiftType(handoff.shiftType),
      'summary': handoff.notes,
      'residentsCovered': handoff.criticalCases,
      'pendingTasks': const [],
    });
  }

  Future<void> createActivity(Activity activity) {
    final start = DateTime.now();
    return ApiClient.instance.post('/activities', body: {
      'title': activity.name,
      'description': activity.badges,
      'startTime': start.toIso8601String(),
      'location': activity.location,
      'participants': const [],
    });
  }

  Future<void> updateActivity(Activity activity) {
    final start = DateTime.now();
    return ApiClient.instance.patch('/activities/${activity.id}', body: {
      'title': activity.name,
      'description': activity.badges,
      'startTime': start.toIso8601String(),
      'location': activity.location,
    });
  }

  Future<void> createMedicalSession({
    required String residentId,
    required MedicalSession session,
  }) {
    return ApiClient.instance.post('/medical-sessions', body: {
      'residentId': residentId,
      'type': _medicalSessionType(session.type),
      'specialistName': session.specialistName,
      'sessionDate': _dateOnly(DateTime.now()),
      'sessionTime': _validTime(session.time),
      'notes': session.notes,
    });
  }

  Future<void> createPrescription({
    required String residentId,
    required MedicalPrescription prescription,
  }) {
    return ApiClient.instance.post('/prescriptions', body: {
      'residentId': residentId,
      'title': prescription.title,
      'doctorName': prescription.doctorName,
      'prescriptionDate': _dateOnly(DateTime.now()),
      if (prescription.imagePath != null && prescription.imagePath!.isNotEmpty)
        'fileUrl': prescription.imagePath,
    });
  }

  Future<void> bookVisit({
    required String residentId,
    required FamilyVisit visit,
  }) {
    final visitDate = visit.scheduledAt ?? DateTime.now();
    final start = _validTime(visit.time);
    return ApiClient.instance.post('/family-bridge/visits', body: {
      'residentId': residentId,
      'visitorName': visit.visitorName,
      'visitorRelationship': 'other',
      'visitDate': _dateOnly(visitDate),
      'visitTimeStart': start,
      'visitTimeEnd': _plusOneHour(start),
      'notes': 'visitType:${visit.type}',
    });
  }

  Future<void> approveVisit(String id) {
    return ApiClient.instance.patch('/family-bridge/visits/$id/approve');
  }

  Future<void> rejectVisit(String id) {
    return ApiClient.instance.patch('/family-bridge/visits/$id/reject');
  }

  Future<void> payBill(String id) {
    return ApiClient.instance.patch('/billing/$id/pay');
  }

  Future<void> createSocialNeed(SocialSpecialistNeed need) {
    return ApiClient.instance.post('/social/needs', body: {
      'type': need.type,
      'roomNumber': need.roomNumber,
      'isUrgent': need.isUrgent,
      'label': need.label,
    });
  }

  Future<void> createSocialAssessment({
    required String residentId,
    required Map<String, double> scores,
    required bool needsIntervention,
    String? notes,
  }) {
    return ApiClient.instance.post('/social/assessments', body: {
      'residentId': residentId,
      'scores': scores,
      'needsIntervention': needsIntervention,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<void> createCareTask({
    required String residentId,
    required CareTask task,
  }) {
    return ApiClient.instance.post('/care-tasks', body: {
      'residentId': residentId,
      'title': task.title,
      'category': _careTaskCategory(task.category),
      'scheduledTime': DateTime.now().toIso8601String(),
    });
  }

  Future<void> createActivitySession(ActivitySession session) {
    return ApiClient.instance.post('/activities', body: {
      'title': session.title,
      'description': session.description,
      'startTime': session.startTime.toIso8601String(),
      'location': session.location,
      'participants': session.participants,
    });
  }

  Future<void> completeCareTask(String id) {
    return ApiClient.instance.patch('/care-tasks/$id/complete');
  }

  Future<void> reopenCareTask(String id) {
    return ApiClient.instance.patch('/care-tasks/$id/reopen');
  }

  Future<void> deleteCareTask(String id) {
    return ApiClient.instance.delete('/care-tasks/$id');
  }

  Future<void> createInventoryItem(InventoryItem item) {
    return ApiClient.instance.post('/inventory', body: {
      'name': item.name,
      'category': _inventoryCategory(item.category),
      'currentStock': item.currentStock,
      'minRequired': item.minRequired,
      'unit': item.unit,
    });
  }

  Future<void> deleteInventoryItem(String id) {
    return ApiClient.instance.delete('/inventory/$id');
  }

  Future<void> updateInventoryStock({
    required String id,
    required int currentStock,
  }) {
    return ApiClient.instance.patch('/inventory/$id/stock', body: {
      'currentStock': currentStock,
    });
  }

  Future<void> createDoctorVisit({
    required String residentId,
    required DoctorVisit visit,
  }) {
    return ApiClient.instance.post('/doctor-visits', body: {
      'residentId': residentId,
      'doctorName': visit.doctorName,
      'specialty': visit.specialty,
      'visitDate': _dateOnly(visit.date),
      'purpose': visit.purpose,
      'results': visit.results,
    });
  }

  Future<void> updateDoctorVisit({
    required String id,
    required DoctorVisit visit,
  }) {
    return ApiClient.instance.patch('/doctor-visits/$id', body: {
      'doctorName': visit.doctorName,
      'specialty': visit.specialty,
      'visitDate': _dateOnly(visit.date),
      'purpose': visit.purpose,
      'results': visit.results,
    });
  }

  Future<void> deleteDoctorVisit(String id) {
    return ApiClient.instance.delete('/doctor-visits/$id');
  }

  Future<void> createMealPlan({
    required String residentId,
    required MealPlan plan,
  }) {
    return ApiClient.instance.post('/meal-plans', body: {
      'residentId': residentId,
      'planDate': _dateOnly(DateTime.now()),
      'breakfast': plan.breakfast,
      'lunch': plan.lunch,
      'dinner': plan.dinner,
      'specialInstructions': plan.specialInstructions,
    });
  }

  Future<void> updateMealPlan({
    required String id,
    required MealPlan plan,
  }) {
    return ApiClient.instance.patch('/meal-plans/$id', body: {
      'planDate': _dateOnly(DateTime.now()),
      'breakfast': plan.breakfast,
      'lunch': plan.lunch,
      'dinner': plan.dinner,
      'specialInstructions': plan.specialInstructions,
    });
  }

  Future<void> deleteMealPlan(String id) {
    return ApiClient.instance.delete('/meal-plans/$id');
  }

  Future<void> createMemory({
    required String residentId,
    required MemoryMoment moment,
  }) {
    return ApiClient.instance.post('/memories', body: {
      'residentId': residentId,
      'activityTitle': moment.activityTitle,
      if (moment.imageUrl.isNotEmpty) 'fileName': moment.imageUrl,
    });
  }

  Future<void> appreciateMemory(String id) {
    return ApiClient.instance.patch('/memories/$id/appreciate');
  }

  Future<void> deleteMemory(String id) {
    return ApiClient.instance.delete('/memories/$id');
  }

  Future<void> deleteActivity(String id) {
    return ApiClient.instance.delete('/activities/$id');
  }

  Future<void> deleteMedicalSession(String id) {
    return ApiClient.instance.delete('/medical-sessions/$id');
  }

  Future<void> deletePrescription(String id) {
    return ApiClient.instance.delete('/prescriptions/$id');
  }

  Future<void> updateVolunteerProfile(VolunteerProfile profile) {
    return ApiClient.instance.put('/volunteers/profile', body: {
      'name': profile.name,
      'bio': profile.bio,
      'location': profile.location,
      'skills': profile.skills,
      'socialLinks': {
        'linkedin': profile.linkedinUrl,
        'facebook': profile.facebookUrl,
        'instagram': profile.instagramUrl,
      },
      if (profile.cvFileName != null && profile.cvFileName!.isNotEmpty)
        'cvFileUrl': profile.cvFileName,
      if (profile.recommendationFileName != null &&
          profile.recommendationFileName!.isNotEmpty)
        'recommendationFileUrl': profile.recommendationFileName,
    });
  }

  Future<void> createVolunteerBooking(String opportunityId) {
    return ApiClient.instance.post('/volunteers/bookings', body: {
      'opportunityId': opportunityId,
    });
  }

  Future<void> createVolunteerOpportunity(VolunteerOpportunity opportunity) {
    return ApiClient.instance.post('/volunteers/opportunities',
        body: _volunteerOpportunityBody(opportunity));
  }

  Future<void> updateVolunteerOpportunity(VolunteerOpportunity opportunity) {
    return ApiClient.instance.patch(
        '/volunteers/opportunities/${opportunity.id}',
        body: _volunteerOpportunityBody(opportunity));
  }

  Future<void> deleteVolunteerOpportunity(String id) {
    return ApiClient.instance.delete('/volunteers/opportunities/$id');
  }

  Future<void> cancelVolunteerBooking(String id) {
    return ApiClient.instance.patch('/volunteers/bookings/$id/cancel');
  }

  Future<void> confirmVolunteerAttendance(String id) {
    return ApiClient.instance
        .patch('/volunteers/bookings/$id/confirm-attendance');
  }

  Future<void> createVolunteerReview({
    required String toName,
    required String session,
    required double score,
  }) {
    return ApiClient.instance.post('/volunteers/reviews', body: {
      'toName': toName,
      'session': session,
      'score': score,
    });
  }

  Future<void> createVoiceMessage({
    required String residentId,
    required String title,
    String senderType = 'resident',
  }) {
    return ApiClient.instance.post('/voice-messages/upload', body: {
      'residentId': residentId,
      'senderType': senderType,
      'title': title,
    });
  }

  Future<void> sendNursingReport({
    required String reportType,
    required List<String> recipients,
  }) {
    return ApiClient.instance.post('/reports/nursing/send', body: {
      'reportType': reportType,
      'recipients': recipients,
    });
  }

  static String _backendRole(String role) {
    return switch (role) {
      'إدارة' => 'Admin',
      'ممرض' => 'Nurse',
      'أخصائي اجتماعي' => 'ClinicalStaff',
      'أسرة' => 'Family',
      'متطوع' => 'Volunteer',
      'مسن' => 'Resident',
      _ => role,
    };
  }

  static String _birthDateFromAge(int? age) {
    final now = DateTime.now();
    final year = now.year - (age ?? 75);
    return '$year-01-01';
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _hhmm(DateTime? date) {
    final value = date ?? DateTime.now();
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  static String _validTime(String value) {
    // Normalize Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩) to ASCII digits
    final normalized = value
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
    final match = RegExp(r'\d{1,2}:\d{2}').firstMatch(normalized);
    if (match == null) return '09:00';
    final parts = match.group(0)!.split(':');
    var hour = int.parse(parts[0]);
    final minute = parts[1];
    // ص = AM, م = PM (Arabic abbreviations)
    if (value.contains('م') && hour < 12) hour += 12;
    if (value.contains('ص') && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  static String _plusOneHour(String value) {
    final parts = value.split(':');
    final hour = (int.tryParse(parts.first) ?? 9) + 1;
    final minute = int.tryParse(parts.last) ?? 0;
    return '${(hour % 24).toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  static String _shiftType(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('night') || value.contains('ليل')) return 'night';
    if (lower.contains('evening') || value.contains('مساء')) return 'evening';
    return 'morning';
  }

  static String _medicalSessionType(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('vital') || value.contains('قياس')) return 'vitals';
    if (lower.contains('pt') || value.contains('علاج')) return 'pt';
    return 'doctor';
  }

  static String _careTaskCategory(String value) {
    if (value.contains('ترفيه')) return 'recreational';
    if (value.contains('فندق')) return 'hotel';
    return 'personal';
  }

  static String _inventoryCategory(String value) {
    if (value.contains('دواء') || value.contains('أدوية')) {
      return 'medications';
    }
    if (value.contains('شخص')) return 'personal';
    return 'supplies';
  }

  static Map<String, dynamic> _volunteerOpportunityBody(
      VolunteerOpportunity opportunity) {
    return {
      'title': opportunity.title,
      'org': opportunity.org,
      'dateInfo': opportunity.dateInfo,
      'tags': opportunity.tags,
      'hours': opportunity.hours,
      'points': opportunity.points,
      'description': opportunity.description,
      'totalSlots': opportunity.totalSlots,
    };
  }
}
