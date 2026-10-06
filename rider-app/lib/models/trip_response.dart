// To parse this JSON data, do
//
//     final cutomerToken = cutomerTokenFromJson(jsonString);

import 'dart:convert';

import 'package:tax_app/models/trip.dart';

TripResponse? tripResponseFromJson(String str) => TripResponse.fromJson(json.decode(str));

String tripResponseToJson(TripResponse? data) => json.encode(data!.toJson());

class TripResponse {
  TripResponse({
    this.trip,
    this.response,
  });

  Trip? trip;
  String? response;

  factory TripResponse.fromJson(Map<String, dynamic> json) => TripResponse(
        trip: json["trip"] == null ? null : Trip.fromJson(json["trip"]),
        response: json["response"],
      );

  Map<String, dynamic> toJson() => {
        "trip": trip!.toJson(),
        "response": response,
      };
}
