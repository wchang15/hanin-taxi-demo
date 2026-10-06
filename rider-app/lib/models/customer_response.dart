// To parse this JSON data, do
//
//     final cutomerToken = cutomerTokenFromJson(jsonString);

import 'dart:convert';

import 'package:tax_app/models/customer.dart';

CustomerResponse? customerResponseFromJson(String str) => CustomerResponse.fromJson(json.decode(str));

String customerResponseToJson(CustomerResponse? data) => json.encode(data!.toJson());

class CustomerResponse {
  CustomerResponse({
    this.customer,
    this.response,
  });

  Customer? customer;
  String? response;

  factory CustomerResponse.fromJson(Map<String, dynamic> json) => CustomerResponse(
        customer: json["customer"] == null ? null : Customer.fromJson(json["customer"]),
        response: json["response"],
      );

  Map<String, dynamic> toJson() => {
        "customer": customer!.toJson(),
        "response": response,
      };
}
