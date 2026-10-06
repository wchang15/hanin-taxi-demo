// import 'dart:async';
// import 'dart:isolate';
// import 'dart:math';
// import 'dart:ui';

// import 'package:background_locator_2/location_dto.dart';

// class LocationServiceRepository {
//   static LocationServiceRepository _instance = LocationServiceRepository._();

//   LocationServiceRepository._();

//   factory LocationServiceRepository() {
//     return _instance;
//   }

//   static const String isolateName = 'LocatorIsolate';

//   int _count = -1;

//   Future<void> init(Map<dynamic, dynamic> params) async {
//     if (params.containsKey('countInit')) {
//       dynamic tmpCount = params['countInit'];
//       if (tmpCount is double) {
//         _count = tmpCount.toInt();
//       } else if (tmpCount is String) {
//         _count = int.parse(tmpCount);
//       } else if (tmpCount is int) {
//         _count = tmpCount;
//       } else {
//         _count = -2;
//       }
//     } else {
//       _count = 0;
//     }
//     //await setLogLabel("start");
//     final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
//     send?.send(null);
//   }

//   Future<void> dispose() async {
//     print("***********Dispose callback handler");
//     print("$_count");
//     //await setLogLabel("end");
//     final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
//     send?.send(null);
//   }

//   Future<void> callback(LocationDto locationDto) async {
//     //await setLogPosition(_count, locationDto);
//     final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
//     send?.send(locationDto.toJson());
//     _count++;
//   }
// }
