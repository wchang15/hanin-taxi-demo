import 'dart:io';
import 'dart:async';
import 'dart:core';

import 'package:path/path.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:tax_app/models/trip_history.dart';
import 'package:tuple/tuple.dart';
import 'dart:convert';

import '../models/customer.dart';
import '../models/user_card.dart';
import '../models/user_location.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class CustomerServices {
  //Saving the custoemr Card
  //Returns List or UserCards or String (Error)
  static Future<Tuple2<List<UserCard>?, String?>> saveCustomerCard(PaymentMethod paymentMethod, bool isDefault) async {
    List<UserCard>? cards;
    String? error;
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/AddCard');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = Map<String, String>();
      headers.addAll({'Authorization': 'bearer ${jwt}', "Content-Type": "application/json"});
      var body = jsonEncode({
        'paymentMethodID': paymentMethod.id,
        'last4': paymentMethod.card.last4,
        'expirationMonth': paymentMethod.card.expMonth,
        'expirationYear': paymentMethod.card.expYear,
        'brand': paymentMethod.card.brand,
        'isDefault': isDefault,
      });
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        cards = userCardFromJson(response.body);
      } else {
        error = response.body;
      }
    } catch (e) {
      print('customer_service.saveCustomerCard');
      print(e);
    }
    return Tuple2(cards, error);
  }

  static Future<Tuple2<List<UserCard>?, String?>> updateDefaultCard(int customerCardID) async {
    List<UserCard>? cards;
    String? error;
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/ChangeDefaultCard?customerCardID=$customerCardID');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = Map<String, String>();
      headers.addAll({'Authorization': 'bearer $jwt'});
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        cards = userCardFromJson(response.body);
      } else {
        error = response.body;
      }
    } catch (e) {
      print('customer_service.updateDefaultCard');
      print(e);
    }
    return Tuple2(cards, error);
  }

  static Future<Tuple2<List<UserCard>?, String?>> deleteCard(int customerCardID) async {
    List<UserCard>? cards;
    String? error;
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/DeleteCard?customerCardID=$customerCardID');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = Map<String, String>();
      headers.addAll({'Authorization': 'bearer $jwt'});
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        cards = userCardFromJson(response.body);
      } else {
        error = response.body;
      }
    } catch (e) {
      print('customer_service.deleteCard');
      print(e);
    }
    return Tuple2(cards, error);
  }

  //Not used
  //Getting the customer
  static Future<Customer?> getCustomer() async {
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/GetMe');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer ${jwt}'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return customerFromJson(response.body);
      }
    } catch (e) {
      print('customer_service.getCustomer');
      print(e);
    }
    return null;
  }

  /// retrieves a user's search history as a list of [UserLocation] objects
  static Future<List<UserLocation>?> getCustomerHistory() async {
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/GetSearchHistory');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer ${jwt}'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return userLocationFromJson(response.body);
      }
    } catch (e) {
      print('customer_service.getCustomerHistory');
      print(e);
    }
    return null;
  }

  /// retrieves a user's saved locations as a list of [UserLocation] objects
  static Future<List<UserLocation>> getCustomerSavedLocations() async {
    var ret = <UserLocation>[];
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/GetSavedLocations');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer ${jwt}'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        ret = userLocationFromJson(response.body)!;
      }
    } catch (e) {
      print('customer_service.getCustomerSavedLocations');
      print(e);
    }
    return ret;
  }

  /// Deletes a customer's saved location by [googleLocationID]
  static Future<bool> deleteCustomerSavedLocation(int googleLocationID) async {
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/RemoveLocation/$googleLocationID');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('customer_service.deleteCustomerSavedLocation');
      print(e);
    }
    return false;
  }

  /// Replaces the work/home location with the given [location]
  static Future<bool?> replaceCustomerSavedLocation(int locationID, UserLocation location) async {
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/ReplaceLocation/$locationID');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', "Content-Type": "application/json"};
      var body = jsonEncode({
        'name': location.name,
        'type': location.type,
        'address': location.address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'locationType': location.locationType.index,
      });
      var response = await http.patch(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('customer_service.replaceCustomerSavedLocation');
      print(e);
    }
    return null;
  }

  /// Adds the given [location] to a customer's saved locations
  static Future<bool?> addCustomerSavedLocation(UserLocation location) async {
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/AddLocation');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', "Content-Type": "application/json"};
      var body = jsonEncode({
        'name': location.name,
        'type': location.type,
        'address': location.address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'locationType': location.locationType.index,
      });
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('customer_service.addCustomerSavedLocation');
      print(e);
    }
    return null;
  }

  /// Adds a coupon's amount to a user's points using its [couponCode], and returns the total point amount
  static Future<double?> applyCoupon(String couponCode) async {
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/ApplyCoupon');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', "Content-Type": "application/json"};
      var body = jsonEncode({
        'couponCode': couponCode,
      });
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('customer_service.applyCoupon');
      print(e);
    }
    return null;
  }

  /// Adds a coupon's amount to a user's points using its [card], and returns the total point amount
  static Future<double?> addPoints(String amount, int customerCardID) async {
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/AddPoints');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', "Content-Type": "application/json"};
      var intAmount = int.tryParse(amount) ?? 0;
      if (intAmount == 0) return null;
      var body = jsonEncode({
        'CustomerCardID': customerCardID,
        'Amount': intAmount,
      });
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('customer_service.addPoints');
      print(e);
    }
    return null;
  }

  //Not used
  //Saving the customer photo
  static Future<Customer?> saveCustomerPhoto(File imageFile) async {
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/UploadPhoto');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer ${jwt}'};
      var request = new http.MultipartRequest('POST', url);
      var stream = imageFile.readAsBytes().asStream();
      var length = await imageFile.length();
      var multipartFile = new http.MultipartFile('file', stream, length, filename: basename(imageFile.path));
      request.headers.addAll(headers);
      request.files.add(multipartFile);
      var response = await request.send();
      if (response.statusCode == 200) {
        var stream = await http.Response.fromStream(response);
        return customerFromJson(stream.body);
      }
    } catch (e) {
      print('customer_service.saveCustomerPhoto');
      print(e);
    }
    return null;
  }

  ///receiving phone verification code
  ///Returns "" if success.
  static Future<String> getOTP(String phoneNumber, String? username) async {
    String res = "";
    try {
      var address =
          username != null ? '${API_ADDRESS}Customer/GetOTP?username=$username' : '${API_ADDRESS}Customer/GetOTP';
      var url = Uri.parse(address);
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', 'Content-Type': 'Application/json'};
      var body = jsonEncode({'phoneNumber': phoneNumber});
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
      } else {
        //error
        res = response.body;
      }
    } catch (e) {
      print('customer_service.getOTP');
      print(e);
    }
    return res;
  }

  ///receiving phone verification code
  ///Returns "" if success.
  static Future<String> resendOTP() async {
    String res = "";
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/ResendOTP');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
      } else {
        //error
        res = response.body;
      }
    } catch (e) {
      print('customer_service.resendOTP');
      print(e);
    }
    return res;
  }

  ///sending the phone verification code to verify the phone and get username
  /// returns username if success
  static Future<String> getUsername(String otp, String phoneNumber) async {
    String res = "";
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/GetUsername');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', 'Content-Type': 'Application/json'};
      var body = jsonEncode({'otp': otp, 'phoneNumber': phoneNumber});
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        res = response.body;
      } else {
        //error
      }
    } catch (e) {
      print('customer_service.getUsername');
      print(e);
    }
    return res;
  }

  ///sending the phone verification code to verify the phone and reset password
  ///retuns customerID if success else 0
  static Future<int> resetPasswordVerifyPhone(String otp, String phoneNumber) async {
    int res = 0;
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/VerifyOTP');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', 'Content-Type': 'Application/json'};
      var body = jsonEncode({'otp': otp, 'phoneNumber': phoneNumber});
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        res = int.tryParse(response.body) ?? 0;
      } else {}
    } catch (e) {
      print('customer_service.resetPasswordVerifyPhone');
      print(e);
    }
    return res;
  }

  ///sending the phone verification code to verify the phone and reset password
  ///retuns "" if success
  static Future<String> resetPassword(String password, int customerID) async {
    String res = "";
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/ResetPassword?password=$password&customerID=$customerID');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
      } else {
        res = response.body;
      }
    } catch (e) {
      print('customer_service.resetPassword');
      print(e);
    }
    return res;
  }

  static Future<List<TripHistory>> getMyCompletedTrips(int filterType) async {
    List<TripHistory> ret = List.empty();
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/GetMyCompletedTrips?filterType=$filterType');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        ret = List<TripHistory>.from(jsonDecode(response.body).map((x) => TripHistory.fromJson(x)));
      } else {
        // error
      }
    } catch (e) {
      print('customerservice.getMyCompletedTrips');
      print(e);
    }
    return ret;
  }

  static Future<bool> updateLanguage(int language) async {
    bool res = false;
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/UpdateLanguage?language=$language');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        res = true;
      } else {
        //error
      }
    } catch (e) {
      print('customer_service.updateLanguage');
      print(e);
    }
    return res;
  }

  static Future<bool> updateCustomer(String firstName, String lastName, String email) async {
    bool res = false;
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/UpdateCustomer');
      var jwt = await StorageService.readSecureData(JWT);
      var body = jsonEncode({'firstName': firstName, 'lastName': lastName, 'email': email});
      var headers = {'Authorization': 'bearer $jwt', 'Content-Type': 'Application/json'};
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        res = true;
      } else {
        //error
      }
    } catch (e) {
      print('customer_service.updateCustomer');
      print(e);
    }
    return res;
  }

  static Future<bool> deleteUser() async {
    bool res = false;
    try {
      var url = Uri.parse('${API_ADDRESS}Login/Delete');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        res = true;
      } else {
        //error
      }
    } catch (e) {
      print('customer_service.deleteUser');
      print(e);
    }
    return res;
  }
}
