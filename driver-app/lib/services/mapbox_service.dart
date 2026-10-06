import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/user_location.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

// Not being used yet. Could use for cheaper route call
class MapBoxService {
  static Future<List<UserLocation>> getAutoComplete(String address) async {
    List<UserLocation> list = <UserLocation>[];

    try {
      // var url = Uri.parse(
      //     //'https://api.mapbox.com/geocoding/v5/mapbox.places/${address}.json?proximity=ip&types=address,poi&access_token=$MAPBOXAPI');
      //     'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${address}&types=geocode|establishment&key=$GOOGLE_API_KEY');
      var url = Uri.parse('${API_ADDRESS}Shared/GetAutoComplete?address=$address');
      var jwt = await StorageService.readSecureData(JWT);
      var headers = {'Authorization': 'bearer $jwt'};
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        list = List<UserLocation>.from(res.map((x) => UserLocation.fromJson(x)));
      }
    } catch (e) {
      print('MapBoxService.getAutoComplete');
      print(e);
    }
    return list;
  }
}
