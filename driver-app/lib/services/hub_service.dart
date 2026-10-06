import 'dart:convert';

import 'package:get/get.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../controllers/driver_controller.dart';
import '../controllers/trip_controller.dart';
import '../models/trip.dart';
import '../utils/constants.dart';

class HubService {
  static HubConnection hubConnection = HubConnectionBuilder()
      .withUrl(HUB_ADDRESS)
      //, options: HttpConnectionOptions(accessTokenFactory: () async => await StorageService.readSecureData(JWT);))
      //transportType: HttpTransportType.WebSockets, options: HttpConnectionOptions(skipNegotiation: true))
      .withAutomaticReconnect(retryDelays: [
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000,
    1000
  ]).build();

  static Future<void>? _startFuture;
  static bool _handlersRegistered = false;

  static Future<void> initSignalR() async {
    _registerHandlers();

    final state = hubConnection.state;
    if (state == HubConnectionState.Connected ||
        state == HubConnectionState.Connecting ||
        state == HubConnectionState.Reconnecting ||
        state == HubConnectionState.Disconnecting) {
      return;
    }

    final pendingStart = _startFuture;
    if (pendingStart != null) {
      await pendingStart;
      return;
    }

    final startFuture = _startConnection();
    _startFuture = startFuture;
    try {
      await startFuture;
    } catch (error) {
      print('Hub connection failed: $error');
    } finally {
      if (identical(_startFuture, startFuture)) {
        _startFuture = null;
      }
    }
  }

  static void _registerHandlers() {
    if (_handlersRegistered) return;
    _handlersRegistered = true;

    TripController tripController = Get.find<TripController>();
    hubConnection.onclose(({error}) async {
      if (error != null) print(error);
      if (hubConnection.state == HubConnectionState.Disconnected) {
        await initSignalR();
      }
    });

    hubConnection.keepAliveIntervalInMilliseconds = 1000 * 60 * 5;
    hubConnection.serverTimeoutInMilliseconds = 1000 * 60 * 10;

    hubConnection.on(HUBMATCH, (params) async {
      if (tripController.tripStatus.value == EnumTripStatus.CUSTOMERSEARCHING) {
        var trip = tripFromJson(jsonEncode(params![1]));
        await tripController.updateStatus(
            trip, int.parse(params[0].toString()));
      }
    });

    hubConnection.on(HUBCUSTOMERCANCEL, (params) async {
      var tripID = int.tryParse(params![1].toString()) ?? -1;
      if (tripID == (tripController.trip.value?.tripID ?? 0)) {
        await tripController.updateStatus(
            null, int.parse(params![0].toString()));
      }
    });

    hubConnection.on(HUBCOMPANYCANCEL, (params) async {
      var tripID = int.tryParse(params![1].toString()) ?? -1;
      if (tripID == (tripController.trip.value?.tripID ?? 0)) {
        await tripController.updateStatus(
            null, int.parse(params![0].toString()));
      }
    });

    // Good
    hubConnection.on(PRICEUPDATE, (params) async {
      var tripID = int.tryParse(params![1].toString()) ?? -1;
      if (tripID == (tripController.trip.value?.tripID ?? 0)) {
        tripController.trip.update(
            (val) => val?.tripAmount = double.parse(params![0].toString()));
      }
    });

    // Good
    hubConnection.on(NOTEUPDATE, (params) async {
      var tripID = int.tryParse(params![1].toString()) ?? -1;
      if (tripID == (tripController.trip.value?.tripID ?? 0)) {
        tripController.trip.update((val) => val?.note = params![0].toString());
      }
    });

    // Good
    hubConnection.on(ALCOHOLDRIVERMATCH, (params) async {
      var tripID = int.tryParse(params![1].toString()) ?? -1;
      if (tripID == (tripController.trip.value?.tripID ?? 0)) {
        tripController.trip
            .update((val) => val?.alcoholPhoneNumber = params![0].toString());
      }
    });

    hubConnection.on(TRIPSTART, (params) async {
      if (tripController.trip.value != null &&
          tripController.trip.value!.getEnumTripType() ==
              EnumTripType.ALCOHOL2) {
        var trip = tripFromJson(jsonEncode(params![1]));
        tripController.updateStatus(trip, int.parse(params[0].toString()));
      }
    });

    hubConnection.onreconnected(({connectionId}) async {
      print("Hub Reconnected");
      await addToGroup();
    });

    hubConnection.onreconnecting(({error}) {
      print("hub reconnecting $error");
    });
  }

  static Future<void> _startConnection() async {
    await hubConnection.start();

    await addToGroup();

    print("Hub Connected");
  }

  static Future<void> addToGroup() async {
    if (!isConnected()) return;

    DriverController driverController = Get.find<DriverController>();
    final driver = driverController.driver.value;
    if (driver == null) return;

    await hubConnection
        .invoke('AddToGroup', args: ['driver${driver.driverID}']);
  }

  static bool isConnected() {
    return hubConnection.state == HubConnectionState.Connected;
  }
}
