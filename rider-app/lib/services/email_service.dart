import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class EmailService {
  //This takes long time. don't await this
  static Future<String?> sendEmailToHanin({required String message, required String screen, int? tripID}) async {
    String? err;
    try {
      var url = Uri.parse('${API_ADDRESS}Email/SendEmailToHanin');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt', 'Content-Type': 'Application/json'};
      var body = jsonEncode({
        'tripID': tripID,
        'message': message,
        'screen': screen,
      });
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
      } else {
        err = response.body;
      }
    } catch (e) {
      print("EmailService.SendEmailToHanin");
      print(e);
    }
    return err;
  }
}
