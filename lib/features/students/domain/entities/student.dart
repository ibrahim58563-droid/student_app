final class Student {
  const Student({
    required this.id,
    required this.fullName,
    required this.grade,
    this.groupName,
    this.avatarIndex = 0,
  });

  final String id;
  final String fullName;
  final String grade;
  final String? groupName;
  final int avatarIndex;
}
