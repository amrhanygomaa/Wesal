import 'package:flutter/material.dart';

/// Removes UUID-like patterns from AI-generated text to prevent internal IDs
/// from being shown to users.
final _uuidPattern = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

/// Returns true if [text] is entirely (or nearly entirely) a UUID.
bool isUuid(String text) {
  final trimmed = text.trim();
  return _uuidPattern.hasMatch(trimmed) && trimmed.length <= 36;
}

/// Strips UUID patterns from [text], collapsing any double-spaces left behind.
String stripUuids(String text) {
  return text
      .replaceAll(_uuidPattern, '')
      .replaceAll(RegExp(r'  +'), ' ')
      .trim();
}

// نموذج يمثل بيانات المستخدم (المسن) ونظام النقاط التحفيزي
class User {
  String name; // اسم المستخدم
  int points; // إجمالي النقاط المكتسبة من الأنشطة
  int streakDays; // عدد الأيام المتتالية للنشاط (التحدي اليومي)
  int completedActivities; // إجمالي الأنشطة التي أتمها المستخدم

  User({
    required this.name,
    required this.points,
    required this.streakDays,
    required this.completedActivities,
  });
}

// نموذج يمثل الدواء والجرعة وحالة التناول والمتابعة
class Medication {
  final String id; // معرف فريد للدواء
  final String name; // اسم الدواء
  final String dosage; // الجرعة (مثلاً: قرص واحد)
  final String timeDescription; // وصف الوقت (مثلاً: ٨ صباحاً)
  final String timeOfDay; // الفترة الزمنية: 'الصباح', 'الظهر', 'المساء'
  bool isTaken; // هل تم تناول الجرعة (تأكيد نهائي من الممرض)؟
  bool isElderlyConfirmed; // هل أكد المسن تناوله للدواء؟
  bool isSkipped; // هل تم تجاوز الجرعة عمداً؟
  String? skipReason; // سبب تجاوز الجرعة (مثلاً: عدم الرغبة)
  final String dayTag; // تصنيف اليوم: 'أمس', 'اليوم', 'غداً'
  final String? residentName; // اسم المقيم (يستخدم في واجهة الممرض)
  final DateTime? scheduledTime; // الوقت المحدد للجرعة بدقة
  final String?
      mealRelation; // 'before_breakfast', 'after_breakfast', 'after_lunch', 'after_dinner', 'empty_stomach'

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timeDescription,
    required this.timeOfDay,
    this.isTaken = false,
    this.isElderlyConfirmed = false,
    this.isSkipped = false,
    this.skipReason,
    this.dayTag = 'اليوم',
    this.residentName,
    this.scheduledTime,
    this.mealRelation,
  });

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? timeDescription,
    String? timeOfDay,
    bool? isTaken,
    bool? isElderlyConfirmed,
    bool? isSkipped,
    String? skipReason,
    String? dayTag,
    String? residentName,
    DateTime? scheduledTime,
    String? mealRelation,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      timeDescription: timeDescription ?? this.timeDescription,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isTaken: isTaken ?? this.isTaken,
      isElderlyConfirmed: isElderlyConfirmed ?? this.isElderlyConfirmed,
      isSkipped: isSkipped ?? this.isSkipped,
      skipReason: skipReason ?? this.skipReason,
      dayTag: dayTag ?? this.dayTag,
      residentName: residentName ?? this.residentName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      mealRelation: mealRelation ?? this.mealRelation,
    );
  }

  String get mealRelationArabic {
    switch (mealRelation) {
      case 'before_breakfast':
        return 'قبل الإفطار';
      case 'after_breakfast':
        return 'بعد الإفطار';
      case 'after_lunch':
        return 'بعد الغذاء';
      case 'after_dinner':
        return 'بعد العشاء';
      case 'empty_stomach':
        return 'على معدة فارغة';
      default:
        return '';
    }
  }

  // التحقق مما إذا كانت الجرعة قد فاتت موعدها ولم تؤخذ
  bool get isMissed {
    if (isTaken || isSkipped || scheduledTime == null) return false;
    return DateTime.now().isAfter(scheduledTime!);
  }
}

// نموذج يمثل فرد من أفراد العائلة وسهولة الوصول إليه
class FamilyMember {
  String id;
  String? residentId;
  String name; // اسم قريب المسن
  String relation; // صلة القرابة (ابن، حفيدة، إلخ)
  String avatarPath; // مسار الصورة الشخصية
  String initials; // الحروف الأولى من الاسم (للعرض البديل)
  String phoneNumber; // رقم الهاتف لإجراء مكالمات حقيقية
  String? email; // البريد المستخدم لدعوة فرد العائلة
  String inviteStatus; // pending, confirmed, failed, skipped
  String? zoomLink; // رابط زووم للمكالمات المرئية
  bool isAvailable; // هل القريب متاح حالياً للمكالمة؟
  bool isPinned; // هل تم اختياره ليظهر في الشاشة الرئيسية؟
  String? userId; // Cognito sub — used as recipientId for messages API

