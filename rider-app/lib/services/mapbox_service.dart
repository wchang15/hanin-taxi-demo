import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import '../models/user_location.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

// Rider route geometry uses Directions; address search goes through the API.
class MapBoxService {
  static Future<Tuple2<List<LatLng>?, int?>> getDirection(
      LatLng from, LatLng to) async {
    List<LatLng>? list;
    int? duration;

    try {
      var url = Uri.parse(
          'https://api.mapbox.com/directions/v5/mapbox/driving/${getLatLngString(from, to)}?alternatives=false&geometries=geojson&overview=simplified&steps=false&access_token=$MAPBOXAPI');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        duration = res["routes"][0]["duration"].toDouble().round();
        list = getPoints(res["routes"][0]["geometry"]["coordinates"]);
      }
    } catch (e) {
      print('MapBoxService.getDirection');
      print(e);
    }
    return Tuple2(list, duration);
  }

  static Future<List<UserLocation>> getAutoComplete(String address) async {
    List<UserLocation> list = <UserLocation>[];

    try {
      final url = Uri.parse('${API_ADDRESS}Shared/GetAutoComplete')
          .replace(queryParameters: {'address': address});
      final jwt = await StorageService.readSecureData(JWT);
      final response =
          await http.get(url, headers: {'Authorization': 'bearer $jwt'});
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body) as List<dynamic>;
        list = res
            .map((item) => UserLocation.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('MapBoxService.getAutoComplete');
      print(e);
    }
    return list;
  }

  static String getLatLngString(LatLng from, LatLng to) {
    return '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
  }

  static List<LatLng> getPoints(List<dynamic> encoded) {
    final points = <LatLng>[];

    encoded.forEach((element) {
      points.add(LatLng(element[1].toDouble(), element[0].toDouble()));
    });

    return points;
  }
}
