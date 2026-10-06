import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/enum_type.dart';
import '../models/event.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class GeneralServices {
  static Future<List<Event>> getEvents() async {
    List<Event> ret = List.empty();
    try {
      var url = Uri.parse('${API_ADDRESS}Taxi/Events');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        ret = List<Event>.from(jsonDecode(response.body).map((x) => Event.fromJson(x)));
      } else {}
    } catch (e) {
      print('GeneralServices.getEvents');
      print(e);
    }
    return ret;
  }
}
