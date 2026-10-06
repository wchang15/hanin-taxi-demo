import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tax_app/models/customer_response.dart';
import 'package:tax_app/models/register_request.dart';
import 'package:tuple/tuple.dart';
import '../models/customer_token.dart';
import '../models/user_login.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class LoginServices {
  //registering a new customer and logging in
  static Future<CustomerResponse> postRegister(RegisterRequest register) async {
    var customerResponse = CustomerResponse();
    try {
      var url = Uri.parse('${API_ADDRESS}Login/RegisterCustomer');
      var headers = {'Content-Type': 'Application/json'};
      var body = jsonEncode(register.toJson());
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        var customerToken = cutomerTokenFromJson(response.body);
        await StorageService.deleteAllSecureData();
        await StorageService.writeSecureData(JWT, customerToken!.token);
        await StorageService.writeSecureData(
            REFRESH, response.headers['set-cookie']!);
        customerResponse.customer = customerToken.customer;
      } else {
        customerResponse.response = response.body;
      }
    } catch (e) {
      print('login_service.postRegister');
      print(e);
    }
    return customerResponse;
  }

  //updating the phone number for phone verification
  static Future<Tuple2<String?, String?>> putPhoneUpdate(
      String number, bool isVerified) async {
    String? err;
    String? num;
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/UpdatePhone');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {
        'Authorization': 'bearer $jwt',
        'Content-Type': 'Application/json'
      };
      var body = jsonEncode({'phoneNumber': number, 'isVerified': isVerified});
      var response = await http.put(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        num = response.body;
      } else {
        err = response.body;
      }
    } catch (e) {
      print('login_service.putPhoneUpdate');
      print(e);
    }
    return Tuple2(num, err);
  }

  //sending the phone verification code to verify the phone
  static Future<Tuple2<bool?, String?>> putPhoneVerification(
      String otp, bool isVerified, String phoneNumber) async {
    String? err;
    bool? success;
    try {
      var url = Uri.parse('${API_ADDRESS}Customer/PhoneVerify');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {
        'Authorization': 'bearer ${jwt}',
        'Content-Type': 'Application/json'
      };
      var body = jsonEncode(
          {'otp': otp, 'isVerified': isVerified, 'phoneNumber': phoneNumber});
      var response = await http.put(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        success = true;
      } else {
        err = response.body;
      }
    } catch (e) {
      print('login_service.putPhoneVerification');
      print(e);
    }
    return Tuple2(success, err);
  }

  //Logging in the customer
  static Future<CustomerResponse> postLoginCustomer(UserLogin userLogin) async {
    CustomerResponse customerResponse = new CustomerResponse();
    try {
      var url = Uri.parse('${API_ADDRESS}Login/LoginCustomer');
      var headers = {"Content-Type": "application/json"};
      var body = jsonEncode(userLogin.toJson());
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        var customerToken = cutomerTokenFromJson(response.body);
        await StorageService.deleteAllSecureData();
        await StorageService.writeSecureData(JWT, customerToken!.token);
        await StorageService.writeSecureData(
            REFRESH, response.headers['set-cookie']!);
        customerResponse.customer = customerToken.customer;
      } else {
        customerResponse.response = response.body;
      }
    } catch (e) {
      print('login_service.postLoginCustomer');
      print(e);
    }
    return customerResponse;
  }

  //Logging out the customer
  static Future<String?> postLogout() async {
    try {
      var url = Uri.parse('${API_ADDRESS}Login/Logout');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        await StorageService.deleteAllSecureData();
        return "Success";
      }
    } catch (e) {
      print('login_service.postLogout');
      print(e);
    }
    return null;
  }

  //Refreshing the customer when they re open the app
  static Future<CustomerResponse> postRefreshToken() async {
    CustomerResponse customerResponse = CustomerResponse();
    try {
      var url = Uri.parse('${API_ADDRESS}Login/RefreshTokenCustomer');
      var isRefreshToken =
          await StorageService.containsKeyInSecureData(REFRESH);
      if (!isRefreshToken) {
        customerResponse.response = "Refresh Token Not Found";
        return customerResponse;
      }
      var refreshTokenWithDate = await StorageService.readSecureData(REFRESH);
      var refreshToken =
          refreshTokenWithDate!.substring(0, refreshTokenWithDate.indexOf(';'));
      var headers = {'cookie': refreshToken};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        var customerToken = cutomerTokenFromJson(response.body);
        await StorageService.deleteAllSecureData();
        await StorageService.writeSecureData(JWT, customerToken!.token);
        await StorageService.writeSecureData(
            REFRESH, response.headers['set-cookie']!);
        customerResponse.customer = customerToken.customer;
      } else {
        customerResponse.response = response.body;
      }
    } catch (e) {
      print('login_service.postRefreshToken');
      print(e);
    }
    return customerResponse;
  }
}
