import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:students_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEditStudentScreen extends ConsumerStatefulWidget {
  const AddEditStudentScreen({this.studentId, super.key});

  final String? studentId; // null = add, non-null = edit

  static const String addPath = '/admin/students/add';
  static String editPath(String id) => '/admin/students/$id/edit';
  @override
  ConsumerState<AddEditStudentScreen> createState() =>
      _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends ConsumerState<AddEditStudentScreen> {
  final _nameController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedLevel;
  int _selectedAvatarIndex = 0;
  bool _isLoading = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _levels = [
    'المرحلة الابتدائية',
    'المرحلة المتوسطة',
    'المرحلة الثانوية',
    'Beginner',
    'Intermediate Grammar',
    'Advanced',
  ];

  bool get isEditing => widget.studentId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.studentId!)
          .single();

      _nameController.text = data['full_name'] as String? ?? '';
      _academicYearController.text = data['grade'] as String? ?? '';
      _notesController.text = data['notes'] as String? ?? '';
      _selectedAvatarIndex = data['avatar_index'] as int? ?? 0;
      final groupName = data['group_name'] as String?;
      if (groupName != null && _levels.contains(groupName)) {
        _selectedLevel = groupName;
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الاسم مطلوب')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        // Update existing student
        await Supabase.instance.client
            .from('profiles')
            .update({
              'full_name': _nameController.text.trim(),
              'grade': _academicYearController.text.trim(),
              'group_name': _selectedLevel,
              'notes': _notesController.text.trim(),
              'avatar_index': _selectedAvatarIndex,
            })
            .eq('id', widget.studentId!);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات ✓')));
          context.pop();
        }
      } else {
        await Supabase.instance.client.from('profiles').insert({
          'full_name': _nameController.text.trim(),
          'role': 'student',
          'admin_id': Supabase.instance.client.auth.currentUser!.id,
          'grade': _academicYearController.text.trim(),
          'group_name': _selectedLevel,
          'notes': _notesController.text.trim(),
          'avatar_index': _selectedAvatarIndex,
        });

        if (mounted) {
          // ← ضيف السطرين دول
          ref.invalidate(allStudentsProvider);
          ref.invalidate(filteredStudentsProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة الطالب بنجاح ✓')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _deleteStudent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الطالب'),
          content: const Text(
            'هل أنت متأكد من حذف هذا الطالب؟ لا يمكن التراجع.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .delete()
          .eq('id', widget.studentId!);
      if (mounted) {
        context.go('/admin/students');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في الحذف: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _academicYearController.dispose();
    _notesController.dispose();
    // مفيش dispose للـ ImagePicker — بس تأكد إن _selectedImage بيتنظف
    _selectedImage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EDE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EDE6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'EDIT STUDENT' : 'ADD STUDENT',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ),
      body: _isLoading && isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Avatar ──────────────────────────────
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 180,
                          height: 210,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8E0D0),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(90),
                              topRight: Radius.circular(90),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(90),
                                    topRight: Radius.circular(90),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: 180,
                                    height: 210,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : 'A',
                                    style: const TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.w300,
                                      color: Color(0xFFADB8A6),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B3A2D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Form Fields ──────────────────────────
                  _buildUnderlineField(
                    label: 'STUDENT IDENTITY',
                    controller: _nameController,
                    hint: 'Enter full name',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 24),
                  // Level & Academic Year (stacked)
                  _buildLevelDropdown(),
                  const SizedBox(height: 24),
                  _buildUnderlineField(
                    label: 'ACADEMIC YEAR',
                    controller: _academicYearController,
                    hint: '2024–2025',
                  ),
                  const SizedBox(height: 24),

                  _buildUnderlineField(
                    label: 'SCHOLARLY NOTES',
                    controller: _notesController,
                    hint: 'Enter observational notes...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),

                  // ── Tip Card ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0E8),
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(color: Color(0xFF1B5E20), width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF1B5E20),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registration Tip',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ensure the student\'s name matches their official enrollment records.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.menu_book_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Save Button ──────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3A2D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEditing ? 'Save Changes' : 'Add Student',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFEDE8DC),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  // Delete button (edit mode only)
                  if (isEditing) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _deleteStudent,
                      child: Text(
                        'حذف الطالب',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildLevelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('LEVEL OF STUDY'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedLevel,
          hint: const Text('level'),

          decoration: InputDecoration(
            filled: false,
            border: const UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1B5E20), width: 1.5),
            ),
          ),
          items: _levels
              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
              .toList(),
          onChanged: (v) => setState(() => _selectedLevel = v),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: Color(0xFFB8A98A),
      ),
    );
  }

  Widget _buildUnderlineField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool obscure = false,
    TextInputType? keyboardType,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: const Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: false,
            border: const UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1B5E20), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }
}
