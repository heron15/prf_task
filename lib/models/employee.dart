class Employee {
  final int? id;
  final String empId;
  final String name;
  final String gender;
  final DateTime dateOfBirth;
  final DateTime? lastModified;
  final bool isSynced;
  final bool isDeleted;

  Employee({
    this.id,
    required this.empId,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    this.lastModified,
    this.isSynced = false,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emp_id': empId,
      'name': name,
      'gender': gender,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      empId: map['emp_id'],
      name: map['name'],
      gender: map['gender'],
      dateOfBirth: DateTime.parse(map['date_of_birth']),
      lastModified: map['last_modified'] != null ? DateTime.parse(map['last_modified']) : null,
      isSynced: map['is_synced'] == 1,
      isDeleted: map['is_deleted'] == 1,
    );
  }

  Employee copyWith({
    int? id,
    String? empId,
    String? name,
    String? gender,
    DateTime? dateOfBirth,
    DateTime? lastModified,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return Employee(
      id: id ?? this.id,
      empId: empId ?? this.empId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toServerMap() {
    return {
      'Emp_ID': int.parse(empId),
      'Emp_name': name,
      'Emp_gender': gender,
      'Emp_DOB': dateOfBirth.toIso8601String().split('T')[0], // YYYY-MM-DD format
    };
  }
}
