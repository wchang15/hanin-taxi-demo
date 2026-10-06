// To parse this JSON data, do
//
//     final Customer = CustomerFromJson(jsonString);

import 'dart:convert';
import 'package:tax_app/models/user_card.dart';
import 'package:tax_app/models/user_location.dart';

Customer? customerFromJson(String str) => Customer.fromJson(json.decode(str));

String customerToJson(Customer? data) => json.encode(data!.toJson());

class Customer {
  Customer({
    this.customerId,
    required this.userName,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
    required this.createdDateTime,
    this.fullname,
    required this.isVerified,
    required this.searchHistories,
    this.defaultCardID,
    required this.point,
    required this.savedCards,
    required this.savedLocations,
    required this.language,
  });

  int? customerId;
  String userName;
  String firstName;
  String lastName;
  String? email;
  String? phoneNumber;
  DateTime createdDateTime;
  String? fullname;
  bool isVerified;
  int? defaultCardID;
  double point;
  int language;
  List<UserCard> savedCards;
  List<UserLocation> searchHistories;
  List<UserLocation> savedLocations;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        customerId: json["customerID"],
        userName: json["userName"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        email: json["email"],
        phoneNumber: json["phoneNumber"],
        createdDateTime: DateTime.parse(json["createdDateTime"]),
        fullname: json["fullname"],
        isVerified: json["isVerified"],
        point: json["point"]?.toDouble(),
        defaultCardID: json["defaultCardID"],
        savedCards: List<UserCard>.from(json["savedCards"].map((x) => UserCard.fromJson(x))),
        searchHistories: List<UserLocation>.from(json["searchHistories"].map((x) => UserLocation.fromJson(x))),
        savedLocations: List<UserLocation>.from(json["savedLocations"].map((x) => UserLocation.fromJson(x))),
        language: json["language"],
      );

  Map<String, dynamic> toJson() => {
        "customerID": customerId,
        "userName": userName,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phoneNumber": phoneNumber,
        "createdDateTime": createdDateTime?.toIso8601String(),
        "fullname": fullname,
        "isVerified": isVerified,
        "point": point,
        "defaultCardID": defaultCardID,
        "savedCards": List<dynamic>.from(savedCards.map((x) => x.toJson())),
        "searchHistories": List<dynamic>.from(searchHistories.map((x) => x.toJson())),
        "savedLocations": List<dynamic>.from(savedLocations.map((x) => x.toJson())),
        "language": language
      };

  String getCardName(int? cardID) {
    UserCard card;
    try {
      card = savedCards.where((e) => e.customerCardID == (cardID ?? defaultCardID)).first;
    } catch (err) {
      return 'Card Not Found';
    }
    return '${card.brand}(${card.last4})';
  }

  UserLocation? getHome() {
    UserLocation loc;
    try {
      loc = savedLocations.where((e) => e.type == 1).first;
    } catch (err) {
      return null;
    }
    return loc;
  }

  UserLocation? getWork() {
    UserLocation loc;
    try {
      loc = savedLocations.where((e) => e.type == 2).first;
    } catch (err) {
      return null;
    }
    return loc;
  }
}
