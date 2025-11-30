class UserModel {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final int riderRating;
  final int driverRating;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.riderRating,
    required this.driverRating,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firstName: json["firstName"] ?? "",
      lastName: json["lastName"] ?? "",
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
      riderRating: json["riderRating"] ?? 0,
      driverRating: json["driverRating"] ?? 0,
    );
  }
}