  FamilyMember({
    required this.id,
    this.residentId,
    required this.name,
    required this.relation,
    required this.avatarPath,
    required this.initials,
    required this.phoneNumber,
    this.email,
    this.inviteStatus = 'pending',
    this.zoomLink,
    this.isAvailable = false,
    this.isPinned = true,
    this.userId,
  });
}

// نموذج يمثل رسالة صوتية مرسلة من العائلة للمسن
class VoiceMessage {
  String id;
  String senderId;
  String title;
  String timeDescription;
  bool isPlaying;
  bool isUnread;
  String? audioUrl;
  int? durationSeconds;
  String? recipientId;
  String? recipientName;
  String deliveryStatus; // pending, sent, failed
  String moderationStatus; // pending, approved, rejected

  VoiceMessage({
    required this.id,
    required this.senderId,
    required this.title,
    required this.timeDescription,
    this.isPlaying = false,
    this.isUnread = true,
    this.audioUrl,
    this.durationSeconds,
    this.recipientId,
    this.recipientName,
    this.deliveryStatus = 'sent',
    this.moderationStatus = 'pending',
  });
}

class MemoryItem {
  String id;
  String category; // 'أسرة', 'رحلات', 'فيديو', 'مناسبات'
  String title;
  String date;
  String type; // 'image', 'video', 'text', 'voice'
  String assetPath;
  String? content;

  MemoryItem({
    required this.id,
    required this.category,
    required this.title,
    required this.date,
    required this.type,
    required this.assetPath,
    this.content,
  });
}

class Activity {
  String id;
  String name;
  String emoji;
  String location;
  String time;
  String status; // 'done', 'active', 'later', 'coming'
  String badges;
  int pointsReward;
  String dayTag; // 'أمس', 'اليوم', 'غداً', 'الأسبوع'

  // الحقول الجديدة لربط واجهة الأخصائي مع المسن
  String? supervisor;
  String? target;
  String? image;
  String? type; // 'رحلة' أو 'نشاط'
  int? colorValue; // حفظ قيمة اللون كرقم
  int? bgValue; // حفظ قيمة اللون كرقم

  Activity({
    required this.id,
    required this.name,
    required this.emoji,
    required this.location,
    required this.time,
    required this.status,
    required this.badges,
    required this.pointsReward,
    this.dayTag = 'اليوم',
    this.supervisor,
    this.target,
    this.image,
    this.type,
    this.colorValue,
    this.bgValue,
  });

  // دوال مساعدة للتعامل مع الألوان
  Color? get color => colorValue != null ? Color(colorValue!) : null;
  Color? get bg => bgValue != null ? Color(bgValue!) : null;
}

class VolunteerOpportunity {
  final String id;
  final String title;
  final String org;
  final String dateInfo;
  final String icon;
  final List<String> tags;
  final int hours;
  final bool isNew;
  final String description;
  final int totalSlots;
  final int filledSlots;
  final int points;
  final String targetAudience;
  final String targetResident;
  final List<String> requiredSkills;

  VolunteerOpportunity({
    required this.id,
    required this.title,
    required this.org,
    required this.dateInfo,
    required this.icon,
    required this.tags,
    required this.hours,
    this.isNew = false,
    this.description = '',
    this.totalSlots = 1,
    this.filledSlots = 0,
    this.points = 10,
    this.targetAudience = '',
    this.targetResident = '',
    this.requiredSkills = const [],
  });

  String get status => filledSlots < totalSlots ? 'متاحة' : 'مكتملة';
  String get date => dateInfo;
  List<String> get displaySkills =>
      requiredSkills.isNotEmpty ? requiredSkills : tags;
}

class VolunteerImpact {
  final int residentsServed;
  final int positiveRatings;
  final int totalHours;

  VolunteerImpact({
    required this.residentsServed,
    required this.positiveRatings,
    required this.totalHours,
  });
}

class VolunteerBooking {
  final String id;
  final String title;
  final String timeInfo;
  final int day;
  final String month;
  final String status; // 'confirmed', 'done', 'cancelled'
  final String location;
  final int points;
  final bool isUrgent;
  final DateTime startTime;
  final bool isRatingRequired;

  VolunteerBooking({
    required this.id,
    required this.title,
    required this.timeInfo,
    required this.day,
    required this.month,
    required this.status,
    this.location = '',
    this.points = 10,
    this.isUrgent = false,
    DateTime? startTime,
    this.isRatingRequired = false,
  }) : startTime = startTime ?? DateTime.now().add(const Duration(hours: 26));
}

class VolunteerCertificate {
  final String id;
  final String name;
  final String icon;
  final String date;
  final bool isLocked;
  final String progressInfo;
  final String awardTitle;
  final String description;
  final double progress;

  VolunteerCertificate({
    required this.id,
    required this.name,
    required this.icon,
    required this.date,
    this.isLocked = false,
    this.progressInfo = '',
    this.awardTitle = '',
    this.description = '',
    this.progress = 0.0,
  });
}

