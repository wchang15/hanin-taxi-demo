import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:tax_app/models/trip_response.dart';
import 'package:tuple/tuple.dart';

import '../models/driver.dart';
import '../models/trip_fare_response.dart';
import '../models/user_location.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class TripService {
  //Create a new find fare trip
  static Future<TripFareResponse> newTrip(UserLocation start, UserLocation end) async {
    TripFareResponse tripFareResponse = TripFareResponse();
    try {
      var url = Uri.parse('${API_ADDRESS}Trip/NewTrip');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', 'Content-Type': 'Application/json'};
      var body = jsonEncode({
        'pickupName': start.name,
        'pickupAddress': start.address,
        'pickupLongitude': start.longitude,
        'pickupLatitude': start.latitude,
        'pickupLocationType': start.locationType.index ?? EnumLocationType.OTHER.index,
        'dropoffName': end.name,
        'dropoffAddress': end.address,
        'dropoffLongitude': end.longitude,
        'dropoffLatitude': end.latitude,
        'dropoffLocationType': end.locationType.index ?? EnumLocationType.OTHER.index,
      });
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        var tripFare = tripFareResponseFromJson(response.body);
        if (tripFare == null) {
          return tripFareResponse;
        } else {
          return tripFare;
        }
      } else {
        tripFareResponse.response = response.body;
      }
    } catch (e) {
      print('trip_service.newTrip');
      print(e);
    }
    return tripFareResponse;
  }

  // confirm the trip and change it to matching stage
  static Future<String?> confirmTrip(int tripID, int? customerCardID, int enumTaxiSize, int enumPaymentType) async {
    try {
      var url = Uri.parse('${API_ADDRESS}Trip/ConfirmTrip');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', 'Content-Type': 'Application/json'};
      var body = jsonEncode({
        'tripID': tripID,
        'customerCardID': customerCardID,
        'enumTaxiSize': enumTaxiSize,
        'enumPaymentType': enumPaymentType,
      });
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        print('success');
      } else {
        return response.body;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  //Remove the trip.
  static Future<String?> removeTrip() async {
    try {
      var url = Uri.parse('${API_ADDRESS}Trip/CustomerCancel');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        print('success');
      } else {
        return response.body;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<String?> completeTrip(double tip) async {
    try {
      var url = Uri.parse('${API_ADDRESS}Payment/CompletePayment?tip=$tip');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
      } else {
        return response.body;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<String?> removeCQ() async {
    try {
      var url = Uri.parse('${API_ADDRESS}Trip/RemoveCustomerQueue');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
      } else {
        return response.body;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<String?> rematchCQ() async {
    try {
      var url = Uri.parse('${API_ADDRESS}Trip/RematchCustomerQueue');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
      } else {
        return response.body;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<String?> giveRating(int tripID, int rating) async {
    try {
      var url = Uri.parse('${API_ADDRESS}Trip/DriverRating?tripID=$tripID&rating=$rating');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        print('success');
      } else {
        return response.body;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  //Get the current trip when refresh the page.
  static Future<TripResponse> getCurrentTrip() async {
    var tripResponse = TripResponse();
    try {
      var url = Uri.parse('${API_ADDRESS}Trip/CurrentTripCustomer');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        tripResponse = tripResponseFromJson(response.body) as TripResponse;
      } else {
        tripResponse.response = response.body;
      }
    } catch (e) {
      print(e);
    }
    return tripResponse;
  }

  //Data polling to get if the trip has been updated
  static Future<String?> getTripStatus() async {
    try {
      var url = Uri.parse('${API_ADDRESS}Trip/TripStatus');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        //Working trip not found -> Driver canceled
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  //getting the driver that has been matched to the customer
  static Future<Tuple2<Driver?, String?>> getTripDriver() async {
    Driver? driver;
    String? err;
    try {
      var url = Uri.parse('${API_ADDRESS}Trip/TripDriver');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        driver = driverFromJson(response.body);
      } else {
        err = response.body;
      }
    } catch (e) {
      print(e);
    }
    return Tuple2(driver, err);
  }

  //getting the matched driver's location
  static Future<Tuple2<LatLng?, String?>> getTripDriverLocation() async {
    LatLng? loc;
    String? err;
    try {
      var url = Uri.parse('${API_ADDRESS}Trip/TripDriverLocation');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        var temp = json.decode(response.body);
        loc = LatLng(temp['latitude']?.toDouble(), temp['longitude']?.toDouble());
      } else {
        err = response.body;
      }
    } catch (e) {
      print(e);
    }
    return Tuple2(loc, err);
  }
}
