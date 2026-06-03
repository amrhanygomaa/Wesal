import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import '../../services/resident_document_service.dart';
import '../../services/backend_mutation_service.dart';
import '../../widgets/app_popup_notification.dart';
import '../../widgets/taptaba_scaffold.dart';

ImageProvider<Object>? _residentImageProvider(String? imageUrl) {
  final value = imageUrl?.trim() ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('/') && !value.startsWith('//')) {
    return NetworkImage('${ApiConfig.baseUrl}$value');
  }
  final uri = Uri.tryParse(value);
  if (uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(value);
  }
  return FileImage(File(value));
}

class AdminResidentDetailScreen extends ConsumerStatefulWidget {
  final String residentId;
  const AdminResidentDetailScreen({super.key, required this.residentId});

  @override
  ConsumerState<AdminResidentDetailScreen> createState() =>
      _AdminResidentDetailScreenState();
}

class _AdminResidentDetailScreenState
    extends ConsumerState<AdminResidentDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditMode = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocuments());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    try {
      final docs = await ResidentDocumentService.instance
          .fetchDocuments(widget.residentId);
      if (!mounted) return;
      ref.read(appRiverpod).setDocumentsForResident(
            widget.residentId,
            docs
                .map((d) => d.url)
                .where((url) => url.trim().isNotEmpty)
                .toList(),
          );
    } catch (_) {
      // silently ignore — documents show empty if backend unreachable
    }
  }

  void _showPopup(
    BuildContext context,
    String message, {
    AppPopupNotificationType type = AppPopupNotificationType.info,
  }) {
    showAppPopupNotification(context, message: message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    // جلب البيانات الحقيقية من الـ Provider
    final appData = ref.watch(appRiverpod);
    final resident = appData.residentFiles.firstWhere(
      (r) => r.id == widget.residentId,
      orElse: () => SpecialistResidentFile(
        id: widget.residentId,
        name: 'مقيم غير معروف',
        nameEn: 'Unknown',
        room: '--',
        status: 'updated',
        lastUpdate: '',
        initials: '?',
        age: 0,
        phone: '',
        categories: ['resident'],
        familyMembers: [],
      ),
    );

    // تحويل البيانات من SpecialistResidentFile إلى Resident model (الذي تستخدمه الواجهة)
    final r = Resident(
      id: resident.id,
      name: resident.name,
      roomNumber: resident.room,
      gender: resident.gender ?? 'غير محدد',
      birthDate:
          DateTime.now().subtract(Duration(days: 365 * (resident.age ?? 0))),
      entryDate: DateTime.now(),
      nationalId: resident.nationalId ?? 'غير متوفر',
      imageUrl: resident.imageUrl,
      emergencyContactName: resident.emergencyContactName ?? 'غير محدد',
      emergencyContactPhone:
          resident.emergencyContactPhone ?? resident.phone ?? '',
      emergencyRelation: resident.emergencyRelation ?? 'غير محدد',
      bloodType: resident.bloodType ?? 'A+',
      chronicDiseases: resident.chronicDiseases ?? [],
      allergies: resident.allergies ?? [],
      insuranceInfo: resident.insuranceInfo ?? 'لا يوجد',
      primaryDoctorName: resident.primaryDoctorName,
      mobilityStatus: resident.mobilityStatus ?? 'مستقل',
      assistiveDevices: resident.assistiveDevices ?? [],
      cognitiveStatus: resident.cognitiveStatus ?? 'وعي كامل',
      dietType: resident.dietType ?? 'عادي',
      foodRestrictions: resident.foodRestrictions ?? [],
      foodPreferences: resident.foodPreferences ?? 'غير محدد',
      previousProfession: resident.previousProfession ?? 'غير محدد',
      hobbies: resident.hobbies ?? [],
      socialStatus: resident.socialStatus ?? 'غير محدد',
      contractType: 'إقامة دائمة',
      uploadedDocuments: resident.uploadedDocuments ?? [],
    );

    return TaptabaScaffold(
      title: 'ونس',
      titleColor: const Color(0xFF0F172A),
      overrideRole: 'مدير',
      body: Column(
        children: [
          _buildProfileHeader(context, r),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfo(r),
                _buildMedicalInfo(r),
                _buildMobilityInfo(r),
                _buildDietaryInfo(r),
                _buildSocialInfo(r),
                _buildFamilyLinkInfo(r),
                _buildDocumentsInfo(r),
                _buildAINotesTab(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorWeight: 3,
        indicatorColor: const Color(0xFF0ea5e9),
        labelColor: const Color(0xFF0369a1),
        unselectedLabelColor: const Color(0xFF94a3b8),
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
        tabs: const [
          Tab(text: 'البيانات الشخصية'),
          Tab(text: 'الملف الطبي'),
          Tab(text: 'الحالة الحركية'),
          Tab(text: 'النظام الغذائي'),
          Tab(text: 'الجانب الاجتماعي'),
          Tab(text: 'إدارة العائلة'),
          Tab(text: 'المستندات'),
          Tab(text: 'ملاحظات الذكاء الاصطناعي'),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Resident r) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('ملف المقيم الشامل',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit')),
              IconButton(
                icon: Icon(
                    _isEditMode
                        ? Icons.check_circle_rounded
                        : Icons.edit_note_rounded,
                    color: _isEditMode ? Colors.greenAccent : Colors.white,
                    size: 28),
                onPressed: () {
                  setState(() => _isEditMode = !_isEditMode);
                  if (!_isEditMode) {
                    _showPopup(
                      context,
                      'تم حفظ التعديلات بنجاح',
                      type: AppPopupNotificationType.success,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // صورة المقيم الممركزة
          Hero(
            tag: 'profile_${r.id}',
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Builder(
                    builder: (context) {
                      final String? imageUrl = r.imageUrl;
                      final imageProvider = _residentImageProvider(imageUrl);
                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white12,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 45)
                            : null,
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      final saved = await ref
                          .read(appRiverpod)
                          .pickAndSetResidentImage(widget.residentId);
                      if (!context.mounted || saved == null) return;
                      final error = ref.read(appRiverpod).backendSyncError;
                      _showPopup(
                        context,
                        saved
                            ? 'تم حفظ صورة المقيم بنجاح'
                            : 'تم اختيار الصورة محلياً، لكن فشل حفظها على السيرفر: ${error ?? 'حاول مرة أخرى'}',
                        type: saved
                            ? AppPopupNotificationType.success
                            : AppPopupNotificationType.error,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0ea5e9),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF1e293b), width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // الاسم والمعلومات الممركزة
          Text(
            r.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          Text(
            'الغرفة ${r.roomNumber}  —  العمر ${r.age} عاماً',
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(Resident r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('البيانات الشخصية الأساسية', [
          _infoRow('الاسم بالكامل', r.name, Icons.person_outline),
          _infoRow('النوع', _genderLabel(r.gender), Icons.wc_rounded),
          _infoRow('الرقم القومي', r.nationalId, Icons.badge_outlined),
          _infoRow(
              'تاريخ الميلاد',
              '${r.birthDate.day}/${r.birthDate.month}/${r.birthDate.year}',
              Icons.calendar_today_outlined),
          _infoRow(
              'تاريخ الدخول',
              '${r.entryDate.day}/${r.entryDate.month}/${r.entryDate.year}',
              Icons.login_rounded),
          _infoRow('رقم الغرفة', r.roomNumber, Icons.door_front_door_outlined),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('بيانات الطوارئ والوصي', [
          _infoRow('اسم المسؤول', r.emergencyContactName,
              Icons.contact_emergency_outlined),
          _infoRow('صلة القرابة', r.emergencyRelation, Icons.people_outline),
          _infoRow('رقم الهاتف', r.emergencyContactPhone,
              Icons.phone_android_outlined),
        ]),
        const SizedBox(height: 24),
        // زر حذف الملف بالكامل
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(context, r),
            icon: const Icon(Icons.delete_forever_rounded,
                color: Colors.redAccent, size: 20),
            label: const Text('حذف ملف المقيم نهائياً',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit')),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, Resident r) {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تأكيد الحذف النهائي ⚠️',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'هل أنت متأكد من رغبتك في حذف ملف المقيم "${r.name}" بالكامل؟ لا يمكن التراجع عن هذا الإجراء.',
            textAlign: TextAlign.center),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final notificationContext =
                  Navigator.of(context, rootNavigator: true).context;
              final provider = ref.read(appRiverpod);
              Navigator.pop(dialogContext);
              navigator.pop();
              final deleted = await provider.deleteResident(r.id);
              if (!notificationContext.mounted) return;
              _showPopup(
                notificationContext,
                deleted
                    ? 'تم حذف ملف ${r.name} بنجاح'
                    : 'تعذر حذف ملف ${r.name}: ${provider.backendSyncError ?? 'حاول مرة أخرى'}',
                type: deleted
                    ? AppPopupNotificationType.success
                    : AppPopupNotificationType.error,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text('نعم، احذف الملف'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfo(Resident r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('الملف الطبي والتحذيرات', [
          _infoRow('فصيلة الدم', r.bloodType, Icons.bloodtype_outlined,
              valColor: Colors.redAccent),
          _infoRow('الأمراض المزمنة', r.chronicDiseases.join('، '),
              Icons.healing_outlined),
          _infoRow(
              'الحساسية',
              r.allergies.isEmpty ? 'لا يوجد' : r.allergies.join('، '),
              Icons.warning_amber_rounded,
              valColor: Colors.orange),
          _infoRow(
              'العمليات السابقة',
              r.pastSurgeries.isEmpty ? 'لا يوجد' : r.pastSurgeries.join('، '),
              Icons.medication_outlined),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('التأمين الطبي والجهة المعالجة', [
          _infoRow('جهة التأمين', r.insuranceInfo, Icons.shield_outlined),
          _infoRow('الطبيب المتابع', r.primaryDoctorName ?? 'غير محدد',
              Icons.person_search_outlined),
        ]),
      ],
    );
  }

  Widget _buildMobilityInfo(Resident r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('الحالة الحركية والوظيفية', [
          _infoRow(
              'درجة الحركة', r.mobilityStatus, Icons.directions_walk_rounded),
          _infoRow('الأجهزة المساعدة', r.assistiveDevices.join('، '),
              Icons.accessible_forward_rounded),
          _infoRow(
              'الحالة الذهنية', r.cognitiveStatus, Icons.psychology_outlined),
        ]),
      ],
    );
  }

  Widget _buildDietaryInfo(Resident r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('نظام الغذاء والتفضيلات', [
          _infoRow(
              'نوع النظام الغذائي', r.dietType, Icons.restaurant_menu_rounded),
          _infoRow('الممنوعات الغذائية', r.foodRestrictions.join('، '),
              Icons.no_food_outlined,
              valColor: Colors.red),
          _infoRow('تفضيلات خاصة', r.foodPreferences,
              Icons.favorite_outline_rounded),
        ]),
      ],
    );
  }

  Widget _buildSocialInfo(Resident r) {
    final appData = ref.watch(appRiverpod);
    final resident =
        appData.residentFiles.where((rf) => rf.id == r.id).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDirectEditCard(
          title: 'التاريخ الاجتماعي والنشاطات',
          onEdit:
              resident != null ? () => _showSocialHistoryForm(resident) : null,
          children: [
            _infoRow(
                'المهنة السابقة',
                resident?.previousProfession ?? r.previousProfession,
                Icons.work_outline_rounded),
            _infoRow(
                'الهوايات والنشاطات',
                (resident?.hobbies ?? r.hobbies).join('، '),
                Icons.interests_outlined),
            _infoRow(
                'الحالة الاجتماعية',
                resident?.socialStatus ?? r.socialStatus,
                Icons.family_restroom_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectEditCard(
      {required String title,
      required List<Widget> children,
      VoidCallback? onEdit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFf1f5f9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0369a1),
                        fontFamily: 'Outfit')),
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 16, color: Color(0xFF0369a1)),
                    ),
                  ),
              ],
            ),
            const Divider(height: 25, color: Color(0xFFf1f5f9), thickness: 1.5),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyLinkInfo(Resident r) {
    final appData = ref.watch(appRiverpod);
    final residentFile =
        appData.residentFiles.where((rf) => rf.id == r.id).firstOrNull;
    final members = residentFile?.familyMembers ?? [];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ─── Header card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0369a1).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.family_restroom_rounded,
                        color: Color(0xFF0ea5e9), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('إدارة أفراد العائلة',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                  ),
                  _buildAddMemberButton(r.id),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'ربط أفراد العائلة بحساباتهم ليتمكنوا من متابعة التقارير اليومية والأدوية.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748b)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Members list ─────────────────────────────────────────────
        if (members.isEmpty)
          _buildEmptyFamilyState(r.id)
        else
          ...members.map((m) => _buildFamilyMemberCard(m, r.id)),
      ],
    );
  }

  Widget _buildAddMemberButton(String residentId) {
    return GestureDetector(
      onTap: () => _showAddFamilyMemberSheet(residentId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF0ea5e9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_rounded, color: Colors.white, size: 15),
            SizedBox(width: 5),
            Text('إضافة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFamilyState(String residentId) {
    return GestureDetector(
      onTap: () => _showAddFamilyMemberSheet(residentId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_add_rounded,
                  color: Color(0xFF0ea5e9), size: 32),
            ),
            const SizedBox(height: 16),
            const Text('لا يوجد أفراد عائلة مرتبطين',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155))),
            const SizedBox(height: 6),
            const Text('اضغط لإضافة فرد من العائلة وربطه بهذا المقيم',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0ea5e9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('إضافة فرد من العائلة',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMemberCard(FamilyMember member, String residentId) {
    final email = member.email?.trim() ?? '';
    final hasEmail = email.isNotEmpty;
    final isLinked = member.userId != null && member.userId!.isNotEmpty;
    final isPendingConfirmation = hasEmail && !isLinked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.name.isNotEmpty ? member.name[0] : '؟',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369a1)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(member.relation,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748b))),
                if (hasEmail) ...[
                  const SizedBox(height: 3),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748b)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLinked
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isLinked
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFFFDBA74),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLinked
                                  ? Icons.verified_rounded
                                  : Icons.hourglass_top_rounded,
                              size: 11,
                              color: isLinked
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFF97316),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isLinked ? 'تم التأكيد' : 'قيد انتظار التأكيد',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isLinked
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFF97316),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasEmail || isPendingConfirmation)
                IconButton(
                  onPressed: () => _showSendInviteSheet(residentId, member),
                  icon: const Icon(Icons.send_rounded,
                      size: 18, color: Color(0xFF0ea5e9)),
                  tooltip: isPendingConfirmation
                      ? 'إعادة إرسال الدعوة'
                      : 'إرسال دعوة',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () =>
                    _showDeleteFamilyMemberDialog(residentId, member),
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Color(0xFFEF4444)),
                tooltip: 'حذف',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddFamilyMemberSheet(String residentId) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_add_rounded,
                          color: Color(0xFF0ea5e9), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('إضافة فرد من العائلة',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                    'أدخل بيانات فرد العائلة. سيصله بريد دعوة للتحقق والربط بحساب المقيم.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
                const SizedBox(height: 20),
                _sheetField('الاسم الكامل', nameCtrl,
                    icon: Icons.person_outline_rounded),
                const SizedBox(height: 12),
                _sheetField('صلة القرابة (مثال: ابن، أخت)', relationCtrl,
                    icon: Icons.people_outline_rounded),
                const SizedBox(height: 12),
                _sheetField('البريد الإلكتروني (للدعوة)', emailCtrl,
                    icon: Icons.alternate_email_rounded,
                    keyboard: TextInputType.emailAddress,
                    ltr: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0ea5e9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: saving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final relation = relationCtrl.text.trim();
                            if (name.isEmpty) {
                              _showPopup(
                                ctx,
                                'أدخل الاسم الكامل',
                                type: AppPopupNotificationType.warning,
                              );
                              return;
                            }
                            if (email.isNotEmpty && !email.contains('@')) {
                              _showPopup(
                                ctx,
                                'أدخل بريداً إلكترونياً صحيحاً أو اتركه فارغاً',
                                type: AppPopupNotificationType.warning,
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              await BackendMutationService.instance
                                  .createFamilyMemberForEmail(
                                residentId: residentId,
                                email: email.isNotEmpty ? email : null,
                                fullName: name,
                                relationship:
                                    relation.isNotEmpty ? relation : 'عائلة',
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ref.read(appRiverpod).syncBackendData();
                                _showPopup(
                                  context,
                                  email.isNotEmpty
                                      ? 'تمت الإضافة وتم إرسال بريد الدعوة إلى $email'
                                      : 'تمت إضافة $name بنجاح',
                                  type: AppPopupNotificationType.success,
                                );
                              }
                            } catch (e) {
                              setSheetState(() => saving = false);
                              final errorText = _friendlyErrorText(e);
                              if (errorText.contains('تم حفظ فرد العائلة')) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ref.read(appRiverpod).syncBackendData();
                                  _showPopup(
                                    context,
                                    errorText,
                                    type: AppPopupNotificationType.warning,
                                  );
                                }
                                return;
                              }
                              if (ctx.mounted) {
                                _showPopup(
                                  ctx,
                                  'خطأ: $errorText',
                                  type: AppPopupNotificationType.error,
                                );
                              }
                            }
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                        saving ? 'جاري الإضافة...' : 'إضافة وإرسال الدعوة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSendInviteSheet(String residentId, FamilyMember member) {
    final existingEmail = member.email?.trim() ?? '';
    final emailCtrl = TextEditingController(text: existingEmail);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.mail_outline_rounded,
                          color: Color(0xFFF97316), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إرسال دعوة',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('إلى: ${member.name}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF64748b))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sheetField('البريد الإلكتروني', emailCtrl,
                    icon: Icons.alternate_email_rounded,
                    keyboard: TextInputType.emailAddress,
                    ltr: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: saving
                        ? null
                        : () async {
                            final email = emailCtrl.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              _showPopup(
                                ctx,
                                'أدخل بريداً إلكترونياً صحيحاً',
                                type: AppPopupNotificationType.warning,
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              await BackendMutationService.instance
                                  .updateFamilyMemberEmail(
                                memberId: member.id,
                                email: email,
                                residentId: residentId,
                                fullName: member.name,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ref.read(appRiverpod).syncBackendData();
                                _showPopup(
                                  context,
                                  'تم إرسال الدعوة إلى $email',
                                  type: AppPopupNotificationType.success,
                                );
                              }
                            } catch (e) {
                              setSheetState(() => saving = false);
                              if (ctx.mounted) {
                                final errorText = _friendlyErrorText(e);
                                _showPopup(
                                  ctx,
                                  'خطأ: $errorText',
                                  type: AppPopupNotificationType.error,
                                );
                              }
                            }
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(saving
                        ? 'جاري الإرسال...'
                        : existingEmail.isEmpty
                            ? 'إرسال الدعوة'
                            : 'إعادة إرسال الدعوة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteFamilyMemberDialog(String residentId, FamilyMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف فرد العائلة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
            'هل تريد حذف "${member.name}" من قائمة أفراد العائلة المرتبطين؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final provider = ref.read(appRiverpod);
              Navigator.pop(ctx);
              final deleted = await provider.deleteFamilyMemberFromResident(
                residentId: residentId,
                member: member,
              );
              if (!mounted) return;
              _showPopup(
                context,
                deleted
                    ? 'تم حذف ${member.name} بنجاح'
                    : 'تعذر حذف ${member.name}: ${provider.backendSyncError ?? 'حاول مرة أخرى'}',
                type: deleted
                    ? AppPopupNotificationType.success
                    : AppPopupNotificationType.error,
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
    bool ltr = false,
  }) {
    return TextField(
      controller: ctrl,
      textAlign: ltr ? TextAlign.left : TextAlign.right,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0ea5e9), width: 1.5)),
      ),
    );
  }

  Widget _buildDocumentsInfo(Resident r) {
    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.0,
          ),
          itemCount: r.uploadedDocuments.length + 1,
          itemBuilder: (context, index) {
            if (index == r.uploadedDocuments.length) {
              return _buildAddDocCard();
            }
            return _buildDocCard(r.uploadedDocuments[index]);
          },
        ),
        if (_isUploading)
          Container(
            color: Colors.black26,
            child: const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFf1f5f9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: InkWell(
        onTap: _isEditMode ? () => _editSection(title) : null,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369a1),
                          fontFamily: 'Outfit')),
                  if (_isEditMode)
                    const Icon(Icons.edit_rounded,
                        size: 18, color: Colors.blueAccent),
                ],
              ),
              const Divider(
                  height: 25, color: Color(0xFFf1f5f9), thickness: 1.5),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon,
      {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0xFFf1f5f9),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: const Color(0xFF0ea5e9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94a3b8),
                        fontFamily: 'Outfit')),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: valColor ?? const Color(0xFF1e293b),
                      fontFamily: 'Outfit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editSection(String title) {
    final appData = ref.read(appRiverpod);
    final resident = appData.residentFiles
        .where((r) => r.id == widget.residentId)
        .firstOrNull;
    if (resident == null) return;

    switch (title) {
      case 'البيانات الشخصية الأساسية':
        _showBasicInfoForm(resident);
        break;
      case 'بيانات الطوارئ والوصي':
        _showEmergencyContactForm(resident);
        break;
      case 'الملف الطبي والتحذيرات':
        _showMedicalInfoForm(resident);
        break;
      case 'الحالة الحركية والوظيفية':
        _showMobilityForm(resident);
        break;
      case 'نظام الغذاء والتفضيلات':
        _showDietForm(resident);
        break;
      case 'التأمين الطبي والجهة المعالجة':
        _showInsuranceForm(resident);
        break;
      case 'التاريخ الاجتماعي والنشاطات':
        _showSocialHistoryForm(resident);
        break;
      case 'إدارة ربط العائلة':
        _showFamilyLinkForm(resident);
        break;
      default:
        _showComingSoonSheet(title);
    }
  }

  void _showBasicInfoForm(SpecialistResidentFile resident) {
    final nameParts = resident.name.trim().split(RegExp(r'\s+'));
    final firstCtrl = TextEditingController(
        text: nameParts.isNotEmpty ? nameParts.first : '');
    final lastCtrl = TextEditingController(
        text: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '');
    final nameEnCtrl = TextEditingController(text: resident.nameEn);
    final roomCtrl = TextEditingController(text: resident.room);
    final phoneCtrl = TextEditingController(text: resident.phone ?? '');
    final nationalIdCtrl =
        TextEditingController(text: resident.nationalId ?? '');
    String selectedGender = _genderForForm(resident.gender);
    // Birth year derived from age (approximate)
    final currentYear = DateTime.now().year;
    final birthYearCtrl = TextEditingController(
        text: resident.age != null ? '${currentYear - resident.age!}' : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تعديل البيانات الشخصية',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _field('الاسم الأول', firstCtrl),
                  const SizedBox(height: 12),
                  _field('اسم العائلة', lastCtrl),
                  const SizedBox(height: 12),
                  _field('الاسم بالإنجليزية', nameEnCtrl, ltr: true),
                  const SizedBox(height: 12),
                  _field('رقم الغرفة', roomCtrl,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _field('رقم الهاتف / المعرف', phoneCtrl,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field('الرقم القومي', nationalIdCtrl),
                  const SizedBox(height: 12),
                  _genderField(
                    current: selectedGender,
                    onChanged: (value) =>
                        setSheetState(() => selectedGender = value),
                  ),
                  const SizedBox(height: 12),
                  _field('سنة الميلاد (مثال: 1950)', birthYearCtrl,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0ea5e9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              try {
                                final birthYear =
                                    int.tryParse(birthYearCtrl.text.trim());
                                final updatedResident = resident.copyWith(
                                  name:
                                      '${firstCtrl.text.trim()} ${lastCtrl.text.trim()}'
                                          .trim(),
                                  nameEn: nameEnCtrl.text.trim().isEmpty
                                      ? resident.nameEn
                                      : nameEnCtrl.text.trim(),
                                  room: roomCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  nationalId: nationalIdCtrl.text.trim(),
                                  gender: selectedGender,
                                  age: birthYear != null
                                      ? DateTime.now().year - birthYear
                                      : resident.age,
                                );
                                await ref
                                    .read(appRiverpod)
                                    .updateResident(updatedResident);
                                if (birthYear != null) {
                                  await BackendMutationService.instance
                                      .updateDateOfBirth(
                                    residentId: resident.id,
                                    dateOfBirth: DateTime(birthYear, 1, 1),
                                  );
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ref.read(appRiverpod).syncBackendData();
                                  _showPopup(
                                    context,
                                    'تم تحديث البيانات بنجاح',
                                    type: AppPopupNotificationType.success,
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => saving = false);
                                if (ctx.mounted) {
                                  final errorText = _friendlyErrorText(e);
                                  _showPopup(
                                    ctx,
                                    'خطأ: $errorText',
                                    type: AppPopupNotificationType.error,
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('حفظ التغييرات',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMedicalInfoForm(SpecialistResidentFile resident) {
    final bloodCtrl = TextEditingController(text: resident.bloodType ?? '');
    final allergiesCtrl =
        TextEditingController(text: (resident.allergies ?? []).join('، '));
    final diseasesCtrl = TextEditingController(
        text: (resident.chronicDiseases ?? []).join('، '));

    _showSimpleEditSheet(
      title: 'تعديل الملف الطبي',
      color: const Color(0xFFEF4444),
      fields: [
        _field('فصيلة الدم', bloodCtrl),
        const SizedBox(height: 12),
        _field('الأمراض المزمنة (مفصولة بفاصلة)', diseasesCtrl),
        const SizedBox(height: 12),
        _field('الحساسية (مفصولة بفاصلة)', allergiesCtrl),
      ],
      onSave: () async {
        final diseases = _splitCSV(diseasesCtrl.text);
        final allergies = _splitCSV(allergiesCtrl.text);
        final updatedResident = resident.copyWith(
          bloodType: bloodCtrl.text.trim(),
          chronicDiseases: diseases,
          allergies: allergies,
        );
        await BackendMutationService.instance.upsertMedicalInfo(
          residentId: resident.id,
          info: ResidentMedicalInfo(
            residentName: resident.name,
            chronicDiseases: diseases,
            allergies: allergies,
          ),
        );
        await ref.read(appRiverpod).updateResident(updatedResident);
      },
    );
  }

  void _showMobilityForm(SpecialistResidentFile resident) {
    final mobilityCtrl =
        TextEditingController(text: resident.mobilityStatus ?? '');
    final assistiveDevicesCtrl = TextEditingController(
        text: (resident.assistiveDevices ?? []).join('، '));
    final cognitiveCtrl =
        TextEditingController(text: resident.cognitiveStatus ?? '');

    _showSimpleEditSheet(
      title: 'تعديل الحالة الحركية',
      color: const Color(0xFF6366F1),
      fields: [
        _field('حالة الحركة (مثال: مستقل، كرسي متحرك)', mobilityCtrl),
        const SizedBox(height: 12),
        _field('الأجهزة المساعدة (مفصولة بفاصلة)', assistiveDevicesCtrl),
        const SizedBox(height: 12),
        _field('الحالة الذهنية', cognitiveCtrl),
      ],
      onSave: () => ref.read(appRiverpod).updateResident(
            resident.copyWith(
              mobilityStatus: mobilityCtrl.text.trim(),
              assistiveDevices: _splitCSV(assistiveDevicesCtrl.text),
              cognitiveStatus: cognitiveCtrl.text.trim(),
            ),
          ),
    );
  }

  void _showDietForm(SpecialistResidentFile resident) {
    final dietCtrl = TextEditingController(text: resident.dietType ?? '');
    final restrictionsCtrl = TextEditingController(
        text: (resident.foodRestrictions ?? []).join('، '));
    final preferencesCtrl =
        TextEditingController(text: resident.foodPreferences ?? '');

    _showSimpleEditSheet(
      title: 'تعديل النظام الغذائي',
      color: const Color(0xFF10B981),
      fields: [
        _field('نوع النظام الغذائي (مثال: عادي، مهروس، سوائل)', dietCtrl),
        const SizedBox(height: 12),
        _field('الممنوعات الغذائية (مفصولة بفاصلة)', restrictionsCtrl),
        const SizedBox(height: 12),
        _field('تفضيلات الطعام', preferencesCtrl),
      ],
      onSave: () => ref.read(appRiverpod).updateResident(
            resident.copyWith(
              dietType: dietCtrl.text.trim(),
              foodPreferences: preferencesCtrl.text.trim(),
              foodRestrictions: _splitCSV(restrictionsCtrl.text),
            ),
          ),
    );
  }

  List<String> _splitCSV(String raw) => raw
      .split(RegExp(r'[،,]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  String _friendlyErrorText(Object error) {
    final text = error.toString();
    final match = RegExp(r'ApiException\(\d+\):\s*(.*)$').firstMatch(text);
    return match?.group(1) ?? text;
  }

  String _genderLabel(String gender) {
    final normalized = gender.trim().toLowerCase();
    if (normalized == 'female' || normalized == 'أنثى') return 'أنثى';
    if (normalized == 'male' || normalized == 'ذكر') return 'ذكر';
    if (normalized == 'other' || normalized == 'آخر') return 'آخر';
    return gender.isEmpty ? 'غير محدد' : gender;
  }

  void _showInsuranceForm(SpecialistResidentFile resident) {
    final insuranceCtrl =
        TextEditingController(text: resident.insuranceInfo ?? '');
    final doctorCtrl =
        TextEditingController(text: resident.primaryDoctorName ?? '');

    _showSimpleEditSheet(
      title: 'تعديل التأمين والجهة المعالجة',
      color: const Color(0xFF0369A1),
      fields: [
        _field('جهة التأمين الصحي', insuranceCtrl),
        const SizedBox(height: 12),
        _field('اسم الطبيب المتابع', doctorCtrl),
      ],
      onSave: () => ref.read(appRiverpod).updateResident(
            resident.copyWith(
              insuranceInfo: insuranceCtrl.text.trim(),
              primaryDoctorName: doctorCtrl.text.trim(),
            ),
          ),
    );
  }

  void _showSocialHistoryForm(SpecialistResidentFile resident) {
    final professionCtrl =
        TextEditingController(text: resident.previousProfession ?? '');
    final hobbiesCtrl =
        TextEditingController(text: (resident.hobbies ?? []).join('، '));
    final statusCtrl = TextEditingController(text: resident.socialStatus ?? '');

    _showSimpleEditSheet(
      title: 'تعديل التاريخ الاجتماعي والنشاطات',
      color: const Color(0xFFD97706),
      fields: [
        _field('المهنة السابقة', professionCtrl),
        const SizedBox(height: 12),
        _field('الهوايات والنشاطات (مفصولة بفاصلة)', hobbiesCtrl),
        const SizedBox(height: 12),
        _field('الحالة الاجتماعية (مثال: متزوج، أرمل)', statusCtrl),
      ],
      onSave: () async {
        await ref.read(appRiverpod).updateResident(
              resident.copyWith(
                previousProfession: professionCtrl.text.trim(),
                socialStatus: statusCtrl.text.trim(),
                hobbies: _splitCSV(hobbiesCtrl.text),
              ),
            );
      },
    );
  }

  void _showSimpleEditSheet({
    required String title,
    required Color color,
    required List<Widget> fields,
    required Future<void> Function() onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ...fields,
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              try {
                                await onSave();
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ref.read(appRiverpod).syncBackendData();
                                  _showPopup(
                                    context,
                                    'تم تحديث البيانات بنجاح',
                                    type: AppPopupNotificationType.success,
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => saving = false);
                                if (ctx.mounted) {
                                  final errorText = _friendlyErrorText(e);
                                  _showPopup(
                                    ctx,
                                    'خطأ: $errorText',
                                    type: AppPopupNotificationType.error,
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('حفظ التغييرات',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEmergencyContactForm(SpecialistResidentFile resident) {
    final nameCtrl =
        TextEditingController(text: resident.emergencyContactName ?? '');
    final phoneCtrl = TextEditingController(
        text: resident.emergencyContactPhone ?? resident.phone ?? '');
    final relationCtrl =
        TextEditingController(text: resident.emergencyRelation ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تعديل بيانات الطوارئ والوصي',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _field('اسم جهة الطوارئ', nameCtrl),
                  const SizedBox(height: 12),
                  _field('رقم الهاتف', phoneCtrl,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field('صلة القرابة (مثال: ابن، ابنة)', relationCtrl),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFef4444),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: saving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();
                              final relation = relationCtrl.text.trim();
                              if (name.isEmpty || phone.isEmpty) {
                                _showPopup(
                                  ctx,
                                  'أدخل الاسم ورقم الهاتف على الأقل',
                                  type: AppPopupNotificationType.warning,
                                );
                                return;
                              }
                              setSheetState(() => saving = true);
                              try {
                                await ref.read(appRiverpod).updateResident(
                                      resident.copyWith(
                                        emergencyContactName: name,
                                        emergencyContactPhone: phone,
                                        emergencyRelation: relation,
                                        phone: resident.phone ?? phone,
                                      ),
                                    );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ref.read(appRiverpod).syncBackendData();
                                  _showPopup(
                                    context,
                                    'تم تحديث بيانات الطوارئ بنجاح',
                                    type: AppPopupNotificationType.success,
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => saving = false);
                                if (ctx.mounted) {
                                  _showPopup(
                                    ctx,
                                    'خطأ: ${_friendlyErrorText(e)}',
                                    type: AppPopupNotificationType.error,
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('حفظ بيانات الطوارئ',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFamilyLinkForm(SpecialistResidentFile resident) {
    final emailCtrl = TextEditingController(text: resident.familyEmail ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إضافة ربط عائلة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                      'أدخل البريد الإلكتروني لأحد أفراد العائلة لمنحه صلاحية متابعة المقيم.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
                  const SizedBox(height: 20),
                  _field('البريد الإلكتروني', emailCtrl,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: saving
                          ? null
                          : () async {
                              final email = emailCtrl.text.trim();
                              if (email.isEmpty || !email.contains('@')) {
                                _showPopup(
                                  ctx,
                                  'أدخل بريداً إلكترونياً صحيحاً',
                                  type: AppPopupNotificationType.warning,
                                );
                                return;
                              }
                              setSheetState(() => saving = true);
                              try {
                                await BackendMutationService.instance
                                    .createFamilyMemberForEmail(
                                  residentId: resident.id,
                                  email: email,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ref.read(appRiverpod).syncBackendData();
                                  _showPopup(
                                    context,
                                    'تم إرسال دعوة الربط بنجاح',
                                    type: AppPopupNotificationType.success,
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => saving = false);
                                if (ctx.mounted) {
                                  final errorText = _friendlyErrorText(e);
                                  _showPopup(
                                    ctx,
                                    'خطأ: $errorText',
                                    type: AppPopupNotificationType.error,
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('إرسال دعوة الربط',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showComingSoonSheet(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded,
                size: 48, color: Color(0xFF94a3b8)),
            const SizedBox(height: 16),
            Text('تعديل: $title',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'سيتوفر هذا النموذج في التحديث القادم.',
              style: TextStyle(color: Color(0xFF64748b), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType keyboardType = TextInputType.text, bool ltr = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          textAlign: ltr ? TextAlign.left : TextAlign.right,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
          ),
        ),
      ],
    );
  }

  String _genderForForm(String? gender) {
    final normalized = (gender ?? '').trim().toLowerCase();
    if (normalized == 'female' || normalized == 'أنثى') return 'female';
    if (normalized == 'other' || normalized == 'آخر') return 'other';
    return 'male';
  }

  Widget _genderField({
    required String current,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('النوع',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFe2e8f0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              items: const [
                DropdownMenuItem(value: 'male', child: Text('ذكر')),
                DropdownMenuItem(value: 'female', child: Text('أنثى')),
                DropdownMenuItem(value: 'other', child: Text('آخر')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocCard(String path) {
    final fileName = _fileNameFromPath(path);
    return InkWell(
      onTap: () => _downloadDocument(path),
      onLongPress: () => _confirmDeleteDoc(path),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFe2e8f0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.insert_drive_file_rounded,
                  color: Color(0xFF0369a1), size: 42),
              const SizedBox(height: 10),
              Text(
                fileName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: () => _downloadDocument(path),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('تحميل', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0369a1),
                    side: const BorderSide(color: Color(0xFFbae6fd)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fileNameFromPath(String path) {
    final value = path.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.last);
    }
    final name = value.split(RegExp(r'[\\/]')).last;
    return name.isEmpty ? 'مستند' : name;
  }

  Future<void> _downloadDocument(String path) async {
    final value = path.trim();
    if (value.isEmpty) {
      _showPopup(
        context,
        'لا يوجد رابط صالح لتحميل المستند',
        type: AppPopupNotificationType.error,
      );
      return;
    }

    final parsed = Uri.tryParse(value);
    final uri = parsed != null &&
            (parsed.scheme == 'http' ||
                parsed.scheme == 'https' ||
                parsed.scheme == 'file')
        ? parsed
        : Uri.file(value);
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    _showPopup(
      context,
      opened ? 'تم فتح رابط تحميل المستند' : 'تعذر فتح رابط المستند',
      type: opened
          ? AppPopupNotificationType.info
          : AppPopupNotificationType.error,
    );
  }

  void _confirmDeleteDoc(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستند؟'),
        content: Text('هل أنت متأكد من حذف "$path"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildAddDocCard() {
    return InkWell(
      onTap: _isUploading ? null : () => _pickAndUploadDocument(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF0ea5e9),
                style: BorderStyle.solid,
                width: 2)),
        child: _isUploading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF0ea5e9), strokeWidth: 2.5))
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: Color(0xFF0ea5e9), size: 35),
                  SizedBox(height: 8),
                  Text('رفع مستند',
                      style: TextStyle(
                          color: Color(0xFF0ea5e9),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Future<void> _pickAndUploadDocument() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ResidentDocumentService.allowedExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final filePath = file.path;
    if (filePath == null) return;

    setState(() => _isUploading = true);
    try {
      final doc = await ResidentDocumentService.instance.uploadDocument(
        residentId: widget.residentId,
        filePath: filePath,
      );
      if (mounted) {
        ref.read(appRiverpod).addDocumentToResident(widget.residentId, doc.url);
        _showPopup(
          context,
          'تم رفع "${file.name}" بنجاح',
          type: AppPopupNotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showPopup(
          context,
          'فشل رفع المستند: ${_friendlyErrorText(e)}',
          type: AppPopupNotificationType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ignore: unused_element
  Widget _buildDeleteBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
        label: const Text('حذف ملف المقيم بالكامل',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
      ),
    );
  }

  // ── تبويب ملاحظات وتوصيات الذكاء الاصطناعي ────────────────────────
  Widget _buildAINotesTab(Resident r) {
    final appData = ref.watch(appRiverpod);
    // نبحث عن ملاحظات الذكاء الاصطناعي الخاصة بهذا المقيم
    final aiNotes = appData.getResidentAINotes(r.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ترويسة التبويب
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ملاحظات وتوصيات الذكاء الاصطناعي',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      Text('تحليل مبني على المحادثات والسلوك والتفاعلات',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (aiNotes == null || aiNotes.isEmpty)
            _buildAIEmptyState()
          else ...[
            if (aiNotes.summary?.isNotEmpty == true)
              _buildAISection('الملخص', stripUuids(aiNotes.summary!),
                  Icons.summarize_rounded, const Color(0xFF6366F1)),
            if (aiNotes.recommendations?.isNotEmpty == true)
              _buildAISection('التوصيات', stripUuids(aiNotes.recommendations!),
                  Icons.recommend_rounded, const Color(0xFF059669)),
            if (aiNotes.warnings?.isNotEmpty == true)
              _buildAISection('التحذيرات', stripUuids(aiNotes.warnings!),
                  Icons.warning_amber_rounded, const Color(0xFFDC2626)),
            if (aiNotes.moodInsights?.isNotEmpty == true)
              _buildAISection(
                  'تحليل المزاج والحالة النفسية',
                  stripUuids(aiNotes.moodInsights!),
                  Icons.psychology_rounded,
                  const Color(0xFF0EA5E9)),
            const SizedBox(height: 8),
            if (aiNotes.lastUpdated != null)
              Text(
                'آخر تحديث: ${aiNotes.lastUpdated}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
                textAlign: TextAlign.end,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF6366F1), size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد ملاحظات أو توصيات\nمن الذكاء الاصطناعي حالياً',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748b),
                  height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'ستظهر التوصيات بعد تراكم بيانات المحادثات والتفاعلات',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISection(
      String title, String content, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF374151), height: 1.6)),
        ],
      ),
    );
  }
}
