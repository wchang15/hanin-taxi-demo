//general imports
import 'package:get/get.dart';
import 'package:flutter/material.dart';

//controller imports
import 'package:tax_app/services/customer_service.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/utils/icon_constants.dart';

//component imports
import '../widgets/custom_saved_location.dart';
import '../widgets/custom_editable_location.dart';
import '../widgets/custom_app_bar.dart';

//model imports
import '../models/user_location.dart';

//metadata imports
import '../utils/constants.dart';
import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

/// Home screen class
class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SavedLocationsScreenState();
}

/// Home screen components/widgets
class SavedLocationsScreenState extends State<SavedLocationsScreen> {
  /// class controlling a customer's metadata
  final customerController = Get.find<CustomerController>();

  /// class for managing trip details (src,dst)
  final tripController = Get.find<TripController>();

  final locationController = Get.find<LocationController>();

  /// Maintains state of nav bar
  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// The following are state variables for a user's saved locations
  List<UserLocation> savedLocations = [];
  UserLocation? workLocation;
  UserLocation? homeLocation;
  // final workLocation = (null as UserLocation?).obs;
  // final homeLocation = (null as UserLocation?).obs;

  /// Flag functions to check if a user has a work/home location set
  bool homeExists() => (homeLocation != null);
  bool workExists() => (workLocation != null);

  /// Sets the initial state of this widget
  @override
  void initState() {
    getSavedLocationsFromCustomer();
    super.initState();
  }

  /// retrieves a user's saved location set and aggregates to work, home and favorites
  void getSavedLocations() async {
    final locationList = await CustomerServices.getCustomerSavedLocations();
    savedLocations.clear();
    locationList?.forEach((location) {
      if (location.type == 1) {
        homeLocation = location;
      } else if (location.type == 2) {
        workLocation = location;
      } else if (location.type == 3) {
        savedLocations.add(location);
      }
    });
    customerController.customer.value!.savedLocations = locationList!;
    setState(() {});
  }

  void getSavedLocationsFromCustomer() async {
    final locationList = customerController.customer.value!.savedLocations;
    savedLocations.clear();
    locationList.forEach((location) {
      if (location.type == 1) {
        homeLocation = location;
      } else if (location.type == 2) {
        workLocation = location;
      } else if (location.type == 3) {
        savedLocations.add(location);
      }
    });
    setState(() {});
  }

  Future setTrip(UserLocation? loc) async {
    await tripController.setEndWithLocation(loc);

    tripController.isLoading.value = true;
    var isSuccess = await tripController.makeNewTrip();
    if (isSuccess) {
      await tripController.setEstimatedRoute(tripController.getStartLatLng(), tripController.getEndLatLng());
    }
    tripController.disposeSelection();
    tripController.isLoading.value = false;
    Get.until((route) => Get.currentRoute == HOME);
  }

  /// Builds the add favorites page on the given build [context]
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          key: scaffoldKey,
          appBar: CustomAppBar(
            title: Text("mylocation".tr, style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () => Get.back(),
            ),
          ),
          backgroundColor: ColorConstant.WHITE,

          // main container
          body: Padding(
            padding: getPadding(left: 16, top: 16, right: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("favorite".tr, style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK1)),
                  const SizedBox(height: 15),

                  // Set/edit home location button
                  CustomEditableLocation(
                    icon: Icon(IconConstant.Home, color: ColorConstant.PRIMARY),
                    leading: "home".tr,
                    text: (homeExists() ? homeLocation!.name : "mylocation_address_help".tr),
                    address: (homeExists() ? homeLocation!.address : ""),
                    trailing: (homeExists() ? "mylocation_edit".tr : "mylocation_add".tr),
                    onPressed: () async {
                      //set dst and route back to search
                      if (homeExists()) {
                        setTrip(homeLocation);
                      }
                    },
                    onTrailingPressed: () async {
                      //route to select locations page and refresh locations after one is selected
                      await Get.toNamed(SELECTLOCATION, arguments: ["HOME", homeLocation]);
                      getSavedLocations();
                    },
                  ),

                  // Set/edit work location button
                  CustomEditableLocation(
                    icon: Icon(IconConstant.Work, color: ColorConstant.PRIMARY),
                    leading: "company".tr,
                    text: (workExists() ? workLocation!.name : "mylocation_address_help".tr),
                    address: (workExists() ? workLocation!.address : ""),
                    trailing: (workExists() ? "mylocation_edit".tr : "mylocation_add".tr),
                    onPressed: () async {
                      //set dst and route back to search
                      if (workExists()) {
                        setTrip(workLocation);
                      }
                    },
                    onTrailingPressed: () async {
                      //route to select locations page and refresh locations after one is selected
                      await Get.toNamed(SELECTLOCATION, arguments: ["WORK", workLocation?.googleLocationID]);
                      getSavedLocations();
                    },
                  ),

                  // List of a user's saved locations
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: getPadding(all: 0),
                    shrinkWrap: true,
                    itemCount: savedLocations.length,
                    itemBuilder: (BuildContext context, int index) {
                      return CustomEditableLocation(
                        icon: Icon(IconConstant.Star, color: ColorConstant.PRIMARY),
                        leading: 'location'.tr + (index + 1).toString(),
                        text: savedLocations[index].name,
                        address: savedLocations[index].address,
                        trailing: "mylocation_delete".tr,
                        onPressed: () async =>
                            await setTrip(savedLocations[index]), //set src, dst and route back to search
                        onTrailingPressed: () async {
                          // Delete a saved location by ID
                          if (await CustomerServices.deleteCustomerSavedLocation(
                              savedLocations[index].googleLocationID!)) {
                            getSavedLocations();
                            setState(() {});
                          }
                        },
                      );
                    },
                  ),
                  // Add favorites button
                  CustomSavedLocation(
                    icon: Icon(IconConstant.Star, color: ColorConstant.PRIMARY),
                    text: "mylocation_add_location".tr,
                    onPressed: () async {
                      //route to select locations page and refresh locations after one is selected
                      await Get.toNamed(SELECTLOCATION, arguments: ["FAVORITE"]);
                      getSavedLocations();
                    },
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
