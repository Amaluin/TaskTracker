class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String? name;
  final String? displayName;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.name,
    this.displayName,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      name: json['raw_user_meta_data']?['name'] as String?,
      displayName: json['raw_user_meta_data']?['display_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayText {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    if (phone != null && phone!.isNotEmpty) {
      return phone!;
    }
    return email;
  }
}
