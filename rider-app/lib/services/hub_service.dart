import 'dart:convert';

import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../controllers/customer_controller.dart';
import '../controllers/trip_controller.dart';
import '../models/trip.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class HubService {
  static HubConnection hubConnection = HubConnectionBuilder()
      .withUrl(HUB_ADDRESS, options: HttpConnectionOptions(
        accessTokenFactory: () async => await StorageService.readSecureData(JWT) ?? '',
      ))
      .withAutomaticReconnect(retryDelays: [
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10
  ]).build();

  static Future<void>? _startFuture;
  static bool _handlersRegistered = false;

  static Future<void> initSignalR() async {
    if ((await StorageService.readSecureData(JWT))?.isNotEmpty != true) return;
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
    });

    hubConnection.on(HUBMATCH, (params) async {
      await tripController.updateStatus(int.parse(params![0].toString()));
    });
    hubConnection.on(HUBUPDATEDRIVERLOCATION, (params) async {
      var jsonString = jsonEncode(params![1]);
      var temp = json.decode(jsonString);
      var loc =
          LatLng(temp['latitude']?.toDouble(), temp['longitude']?.toDouble());
      await tripController.setDriverLocation(loc);
    });
    hubConnection.on(HUBTRIPSTART, (params) async {
      await tripController.updateStatus(int.parse(params![0].toString()));
    });
    hubConnection.on(HUBTRIPCOMPLETE, (params) async {
      await tripController.updateStatus(int.parse(params![0].toString()));
    });
    hubConnection.on(HUBDRIVERCANCEL, (params) async {
      await tripController.updateStatus(int.parse(params![0].toString()));
    });

    hubConnection.onreconnected(({connectionId}) async => addToGroup());
  }

  static Future<void> _startConnection() async {
    await hubConnection.start();

    await addToGroup();
  }

  static Future<void> addToGroup() async {
    if (!isConnected()) return;

    CustomerController customerController = Get.find<CustomerController>();
    final customer = customerController.customer.value;
    if (customer == null) return;

    await hubConnection
        .invoke('AddToGroup', args: ['customer${customer.customerId}']);
  }

  static bool isConnected() {
    return hubConnection.state == HubConnectionState.Connected;
  }

  static Future<void> stop() async => await hubConnection.stop();
}
