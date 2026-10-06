// To parse this JSON data, do
//
//     final cutomerToken = cutomerTokenFromJson(jsonString);

import 'dart:convert';

import 'package:tax_app/models/customer.dart';

CutomerToken? cutomerTokenFromJson(String str) => CutomerToken.fromJson(json.decode(str));

String cutomerTokenToJson(CutomerToken? data) => json.encode(data!.toJson());

class CutomerToken {
  CutomerToken({
    required this.customer,
    required this.token,
    this.response,
  });

  Customer customer;
  String token;
  String? response;

  factory CutomerToken.fromJson(Map<String, dynamic> json) => CutomerToken(
        customer: Customer.fromJson(json["customer"]),
        token: json["token"],
        response: json["response"],
      );

  Map<String, dynamic> toJson() => {
        "customer": customer!.toJson(),
        "token": token,
        "response": response,
      };
}
