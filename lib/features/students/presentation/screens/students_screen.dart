import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_app/features/students/presentation/providers/students_provider.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  static const String routeName = 'students';
  static const String routePath = '/students';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsState = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الطلاب / Students')),
      body: studentsState.when(
        data: (students) {
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                title: Text(student.fullName),
                subtitle: Text(student.grade),
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              );
            },
          );
        },
        error: (error, stackTrace) => Center(child: Text('حدث خطأ: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
