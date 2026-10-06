import 'dart:convert';

List<UserLocation>? userLocationFromJson(String str) => json.decode(str) == null
    ? null
    : List<UserLocation>.from(
        json.decode(str)!.map((x) => UserLocation.fromJson(x)));

String userLocationToJson(List<UserLocation>? data) => json.encode(
    data == null ? null : List<dynamic>.from(data!.map((x) => x!.toJson())));

class UserLocation {
  UserLocation({
    this.googleLocationID,
    this.type,
    required this.address,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.locationType,
  });

  int? customerSavedLocationID;
  int? googleLocationID;
  int? type; // saved type
  String address;
  String name;
  double latitude;
  double longitude;
  EnumLocationType locationType = EnumLocationType.OTHER;

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
        googleLocationID: json["googleLocationID"],
        type: json["type"],
        address: json["address"],
        name: json["name"],
        latitude: (json["latitude"] as num).toDouble(),
        longitude: (json["longitude"] as num).toDouble(),
        locationType: EnumLocationType.values[json["locationType"]] ??
            EnumLocationType.OTHER,
      );

  Map<String, dynamic> toJson() => {
        "googleLocationID": googleLocationID,
        "type": type,
        "address": address,
        "name": name,
        "latitude": latitude,
        "longitude": longitude,
        "locationType": locationType.index,
      };
}

enum EnumLocationType {
  PLACEHOLDER,
  AIRPORT,
  RESTAURANT,
  STORE,
  PARK,
  SCHOOL,
  HOSPITAL,
  OTHER
} //Ignore Place holder
