// To parse this JSON data, do
//
//     final driver = driverFromJson(jsonString);

import 'dart:convert';

import 'package:driverapp/models/user_location.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';

Driver driverFromJson(String str) => Driver.fromJson(json.decode(str));

String driverToJson(Driver data) => json.encode(data.toJson());

class Driver {
  Driver({
    required this.firstName,
    required this.lastName,
    required this.driverNumber,
    this.dob,
    this.email,
    required this.phoneNumber,
    required this.companyName,
    required this.color,
    required this.make,
    required this.model,
    required this.licensePlate,
    required this.size,
    required this.language,
    required this.earnedToday,
    required this.driverID,
    required this.map,
    required this.frequentLocations,
  });

  String firstName;
  String lastName;
  int driverNumber;
  dynamic dob;
  dynamic email;
  String phoneNumber;
  String companyName;
  String color;
  String make;
  String model;
  String licensePlate;
  int size;
  int language;
  double earnedToday;
  int driverID;
  String map;
  List<UserLocation> frequentLocations;

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        driverID: json["driverID"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        driverNumber: json["driverNumber"],
        dob: json["dob"],
        email: json["email"],
        phoneNumber: json["phoneNumber"],
        companyName: json["companyName"],
        color: json["color"],
        make: json["make"],
        model: json["model"],
        licensePlate: json["licensePlate"],
        size: json["size"],
        language: json["language"],
        earnedToday: json["earnedToday"].toDouble(),
        map: json["map"] ?? "",
        frequentLocations: List<UserLocation>.from(json["frequentLocations"].map((x) => UserLocation.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "driverID": driverID,
        "firstName": firstName,
        "lastName": lastName,
        "driverNumber": driverNumber,
        "dob": dob,
        "email": email,
        "phoneNumber": phoneNumber,
        "companyName": companyName,
        "color": color,
        "make": make,
        "model": model,
        "licensePlate": licensePlate,
        "size": size,
        "language": language,
        "earnedToday": earnedToday,
        "map": map,
        "savedLocations": List<dynamic>.from(frequentLocations.map((x) => x.toJson())),
      };

  String earnedString() {
    return NumberFormat.simpleCurrency(name: 'USD').format(earnedToday);
  }

  String fullName() {
    return "$firstName $lastName";
  }
}
