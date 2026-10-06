import 'dart:convert';

import 'package:driverapp/controllers/trip_controller.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:tuple/tuple.dart';
import '../models/trip.dart';
import '../models/user_location.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class TripService {
  static Future<Tuple3<Trip?, EnumTripStatus?, String?>> getQueueStatus() async {
    Trip? trip;
    String? str;
    EnumTripStatus? enumTrip;
    try {
      var url = Uri.parse('${API_ADDRESS}DriverQueue/GetDriverQueueStatus');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        try {
          trip = tripFromJson(response.body);
        } catch (err) {
          //Waiting
          if (response.body == 'NoQueue') {
            enumTrip = EnumTripStatus.NONE;
          } else if (response.body == 'waiting') {
            enumTrip = EnumTripStatus.CUSTOMERSEARCHING;
          } else if (response.body == 'customercancel') {
            enumTrip = EnumTripStatus.CUSTOMERCANCELED;
          } else if (response.body == 'companycancel') {
            enumTrip = EnumTripStatus.COMPANYCANCELED;
          }
        }
      } else {
        str = response.body;
      }
    } catch (e) {
      print('trip_service.getQueueStatus');
      print(e);
    }
    return Tuple3(trip, enumTrip, str);
  }

  static Future updateQueueLocation(LatLng curLoc) async {
    try {
      var url = Uri.parse('${API_ADDRESS}DriverQueue/UpdateDriverQueueLocation');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', "Content-Type": "application/json"};
      var body = jsonEncode({
        'latitude': curLoc.latitude,
        'longitude': curLoc.longitude,
      });
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
      } else {}
    } catch (e) {
      print('trip_service.updateQueueLocation');
      print(e);
    }
    return;
  }

  static Future<String?> removeQueueFromDB() async {
    String? str;
    try {
      var url = Uri.parse('${API_ADDRESS}DriverQueue');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        //success
      } else {
        str = response.body;
      }
    } catch (e) {
      print('trip_service.removeQueueFromDB');
      print(e);
    }
    return str;
  }

  static Future<Tuple2<bool?, String?>> increaseDeclined() async {
    String? str;
    bool? bo;
    try {
      var url = Uri.parse('${API_ADDRESS}DriverQueue/DeclinedQueue');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        //success
        //if false removed
        //if true declined
        if (response.body == 'true') {
          bo = true;
        } else if (response.body == 'false') {
          bo = false;
        }
      } else {
        str = response.body;
      }
    } catch (e) {
      print('trip_service.increaseDeclined');
      print(e);
    }
    return Tuple2(bo, str);
  }

  static Future<String?> matchTrip() async {
    String? str;

    try {
      var url = Uri.parse('${API_ADDRESS}DriverQueue/MatchTrip');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        //success
      } else {
        str = response.body;
      }
    } catch (e) {
      print('trip_service.matchTrip');
      print(e);
    }
    return str;
  }

  static Future<Tuple2<double?, String?>> startTrip(UserLocation? dest) async {
    String? str;
    String? body;
    double? amount;

    try {
      var url = Uri.parse('${API_ADDRESS}Trip/StartTrip');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', "Content-Type": "application/json"};

      body = jsonEncode({
        'dropoffName': dest?.name ?? "",
        'dropoffAddress': dest?.address ?? "",
        'dropoffLongitude': dest?.longitude ?? 0,
        'dropoffLatitude': dest?.latitude ?? 0,
        'dropoffLocationType': dest?.locationType.index ?? 1,
      });

      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        //success
        var res = double.parse(response.body);
        if (res != 0) amount = res;
      } else {
        str = response.body;
      }
    } catch (e) {
      print('trip_service.startTrip');
      print(e);
    }
    return Tuple2(amount, str);
  }

  static Future<String?> completeTrip() async {
    String? str;

    try {
      var url = Uri.parse('${API_ADDRESS}Trip/CompleteTrip');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        //success
      } else {
        str = response.body;
      }
    } catch (e) {
      print('trip_service.completeTrip');
      print(e);
    }
    return str;
  }

  static Future<String?> driverCancel() async {
    String? str;

    try {
      var url = Uri.parse('${API_ADDRESS}Trip/DriverCancel');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        //success
      } else {
        str = response.body;
      }
    } catch (e) {
      print('trip_service.driverCancel');
      print(e);
    }
    return str;
  }

  static Future<String?> addDestination(UserLocation location) async {
    String? str;

    try {
      var url = Uri.parse('${API_ADDRESS}Trip/AddDestination');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', "Content-Type": "application/json"};
      var body = jsonEncode({
        'name': location.name,
        'type': location.type,
        'address': location.address,
        'latitude': location.latitude,
        'longitude': location.longitude,
      });
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        //success // return trip
      } else {
        str = response.body;
      }
    } catch (e) {
      print('trip_service.addDestination');
      print(e);
    }
    return str;
  }
}
