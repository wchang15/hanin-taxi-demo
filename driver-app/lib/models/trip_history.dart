// To parse this JSON data, do
//
//     final tripHistory = tripHistoryFromJson(jsonString);

import 'dart:convert';

TripHistory tripHistoryFromJson(String str) => TripHistory.fromJson(json.decode(str));

String tripHistoryToJson(TripHistory data) => json.encode(data.toJson());

class TripHistory {
  TripHistory({
    required this.amount,
    required this.tip,
    required this.tax,
    required this.date,
    required this.time,
    required this.paymentType,
    required this.pickUpLocation,
    required this.dropUpLocation,
    required this.mileage,
    required this.totalAmount,
  });

  String amount;
  String tip;
  String tax;
  String date;
  String time;
  String paymentType;
  String pickUpLocation;
  String dropUpLocation;
  String mileage;
  String totalAmount;

  factory TripHistory.fromJson(Map<String, dynamic> json) => TripHistory(
        amount: json["amount"],
        tip: json["tip"],
        tax: json["tax"],
        totalAmount: json["totalAmount"],
        date: json["date"],
        time: json["time"],
        paymentType: json["paymentType"],
        pickUpLocation: json["pickUpLocation"],
        dropUpLocation: json["dropUpLocation"],
        mileage: json["mileage"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "tip": tip,
        "tax": tax,
        "totalAmount": totalAmount,
        "date": date,
        "time": time,
        "paymentType": paymentType,
        "pickUpLocation": pickUpLocation,
        "dropUpLocation": dropUpLocation,
        "mileage": mileage,
      };
}
