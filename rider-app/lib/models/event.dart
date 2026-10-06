// To parse this JSON data, do
//
//     final event = eventFromJson(jsonString);

import 'dart:convert';

import 'package:intl/intl.dart';

Event eventFromJson(String str) => Event.fromJson(json.decode(str));

String eventToJson(Event data) => json.encode(data.toJson());

class Event {
  Event({
    this.eventId,
    this.eventStartDate,
    this.eventEndDate,
    required this.eventName,
    required this.eventDescription,
  });

  int? eventId;
  DateTime? eventStartDate;
  DateTime? eventEndDate;
  String eventName;
  String eventDescription;

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        eventId: json["eventID"],
        eventStartDate: DateTime.parse(json["eventStartDate"]),
        eventEndDate: DateTime.parse(json["eventEndDate"]),
        eventName: json["eventName"],
        eventDescription: json["eventDescription"],
      );

  Map<String, dynamic> toJson() => {
        "eventID": eventId,
        "eventStartDate": eventStartDate!.toIso8601String(),
        "eventEndDate": eventEndDate!.toIso8601String(),
        "eventName": eventName,
        "eventDescription": eventDescription,
      };

  String getDate() {
    return "${DateFormat('yMd').format(eventStartDate!)} ~ ${DateFormat.yMd().format(eventEndDate!)}";
  }
}
