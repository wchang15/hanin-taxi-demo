import 'dart:convert';

import 'package:driverapp/models/trip_history.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:tuple/tuple.dart';
import '../models/driver.dart';
import '../models/driver_token.dart';
import '../models/trip_history_return.dart';
import '../models/user_login.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class DriverService {
  //need to send location
  static Future<String?> postDriverQueue(LatLng curLoc) async {
    try {
      var url = Uri.parse('${API_ADDRESS}DriverQueue/EnqueueDriver');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', "Content-Type": "application/json"};
      var body = jsonEncode({
        'latitude': curLoc.latitude,
        'longitude': curLoc.longitude,
      });
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
      } else {
        return response.body;
      }
    } catch (e) {
      print('driver_service.postDriverQueue');
      print(e);
    }
    return null;
  }

  static Future<TripHistoryReturn?> getMyCompletedTrips(int filterType) async {
    TripHistoryReturn? ret;
    try {
      var url = Uri.parse('${API_ADDRESS}Driver/GetMyCompletedTrips?filterType=$filterType');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        ret = tripHistoryReturnFromJson(response.body);
      } else {
        // error
      }
    } catch (e) {
      print('driver_service.getMyCompletedTrips');
      print(e);
    }
    return ret;
  }

  static Future<String?> updateMap(String mapName) async {
    String? ret;
    try {
      var url = Uri.parse('${API_ADDRESS}Driver/UpdateDefaultMap?mapName=$mapName');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        // Success
      } else {
        ret = "error";
        // error
      }
    } catch (e) {
      print('driver_service.getMyCompletedTrips');
      print(e);
    }
    return ret;
  }
}
