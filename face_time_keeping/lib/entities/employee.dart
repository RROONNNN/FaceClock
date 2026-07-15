class Employee {
  final int id;
  final String? pin;

  final String name;
  final dynamic jobTitle; // Can be false or string

  Employee({
    required this.id,
    required this.pin,
    required this.name,
    this.jobTitle,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      pin: json['pin'] is String ? json['pin'] as String : null,
      name: json['name'] as String,
      jobTitle: json['job_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pin': pin,
      'name': name,
      'job_title': jobTitle,
    };
  }

  @override
  String toString() {
    return 'Employee(id: $id, pin: $pin, name: $name, jobTitle: $jobTitle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee &&
        other.id == id &&
        other.pin == pin &&
        other.name == name &&
        other.jobTitle == jobTitle;
  }

  @override
  int get hashCode {
    return id.hashCode ^ pin.hashCode ^ name.hashCode ^ jobTitle.hashCode;
  }

  Employee copyWith({
    int? id,
    String? pin,
    dynamic barcode,
    String? name,
    dynamic jobTitle,
  }) {
    return Employee(
      id: id ?? this.id,
      pin: pin ?? this.pin,
      name: name ?? this.name,
      jobTitle: jobTitle ?? this.jobTitle,
    );
  }
}
