import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';
import '../nurse_medications_screen.dart';
import '../widgets/healing_particles.dart';

class OperationsView extends ConsumerStatefulWidget {
  const OperationsView({super.key});

  @override
  ConsumerState<OperationsView> createState() => _OperationsViewState();
}

class _OperationsViewState extends ConsumerState<OperationsView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const NurseMedicationsScreen(),
              _buildCareChecklist(provider),
              _buildInventory(provider),
              _buildDoctorLog(provider),
              _buildNutrition(provider),
              _buildActivities(provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const HealingParticles(), // إضافة الأنيميشن الموحد
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إدارة العمليات والمنشأة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('تنظيم المهام اليومية، الأدوية، وإدارة المخزون',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: const Color(0xFF0369A1),
        unselectedLabelColor: isDark ? Colors.white54 : const Color(0xFF94A3B8),
        indicatorColor: const Color(0xFF0369A1),
        indicatorWeight: 4,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'Cairo'),
        tabs: const [
          Tab(child: FittedBox(child: Text('الأدوية'))),
          Tab(child: FittedBox(child: Text('المهام'))),
          Tab(child: FittedBox(child: Text('المخزون'))),
          Tab(child: FittedBox(child: Text('الزيارات'))),
          Tab(child: FittedBox(child: Text('التغذية'))),
          Tab(child: FittedBox(child: Text('الأنشطة'))),
        ],
      ),
    );
  }

  // --- 1. Care Checklist ---
  Widget _buildCareChecklist(AppRiverpod provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.careTasks.length + 1, // إضافة زر الإضافة في النهاية
      itemBuilder: (context, index) {
        if (index == provider.careTasks.length) {
          return _buildAddTaskButton(provider);
        }

        final task = provider.careTasks[index];
        final isDone = task.isCompleted;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDone
                ? (isDark
                    ? const Color(0xFF10B981).withValues(alpha: 0.05)
                    : const Color(0xFFF0FDF4))
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              width: isDone ? 1.5 : 1.0,
            ),
            boxShadow: isDone
                ? []
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => provider.toggleCareTask(task.id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF10B981)
                            : Colors.transparent,
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFF10B981)
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDone
                                  ? const Color(0xFF94A3B8)
                                  : (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A)),
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${task.residentName} · ${task.time}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDone
                                  ? const Color(0xFFCBD5E1)
                                  : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _categoryChip(task.category),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => provider.deleteCareTask(task.id),
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFEF4444), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTaskButton(AppRiverpod provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showAddTaskModal(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F9FF),
          foregroundColor: const Color(0xFF0369A1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFBAE6FD))),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('إضافة مهمة جديدة',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddTaskModal(AppRiverpod provider) {
    final titleController = TextEditingController();
    final residentController = TextEditingController();
    final timeController = TextEditingController();
    String selectedCategory = 'شخصية';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 24),
                  const Text('إضافة مهمة جديدة لرعاية مسن',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان المهمة',
                      hintText: 'مثلاً: تغيير ملابس، رياضة...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: residentController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المسن',
                      hintText: 'اسم المقيم كما يظهر من السيرفر',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'الوقت',
                      hintText: 'مثلاً: ٠٨:٠٠ ص',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('التصنيف:',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  Row(
                    children: ['شخصية', 'ترفيهية', 'فندقية'].map((cat) {
                      final active = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: active,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => selectedCategory = cat);
                            }
                          },
                          selectedColor: const Color(0xFFE0F2FE),
                          labelStyle: TextStyle(
                              color: active
                                  ? const Color(0xFF0369A1)
                                  : const Color(0xFF475569),
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            residentController.text.isNotEmpty) {
                          provider.addCareTask(CareTask(
                            id: 'c_custom_${DateTime.now().millisecondsSinceEpoch}',
                            title: titleController.text,
                            residentName: residentController.text,
                            time: timeController.text.isNotEmpty
                                ? timeController.text
                                : '٠٨:٠٠ ص',
                            category: selectedCategory,
                          ));
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0369A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('حفظ المهمة',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _categoryChip(String cat) {
    Color color = const Color(0xFF0EA5E9);
    if (cat == 'فندقية') color = const Color(0xFF6366F1);
    if (cat == 'ترفيهية') color = const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Text(cat,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // --- 2. Inventory ---
  Widget _buildInventory(AppRiverpod provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.inventoryItems.length + 1,
      itemBuilder: (context, index) {
        if (index == provider.inventoryItems.length) {
          return _buildAddInventoryButton(provider);
        }
        final item = provider.inventoryItems[index];
        final progress = item.currentStock / (item.minRequired * 2);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark
                    ? Colors.white12
                    : const Color(0xFF0EA5E9).withValues(alpha: 0.5),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: item.isLowStock
                            ? (isDark
                                ? const Color(0xFF991B1B).withValues(alpha: 0.2)
                                : const Color(0xFFFEF2F2))
                            : (isDark
                                ? const Color(0xFF0C4A6E).withValues(alpha: 0.2)
                                : const Color(0xFFF0F9FF)),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                        item.isLowStock ? 'مخزون منخفض ⚠️' : 'متوفر بشكل جيد ✅',
                        style: TextStyle(
                            color: item.isLowStock
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF0284C7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item.name,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () =>
                              provider.deleteInventoryItem(item.id),
                          icon: const Icon(Icons.delete_outline,
                              color: Color(0xFFEF4444), size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: progress > 1.0 ? 1.0 : progress,
                        backgroundColor:
                            isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        color: item.isLowStock
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                      '${item.currentStock} / ${item.minRequired * 2} ${item.unit}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155))),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showSupplyRequestModal(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0369A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      icon:
                          const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('طلب توريد',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              provider.updateInventoryStock(item.id, 1),
                          icon: const Icon(Icons.add_rounded,
                              color: Color(0xFF0EA5E9), size: 22),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        Container(
                            width: 1,
                            height: 20,
                            color: const Color(0xFFE2E8F0)),
                        IconButton(
                          onPressed: item.currentStock > 0
                              ? () => provider.updateInventoryStock(item.id, -1)
                              : null,
                          icon: Icon(Icons.remove_rounded,
                              color: item.currentStock > 0
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFFCBD5E1),
                              size: 22),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSupplyRequestModal(InventoryItem item) {
    int requestedQuantity = item.minRequired; // الكمية الافتراضية للطلب
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 24),
                  const Icon(Icons.inventory_2_rounded,
                      size: 50, color: Color(0xFF0369A1)),
                  const SizedBox(height: 16),
                  Text('طلب توريد لـ ${item.name}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Text('الرصيد الحالي: ${item.currentStock} ${item.unit}',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF64748B))),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: requestedQuantity > 1
                            ? () => setModalState(() => requestedQuantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded,
                            size: 36, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 24),
                      Text('$requestedQuantity',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0369A1))),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: () =>
                            setModalState(() => requestedQuantity++),
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            size: 36, color: Color(0xFF0EA5E9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('الكمية المطلوبة (${item.unit})',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        // إرسال إشعار للإدارة
                        ref.read(appRiverpod).triggerNotification(
                              title: 'طلب توريد جديد 📦',
                              body:
                                  'تم إرسال طلب توريد ($requestedQuantity ${item.unit}) من "${item.name}" إلى الإدارة.',
                              type: 'admin',
                              targetRole: 'إدارة',
                            );

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('تم إرسال الطلب للإدارة بنجاح',
                              style: TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0369A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('تأكيد وإرسال الطلب',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  Widget _buildAddInventoryButton(AppRiverpod provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showAddInventoryModal(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F9FF),
          foregroundColor: const Color(0xFF0369A1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFBAE6FD))),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('إضافة مادة للمخزون',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddInventoryModal(AppRiverpod provider) {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final minController = TextEditingController();
    final unitController = TextEditingController();
    String selectedCategory = 'أدوية';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 24),
                  const Text('إضافة مادة جديدة للمخزون',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المادة',
                      hintText: 'مثلاً: بندول ٥٠٠ مجم، حفاضات...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'المخزون الحالي',
                            hintText: 'مثلاً: ٢٠',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'الحد الأدنى',
                            hintText: 'مثلاً: ١٠',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'الوحدة',
                      hintText: 'مثلاً: شريط، علبة، عبوة...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('التصنيف:',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  Row(
                    children: ['أدوية', 'شخصي', 'مستلزمات'].map((cat) {
                      final active = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: active,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => selectedCategory = cat);
                            }
                          },
                          selectedColor: const Color(0xFFE0F2FE),
                          labelStyle: TextStyle(
                              color: active
                                  ? const Color(0xFF0369A1)
                                  : const Color(0xFF475569),
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty &&
                            stockController.text.isNotEmpty &&
                            minController.text.isNotEmpty) {
                          provider.addInventoryItem(InventoryItem(
                            id: 'i_custom_${DateTime.now().millisecondsSinceEpoch}',
                            name: nameController.text,
                            category: selectedCategory,
                            currentStock: int.parse(stockController.text),
                            minRequired: int.parse(minController.text),
                            unit: unitController.text.isNotEmpty
                                ? unitController.text
                                : 'قطعة',
                          ));
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0369A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('حفظ المادة',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // --- 3. Doctor Log ---
  Widget _buildDoctorLog(AppRiverpod provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.doctorVisits.length + 1,
      itemBuilder: (context, index) {
        if (index == provider.doctorVisits.length) {
          return _buildAddDoctorVisitButton(provider);
        }
        final visit = provider.doctorVisits[index];
        bool isUpcoming = visit.date.isAfter(DateTime.now());

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isUpcoming
                ? (isDark
                    ? const Color(0xFF0C4A6E).withValues(alpha: 0.2)
                    : const Color(0xFFF0F9FF))
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isUpcoming
                    ? const Color(0xFF0EA5E9).withValues(alpha: 0.3)
                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? const Color(0xFFE0F2FE)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                        isUpcoming ? 'زيارة مرتقبة 🗓️' : 'تمت الزيارة ✅',
                        style: TextStyle(
                            color: isUpcoming
                                ? const Color(0xFF0369A1)
                                : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      Text(visit.doctorName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => provider.deleteDoctorVisit(visit.id),
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFEF4444), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('${visit.specialty} · لمتابعة حالة ${visit.residentName}',
                  style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? Colors.white60 : const Color(0xFF475569))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الغرض من الزيارة:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(visit.purpose,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B))),
                    if (visit.results.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text('النتائج والتوصيات:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF10B981))),
                      const SizedBox(height: 4),
                      Text(visit.results,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddDoctorVisitButton(AppRiverpod provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showAddDoctorVisitModal(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F9FF),
          foregroundColor: const Color(0xFF0369A1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFBAE6FD))),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('إضافة زيارة طبيب',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddDoctorVisitModal(AppRiverpod provider) {
    final doctorController = TextEditingController();
    final specialtyController = TextEditingController();
    final purposeController = TextEditingController();
    final resultsController = TextEditingController();
    final residentController = TextEditingController();
    bool isGeneral = true;
    bool isCompleted = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                const Text('إضافة زيارة طبيب جديدة',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                TextField(
                  controller: doctorController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الطبيب',
                    hintText: 'اسم الطبيب من بيانات السيرفر',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specialtyController,
                  decoration: const InputDecoration(
                    labelText: 'التخصص',
                    hintText: 'مثلاً: باطنة، عظام...',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('نوع الزيارة:',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('زيارة عامة للدار'),
                      selected: isGeneral,
                      onSelected: (val) {
                        setModalState(() => isGeneral = val);
                      },
                      selectedColor: const Color(0xFFE0F2FE),
                      labelStyle: TextStyle(
                          color: isGeneral
                              ? const Color(0xFF0369A1)
                              : const Color(0xFF475569),
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('زيارة لمقيم'),
                      selected: !isGeneral,
                      onSelected: (val) {
                        setModalState(() => isGeneral = !val);
                      },
                      selectedColor: const Color(0xFFE0F2FE),
                      labelStyle: TextStyle(
                          color: !isGeneral
                              ? const Color(0xFF0369A1)
                              : const Color(0xFF475569),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!isGeneral)
                  TextField(
                    controller: residentController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المقيم',
                      hintText: 'اسم المقيم كما يظهر من السيرفر',
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeController,
                  decoration: const InputDecoration(
                    labelText: 'الغرض من الزيارة',
                    hintText: 'مثلاً: فحص دوري، شكوى من ألم...',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('هل تمت الزيارة؟'),
                    const Spacer(),
                    Switch(
                      value: isCompleted,
                      onChanged: (val) {
                        setModalState(() => isCompleted = val);
                      },
                      activeThumbColor: const Color(0xFF0369A1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isCompleted)
                  TextField(
                    controller: resultsController,
                    decoration: const InputDecoration(
                      labelText: 'النتائج والتوصيات',
                      hintText: 'مثلاً: استقرار الحالة، صرف دواء...',
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (doctorController.text.isNotEmpty &&
                          specialtyController.text.isNotEmpty) {
                        provider.addDoctorVisit(DoctorVisit(
                          id: 'v_custom_${DateTime.now().millisecondsSinceEpoch}',
                          doctorName: doctorController.text,
                          specialty: specialtyController.text,
                          date: isCompleted
                              ? DateTime.now()
                                  .subtract(const Duration(hours: 1))
                              : DateTime.now().add(const Duration(days: 1)),
                          purpose: purposeController.text,
                          results: resultsController.text,
                          residentName: isGeneral
                              ? 'عامة للدار'
                              : residentController.text,
                        ));
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0369A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('حفظ الزيارة',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // --- 4. Nutrition ---
  Widget _buildNutrition(AppRiverpod provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.mealPlans.length + 1,
      itemBuilder: (context, index) {
        if (index == provider.mealPlans.length) {
          return _buildAddMealPlanButton(provider);
        }
        final plan = provider.mealPlans[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ]),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: Color(0xFFFFEDD5))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.restaurant_rounded,
                        color: Color(0xFFEA580C)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                                'الخطة الغذائية لـ ${plan.residentName}',
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF9A3412))),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () =>
                                provider.deleteMealPlan(plan.residentName),
                            icon: const Icon(Icons.delete_outline,
                                color: Color(0xFFEF4444), size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _mealRow('وجبة الإفطار 🍳', plan.breakfast),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _mealRow('وجبة الغداء 🍲', plan.lunch),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _mealRow('وجبة العشاء 🥛', plan.dinner),
                    if (plan.snacks.isNotEmpty) ...[
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _mealRow('وجبة خفيفة 🍎', plan.snacks),
                    ],
                    if (plan.isAiGenerated) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF4FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF0ABFC)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: Color(0xFFC026D3), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('توصية الذكاء الاصطناعي',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF86198F))),
                                  const SizedBox(height: 4),
                                  Text(plan.aiRationale ?? '',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF701A75))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (plan.specialInstructions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFECACA))),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(plan.specialInstructions,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFB91C1C),
                                        fontWeight: FontWeight.bold,
                                        height: 1.5))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddMealPlanButton(AppRiverpod provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showGenerateAiDietModal(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDF4FF),
                foregroundColor: const Color(0xFFC026D3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFF0ABFC))),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('✨ توليد خطة ذكية بالـ AI',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddMealPlanModal(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F9FF),
                foregroundColor: const Color(0xFF0369A1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFBAE6FD))),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('إضافة خطة غذائية يدوياً',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentNutritionSearch({
    required AppRiverpod provider,
    required String labelText,
    required String hintText,
    required ValueChanged<String> onTextChanged,
    required ValueChanged<SpecialistResidentFile> onSelected,
  }) {
    return Autocomplete<SpecialistResidentFile>(
      displayStringForOption: (resident) => resident.name,
      optionsBuilder: (textEditingValue) {
        return provider.searchResidentsForNutrition(textEditingValue.text);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          onChanged: onTextChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        final width = min(MediaQuery.of(context).size.width - 48, 360.0);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SizedBox(
                width: width,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final resident = options.elementAt(index);
                    return ListTile(
                      onTap: () => onSelectedOption(resident),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF0F9FF),
                        child: Text(
                          resident.initials.isNotEmpty
                              ? resident.initials
                              : (resident.name.isNotEmpty
                                  ? resident.name[0]
                                  : '؟'),
                          style: const TextStyle(
                              color: Color(0xFF0369A1),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        resident.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'غرفة ${resident.room} · كود ${_shortResidentCode(resident.id)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutritionProfilePreview(
    AppRiverpod provider,
    SpecialistResidentFile resident,
  ) {
    final info = provider.getNutritionMedicalInfo(resident);
    final restrictions = [
      if ((resident.dietType ?? '').trim().isNotEmpty)
        'النظام: ${resident.dietType}',
      ...info.chronicDiseases,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded,
                  color: Color(0xFF0369A1), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${resident.name} · غرفة ${resident.room} · كود ${_shortResidentCode(resident.id)}',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (restrictions.isEmpty && info.allergies.isEmpty)
                _nutritionChip('لا توجد قيود مسجلة', const Color(0xFF059669)),
              ...restrictions
                  .take(4)
                  .map((item) => _nutritionChip(item, const Color(0xFF0369A1))),
              ...info.allergies.take(3).map(
                    (item) => _nutritionChip(
                      'حساسية: $item',
                      const Color(0xFFDC2626),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutritionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _shortResidentCode(String id) {
    final clean = id.trim();
    if (clean.length <= 8) return clean.isEmpty ? 'غير محدد' : clean;
    return clean.substring(0, 8);
  }

  void _showGenerateAiDietModal(AppRiverpod provider) {
    String residentLookup = '';
    SpecialistResidentFile? selectedResident;
    bool isGenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFC026D3)),
                    SizedBox(width: 8),
                    Text('توليد خطة غذائية بالـ AI',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF86198F))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildResidentNutritionSearch(
                  provider: provider,
                  labelText: 'بحث عن المقيم',
                  hintText: 'ابحث بالاسم، رقم الغرفة، أو كود المقيم',
                  onTextChanged: (value) {
                    residentLookup = value;
                    setModalState(() {
                      selectedResident =
                          provider.findResidentForNutrition(value);
                    });
                  },
                  onSelected: (resident) {
                    residentLookup = resident.name;
                    setModalState(() => selectedResident = resident);
                  },
                ),
                const SizedBox(height: 12),
                if (selectedResident != null)
                  _buildNutritionProfilePreview(provider, selectedResident!)
                else if (residentLookup.trim().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Text(
                      'اختر المقيم من نتائج البحث لضمان حفظ الخطة في ملفه الصحيح.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: Color(0xFF9A3412),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isGenerating
                        ? null
                        : () async {
                            final lookup =
                                selectedResident?.name ?? residentLookup.trim();
                            if (lookup.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ابحث واختر المقيم أولاً'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                              return;
                            }

                            setModalState(() => isGenerating = true);
                            try {
                              await provider.generateAndSaveMealPlan(lookup);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              final hasSyncWarning =
                                  provider.backendSyncError != null;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(hasSyncWarning
                                      ? 'تم توليد الخطة محلياً، لكن تعذر حفظها على السيرفر: ${provider.backendSyncError}'
                                      : 'تم توليد وحفظ الخطة الغذائية بنجاح'),
                                  backgroundColor: hasSyncWarning
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF059669),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              setModalState(() => isGenerating = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC026D3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('✨ توليد وحفظ',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showAddMealPlanModal(AppRiverpod provider) {
    String residentLookup = '';
    SpecialistResidentFile? selectedResident;
    final breakfastController = TextEditingController();
    final lunchController = TextEditingController();
    final dinnerController = TextEditingController();
    final instructionsController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                const Text('إضافة خطة غذائية جديدة',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                _buildResidentNutritionSearch(
                  provider: provider,
                  labelText: 'بحث عن المقيم',
                  hintText: 'ابحث بالاسم، رقم الغرفة، أو كود المقيم',
                  onTextChanged: (value) {
                    residentLookup = value;
                    setModalState(() {
                      selectedResident =
                          provider.findResidentForNutrition(value);
                    });
                  },
                  onSelected: (resident) {
                    residentLookup = resident.name;
                    setModalState(() => selectedResident = resident);
                  },
                ),
                if (selectedResident != null) ...[
                  const SizedBox(height: 12),
                  _buildNutritionProfilePreview(provider, selectedResident!),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: breakfastController,
                  decoration: const InputDecoration(
                    labelText: 'وجبة الإفطار',
                    hintText: 'مثلاً: فول، بيض...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lunchController,
                  decoration: const InputDecoration(
                    labelText: 'وجبة الغداء',
                    hintText: 'مثلاً: فراخ مشوية، أرز...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dinnerController,
                  decoration: const InputDecoration(
                    labelText: 'وجبة العشاء',
                    hintText: 'مثلاً: زبادي، فاكهة...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'تعليمات خاصة',
                    hintText: 'مثلاً: قليل الملح، تقطيع الطعام...',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final lookup =
                                selectedResident?.name ?? residentLookup.trim();
                            if (lookup.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ابحث واختر المقيم أولاً'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                              return;
                            }
                            setModalState(() => isSaving = true);
                            await provider.addMealPlan(MealPlan(
                              residentName: lookup,
                              breakfast: breakfastController.text,
                              lunch: lunchController.text,
                              dinner: dinnerController.text,
                              snacks: '',
                              specialInstructions: instructionsController.text,
                            ));
                            if (!context.mounted) return;
                            if (provider.backendSyncError != null) {
                              setModalState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.backendSyncError!),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0369A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('حفظ الخطة',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _mealRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF334155), height: 1.4))),
        const SizedBox(width: 16),
        Container(
          width: 100,
          alignment: Alignment.centerLeft,
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0369A1))),
        ),
      ],
    );
  }

  // --- 5. Activities ---
  Widget _buildActivities(AppRiverpod provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.activitySessions.length,
      itemBuilder: (context, index) {
        final session = provider.activitySessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24))),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.local_activity_rounded,
                          color: Color(0xFF4F46E5), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF312E81))),
                          const SizedBox(height: 2),
                          Text(
                              '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')} · في ${session.location}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF4338CA))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.description,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.5)),
                    const SizedBox(height: 20),
                    const Text('المشاركين:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: session.participants
                          .map((p) => _activityParticipantName(provider, p))
                          .map((p) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0))),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person_rounded,
                                        size: 14, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 6),
                                    Text(p,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF334155),
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _activityParticipantName(AppRiverpod provider, String participant) {
    final clean = participant.trim();
    if (clean.isEmpty) return 'مشارك غير معروف';

    for (final resident in provider.residentFiles) {
      if (resident.id == clean ||
          resident.name == clean ||
          resident.nameEn == clean ||
          resident.nationalId == clean) {
        return resident.name;
      }
      for (final member in resident.familyMembers) {
        if (member.id == clean ||
            member.userId == clean ||
            member.email == clean ||
            member.name == clean) {
          return member.name;
        }
      }
    }

    for (final member in provider.familyMembersList) {
      if (member.id == clean ||
          member.userId == clean ||
          member.email == clean ||
          member.name == clean) {
        return member.name;
      }
    }

    return _looksLikeIdentifier(clean) ? 'مشارك غير معروف' : clean;
  }

  bool _looksLikeIdentifier(String value) {
    return RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(value) ||
        RegExp(r'^[0-9a-fA-F]{24,}$').hasMatch(value);
  }
}
