class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.role,
    this.name,
    this.photoUrl,
  });

  final String id;
  final String firebaseUid;
  final String email;
  final String role;
  final String? name;
  final String? photoUrl;

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'] as String,
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      name: json['name'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}
