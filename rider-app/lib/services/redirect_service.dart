import 'dart:io';

import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';

class RedirectService {
  static Future<bool> launchMapSearch(double latitude, double longitude) {
    return launchUrl(createSearchUri(latitude, longitude));
  }

  static Future<bool> launchMapNavigation(double latitude, double longitude) {
    return launchUrl(createNavigationUri(latitude, longitude));
  }

  static Uri createSearchUri(double latitude, double longitude) {
    Uri uri;

    if (Platform.isAndroid) {
      var query = '$latitude,$longitude';

      uri = Uri(scheme: 'geo', host: '0,0', queryParameters: {'q': query});
    } else if (Platform.isIOS) {
      var params = {
        'll': '$latitude,$longitude',
        'q': '$latitude, $longitude',
      };

      uri = Uri.https('maps.apple.com', '/', params);
    } else {
      uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$latitude,$longitude'});
    }

    return uri;
  }

  static Uri createNavigationUri(double latitude, double longitude) {
    Uri uri;

    if (Platform.isAndroid) {
      var query = '$latitude,$longitude';

      uri = Uri(scheme: 'google.navigation', host: '0,0', queryParameters: {'q': query});
    } else if (Platform.isIOS) {
      var params = {
        'daddr': '$latitude,$longitude',
        'dirflag': 'd',
      };

      uri = Uri.https('maps.apple.com', '/', params);
    } else {
      uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$latitude,$longitude'});
    }

    return uri;
  }

  static Future makeCall(String number) async {
    var phoneNumberCaller = number.replaceAll(RegExp(r"\D"), "");
    String pattern = "^(?:[+0]9)?[0-9]{10}\$";
    RegExp reg = RegExp(pattern);
    if (reg.hasMatch(phoneNumberCaller)) {
      await FlutterPhoneDirectCaller.callNumber(phoneNumberCaller);
    }
  }
}
