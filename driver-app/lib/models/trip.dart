// To parse this JSON data, do
//
//     final trip = tripFromJson(jsonString);

import 'dart:convert';
import 'dart:core';

import 'package:driverapp/controllers/trip_controller.dart';
import 'package:intl/intl.dart';

Trip tripFromJson(String str) => Trip.fromJson(json.decode(str));

String tripToJson(Trip data) => json.encode(data.toJson());

class Trip {
  Trip({
    required this.tripID,
    required this.tripStatus,
    this.startPreferredName,
    required this.startName,
    required this.startAddress,
    required this.startLatitude,
    required this.startLongitude,
    this.endPreferredName,
    this.endName,
    this.endAddress,
    this.endLatitude,
    this.endLongitude,
    required this.customerFirstName,
    required this.customerPhoneNumber,
    required this.tripType,
    required this.paymentType,
    required this.tripAmount,
    required this.note,
    required this.alcoholPhoneNumber,
  });

  int tripID;
  int tripStatus;
  String? startPreferredName;
  String startName;
  String startAddress;
  double startLatitude;
  double startLongitude;
  String? endPreferredName;
  String? endName;
  String? endAddress;
  double? endLatitude;
  double? endLongitude;
  String customerFirstName;
  String customerPhoneNumber;
  int tripType;
  int paymentType;
  double tripAmount;
  String note;
  String alcoholPhoneNumber;

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        tripID: json["tripID"],
        tripStatus: json["tripStatus"],
        startPreferredName: json["startPreferredName"],
        startName: json["startName"],
        startAddress: json["startAddress"],
        startLatitude: json["startLatitude"]?.toDouble(),
        startLongitude: json["startLongitude"]?.toDouble(),
        endPreferredName: json["endPreferredName"],
        endName: json["endName"],
        endAddress: json["endAddress"],
        endLatitude: json["endLatitude"]?.toDouble(),
        endLongitude: json["endLongitude"]?.toDouble(),
        customerFirstName: json["customerFirstName"],
        customerPhoneNumber: json["customerPhoneNumber"],
        tripType: json["tripType"],
        paymentType: json["paymentType"] ?? 1,
        tripAmount: json["tripAmount"].toDouble(),
        note: json["note"],
        alcoholPhoneNumber: json["alcoholPhoneNumber"],
      );

  Map<String, dynamic> toJson() => {
        "tripID": tripID,
        "tripStatus": tripStatus,
        "startPreferredName": startPreferredName,
        "startName": startName,
        "startAddress": startAddress,
        "startLatitude": startLatitude,
        "startLongitude": startLongitude,
        "endPreferredName": endPreferredName,
        "endName": endName,
        "endAddress": endAddress,
        "endLatitude": endLatitude,
        "endLongitude": endLongitude,
        "customerFirstName": customerFirstName,
        "customerPhoneNumber": customerPhoneNumber,
        "tripType": tripType,
        "paymentType": paymentType,
        "tripAmount": tripAmount,
        "note": note,
        "alcoholPhoneNumber": alcoholPhoneNumber,
      };

  EnumTripType getEnumTripType() {
    return EnumTripType.values[tripType - 1];
  }

  EnumPaymentType getEnumPaymentType() {
    final index = paymentType - 1;
    if (index < 0 || index >= EnumPaymentType.values.length) {
      return EnumPaymentType.CARD;
    }
    return EnumPaymentType.values[index];
  }

  String tripAmountString() {
    return NumberFormat.simpleCurrency(name: 'USD').format(tripAmount);
  }

  String fullStartName() {
    return startPreferredName == null || (startPreferredName?.length ?? 0) == 0
        ? '$startName, $startAddress'
        : "$startPreferredName : $startName, $startAddress";
  }

  String fullEndName() {
    return endName != null
        ? endPreferredName == null || (endPreferredName?.length ?? 0) == 0
            ? '$endName, $endAddress'
            : "$endPreferredName : $endName, $endAddress"
        : "";
  }
}
