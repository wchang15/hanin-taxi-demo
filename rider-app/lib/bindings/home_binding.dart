import 'package:get/get.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';

import '../controllers/location_controller.dart';
import '../services/email_service.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() async {
    var customerController = Get.put(CustomerController());
    var locationController = Get.put(LocationController());
    var tripController = Get.put(TripController());

    customerController.getInitialLocale();
    //StorageService.deleteAllSecureData();
    await customerController.refreshToken();
    await locationController.setCurrentLocation();

    if (locationController.currentLocation.value != null) {
      await tripController
          .setStartWithLocation(locationController.currentLocation.value!);
    }

    if (customerController.customer.value != null) {
      final defaultCardID =
          customerController.customer.value!.defaultCardID ?? 0;
      if (defaultCardID != 0) {
        tripController.selectCustomerCard(defaultCardID);
      } else {
        tripController.setCustomerCardID(0);
      }
    }
    tripController.tripStatusListen();
    if (customerController.customer.value != null) {
      await tripController.setCurrentTrip();
    }
  }
}
