
// To parse this JSON data, do
//
//     final userLogin = userLoginFromJson(jsonString);

import 'dart:convert';

UserLogin? userLoginFromJson(String str) => UserLogin.fromJson(json.decode(str));

String userLoginToJson(UserLogin? data) => json.encode(data!.toJson());

class UserLogin {
  UserLogin({
    required this.username,
    required this.password,
  });

  String username;
  String password;

  factory UserLogin.fromJson(Map<String, dynamic> json) => UserLogin(
        username: json["username"],
        password: json["password"],
      );

  Map<String, dynamic> toJson() => {
        "username": username,
        "password": password,
      };
}
