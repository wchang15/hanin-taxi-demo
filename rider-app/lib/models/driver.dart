// To parse this JSON data, do
//
//     final driver = driverFromJson(jsonString);

import 'dart:convert';

Driver driverFromJson(String str) => Driver.fromJson(json.decode(str));

String driverToJson(Driver data) => json.encode(data.toJson());

class Driver {
  Driver({
    required this.licensePlate,
    required this.carModel,
    required this.carColor,
    required this.companyName,
    required this.driverName,
    required this.phoneNumber,
  });

  String licensePlate;
  String carModel;
  String carColor;
  String companyName;
  String driverName;
  String phoneNumber;

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        licensePlate: json["licensePlate"],
        carModel: json["carModel"],
        carColor: json["carColor"],
        companyName: json["companyName"],
        driverName: json["driverName"],
        phoneNumber: json["phoneNumber"],
      );

  Map<String, dynamic> toJson() => {
        "licensePlate": licensePlate,
        "carModel": carModel,
        "carColor": carColor,
        "companyName": companyName,
        "driverName": driverName,
        "phoneNumber": phoneNumber,
      };
}
