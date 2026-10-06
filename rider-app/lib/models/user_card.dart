import 'dart:convert';

List<UserCard>? userCardFromJson(String str) =>
    json.decode(str) == null ? null : List<UserCard>.from(json.decode(str)!.map((x) => UserCard.fromJson(x)));

String userCardToJson(List<UserCard>? data) =>
    json.encode(data == null ? null : List<dynamic>.from(data!.map((x) => x!.toJson())));

class UserCard {
  UserCard({
    this.customerCardID,
    this.last4,
    this.brand,
    this.expirationMonth,
    this.expirationYear,
    this.isDefault,
  });

  int? customerCardID;
  String? last4;
  String? brand;
  int? expirationMonth;
  int? expirationYear;
  bool? isDefault;

  factory UserCard.fromJson(Map<String, dynamic> json) => UserCard(
        customerCardID: json["customerCardID"],
        last4: json["last4"],
        brand: json["brand"],
        expirationMonth: json["expirationMonth"],
        expirationYear: json["expirationYear"],
        isDefault: json["isDefault"],
      );

  Map<String, dynamic> toJson() => {
        "customerCardID": customerCardID,
        "last4": last4,
        "brand": brand,
        "expirationMonth": expirationMonth,
        "expirationYear": expirationYear,
        "isDefault": isDefault,
      };

  bool isExpired() {
    var time = DateTime.now();
    if (time.year > expirationYear!) return true;
    if (time.month > expirationMonth! && time.year == expirationYear!) return true;
    return false;
  }
}
