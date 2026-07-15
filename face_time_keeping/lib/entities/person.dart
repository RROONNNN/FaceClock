import 'package:hive/hive.dart';

part 'person.g.dart';

@HiveType(typeId: 2)
class Person extends HiveObject {
  @HiveField(0)
  final int employeeId;

  @HiveField(1)
  final DateTime updatedTime;

  @HiveField(2)
  final bool isSynced;

  Person({
    required this.employeeId,
    required this.updatedTime,
    this.isSynced = false,
  });

  Person copyWith({
    int? employeeId,
    DateTime? updatedTime,
    bool? isSynced,
  }) {
    return Person(
        employeeId: employeeId ?? this.employeeId,
        updatedTime: updatedTime ?? this.updatedTime,
        isSynced: isSynced ?? this.isSynced);
  }

  @override
  String toString() {
    return 'Person(employeeId: $employeeId, updatedTime: $updatedTime, isSynced: $isSynced)';
  }
}