class VolunteerRating {
  final String id;
  final String fromName;
  final String category;
  final double score;
  final String comment;
  final String date;
  final String icon;
  final List<String> chips;
  final Map<String, double> criteriaScores;

  VolunteerRating({
    required this.id,
    required this.fromName,
    required this.category,
    required this.score,
    required this.comment,
    required this.date,
    this.icon = '😊',
    this.chips = const [],
    this.criteriaScores = const {},
  });
}

class VolunteerReview {
  final String id;
  final String toName;
  final String session;
  final String date;
  final double score;
  final bool isPending;
  final String icon;

  VolunteerReview({
    required this.id,
    required this.toName,
    required this.session,
    required this.date,
    required this.score,
    required this.isPending,
    this.icon = '👴',
  });
}

class SocialSpecialistNeed {
  final String id;
  final String type; // 'نفسي', 'أسري', 'مالي', 'طبي'
  final String roomNumber;
  final bool isUrgent;
  final String label;

  SocialSpecialistNeed({
    required this.id,
    required this.type,
    required this.roomNumber,
    this.isUrgent = false,
    required this.label,
  });
}

class SocialSpecialistAssessmentTool {
  final String id;
  final String name;
  final String subtitle;
  final String score;
  final String status; // 'جديد', 'مكتمل', 'تحديث'
  final String icon;

  SocialSpecialistAssessmentTool({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.score,
    required this.status,
    required this.icon,
  });
}

class SocialSpecialistResidentScore {
  final String id;
  final String name;
  final String initials;
  final String room;
  final String date;
  final Map<String, double> scores; // { 'نفسي': 0.45, ... }
  final bool isUrgent;
  final String healthStatus; // 'stable', 'monitoring', 'critical'
  final DateTime lastAssessment;

  SocialSpecialistResidentScore({
    required this.id,
    required this.name,
    required this.initials,
    required this.room,
    required this.date,
    required this.scores,
    this.isUrgent = false,
    this.healthStatus = 'stable',
    required this.lastAssessment,
  });
}

class ComplaintStep {
  final String text;
  final String time;
  final String status; // 'done', 'pending', 'alert'

  ComplaintStep({required this.text, required this.time, required this.status});
}

class SocialSpecialistComplaint {
  final String id;
  final String title;
  final String residentName;
  final String room;
  final String date;
  final String priority; // 'high', 'medium', 'low'
  final String status; // 'open', 'progress', 'done'
  final String category; // 'food', 'service', 'psych', 'maintenance'
  final String icon;
  final List<ComplaintStep> timeline;
  final bool isEscalated; // هل تم تصعيد الشكوى للإدارة؟

  SocialSpecialistComplaint({
    required this.id,
    required this.title,
    required this.residentName,
    required this.room,
    required this.date,
    required this.priority,
    required this.status,
    required this.category,
    required this.icon,
    required this.timeline,
    this.isEscalated = false,
  });

  SocialSpecialistComplaint copyWith({
    String? id,
    String? title,
    String? residentName,
    String? room,
    String? date,
    String? priority,
    String? status,
    String? category,
    String? icon,
    List<ComplaintStep>? timeline,
    bool? isEscalated,
  }) {
    return SocialSpecialistComplaint(
      id: id ?? this.id,
      title: title ?? this.title,
      residentName: residentName ?? this.residentName,
      room: room ?? this.room,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      timeline: timeline ?? this.timeline,
      isEscalated: isEscalated ?? this.isEscalated,
    );
  }
}

class SocialSpecialistKPI {
  final String id;
  final String label;
  final String value;
  final String trend;
  final bool isPositive;
  final List<double> history;

  SocialSpecialistKPI({
    required this.id,
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
    this.history = const [],
  });
}

class AssessmentQuestion {
  final String id;
  final String text;
  final String type; // 'choice', 'scale', 'text'
  final List<String>? options;
  final String? userAnswer;
  final int? userScale;

  AssessmentQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.userAnswer,
    this.userScale,
  });
}

class AssessmentHistoricalEntry {
  final String date;
  final double score;
  final String total;
  final String trend; // 'up', 'down', 'stable'

  AssessmentHistoricalEntry({
    required this.date,
    required this.score,
    required this.total,
    required this.trend,
  });
}

class FamilyVisit {
  final String id;
  final String date;
  final String time;
  final String visitorName;
  final String status; // 'pending', 'upcoming', 'completed', 'cancelled'
  final String type; // 'physical', 'video'
  final DateTime? scheduledAt; // actual DateTime for backend submission
  final String? zoomLink; // populated by backend for video visits

  FamilyVisit({
    required this.id,
    required this.date,
    required this.time,
    required this.visitorName,
    required this.status,
    required this.type,
    this.scheduledAt,
    this.zoomLink,
  });

