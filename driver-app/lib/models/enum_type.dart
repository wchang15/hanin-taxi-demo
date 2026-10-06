
// To parse this JSON data, do
//
//     final enumType = enumTypeFromJson(jsonString);

import 'dart:convert';

List<EnumType?>? enumTypeFromJson(String str) =>
    json.decode(str) == null ? [] : List<EnumType?>.from(json.decode(str)!.map((x) => EnumType.fromJson(x)));

String enumTypeToJson(List<EnumType?>? data) =>
    json.encode(data == null ? [] : List<dynamic>.from(data!.map((x) => x!.toJson())));

class EnumType {
  EnumType({
    required this.id,
    required this.value,
  });

  int id;
  String value;

  factory EnumType.fromJson(Map<String, dynamic> json) => EnumType(
        id: json["id"],
        value: json["value"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "value": value,
      };
}
