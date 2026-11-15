
class UserModel {
  final String id;
  final String name;
  final String email;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserModel.fromMap(
      String id,
      Map<String, dynamic> data,
      ) {
    return UserModel(
      id: id,
      name: data['name'] ?? 'Unknown Student',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
    };
  }
}
