import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'constants.dart';

MapCamera fitRouteCamera(
  MapCamera camera,
  List<LatLng> points, {
  required double topInset,
}) {
  // Keep endpoint labels below the status bar and the top-left back button.
  return CameraFit.bounds(
    bounds: LatLngBounds.fromPoints(points),
    padding: EdgeInsets.fromLTRB(56, topInset + 96, 56, 56),
    maxZoom: MAP_ROUTE_MAX_ZOOM,
  ).fit(camera);
}
