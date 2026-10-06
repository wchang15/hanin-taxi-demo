import 'dart:convert';

TripFareResponse? tripFareResponseFromJson(String str) => TripFareResponse.fromJson(json.decode(str));

String tripFareResponseToJson(TripFareResponse? data) => json.encode(data!.toJson());

class TripFareResponse {
  TripFareResponse({
    this.smallTaxiFee,
    this.largeTaxiFee,
    this.tripID,
    this.customerCardID,
    this.response,
  });

  String? smallTaxiFee;
  String? largeTaxiFee;
  int? tripID;
  int? customerCardID;
  String? response;

  factory TripFareResponse.fromJson(Map<String, dynamic> json) => TripFareResponse(
        smallTaxiFee: json["smallTaxiFee"],
        largeTaxiFee: json["largeTaxiFee"],
        tripID: json["tripID"],
        customerCardID: json["customerCardID"],
        response: json["response"],
      );

  Map<String, dynamic> toJson() => {
        "smallTaxiFee": smallTaxiFee,
        "largeTaxiFee": largeTaxiFee,
        "tripID": tripID,
        "customerCardID": customerCardID,
        "response": response,
      };
}
