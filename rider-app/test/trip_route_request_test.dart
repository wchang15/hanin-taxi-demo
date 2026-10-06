import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/models/customer.dart';
import 'package:tax_app/models/user_location.dart';
import 'package:tuple/tuple.dart';

class DelayedLocationController extends GetxController
    implements LocationController {
  final requests = <Completer<Tuple2<List<LatLng>, int>>>[];

  @override
  final currentLocation = Rxn<UserLocation>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Tuple2<List<LatLng>, int>> getRoute(LatLng src, LatLng dst) {
    final request = Completer<Tuple2<List<LatLng>, int>>();
    requests.add(request);
    return request.future;
  }
}

UserLocation location(String name, double latitude, double longitude) =>
    UserLocation(
      name: name,
      address: '$name, NJ',
      latitude: latitude,
      longitude: longitude,
      locationType: EnumLocationType.OTHER,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DelayedLocationController locations;
  late TripController trips;
  const route = [LatLng(40.8509, -73.9701), LatLng(40.6413, -73.7781)];

  setUp(() async {
    Get.testMode = true;
    locations = DelayedLocationController();
    Get.put<LocationController>(locations);
    final customers = Get.put(CustomerController());
    customers.customer.value = Customer(
      userName: 'test',
      firstName: 'Test',
      lastName: 'Rider',
      createdDateTime: DateTime(2026),
      isVerified: true,
      searchHistories: [],
      point: 0,
      savedCards: [],
      savedLocations: [],
      language: 1,
    );
    trips = Get.put(TripController());
    locations.currentLocation.value = location('Pickup', 40.8509, -73.9701);
    await trips.setStartWithLocation(locations.currentLocation.value);
    await trips.setEndWithLocation(location('Airport', 40.6413, -73.7781));
  });

  tearDown(() => Get.reset());

  test('late route response cannot restore a reset trip', () async {
    final pending = trips.setEstimatedRoute(route.first, route.last);
    await trips.resetTrip();
    locations.requests.single.complete(const Tuple2(route, 1800));
    await pending;

    expect(trips.endLocation.value, isNull);
    expect(trips.estimatedRoute.value, isNull);
    expect(trips.estimatedTime.value, 0);
  });

  test('a changed destination invalidates the pending route', () async {
    final pending = trips.setEstimatedRoute(route.first, route.last);
    await trips.setEndWithLocation(location('New destination', 40.7, -73.8));
    locations.requests.single.complete(const Tuple2(route, 1800));
    await pending;
    expect(trips.estimatedRoute.value, isNull);
  });

  test('the latest request wins when responses arrive out of order', () async {
    final first = trips.setEstimatedRoute(route.first, route.last);
    final second = trips.setEstimatedRoute(route.first, route.last);
    locations.requests[1].complete(const Tuple2(route, 900));
    await second;
    locations.requests[0].complete(const Tuple2(route, 1800));
    await first;
    expect(trips.estimatedTime.value, 900);
  });

  test('a current route response still updates the trip', () async {
    final pending = trips.setEstimatedRoute(route.first, route.last);
    locations.requests.single.complete(const Tuple2(route, 1800));
    await pending;
    expect(trips.estimatedRoute.value, route);
    expect(trips.estimatedTime.value, 1800);
  });
}
