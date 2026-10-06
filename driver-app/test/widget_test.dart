// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:driverapp/controllers/trip_controller.dart';
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/models/user_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the dispatcher preferred location name when available', () {
    final location = UserLocation(
      name: '100 Main Street',
      preferredName: 'Hanin Taxi Office',
      address: 'Fort Lee, NJ 07024',
      latitude: 40.8509,
      longitude: -73.9701,
      locationType: EnumLocationType.OTHER,
    );

    expect(location.getName(), 'Hanin Taxi Office : 100 Main Street');
    expect(
      location.getFullAddress(),
      'Hanin Taxi Office : 100 Main Street, Fort Lee, NJ 07024',
    );
  });

  test('reads the payment type returned by the driver trip API', () {
    final trip = Trip.fromJson(_tripJson(paymentType: 4));

    expect(trip.getEnumPaymentType(), EnumPaymentType.CASH);
  });

  test('defaults older driver trip responses to card payment', () {
    final trip = Trip.fromJson(_tripJson());

    expect(trip.getEnumPaymentType(), EnumPaymentType.CARD);
  });
}

Map<String, dynamic> _tripJson({int? paymentType}) {
  return {
    'tripID': 1,
    'tripStatus': 3,
    'startPreferredName': '',
    'startName': 'W 47th St',
    'startAddress': 'New York, NY 10036',
    'startLatitude': 40.759211,
    'startLongitude': -73.984638,
    'endPreferredName': '',
    'endName': 'Times Square',
    'endAddress': 'New York, NY 10036',
    'endLatitude': 40.758,
    'endLongitude': -73.9855,
    'customerFirstName': 'Demo',
    'customerPhoneNumber': '2015550101',
    'tripType': 1,
    if (paymentType != null) 'paymentType': paymentType,
    'tripAmount': 6.0,
    'note': '',
    'alcoholPhoneNumber': '',
  };
}
