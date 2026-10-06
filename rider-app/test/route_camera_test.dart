import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tax_app/utils/constants.dart';
import 'package:tax_app/utils/route_camera.dart';

void main() {
  const route = [
    LatLng(40.8509, -73.9701),
    LatLng(40.7580, -73.9855),
    LatLng(40.6413, -73.7781),
  ];

  for (final size in [const Size(402, 430), const Size(375, 370)]) {
    for (final inset in [0.0, 62.0]) {
      test('route labels clear top controls at $size, inset $inset', () {
        final fitted = fitRouteCamera(
          MapCamera(
            crs: const Epsg3857(),
            center: route.first,
            zoom: MAP_LOCATION_ZOOM,
            rotation: 0,
            nonRotatedSize: size,
          ),
          route,
          topInset: inset,
        );

        for (final point in route) {
          final offset = fitted.latLngToScreenOffset(point);
          expect(offset.dx, inInclusiveRange(55.9, size.width - 55.9));
          expect(offset.dy, inInclusiveRange(inset + 95.9, size.height - 55.9));
        }
        expect(fitted.zoom, lessThanOrEqualTo(MAP_ROUTE_MAX_ZOOM));
      });
    }
  }
}
