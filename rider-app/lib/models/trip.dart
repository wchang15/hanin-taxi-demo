// To parse this JSON data, do
//
//     final trip = tripFromJson(jsonString);

import 'dart:convert';

import 'package:tax_app/models/user_location.dart';

Trip tripFromJson(String str) => Trip.fromJson(json.decode(str));

String tripToJson(Trip data) => json.encode(data.toJson());

class Trip {
  Trip({
    required this.tripID,
    required this.tripStatus,
    required this.calledTaxiSize,
    required this.amount,
    required this.smallTaxiFee,
    required this.largeTaxiFee,
    required this.createdDateTime,
    required this.startName,
    required this.startAddress,
    required this.startLatitude,
    required this.startLongitude,
    required this.startLocationType,
    required this.endName,
    required this.endAddress,
    required this.endLatitude,
    required this.endLongitude,
    required this.endLocationType,
    this.customerCardID,
    required this.enumPaymentType,
    required this.pointUsed,
  });

  int tripID;
  int tripStatus;
  int calledTaxiSize;
  int enumPaymentType;
  double pointUsed;
  String amount;
  String smallTaxiFee;
  String largeTaxiFee;
  DateTime createdDateTime;
  String startName;
  String startAddress;
  double startLatitude;
  double startLongitude;
  EnumLocationType startLocationType;
  String endName;
  String endAddress;
  double endLatitude;
  double endLongitude;
  EnumLocationType endLocationType;
  int? customerCardID;

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        tripID: json["tripID"],
        tripStatus: json["tripStatus"],
        calledTaxiSize: json["calledTaxiSize"],
        amount: json["amount"],
        enumPaymentType: json["enumPaymentType"],
        pointUsed: json["pointUsed"]?.toDouble(),
        smallTaxiFee: json["smallTaxiFee"],
        largeTaxiFee: json["largeTaxiFee"],
        createdDateTime: DateTime.parse(json["createdDateTime"]),
        startName: json["startName"],
        startAddress: json["startAddress"],
        startLatitude: json["startLatitude"]?.toDouble(),
        startLongitude: json["startLongitude"]?.toDouble(),
        startLocationType: EnumLocationType.values[json["startLocationType"]],
        endName: json["endName"],
        endAddress: json["endAddress"],
        endLatitude: json["endLatitude"]?.toDouble(),
        endLongitude: json["endLongitude"]?.toDouble(),
        endLocationType: EnumLocationType.values[json["endLocationType"]],
        customerCardID: json["customerCardID"],
      );

  Map<String, dynamic> toJson() => {
        "tripID": tripID,
        "tripStatus": tripStatus,
        "calledTaxiSize": calledTaxiSize,
        "enumPaymentType": enumPaymentType,
        "pointUsed": pointUsed,
        "amount": amount,
        "smallTaxiFee": smallTaxiFee,
        "largeTaxiFee": largeTaxiFee,
        "createdDateTime": createdDateTime.toIso8601String(),
        "startName": startName,
        "startAddress": startAddress,
        "startLatitude": startLatitude,
        "startLongitude": startLongitude,
        "startLocationType": startLocationType,
        "endName": endName,
        "endAddress": endAddress,
        "endLatitude": endLatitude,
        "endLongitude": endLongitude,
        "endLocationType": endLocationType,
        "customerCardID": customerCardID,
      };
}
