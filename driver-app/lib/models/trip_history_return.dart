// To parse this JSON data, do
//
//     final cutomerToken = cutomerTokenFromJson(jsonString);

import 'dart:convert';

import 'package:driverapp/models/trip_history.dart';

import 'driver.dart';

TripHistoryReturn? tripHistoryReturnFromJson(String str) => TripHistoryReturn.fromJson(json.decode(str));

String tripHistoryReturnToJson(TripHistoryReturn? data) => json.encode(data!.toJson());

class TripHistoryReturn {
  TripHistoryReturn({
    required this.tripHistories,
    required this.totalAmount,
  });

  List<TripHistory> tripHistories;
  String totalAmount;

  factory TripHistoryReturn.fromJson(Map<String, dynamic> json) => TripHistoryReturn(
        tripHistories: List<TripHistory>.from(json["tripHistories"].map((x) => TripHistory.fromJson(x))),
        totalAmount: json["totalAmount"],
      );

  Map<String, dynamic> toJson() => {
        "tripHistories": List<dynamic>.from(tripHistories.map((x) => x.toJson())),
        "totalAmount": totalAmount,
      };
}
