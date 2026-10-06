// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/models/user_location.dart';
import 'package:tax_app/services/mapbox_service.dart';

void main() {
  test('formats Mapbox direction coordinates as longitude,latitude', () {
    final value = MapBoxService.getLatLngString(
      const LatLng(40.8509, -73.9701),
      const LatLng(40.7580, -73.9855),
    );

    expect(value, '-73.9701,40.8509;-73.9855,40.758');
  });

  test('converts Mapbox GeoJSON points to latitude,longitude', () {
    final points = MapBoxService.getPoints([
      [-73.9701, 40.8509],
      [-73.9855, 40.7580],
    ]);

    expect(points, hasLength(2));
    expect(points.first.latitude, 40.8509);
    expect(points.first.longitude, -73.9701);
    expect(points.last.latitude, 40.7580);
    expect(points.last.longitude, -73.9855);
  });

  test('supports a New Jersey pickup with an airport destination', () {
    final pickup = UserLocation(
      name: 'Hanin Taxi Demo Office',
      address: '100 Main St, Fort Lee, NJ 07024',
      latitude: 40.8509,
      longitude: -73.9701,
      locationType: EnumLocationType.OTHER,
    );
    final airport = UserLocation(
      name: 'John F. Kennedy International Airport',
      address: 'Queens, NY 11430',
      latitude: 40.6413,
      longitude: -73.7781,
      locationType: EnumLocationType.AIRPORT,
    );

    expect(isSupportedServiceTrip(pickup, airport), isTrue);
  });
}
