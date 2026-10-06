// To parse this JSON data, do
//
//     final registerRequest = registerRequestFromJson(jsonString);

import 'dart:convert';

String registerRequestToJson(RegisterRequest data) => json.encode(data.toJson());

class RegisterRequest {
  RegisterRequest({
    required this.username,
    required this.password,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.language,
    required this.terms,
    required this.phoneNumber,
  });

  String username;
  String password;
  int role;
  String firstName;
  String lastName;
  String? email;
  String phoneNumber;
  int language;
  List<bool> terms;

  Map<String, dynamic> toJson() => {
        "username": username,
        "password": password,
        "role": role,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "language": language,
        "terms": terms,
        "phoneNumber": phoneNumber,
      };
}
