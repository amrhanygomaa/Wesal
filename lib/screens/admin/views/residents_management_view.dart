import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api_config.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';
import '../../../widgets/app_popup_notification.dart';
import '../admin_resident_detail_screen.dart';

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

class ResidentsManagementView extends ConsumerStatefulWidget {
  final List<Animation<double>> fadeAnimations;

  const ResidentsManagementView({super.key, required this.fadeAnimations});

  @override
  ConsumerState<ResidentsManagementView> createState() =>
      _ResidentsManagementViewState();
}

class _ResidentsManagementViewState
    extends ConsumerState<ResidentsManagementView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final provider = ref.watch(appRiverpod);

    final filteredResidents = provider.residentFiles.where((r) {
      final nameMatch = r.name.contains(_searchQuery);
      final roomMatch = r.room.contains(_searchQuery);
      final nameEnMatch =
          r.nameEn.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch || roomMatch || nameEnMatch;
    }).toList();

    return Stack(
      children: [
        Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            if (filteredResidents.isEmpty)
              _buildEmptyState()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: List.generate(filteredResidents.length, (index) {
                    final r = filteredResidents[index];
                    return FadeTransition(
                      opacity: widget
                          .fadeAnimations[index % widget.fadeAnimations.length],
                      child: _buildResidentControlCard(r),
                    );
                  }),
                ),
              ),
            const SizedBox(height: 100), // مساحة للزر العائم
          ],
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showResidentForm(context, ref),
            backgroundColor: const Color(0xFF0f172a),
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: const Text('إضافة مقيم',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo')),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('لا يوجد نتائج لـ "$_searchQuery"',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFe2e8f0))),
        child: TextField(
          controller: _searchController,
          textAlign: TextAlign.right,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'بحث عن مقيم أو غرفة...',
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94a3b8)),
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Color(0xFF94a3b8), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildResidentControlCard(SpecialistResidentFile r) {
    Color statusColor = r.status == 'critical'
        ? Colors.red
        : (r.status == 'pending' ? Colors.amber : Colors.green);
    String statusText = r.status == 'critical'
        ? 'حالة حرجة'
        : (r.status == 'pending' ? 'متابعة دقيقة' : 'مستقر');

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 2, right: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: statusColor.withValues(alpha: 0.05),
              blurRadius: 1,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdminResidentDetailScreen(residentId: r.id),
              ),
            ),
            borderRadius: BorderRadius.circular(24),
            splashColor: statusColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 1. أيقونة التعريف الملونة (3D Effect)
                      GestureDetector(
                        onTap: () async {
                          final saved = await ref
                              .read(appRiverpod)
                              .pickAndSetResidentImage(r.id);
                          if (!mounted || saved == null) return;
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
                        child: Stack(
                          children: [
                            Builder(
                              builder: (context) {
                                final String? img = r.imageUrl;
                                final imageProvider =
                                    _residentImageProvider(img);
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        statusColor.withValues(alpha: 0.2),
                                        statusColor.withValues(alpha: 0.05),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    image: imageProvider != null
                                        ? DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: imageProvider == null
                                      ? Center(
                                          child: Text(
                                            r.name.isNotEmpty
                                                ? (r.name.isNotEmpty
                                                    ? r.name.substring(0, 1)
                                                    : 'م')
                                                : 'م',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                            ),
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 2. معلومات المقيم
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0f172a),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.meeting_room_rounded,
                                    size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  'غرفة ${r.room}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 3. مؤشر الحالة الجمالي
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'تعديل بيانات المقيم',
                        onPressed: () =>
                            _showResidentForm(context, ref, resident: r),
                        icon: const Icon(Icons.edit_note_rounded,
                            color: Color(0xFF0369a1)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResidentForm(BuildContext context, WidgetRef ref,
      {SpecialistResidentFile? resident}) {
    final bool isEdit = resident != null;
    final nameArController = TextEditingController(text: resident?.name ?? '');
    final nameEnController =
        TextEditingController(text: resident?.nameEn ?? '');
    final roomController = TextEditingController(text: resident?.room ?? '');
    final phoneController = TextEditingController(text: resident?.phone ?? '');
    final ageController =
        TextEditingController(text: resident?.age?.toString() ?? '');
    final nationalIdController =
        TextEditingController(text: resident?.nationalId ?? '');
    String selectedGender = _genderForForm(resident?.gender);
    final emergencyNameController =
        TextEditingController(text: resident?.emergencyContactName ?? '');
    final emergencyPhoneController = TextEditingController(
        text: resident?.emergencyContactPhone ?? resident?.phone ?? '');
    final emergencyRelationController =
        TextEditingController(text: resident?.emergencyRelation ?? '');
    String selectedStatus = resident?.status ?? 'updated';

    // Medical State
    final bloodTypeController =
        TextEditingController(text: resident?.bloodType ?? 'A+');
    final chronicDiseasesController = TextEditingController(
        text: (resident?.chronicDiseases ?? []).join('، '));
    final allergiesController =
        TextEditingController(text: (resident?.allergies ?? []).join('، '));
    final insuranceInfoController =
        TextEditingController(text: resident?.insuranceInfo ?? '');
    final primaryDoctorController =
        TextEditingController(text: resident?.primaryDoctorName ?? '');

    // Functional/Dietary State
    const mobilityOptions = [
      'مستقل',
      'مساعدة خفيفة',
      'كرسي متحرك',
      'طريح الفراش'
    ];
    String mobilityStatus = mobilityOptions.contains(resident?.mobilityStatus)
        ? resident!.mobilityStatus!
        : 'مستقل';
    final assistiveDevicesController = TextEditingController(
        text: (resident?.assistiveDevices ?? []).join('، '));
    final cognitiveStatusController =
        TextEditingController(text: resident?.cognitiveStatus ?? '');
    final dietTypeController =
        TextEditingController(text: resident?.dietType ?? 'عادي');
    final foodRestrictionsController = TextEditingController(
        text: (resident?.foodRestrictions ?? []).join('، '));
    final foodPreferencesController =
        TextEditingController(text: resident?.foodPreferences ?? '');

    // Social State
    final professionController =
        TextEditingController(text: resident?.previousProfession ?? '');
    final hobbiesController =
        TextEditingController(text: (resident?.hobbies ?? []).join('، '));
    final socialStatusController =
        TextEditingController(text: resident?.socialStatus ?? '');
    final familyEmailController =
        TextEditingController(text: resident?.familyEmail ?? '');

    // Validation State
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85, // جعل النافذة أكبر
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 15),
                Text(isEdit ? 'تعديل بيانات المقيم ✏️' : 'تسجيل مقيم شامل 👥',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0f172a))),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('البيانات الأساسية'),
                        _buildLabel('الاسم بالكامل (عربي) *'),
                        _buildField(nameArController,
                            'اسم المقيم كما سيحفظ في السيرفر'),
                        const SizedBox(height: 12),
                        _buildLabel('الاسم بالإنجليزية'),
                        _buildField(nameEnController, 'Resident Name',
                            isEn: true),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  _buildLabel('العمر'),
                                  _buildField(ageController, '70',
                                      keyboardType: TextInputType.number)
                                ])),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  _buildLabel('رقم الغرفة *'),
                                  _buildField(roomController, '101',
                                      keyboardType: TextInputType.number)
                                ])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLabel('رقم الهاتف / المعرف'),
                        _buildField(phoneController, '01xxxxxxxxx',
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        _buildLabel('الرقم القومي'),
                        _buildField(nationalIdController, 'الرقم القومي'),
                        const SizedBox(height: 12),
                        _buildLabel('النوع'),
                        _buildGenderDropdown(
                          selectedGender,
                          (val) => setModalState(() => selectedGender = val),
                        ),
                        const SizedBox(height: 12),
                        _buildLabel('بريد العائلة المرتبط'),
                        _buildField(familyEmailController, 'family@example.com',
                            keyboardType: TextInputType.emailAddress,
                            isEn: true),
                        const SizedBox(height: 24),
                        _buildSectionHeader('بيانات الطوارئ والوصي'),
                        _buildLabel('اسم جهة الطوارئ'),
                        _buildField(emergencyNameController, 'اسم المسؤول'),
                        const SizedBox(height: 12),
                        _buildLabel('هاتف الطوارئ'),
                        _buildField(emergencyPhoneController, '01xxxxxxxxx',
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        _buildLabel('صلة القرابة'),
                        _buildField(emergencyRelationController,
                            'ابن، ابنة، زوج/زوجة، ...'),
                        const SizedBox(height: 24),
                        _buildSectionHeader('الملف الطبي'),
                        Row(
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  _buildLabel('فصيلة الدم'),
                                  _buildField(bloodTypeController, 'A+')
                                ])),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  _buildLabel('الحالة الصحية'),
                                  _buildMiniStatus(
                                      selectedStatus,
                                      (val) => setModalState(
                                          () => selectedStatus = val))
                                ])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLabel('الأمراض المزمنة (افصل بفاصلة)'),
                        _buildField(
                            chronicDiseasesController, 'السكري، ضغط، ...'),
                        const SizedBox(height: 12),
                        _buildLabel('الحساسية'),
                        _buildField(
                            allergiesController, 'البنسلين، أطعمة معينة، ...'),
                        const SizedBox(height: 12),
                        _buildLabel('بيانات التأمين الصحي'),
                        _buildField(insuranceInfoController,
                            'شركة التأمين أو رقم الملف الطبي'),
                        const SizedBox(height: 12),
                        _buildLabel('الطبيب المتابع'),
                        _buildField(primaryDoctorController, 'اسم الطبيب'),
                        const SizedBox(height: 24),
                        _buildSectionHeader('الحالة الحركية والغذائية'),
                        _buildLabel('درجة الحركة'),
                        _buildDropdown(
                            mobilityOptions,
                            mobilityStatus,
                            (val) =>
                                setModalState(() => mobilityStatus = val!)),
                        const SizedBox(height: 12),
                        _buildLabel('الأجهزة المساعدة'),
                        _buildField(assistiveDevicesController,
                            'نظارة، سماعة، مشاية، ...'),
                        const SizedBox(height: 12),
                        _buildLabel('الحالة الذهنية'),
                        _buildField(cognitiveStatusController,
                            'وعي كامل، ضعف ذاكرة، ...'),
                        const SizedBox(height: 12),
                        _buildLabel('نوع النظام الغذائي'),
                        _buildField(
                            dietTypeController, 'عادي، مهروس، سوائل...'),
                        const SizedBox(height: 12),
                        _buildLabel('الممنوعات من الطعام'),
                        _buildField(foodRestrictionsController,
                            'السكريات، الأملاح، ...'),
                        const SizedBox(height: 12),
                        _buildLabel('تفضيلات الطعام'),
                        _buildField(foodPreferencesController,
                            'يفضل الشوربة، لا يحب الأطعمة الحارة، ...'),
                        const SizedBox(height: 24),
                        _buildSectionHeader('الجانب الاجتماعي'),
                        _buildLabel('المهنة السابقة'),
                        _buildField(professionController, 'مثلاً: مدرس متقاعد'),
                        const SizedBox(height: 12),
                        _buildLabel('الهوايات'),
                        _buildField(hobbiesController, 'القراءة، المشي، ...'),
                        const SizedBox(height: 12),
                        _buildLabel('الحالة الاجتماعية'),
                        _buildField(
                            socialStatusController, 'متزوج، أرمل، أعزب، ...'),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final residentData = SpecialistResidentFile(
                          id: isEdit
                              ? resident.id
                              : 'r${DateTime.now().millisecondsSinceEpoch}',
                          name: nameArController.text.trim(),
                          nameEn: nameEnController.text.trim().isEmpty
                              ? nameArController.text.trim()
                              : nameEnController.text.trim(),
                          room: roomController.text.trim(),
                          status: selectedStatus,
                          lastUpdate:
                              isEdit ? 'تم التحديث الآن' : 'تم التسجيل الآن',
                          initials: nameArController.text.trim().isNotEmpty
                              ? nameArController.text.trim().substring(0, 1)
                              : 'م',
                          categories:
                              isEdit ? resident.categories : ['resident'],
                          familyMembers: isEdit
                              ? resident.familyMembers
                              : <FamilyMember>[],
                          age: int.tryParse(ageController.text) ??
                              resident?.age ??
                              70,
                          phone: phoneController.text.trim(),
                          familyEmail: familyEmailController.text.trim().isEmpty
                              ? resident?.familyEmail
                              : familyEmailController.text.trim(),
                          nationalId: nationalIdController.text.trim(),
                          gender: selectedGender,
                          emergencyContactName:
                              emergencyNameController.text.trim(),
                          emergencyContactPhone:
                              emergencyPhoneController.text.trim(),
                          emergencyRelation:
                              emergencyRelationController.text.trim(),
                          bloodType: bloodTypeController.text.trim(),
                          chronicDiseases:
                              _splitCommaValues(chronicDiseasesController.text),
                          allergies:
                              _splitCommaValues(allergiesController.text),
                          insuranceInfo: insuranceInfoController.text.trim(),
                          primaryDoctorName:
                              primaryDoctorController.text.trim(),
                          mobilityStatus: mobilityStatus,
                          assistiveDevices: _splitCommaValues(
                              assistiveDevicesController.text),
                          cognitiveStatus:
                              cognitiveStatusController.text.trim(),
                          dietType: dietTypeController.text.trim(),
                          foodRestrictions: _splitCommaValues(
                              foodRestrictionsController.text),
                          foodPreferences:
                              foodPreferencesController.text.trim(),
                          previousProfession: professionController.text.trim(),
                          hobbies: _splitCommaValues(hobbiesController.text),
                          socialStatus: socialStatusController.text.trim(),
                          uploadedDocuments:
                              isEdit ? resident.uploadedDocuments : const [],
                          imageUrl: isEdit ? resident.imageUrl : null,
                        );

                        if (isEdit) {
                          ref.read(appRiverpod).updateResident(residentData);
                        } else {
                          ref.read(appRiverpod).addResident(residentData);
                        }
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0ea5e9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    child: Text(
                        isEdit ? 'حفظ التعديلات' : 'تأكيد التسجيل الشامل',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _splitCommaValues(String raw) => raw
      .split(RegExp(r'[،,]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFe2e8f0))),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0ea5e9)))),
            const Expanded(child: Divider(color: Color(0xFFe2e8f0))),
          ],
        ),
      );

  Widget _buildMiniStatus(String current, Function(String) onSelect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          onChanged: (v) => onSelect(v!),
          items: const [
            DropdownMenuItem(
                value: 'updated',
                child: Text('مستقر', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(
                value: 'pending',
                child: Text('متابعة', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(
                value: 'critical',
                child: Text('حرجة', style: TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items, String current, Function(String?) onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          onChanged: onChange,
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13))))
              .toList(),
        ),
      ),
    );
  }

  String _genderForForm(String? gender) {
    final normalized = (gender ?? '').trim().toLowerCase();
    if (normalized == 'female' || normalized == 'أنثى') return 'female';
    if (normalized == 'other' || normalized == 'آخر') return 'other';
    return 'male';
  }

  Widget _buildGenderDropdown(String current, ValueChanged<String> onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          onChanged: (value) {
            if (value != null) onChange(value);
          },
          items: const [
            DropdownMenuItem(
                value: 'male',
                child: Text('ذكر', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(
                value: 'female',
                child: Text('أنثى', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(
                value: 'other',
                child: Text('آخر', style: TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155))),
      );

  Widget _buildField(TextEditingController controller, String hint,
      {TextInputType? keyboardType,
      String? Function(String?)? validator,
      bool isEn = false}) {
    return TextFormField(
      controller: controller,
      textAlign: isEn ? TextAlign.left : TextAlign.right,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94a3b8)),
        filled: true,
        fillColor: const Color(0xFFf8fafc),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0ea5e9))),
        errorStyle: const TextStyle(fontSize: 10),
      ),
    );
  }

  // ignore: unused_element
  Widget _statusOption(String value, String label, Color color, bool isSelected,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? color : const Color(0xFFe2e8f0))),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748b),
                      fontSize: 13,
                      fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showLinkFamilySheet(
      BuildContext context, WidgetRef ref, SpecialistResidentFile resident) {
    final emailController = TextEditingController(text: resident.familyEmail);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text('ربط فرد عائلة بـ ${resident.name} 🔗',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0f172a))),
            const Text(
                'أدخل البريد الإلكتروني المسجل لفرد العائلة ليتمكن من متابعة حالة المسن',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
            const SizedBox(height: 24),
            _buildLabel('بريد فرد العائلة'),
            _buildField(emailController, 'example@family.com',
                keyboardType: TextInputType.emailAddress, isEn: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  final provider = ref.read(appRiverpod);
                  final linked = await provider.linkFamilyToResident(
                    resident.id,
                    emailController.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showPopup(
                    context,
                    linked
                        ? 'تم ربط فرد العائلة وإرسال الدعوة بنجاح'
                        : 'تعذر إرسال دعوة الربط: ${provider.backendSyncError ?? 'حاول مرة أخرى'}',
                    type: linked
                        ? AppPopupNotificationType.success
                        : AppPopupNotificationType.error,
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0ea5e9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: const Text('تأكيد الربط',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
