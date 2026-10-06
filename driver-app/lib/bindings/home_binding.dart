import 'package:driverapp/controllers/driver_controller.dart';
import 'package:driverapp/controllers/location_controller.dart';
import 'package:get/get.dart';

import '../controllers/trip_controller.dart';
import '../services/hub_service.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() async {
    Get.put(LocationController());
    var tripController = Get.put(TripController());
    var driverController = Get.put(DriverController());
    //await StorageService.deleteAllSecureData();
    Get.updateLocale(ENGLISH);

    await driverController.refreshToken();
    tripController.tripStatusListen();
    if (driverController.driver.value != null) {
      await tripController.getStatus();
    }
    tripController.startPolling();
  }
}
