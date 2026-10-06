import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/utils/icon_constants.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';

import '../models/user_location.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../utils/validate_text.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_location.dart';
import '../widgets/custom_saved_location.dart';
import '../widgets/custom_text_form_field.dart';

class TripSettingScreen extends StatefulWidget {
  const TripSettingScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TripSettingScreenState();
}

/// Pop up page for user to enter address
class TripSettingScreenState extends State<TripSettingScreen> {
  final customerController = Get.find<CustomerController>();
  final locationController = Get.find<LocationController>();
  final tripController = Get.find<TripController>();
  late FocusNode startFocusNode;
  late FocusNode endFocusNode;

  /// holds the set of suggested source search results
  List<UserLocation> searchResults = [];

  /// holds state of whether the src or dst search result is being set

  @override
  void initState() {
    startFocusNode = FocusNode();
    endFocusNode = FocusNode();
    startFocusNode.addListener(() {
      if (!startFocusNode.hasFocus) {
        setStartLocation();
        endFocusNode.requestFocus();
      }
    });
    endFocusNode.addListener(() {
      endFocusNode.hasFocus ? null : calculateRoute();
      if (!endFocusNode.hasFocus && tripController.endLocation.value == null) {
        tripController.endLocationController.value.text = "";
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => setFocus());
    super.initState();
  }

  @override
  void dispose() {
    startFocusNode.dispose();
    endFocusNode.dispose();
    super.dispose();
  }

  Future setStartLocation() async {
    if (tripController.startLocation.value == null) {
      final currentLocation = locationController.currentLocation.value;
      if (currentLocation != null) {
        await tripController.setStartWithLocation(currentLocation);
      }
    } else {
      tripController.startLocationController.value.text =
          tripController.startLocation.value!.name;
    }
    await calculateRoute();
  }

  void setFocus() {
    if (tripController.isFocusStart.value) {
      tripController.highlightStart();
      startFocusNode.requestFocus();
    } else {
      tripController.highlightEnd();
      endFocusNode.requestFocus();
    }
  }

  /// flag controlling whether source search results are viewable
  bool showSearchResults() => searchResults.isNotEmpty;

  Future calculateRoute() async {
    if (!startFocusNode.hasFocus && !endFocusNode.hasFocus) {
      if (tripController.isTripSet()) {
        tripController.isLoading.value = true;
        var isSuccess = await tripController.makeNewTrip();
        if (isSuccess) {
          await tripController.setEstimatedRoute(
              tripController.getStartLatLng(), tripController.getEndLatLng());
        }
        dismissKeyboard();
        tripController.disposeSelection();
        tripController.isLoading.value = false;
        Get.back();
      }
    }
  }

  void dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            title: Text("tripsetting_header".tr,
                style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () {
                if (tripController.endLocation.value == null) {
                  tripController.endLocationController.value.clear();
                }
                tripController.disposeSelection();
                Get.back();
              },
            ),
          ),
          body: Container(
            width: SIZE.width,
            padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
            child: ListView(
              children: [
                //source location input field
                CustomTextFormField(
                  controller: tripController.startLocationController.value,
                  text: 'home_set_start'.tr,
                  validate: validateText,
                  onChanged: (text) async {
                    EasyDebounce.debounce(
                        'startdebounce', const Duration(milliseconds: DEBOUNCE),
                        () async {
                      searchResults =
                          await locationController.autoCompleteSearch(text);
                      tripController.setError("");
                      setState(() {});
                    });
                  },
                  suffixIcon: IconButton(
                    icon: Icon(IconConstant.MyLocation),
                    onPressed: () async {
                      tripController.isLoading.value = true;
                      try {
                        await locationController.setCurrentLocation();
                        final currentLocation =
                            locationController.currentLocation.value;
                        if (currentLocation == null) {
                          tripController
                              .setError('location_permission_required'.tr);
                          return;
                        }
                        await tripController
                            .setStartWithLocation(currentLocation);
                        startFocusNode.unfocus();
                        tripController.isFocusStart(false);
                      } finally {
                        tripController.isLoading.value = false;
                      }
                    },
                  ),
                  onTap: () {
                    tripController.isFocusStart(true);
                    tripController.highlightStart();
                  },
                  focusNode: startFocusNode,
                ),

                //add space between
                const SizedBox(height: 10),

                //destination location input field
                CustomTextFormField(
                  controller: tripController.endLocationController.value,
                  text: 'home_set_end'.tr,
                  validate: validatePassword,
                  onChanged: (text) async {
                    EasyDebounce.debounce(
                        'enddebounce', const Duration(milliseconds: DEBOUNCE),
                        () async {
                      searchResults =
                          await locationController.autoCompleteSearch(text);
                      tripController.setError("");
                      if (text == "") tripController.setEndWithLocation(null);
                      setState(() {});
                    });
                  },
                  suffixIcon: IconButton(
                    icon: Icon(IconConstant.MyLocation),
                    onPressed: () async {
                      tripController.isLoading.value = true;
                      try {
                        await locationController.setCurrentLocation();
                        final currentLocation =
                            locationController.currentLocation.value;
                        if (currentLocation == null) {
                          tripController
                              .setError('location_permission_required'.tr);
                          return;
                        }
                        await tripController
                            .setEndWithLocation(currentLocation);
                        endFocusNode.unfocus();
                        tripController.isFocusStart(true);
                      } finally {
                        tripController.isLoading.value = false;
                      }
                    },
                  ),
                  onTap: () {
                    tripController.isFocusStart(false);
                    tripController.highlightEnd();
                  },
                  focusNode: endFocusNode,
                ),

                //search results menu
                Visibility(
                  visible: showSearchResults(),
                  child: SizedBox(
                    height: 350,
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          //title: Text(searchResults[index].address!),
                          title: CustomLocation(
                              userLocation: searchResults[index]),

                          // saves the address selected by user
                          onTap: () async {
                            if (tripController.isFocusStart.value) {
                              var startLocation = searchResults[index];
                              await locationController
                                  .getCoordinates(startLocation!);
                              await tripController
                                  .setStartWithLocation(startLocation);
                              startFocusNode.unfocus();
                              tripController.isFocusStart(false);
                            } else {
                              var endLocation = searchResults[index];
                              await locationController
                                  .getCoordinates(endLocation!);
                              await tripController
                                  .setEndWithLocation(endLocation);
                              endFocusNode.unfocus();
                            }
                            searchResults.clear();

                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),

                ///button to route to the saved locations page
                Row(
                  children: [
                    //home icon - onclick, set src:current, dst:home_location
                    CustomSavedLocation(
                      icon:
                          Icon(IconConstant.Home, color: ColorConstant.PRIMARY),
                      text: "home".tr,
                      onPressed: () async {
                        if (customerController.customer.value!.getHome() !=
                            null) {
                          await tripController.setEndWithLocation(
                              customerController.customer.value!.getHome());

                          tripController.isLoading.value = true;
                          var isSuccess = await tripController.makeNewTrip();
                          if (isSuccess) {
                            await tripController.setEstimatedRoute(
                                tripController.getStartLatLng(),
                                tripController.getEndLatLng());
                          }
                          tripController.disposeSelection();
                          tripController.isLoading.value = false;
                          Get.until((route) => Get.currentRoute == HOME);
                        } else {
                          Get.toNamed(SAVEDLOCATIONS);
                        }
                      },
                    ),

                    //work icon - onclick, set src:current, dst:work_location
                    CustomSavedLocation(
                      icon:
                          Icon(IconConstant.Work, color: ColorConstant.PRIMARY),
                      text: "company".tr,
                      onPressed: () async {
                        if (customerController.customer.value!.getWork() !=
                            null) {
                          await tripController.setEndWithLocation(
                              customerController.customer.value!.getWork());

                          tripController.isLoading.value = true;
                          var isSuccess = await tripController.makeNewTrip();
                          if (isSuccess) {
                            await tripController.setEstimatedRoute(
                                tripController.getStartLatLng(),
                                tripController.getEndLatLng());
                          }
                          tripController.disposeSelection();
                          tripController.isLoading.value = false;
                          Get.until((route) => Get.currentRoute == HOME);
                        } else {
                          Get.toNamed(SAVEDLOCATIONS);
                        }
                      },
                    ),
                    CustomSavedLocation(
                      icon:
                          Icon(IconConstant.Star, color: ColorConstant.PRIMARY),
                      text: "mylocation".tr,
                      onPressed: () => Get.toNamed(SAVEDLOCATIONS),
                    ),

                    //add an icon to add more (saved locations) - maybe not for mvp
                  ],
                ),

                const Divider(),

                //recent search history section
                Text('tripsetting_recent'.tr,
                    style: CustomTextStyle.txtBody3(height: 2)),
                Visibility(
                  visible: true,
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: customerController
                        .customer.value!.searchHistories.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(customerController
                            .customer.value!.searchHistories[index].name),
                        // saves the address selected by user
                        onTap: () async {
                          if (startFocusNode.hasFocus) {
                            await tripController.setStartWithLocation(
                                customerController
                                    .customer.value!.searchHistories[index]);
                            startFocusNode.unfocus();
                            endFocusNode.unfocus();
                          } else if (endFocusNode.hasFocus) {
                            await tripController.setEndWithLocation(
                                customerController
                                    .customer.value!.searchHistories[index]);
                            startFocusNode.unfocus();
                            endFocusNode.unfocus();
                          }
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),

                const Divider(),

                const SizedBox(height: 140),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
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
            ],
          ),
        ),
        Obx(
          () {
            if (tripController.isLoading.value) {
              return CustomLoadingDialog();
            } else {
              return const Center();
            }
          },
        )
      ],
    );
  }
}
