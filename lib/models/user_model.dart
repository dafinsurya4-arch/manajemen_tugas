class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final List<String> groups;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.groups,
  });

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'fullName': fullName, 'groups': groups};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      groups: List<String>.from(map['groups'] ?? []),
    );
  }
}
