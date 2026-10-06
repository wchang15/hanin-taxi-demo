import 'dart:convert';

import 'package:driverapp/controllers/driver_controller.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';
import '../models/driver.dart';
import '../models/driver_token.dart';
import '../models/user_login.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class LoginService {
  //Logging in the customer
  static Future<Tuple2<Driver?, String?>> postLoginDriver(
      UserLogin userLogin) async {
    Driver? driver;
    String? err;
    try {
      var url = Uri.parse('${API_ADDRESS}Login/LoginDriver');
      var headers = {"Content-Type": "application/json"};
      var body = jsonEncode(userLogin.toJson());
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        var driverToken = driverTokenFromJson(response.body);
        driver = driverToken!.driver;
        await StorageService.deleteAllSecureData();
        await StorageService.writeSecureData(JWT, driverToken.token);
        await StorageService.writeSecureData(
            REFRESH, response.headers['set-cookie']!);
        DriverController driverController = Get.find<DriverController>();
        await driverController.setMap(driver.map);
      } else {
        err = response.body;
      }
    } catch (e) {
      print('login_service.postLoginDriver');
      print(e);
    }
    return Tuple2(driver, err);
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
  static Future<Tuple2<Driver?, String?>> postRefreshToken() async {
    Driver? driver;
    String? err;
    try {
      var url = Uri.parse('${API_ADDRESS}Login/RefreshTokenDriver');
      var isRefreshToken =
          await StorageService.containsKeyInSecureData(REFRESH);
      if (!isRefreshToken) {
        err = "Refresh Token Not Found";
        return Tuple2(driver, err);
      }
      var refreshTokenWithDate = await StorageService.readSecureData(REFRESH);
      var refreshToken =
          refreshTokenWithDate!.substring(0, refreshTokenWithDate.indexOf(';'));
      var headers = {'cookie': refreshToken};
      var response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        var driverToken = driverTokenFromJson(response.body);
        driver = driverToken!.driver;
        await StorageService.deleteAllSecureData();
        await StorageService.writeSecureData(JWT, driverToken.token);
        await StorageService.writeSecureData(
            REFRESH, response.headers['set-cookie']!);
        DriverController driverController = Get.find<DriverController>();
        await driverController.setMap(driver.map);
      } else {
        err = response.body;
      }
    } catch (e) {
      print('login_service.postRefreshToken');
      print(e);
    }
    return Tuple2(driver, err);
  }
}