  FamilyVisit copyWith({
    String? id,
    String? date,
    String? time,
    String? visitorName,
    String? status,
    String? type,
    DateTime? scheduledAt,
    String? zoomLink,
  }) {
    return FamilyVisit(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      visitorName: visitorName ?? this.visitorName,
      status: status ?? this.status,
      type: type ?? this.type,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      zoomLink: zoomLink ?? this.zoomLink,
    );
  }
}

class FamilyBill {
  final String id;
  final String title;
  final String month;
  final double amount;
  final bool isPaid;
  final String dueDate;

  FamilyBill({
    required this.id,
    required this.title,
    required this.month,
    required this.amount,
    required this.isPaid,
    required this.dueDate,
  });

  FamilyBill copyWith({
    String? id,
    String? title,
    String? month,
    double? amount,
    bool? isPaid,
    String? dueDate,
  }) {
    return FamilyBill(
      id: id ?? this.id,
      title: title ?? this.title,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class ShiftHandoff {
  final String nurseName;
  final String shiftType;
  final String notes;
  final DateTime timestamp;
  final List<String> criticalCases;

  ShiftHandoff({
    required this.nurseName,
    required this.shiftType,
    required this.notes,
    required this.timestamp,
    required this.criticalCases,
  });
}

class PendingAssessment {
  final String residentName;
  final String toolName;
  final Map<int, int> selections;
  final Map<int, int> scales;
  final String notes;
  final DateTime timestamp;

  PendingAssessment({
    required this.residentName,
    required this.toolName,
    required this.selections,
    required this.scales,
    required this.notes,
    required this.timestamp,
  });
}

class FamilyHealthMetric {
  final String label;
  final double value; // 0.0 to 1.0
  final String status; // 'good', 'medium', 'critical'
  final String trend; // 'up', 'down', 'stable'
  final List<double> history;

  FamilyHealthMetric({
    required this.label,
    required this.value,
    required this.status,
    required this.trend,
    required this.history,
  });
}

class SpecialistResidentFile {
  final String id;
  final String name; // الاسم بالعربية
  final String nameEn;
  final String room;
  final String status;
  final String lastUpdate;
  final List<String> categories;
  final String initials;
  final List<FamilyMember> familyMembers;
  final String? phone;
  final int? age;
  final String? familyEmail;
  final String? nationalId;
  final String? gender;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyRelation;

  // الحقول الجديدة للأرشيف الشامل
  final String? bloodType;
  final List<String>? chronicDiseases;
  final List<String>? allergies;
  final String? insuranceInfo;
  final String? primaryDoctorName;
  final String? mobilityStatus;
  final List<String>? assistiveDevices;
  final String? cognitiveStatus;
  final String? dietType;
  final List<String>? foodRestrictions;
  final String? foodPreferences;
  final String? previousProfession;
  final List<String>? hobbies;
  final String? socialStatus;
  final List<String>? uploadedDocuments;
  final String? imageUrl;
  final String? nickname; // اسم الدلع / الاسم المُفضَّل
  final bool? isOnline;

  SpecialistResidentFile({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.room,
    required this.status,
    required this.lastUpdate,
    required this.categories,
    required this.initials,
    this.familyMembers = const [],
    this.phone,
    this.age,
    this.familyEmail,
    this.nationalId,
    this.gender,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyRelation,
    this.bloodType,
    this.chronicDiseases,
    this.allergies,
    this.insuranceInfo,
    this.primaryDoctorName,
    this.mobilityStatus,
    this.assistiveDevices,
    this.cognitiveStatus,
    this.dietType,
    this.foodRestrictions,
    this.foodPreferences,
    this.previousProfession,
    this.hobbies,
    this.socialStatus,
    this.uploadedDocuments,
    this.imageUrl,
    this.nickname,
    this.isOnline,
  });

  SpecialistResidentFile copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? room,
    String? status,
    String? lastUpdate,
    List<String>? categories,
    String? initials,
    List<FamilyMember>? familyMembers,
    String? phone,
    int? age,
    String? familyEmail,
    String? nationalId,
    String? gender,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyRelation,
    String? bloodType,
    List<String>? chronicDiseases,
    List<String>? allergies,
    String? insuranceInfo,
    String? primaryDoctorName,
    String? mobilityStatus,
    List<String>? assistiveDevices,
    String? cognitiveStatus,
    String? dietType,
    List<String>? foodRestrictions,
    String? foodPreferences,
    String? previousProfession,
    List<String>? hobbies,
    String? socialStatus,
    List<String>? uploadedDocuments,
    String? imageUrl,
    String? nickname,
    bool? isOnline,
  }) {
    return SpecialistResidentFile(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      room: room ?? this.room,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      categories: categories ?? this.categories,
      initials: initials ?? this.initials,
      familyMembers: familyMembers ?? this.familyMembers,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      familyEmail: familyEmail ?? this.familyEmail,
      nationalId: nationalId ?? this.nationalId,
      gender: gender ?? this.gender,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyRelation: emergencyRelation ?? this.emergencyRelation,
      bloodType: bloodType ?? this.bloodType,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      allergies: allergies ?? this.allergies,
      insuranceInfo: insuranceInfo ?? this.insuranceInfo,
      primaryDoctorName: primaryDoctorName ?? this.primaryDoctorName,
      mobilityStatus: mobilityStatus ?? this.mobilityStatus,
      assistiveDevices: assistiveDevices ?? this.assistiveDevices,
      cognitiveStatus: cognitiveStatus ?? this.cognitiveStatus,
      dietType: dietType ?? this.dietType,
      foodRestrictions: foodRestrictions ?? this.foodRestrictions,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      previousProfession: previousProfession ?? this.previousProfession,
      hobbies: hobbies ?? this.hobbies,
      socialStatus: socialStatus ?? this.socialStatus,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      imageUrl: imageUrl ?? this.imageUrl,
      nickname: nickname ?? this.nickname,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class MedicalSession {
  final String id;
  final String type; // 'doctor', 'pt', 'nursing'
  final String specialistName;
  final String time;
  final String date;
  final String notes;
  final String residentName;

  MedicalSession({
    required this.id,
    required this.type,
    required this.specialistName,
    required this.time,
    required this.date,
    required this.notes,
    required this.residentName,
  });
}

class MedicalPrescription {
  final String id;
  final String title;
  final String doctorName;
  final String date;
  final String residentName;
  final String? imagePath;

  MedicalPrescription({
    required this.id,
    required this.title,
    required this.doctorName,
    required this.date,
    required this.residentName,
    this.imagePath,
  });
}

class StaffPerformance {
  final String id;
  final String? managedUserId;
  final String? authUserId;
  final String name;
  final String role; // 'Specialist', 'Nurse'
  final double completionRate;
  final String lastActive;
  final String status; // 'online', 'offline'
  final String? imageUrl;

  StaffPerformance({
    required this.id,
    this.managedUserId,
    this.authUserId,
    required this.name,
    required this.role,
    required this.completionRate,
    required this.lastActive,
    required this.status,
    this.imageUrl,
  });

  StaffPerformance copyWith({
    String? id,
    String? managedUserId,
    String? authUserId,
    String? name,
    String? role,
    double? completionRate,
    String? lastActive,
    String? status,
    String? imageUrl,
  }) {
    return StaffPerformance(
      id: id ?? this.id,
      managedUserId: managedUserId ?? this.managedUserId,
      authUserId: authUserId ?? this.authUserId,
      name: name ?? this.name,
      role: role ?? this.role,
      completionRate: completionRate ?? this.completionRate,
      lastActive: lastActive ?? this.lastActive,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class CenterOperationalStat {
  final String label;
  final String value;
  final String trend;
  final bool isPositive;
  final List<double> history;

  CenterOperationalStat({
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
    this.history = const [],
  });
}

// نموذج التنبيهات الموحد في التطبيق (الإشعارات الداخلية)
class TaptabaNotification {
  final String id; // المعرف الفريد للتنبيه
  final String title; // عنوان التنبيه (مثال: حالة طبية حرجة)
  final String body; // نص التنبيه التفصيلي
  final String time; // وقت وصول التنبيه (مثال: منذ ٥ دقائق)
  final String type; // نوع التنبيه (medical, complaint, social, stable)
  final String targetRole; // الدور المستهدف بالتنبيه (مدير، أخصائي، إلخ)
  final String?
      residentId; // معرف المقيم المرتبط بالتنبيه (للتنقل السريع لملفه)
  bool isRead; // حالة القراءة (هل تمت معالجة التنبيه؟)

  TaptabaNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.targetRole = 'all',
    this.residentId,
    this.isRead = false,
  });
}

class MemoryMoment {
  final String id;
  final String residentId;
  final String residentName;
  final String imageUrl;
  final String? fallbackPath;
  final String activityTitle;
  final String date;
  final int appreciations;

  MemoryMoment({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.imageUrl,
    this.fallbackPath,
    required this.activityTitle,
    required this.date,
    this.appreciations = 0,
  });
}

class VolunteerProfile {
  final String name;
  final String location;
  final String bio;
  final List<String> skills;
  final String? linkedinUrl;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? cvFileName;
  final String? recommendationFileName;
  final List<String> otherWorks;

  VolunteerProfile({
    required this.name,
    required this.location,
    required this.bio,
    required this.skills,
    this.linkedinUrl,
    this.facebookUrl,
    this.instagramUrl,
    this.cvFileName,
    this.recommendationFileName,
    this.otherWorks = const [],
  });

  VolunteerProfile copyWith({
    String? name,
    String? location,
    String? bio,
    List<String>? skills,
    String? linkedinUrl,
    String? facebookUrl,
    String? instagramUrl,
    String? cvFileName,
    String? recommendationFileName,
    List<String>? otherWorks,
  }) {
    return VolunteerProfile(
      name: name ?? this.name,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      cvFileName: cvFileName ?? this.cvFileName,
      recommendationFileName:
          recommendationFileName ?? this.recommendationFileName,
      otherWorks: otherWorks ?? this.otherWorks,
    );
  }
}

class NursingNote {
  final String id;
  final String residentName;
  final String title;
  final String content;
  final String author;
  final DateTime timestamp;

  NursingNote({
    required this.id,
    required this.residentName,
    required this.title,
    required this.content,
    required this.author,
    required this.timestamp,
  });
}

class ResidentMedicalInfo {
  final String residentName;
  final List<String> medications;
  final List<String> allergies;
  final List<String> chronicDiseases;

  ResidentMedicalInfo({
    required this.residentName,
    this.medications = const [],
    this.allergies = const [],
    this.chronicDiseases = const [],
  });
}

class CareTask {
  final String id;
  final String residentName;
  final String title;
  final String category; // 'فندقية', 'شخصية', 'ترفيهية'
  bool isCompleted;
  final String time;

  CareTask({
    required this.id,
    required this.residentName,
    required this.title,
    required this.category,
    this.isCompleted = false,
    required this.time,
  });
}

class InventoryItem {
  final String id;
  final String name;
  final String category; // 'أدوية', 'مستلزمات', 'شخصي'
  final int currentStock;
  final int minRequired;
  final String unit;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minRequired,
    this.unit = 'قطعة',
  });

  bool get isLowStock => currentStock <= minRequired;
}

class DoctorVisit {
  final String id;
  final String doctorName;
  final String specialty;
  final DateTime date;
  final String purpose;
  final String results;
  final String residentName;

  DoctorVisit({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.purpose,
    this.results = '',
    required this.residentName,
  });
}

class MealPlan {
  final String residentName;
  final String breakfast;
  final String lunch;
  final String dinner;
  final String snacks;
  final String specialInstructions;
  final bool isAiGenerated;
  final String? aiRationale;

  MealPlan({
    required this.residentName,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    this.snacks = '',
    this.specialInstructions = '',
    this.isAiGenerated = false,
    this.aiRationale,
  });
}

class ActivitySession {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final String location;
  final List<String> participants;

  ActivitySession({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.location,
    required this.participants,
  });
}

class AIInsight {
  final String id;
  final String? residentId;
  final String residentName;
  final String? roomNumber;
  final String summary;
  final String rationale;
  final DateTime generationDate;
  final double confidenceScore;
  final String type; // 'recommendation', 'predictive_alert'

  AIInsight({
    required this.id,
    this.residentId,
    required this.residentName,
    this.roomNumber,
    required this.summary,
    required this.rationale,
    required this.generationDate,
    this.confidenceScore = 0.85,
    this.type = 'recommendation',
  });

  /// Human-readable resident label safe for display (never exposes UUIDs).
  String get residentLabel {
    final safeName = isUuid(residentName) ? '' : residentName.trim();
    if (safeName.isEmpty) return 'مشكلة عامة في النظام / الدار';
    final room = roomNumber?.trim();
    if (room != null && room.isNotEmpty) {
      return 'المقيم: $safeName — الغرفة $room';
    }
    return safeName;
  }
}

/// ملاحظات الذكاء الاصطناعي الخاصة بمقيم معين
class ResidentAINotes {
  final String residentId;
  final String? summary;
  final String? recommendations;
  final String? warnings;
  final String? moodInsights;
  final String? source;
  final String? status;
  final String? lastUpdated;

  ResidentAINotes({
    required this.residentId,
    this.summary,
    this.recommendations,
    this.warnings,
    this.moodInsights,
    this.source,
    this.status,
    this.lastUpdated,
  });

  bool get isEmpty =>
      (summary?.isEmpty ?? true) &&
      (recommendations?.isEmpty ?? true) &&
      (warnings?.isEmpty ?? true) &&
      (moodInsights?.isEmpty ?? true);
}

class CompanionMessage {
  final String id;
  final String text;
  final bool isFromAI;
  final DateTime timestamp;
  final String? mediaPath; // مسار الملف المرفق (صورة أو ملف)
  final String? mediaType; // نوع الملف (image, file)
  final String? sentiment; // 'happy', 'sad', 'stressed', 'neutral'

  CompanionMessage({
    required this.id,
    required this.text,
    required this.isFromAI,
    required this.timestamp,
    this.mediaPath,
    this.mediaType,
    this.sentiment,
  });
}

class CognitiveGameResult {
  final String id;
  final String residentId;
  final DateTime date;
  final int score;
  final String feedback;

  CognitiveGameResult({
    required this.id,
    required this.residentId,
    required this.date,
    required this.score,
    required this.feedback,
  });
}

class SpecialistRecommendation {
  final String id;
  final String residentName;
  final String content;
  final String time;

  SpecialistRecommendation({
    required this.id,
    required this.residentName,
    required this.content,
    required this.time,
  });
}

class AppAccount {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? facilityName;
  final String? facilityAddress;
  final List<String>? amenities;

  // حقول إضافية للفئات المختلفة
  final String? room; // للمسن
  final String? specialty; // للممرض/الأخصائي
  final String? shift; // للموظفين
  final String? bloodType; // للمسن
  final List<String>? chronicDiseases; // للمسن
  final String? linkedResidentId; // للأسرة (لمتابعة قريبهم)
  final String? phone;
  final String? imageUrl;
  final String? mobilityStatus; // للمسن
  final String? dietType; // للمسن
  final String? facilityPhone; // للدار
  final String? facilityEmail; // للدار
  final String? licenseNumber; // للدار
  final String? facilityYearOfEst; // سنة الإنشاء
  final String? facilityCapacity; // السعة الاستيعابية
  final String? facilityLocationUrl; // رابط الخريطة

  AppAccount({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.facilityName,
    this.facilityAddress,
    this.amenities,
    this.room,
    this.specialty,
    this.shift,
    this.bloodType,
    this.chronicDiseases,
    this.linkedResidentId,
    this.phone,
    this.imageUrl,
    this.mobilityStatus,
    this.dietType,
    this.facilityPhone,
    this.facilityEmail,
    this.licenseNumber,
    this.facilityYearOfEst,
    this.facilityCapacity,
    this.facilityLocationUrl,
  });

  AppAccount copyWith({
    String? name,
    String? email,
    String? password,
    String? role,
    String? facilityName,
    String? facilityAddress,
    List<String>? amenities,
    String? room,
    String? specialty,
    String? shift,
    String? bloodType,
    List<String>? chronicDiseases,
    String? linkedResidentId,
    String? phone,
    String? imageUrl,
    String? mobilityStatus,
    String? dietType,
    String? facilityPhone,
    String? facilityEmail,
    String? licenseNumber,
    String? facilityYearOfEst,
    String? facilityCapacity,
    String? facilityLocationUrl,
  }) {
    return AppAccount(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      facilityName: facilityName ?? this.facilityName,
      facilityAddress: facilityAddress ?? this.facilityAddress,
      amenities: amenities ?? this.amenities,
      room: room ?? this.room,
      specialty: specialty ?? this.specialty,
      shift: shift ?? this.shift,
      bloodType: bloodType ?? this.bloodType,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      linkedResidentId: linkedResidentId ?? this.linkedResidentId,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      mobilityStatus: mobilityStatus ?? this.mobilityStatus,
      dietType: dietType ?? this.dietType,
      facilityPhone: facilityPhone ?? this.facilityPhone,
      facilityEmail: facilityEmail ?? this.facilityEmail,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      facilityYearOfEst: facilityYearOfEst ?? this.facilityYearOfEst,
      facilityCapacity: facilityCapacity ?? this.facilityCapacity,
      facilityLocationUrl: facilityLocationUrl ?? this.facilityLocationUrl,
    );
  }
}

// نموذج "ملف المقيم الشامل" - أرشيف رقمي متكامل يغني عن الورق
class Resident {
  final String id;
  final String name;
  final String roomNumber;
  final String gender;
  final DateTime birthDate;
  final DateTime entryDate; // تاريخ الدخول للدار
  final String nationalId; // الرقم القومي
  final String? imageUrl; // صورة المقيم

  // بيانات التواصل والطوارئ
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyRelation;

  // التاريخ الطبي الشامل
  final String bloodType;
  final List<String> allergies;
  final List<String> chronicDiseases;
  final List<String> pastSurgeries;
  final String insuranceInfo; // بيانات التأمين الصحي
  final String? primaryDoctorName; // الطبيب المتابع الخارجي

  // الحالة الوظيفية والحركية
  final String
      mobilityStatus; // 'مستقل', 'مساعدة خفيفة', 'كرسي wheelchair', 'طريح bedridden'
  final List<String>
      assistiveDevices; // 'سماعة hearing aid', 'نظارة glasses', 'طقم dentures'
  final String cognitiveStatus; // الحالة الذهنية (ذاكرة، وعي)

  // النظام الغذائي
  final String dietType; // 'عادي normal', 'مهروس pureed', 'سوائل liquids'
  final List<String> foodRestrictions; // 'سكري diabetes', 'ضغط hypertension'
  final String foodPreferences;

  // الجانب الاجتماعي
  final String previousProfession;
  final List<String> hobbies;
  final String socialStatus;

  // الإدارة المالية والقانونية
  final String contractType; // 'شهري monthly', 'سنوي yearly'
  final List<String> uploadedDocuments; // مسارات الملفات المرفوعة

  Resident({
    required this.id,
    required this.name,
    required this.roomNumber,
    required this.gender,
    required this.birthDate,
    required this.entryDate,
    required this.nationalId,
    this.imageUrl,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyRelation,
    required this.bloodType,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.pastSurgeries = const [],
    required this.insuranceInfo,
    this.primaryDoctorName,
    required this.mobilityStatus,
    this.assistiveDevices = const [],
    required this.cognitiveStatus,
    required this.dietType,
    this.foodRestrictions = const [],
    required this.foodPreferences,
    required this.previousProfession,
    this.hobbies = const [],
    required this.socialStatus,
    required this.contractType,
    this.uploadedDocuments = const [],
  });

  Resident copyWith({
    String? id,
    String? name,
    String? roomNumber,
    String? gender,
    DateTime? birthDate,
    DateTime? entryDate,
    String? nationalId,
    String? imageUrl,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyRelation,
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicDiseases,
    List<String>? pastSurgeries,
    String? insuranceInfo,
    String? primaryDoctorName,
    String? mobilityStatus,
    List<String>? assistiveDevices,
    String? cognitiveStatus,
    String? dietType,
    List<String>? foodRestrictions,
    String? foodPreferences,
    String? previousProfession,
    List<String>? hobbies,
    String? socialStatus,
    String? contractType,
    List<String>? uploadedDocuments,
  }) {
    return Resident(
      id: id ?? this.id,
      name: name ?? this.name,
      roomNumber: roomNumber ?? this.roomNumber,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      entryDate: entryDate ?? this.entryDate,
      nationalId: nationalId ?? this.nationalId,
      imageUrl: imageUrl ?? this.imageUrl,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyRelation: emergencyRelation ?? this.emergencyRelation,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      pastSurgeries: pastSurgeries ?? this.pastSurgeries,
      insuranceInfo: insuranceInfo ?? this.insuranceInfo,
      primaryDoctorName: primaryDoctorName ?? this.primaryDoctorName,
      mobilityStatus: mobilityStatus ?? this.mobilityStatus,
      assistiveDevices: assistiveDevices ?? this.assistiveDevices,
      cognitiveStatus: cognitiveStatus ?? this.cognitiveStatus,
      dietType: dietType ?? this.dietType,
      foodRestrictions: foodRestrictions ?? this.foodRestrictions,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      previousProfession: previousProfession ?? this.previousProfession,
      hobbies: hobbies ?? this.hobbies,
      socialStatus: socialStatus ?? this.socialStatus,
      contractType: contractType ?? this.contractType,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
    );
  }

  // حساب العمر تلقائياً
  int get age => DateTime.now().year - birthDate.year;
}

class CareReport {
  final String id;
  final String title;
  final String date;
  final String summary;
  final String socialNotes;
  final String recommendations;
  final String authorName;
  final String authorRole;
  final String interactionLevel; // ممتاز, جيد, الخ
  final String moodStatus; // مستقر, متقلب, الخ

  CareReport({
    required this.id,
    required this.title,
    required this.date,
    required this.summary,
    required this.socialNotes,
    required this.recommendations,
    required this.authorName,
    required this.authorRole,
    required this.interactionLevel,
    required this.moodStatus,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isFromMe;
  final DateTime timestamp;
  final String? mediaPath;
  final String? mediaType;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromMe,
    required this.timestamp,
    this.mediaPath,
    this.mediaType,
  });
}

class SentReport {
  final String id;
  final String icon;
  final String title;
  final String meta;
  final String status;
  final String date;

  SentReport({
    required this.id,
    required this.icon,
    required this.title,
    required this.meta,
    required this.status,
    required this.date,
  });
}

class Review {
  final String id;
  final String fromRole; // 'family' or 'elderly'
  final String fromName; // اسم المقيم أو صاحب التقييم
  final String toRole; // 'specialist', 'nurse', or 'home'
  final double rating; // 1 to 5
  final String comment;
  final String date;

  Review({
    required this.id,
    required this.fromRole,
    required this.fromName,
    required this.toRole,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

// تعريف وسام واحد مع شرط فتحه وبياناته البصرية
class BadgeDefinition {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String requirement; // النص المعروض للمستخدم عن شرط الفتح
  final bool Function(User user) isUnlocked;

  BadgeDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.requirement,
    required this.isUnlocked,
  });

  static final List<BadgeDefinition> all = [
    BadgeDefinition(
      id: 'wisdom',
      name: 'وسام الحكمة',
      icon: Icons.stars_rounded,
      color: const Color(0xFFFBBF24),
      requirement: '٥٠ نقطة',
      isUnlocked: (u) => u.points >= 50,
    ),
    BadgeDefinition(
      id: 'friend',
      name: 'صديق الجميع',
      icon: Icons.favorite_rounded,
      color: const Color(0xFFEC4899),
      requirement: '٥ أنشطة مكتملة',
      isUnlocked: (u) => u.completedActivities >= 5,
    ),
    BadgeDefinition(
      id: 'hero',
      name: 'بطل النشاط',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFF6B35),
      requirement: '١٠٠ نقطة',
      isUnlocked: (u) => u.points >= 100,
    ),
    BadgeDefinition(
      id: 'happiness',
      name: 'خبير السعادة',
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xFF10B981),
      requirement: '٣ أيام متتالية',
      isUnlocked: (u) => u.streakDays >= 3,
    ),
  ];
}
