//general imports
import 'dart:async';
import 'package:driverapp/controllers/driver_controller.dart';
import 'package:driverapp/controllers/location_controller.dart';
import 'package:driverapp/services/driver_service.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';

//component imports
import '../controllers/trip_controller.dart';
import '../models/user_location.dart';
import '../services/mapbox_service.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_location.dart';
import '../widgets/custom_text_form_field.dart';
import '../widgets/custom_tap.dart';
import '../widgets/custom_app_bar.dart';

//style imports
import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../utils/validate_text.dart';

/// Home screen class
class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SelectLocationScreenState();
}

/// Home screen components/widgets
class SelectLocationScreenState extends State<SelectLocationScreen> {
  /// class for managing trip details (src,dst)
  final tripController = Get.find<TripController>();
  final locationController = Get.find<LocationController>();
  final driverController = Get.find<DriverController>();

  /// Manages the user's search input
  final userInput = TextEditingController();

  UserLocation? selectedLocation;

  /// Holds the set of suggested search results
  List<UserLocation> searchResults = [];

  /// Holds state for controlling the submission button
  bool hasSelected = false;

  ///if true update db, if not dont
  bool isChanged = true;

  /// google location id when editing
  int? editGoogleLocationID;

  /// Sets the initial state of this widget
  @override
  void initState() {
    super.initState();
  }

  /// Saved a searched location to their set of saved locations
  Future<void> saveLocation() async {
    final userLocation = selectedLocation!;

    print("${userLocation.name} ${userLocation.address}");
    var res = await tripController.startTrip(dest: userLocation);
    if (!res) {
      //Fail
      Get.until((route) => Get.currentRoute == HOME);
    } else {
      Get.until((route) => Get.currentRoute == TRIP);
    }
  }

  /// Builds the add favorites page on the given build [context]
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBar(
            title: Text("trip_dest".tr, style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () => Get.back(),
            ),
          ),
          backgroundColor: ColorConstant.WHITE,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Obx(
                () => CustomAlert(
                  bgColor: ColorConstant.RED1,
                  color: ColorConstant.RED,
                  icon: IconConstant.Notification,
                  text: tripController.errorResponse.value,
                  visible: tripController.errorResponse.value.isNotEmpty,
                ),
              ),
              //confirmation button
              Obx(
                () => CustomTap(
                  color: (hasSelected ? ColorConstant.PRIMARY : ColorConstant.GREY3),
                  onTap: tripController.isLoading.value
                      ? null
                      : () async {
                          tripController.isLoading.value = true;
                          if (hasSelected) {
                            await saveLocation();
                          }
                          tripController.isLoading.value = false;
                        },
                  child: Text("trip_start".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
                ),
              ),
            ],
          ),

          // main container
          body: Padding(
            padding: getPadding(left: 16, top: 16, right: 16),
            child: Column(
              children: [
                //destination location input field
                CustomTextFormField(
                  controller: userInput,
                  text: 'dest_location_hint'.tr,
                  validate: validatePassword,
                  autoFocus: false,
                  onChanged: (text) async {
                    EasyDebounce.debounce('mylocationdebounce', const Duration(milliseconds: DOUBLECLICKDEBOUNCE),
                        () async {
                      hasSelected = false; // set flag signifying address changed
                      searchResults = await MapBoxService.getAutoComplete(text);
                      setState(() {});
                    });
                  },
                  suffixIcon: userInput.value.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            IconConstant.Clear,
                            color: ColorConstant.BLACK,
                          ),
                          onPressed: () => setState(
                            () {
                              userInput.clear();
                            },
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 1),

                //search results menu
                Visibility(
                  visible: searchResults.isNotEmpty,
                  child: SizedBox(
                    height: 350,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: CustomLocation(userLocation: searchResults[index]),
                          // sets user input to the selected address
                          onTap: () async {
                            isChanged = true;
                            hasSelected = true; // set flag signifying actual address selected
                            selectedLocation = searchResults[index];
                            userInput.text = searchResults[index].getFullAddress();
                            searchResults.clear();
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),

                Visibility(
                  visible: searchResults.isEmpty,
                  child: SizedBox(
                    height: SIZE.height * 2 / 3,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: driverController.driver.value!.frequentLocations.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: CustomLocation(userLocation: driverController.driver.value!.frequentLocations[index]),
                          // sets user input to the selected address
                          onTap: () async {
                            isChanged = true;
                            hasSelected = true; // set flag signifying actual address selected
                            selectedLocation = driverController.driver.value!.frequentLocations[index];
                            userInput.text = driverController.driver.value!.frequentLocations[index].getFullAddress();
                            searchResults.clear();
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
