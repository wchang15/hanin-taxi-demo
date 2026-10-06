//general imports
import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';

//google maps/geo service imports

//local utility imports
import 'package:tax_app/services/customer_service.dart';
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/utils/icon_constants.dart';

//component imports
import '../models/user_location.dart';
import '../utils/constants.dart';
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
  /// class controlling a customer's metadata
  final customerController = Get.find<CustomerController>();

  /// class for accessing location functions
  final locationController = Get.find<LocationController>();

  /// class for managing trip details (src,dst)
  final tripController = Get.find<TripController>();

  /// Maintains state of nav bar
  final scaffoldKey = GlobalKey<ScaffoldState>();

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
    //UserLocation loc = Get.arguments[1];
    if (Get.arguments.length > 1 && Get.arguments[1] != null) {
      selectedLocation = Get.arguments[1];
      userInput.text = Get.arguments[1].address;
      userInput.selection = TextSelection(baseOffset: 0, extentOffset: userInput.text.length);
      hasSelected = true;
      isChanged = false;
      editGoogleLocationID = Get.arguments[1].googleLocationID;
    }
    super.initState();
  }

  /// Saved a searched location to their set of saved locations
  Future<void> saveLocation() async {
    final userLocation = selectedLocation!;

    // save based on type of location specified
    if (Get.arguments[0] == "HOME") {
      userLocation.type = 1;
      if (editGoogleLocationID != null) {
        await CustomerServices.replaceCustomerSavedLocation(editGoogleLocationID!, userLocation);
      } else {
        await CustomerServices.addCustomerSavedLocation(userLocation);
      }
    } else if (Get.arguments[0] == "WORK") {
      userLocation.type = 2;
      if (Get.arguments[1] != null) {
        await CustomerServices.replaceCustomerSavedLocation(editGoogleLocationID!, userLocation);
      } else {
        await CustomerServices.addCustomerSavedLocation(userLocation);
      }
    } else {
      userLocation.type = 3;
      await CustomerServices.addCustomerSavedLocation(userLocation);
    }
    Get.back();
  }

  /// Builds the add favorites page on the given build [context]
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: true,
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
              CustomTap(
                color: (hasSelected ? ColorConstant.PRIMARY : ColorConstant.GREY3),
                onTap: () async {
                  if (hasSelected) {
                    await saveLocation();
                  }
                },
                child: Text("mylocation_add_button".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
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
                  text: 'mylocation_hint'.tr,
                  validate: validatePassword,
                  onChanged: (text) async {
                    EasyDebounce.debounce('mylocationdebounce', const Duration(milliseconds: DEBOUNCE), () async {
                      hasSelected = false; // set flag signifying address changed
                      searchResults = await locationController.autoCompleteSearch(text);
                      setState(() {});
                    });
                  },
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 1),

                //search results menu
                Container(
                  height: SIZE.height / 2,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: false,
                    itemCount: searchResults.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: CustomLocation(userLocation: searchResults[index]),
                        // sets user input to the selected address
                        onTap: () async {
                          isChanged = true;
                          hasSelected = true; // set flag signifying actual address selected
                          selectedLocation = searchResults[index];
                          await locationController.getCoordinates(selectedLocation!);
                          userInput.text = searchResults[index].name;
                          searchResults.clear();
                          setState(() {});
                        },
                      );
                    },
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
