import 'package:http/http.dart' as http;

import '../models/enum_type.dart';
import '../utils/constants.dart';

class EnumServices {
  //Get enum
  static Future<Object?> getEnum(String enumType) async {
    try {
      var url = Uri.parse('${API_ADDRESS}Enum/$enumType');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        return enumTypeFromJson(response.body);
      }
    } 
    catch (e) {
      print('enum_service.getEnum');
      print(e);
    }
    return null;
  }
}
