// To parse this JSON data, do
//
//     final cutomerToken = cutomerTokenFromJson(jsonString);

import 'dart:convert';

import 'driver.dart';

DriverToken? driverTokenFromJson(String str) => DriverToken.fromJson(json.decode(str));

String driverTokenToJson(DriverToken? data) => json.encode(data!.toJson());

class DriverToken {
  DriverToken({
    required this.driver,
    required this.token,
  });

  Driver driver;
  String token;

  factory DriverToken.fromJson(Map<String, dynamic> json) => DriverToken(
        driver: Driver.fromJson(json["driver"]),
        token: json["token"],
      );

  Map<String, dynamic> toJson() => {
        "driver": driver!.toJson(),
        "token": token,
      };
}
