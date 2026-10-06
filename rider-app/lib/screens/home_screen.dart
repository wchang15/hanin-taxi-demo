//general imports
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

//google maps/geo service imports

//local utility imports
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/utils/icon_constants.dart';
import 'package:tax_app/utils/image_constants.dart';
import 'package:tax_app/utils/route_camera.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

//component imports
import '../services/email_service.dart';
import '../services/hub_service.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_cancel_dialog.dart';
import '../widgets/custom_driver_card.dart';
import '../widgets/custom_svg_container.dart';
import '../widgets/custom_text_button.dart';
import '../widgets/custom_text_form_field.dart';
import '../widgets/custom_saved_location.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';
import '../widgets/custom_tap.dart';

//metadata imports
import '../utils/constants.dart';

//style imports
import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../utils/validate_text.dart';

/// Home screen class
/// Home Screen is with Map (FindFare, matching, waiting Stage)
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

/// Home screen components/widgets
class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  /// class controlling a customer's metadata
  final customerController = Get.find<CustomerController>();

  /// class for accessing location functions
  final locationController = Get.find<LocationController>();

  /// class for managing trip details (src,dst)
  final tripController = Get.find<TripController>();

  /// Maintains state of nav bar
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool drawerOpen = false;

  MapController mapController = MapController();
  AnimationController? _mapAnimation;
  final mapReady = false.obs;
  late final Worker locationWorker;
  late final Worker routeWorker;
  late final Worker pickupWorker;
  late final Worker destinationWorker;

  var menuItemsOne = [
    ['menu_event'.tr, EVENT],
    ['menu_profile'.tr, PROFILE],
    ['menu_history'.tr, TRIPHISTORY],
    ['menu_payment'.tr, PAYMENTSELECT]
  ];

  var menuItemsTwo = [
    ['menu_customerservice'.tr, CUSTOMERSERVICE],
    ['menu_setting'.tr, SETTING]
  ];

  /// Sets the initial state of this widget
  @override
  void initState() {
    super.initState();
    locationWorker = ever(locationController.currentLocation, (_) {
      if (mapReady.value &&
          locationController.currentLocation.value != null &&
          !tripController.isTripSet()) {
        _jumpMapTo(
          locationController.getCurrentLocation(),
          MAP_LOCATION_ZOOM,
        );
      }
    });
    routeWorker = ever(tripController.estimatedRoute, (route) {
      _stopMapAnimation();
      // Fit after the fare panel has changed the available map height.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !mapReady.value) return;
        final currentRoute = tripController.estimatedRoute.value;
        if (tripController.isTripSet() &&
            currentRoute != null && currentRoute.length >= 2) {
          animationCenterRoute(currentRoute);
        } else {
          _centerMapOnPickupIfIdle();
        }
      });
    });
    pickupWorker = ever(tripController.startLocation, (_) {
      _centerMapOnPickupIfIdle();
    });
    destinationWorker = ever(tripController.endLocation, (_) {
      _centerMapOnPickupIfIdle();
    });
    if (customerController.customer.value != null) {
      final defaultCardID =
          customerController.customer.value!.defaultCardID ?? 0;
      if (defaultCardID != 0) {
        tripController.selectCustomerCard(defaultCardID);
      } else {
        tripController.setCustomerCardID(0);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _setInitialPickup();
      await tripController.setCurrentTrip();
      tripController.openCurrentTripScreenIfNeeded();
    });
    HubService.initSignalR();
  }

  @override
  void dispose() {
    locationWorker.dispose();
    routeWorker.dispose();
    pickupWorker.dispose();
    destinationWorker.dispose();
    _stopMapAnimation();
    mapController.dispose();
    super.dispose();
  }

  void _centerMapOnPickupIfIdle() {
    final pickup = tripController.startLocation.value;
    if (!mapReady.value ||
        pickup == null ||
        tripController.endLocation.value != null ||
        tripController.tripStatus.value != EnumTripStatus.CUSTOMERSEARCHING) {
      return;
    }

    _jumpMapTo(
      LatLng(pickup.latitude, pickup.longitude),
      MAP_LOCATION_ZOOM,
    );
  }

  Future<void> _setInitialPickup() async {
    if (locationController.currentLocation.value == null ||
        locationController.locationStatus.value ==
            EnumLocationControllerStatus.Error) {
      await locationController.setCurrentLocation();
    }
    final currentLocation = locationController.currentLocation.value;
    if (currentLocation != null &&
        tripController.startLocation.value == null &&
        tripController.tripID.value == 0) {
      await tripController.setStartWithLocation(currentLocation);
    }
  }

  /// Event to close the side drawer
  void closeDrawer() => scaffoldKey.currentState!.openEndDrawer();

  /// Event to open the side drawer
  void openDrawer() => scaffoldKey.currentState!.openDrawer();

  void floatingActionButtonClick() =>
      tripController.isTripSet() ? removeTrip() : openDrawer();

  void removeTrip() => tripController.removeTrip();

  late final startMarkerDesign = Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
        color: ColorConstant.PRIMARY,
        borderRadius: const BorderRadius.all(Radius.circular(8))),
    child: Text('map_pickup'.tr,
        style: CustomTextStyle.txtCaption2(color: ColorConstant.WHITE)),
  );
  late final arrivalMarkerDesign = Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
        color: ColorConstant.BLACK1,
        borderRadius: const BorderRadius.all(Radius.circular(8))),
    child: Text('map_dropoff'.tr,
        style: CustomTextStyle.txtCaption2(color: ColorConstant.WHITE)),
  );
  var circleMarker = Container(
      child: SvgPicture.asset(ImageConstant.imgLocation, fit: BoxFit.fill));

  List<Marker> getFlutterMarkers() {
    var markers = <Marker>[];
    final startLocation = tripController.startLocation.value;
    if (startLocation == null) return markers;

    final startPoint = LatLng(startLocation.latitude, startLocation.longitude);

    var startMarker =
        Marker(width: 100, height: 100, point: startPoint, child: circleMarker);

    if (tripController.tripStatus.value == EnumTripStatus.CUSTOMERSEARCHING) {
      if (tripController.endLocation.value != null) {
        markers.add(Marker(
            width: 64,
            height: 32,
            point: startPoint,
            child: startMarkerDesign));
        markers.add(Marker(
            width: 64,
            height: 32,
            point: tripController.getEndLatLng(),
            child: arrivalMarkerDesign));
      }
      if (markers.isEmpty) markers.add(startMarker);
    }

    if (tripController.tripStatus.value == EnumTripStatus.MATCHING) {
      final endLocation = tripController.endLocation.value;
      if (endLocation == null) {
        markers.add(startMarker);
      } else {
        markers.add(Marker(
            width: 64,
            height: 32,
            point: startPoint,
            child: startMarkerDesign));
        markers.add(Marker(
            width: 64,
            height: 32,
            point: LatLng(endLocation.latitude, endLocation.longitude),
            child: arrivalMarkerDesign));
      }
    }

    if (tripController.tripStatus.value == EnumTripStatus.PICKINGUPCUSTOMER) {
      markers.add(Marker(
        width: 45,
        height: 32,
        point: startPoint,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: ColorConstant.PRIMARY,
              borderRadius: const BorderRadius.all(Radius.circular(12))),
          child: Text('map_you'.tr,
              style: CustomTextStyle.txtCaption2(color: ColorConstant.WHITE)),
        ),
      ));
      if (tripController.driverLocation.value != null) {
        markers.add(Marker(
          width: 45,
          height: 32,
          point: tripController.driverLocation.value!,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: ColorConstant.PRIMARY,
                borderRadius: const BorderRadius.all(Radius.circular(12))),
            child: Text('map_driver'.tr,
                style: CustomTextStyle.txtCaption2(color: ColorConstant.WHITE)),
          ),
        ));
      }
    }

    return markers;
  }

  List<Polyline> getPolylines() {
    var polylines = <Polyline>[];
    final route = tripController.estimatedRoute.value;
    if (route != null && route.length >= 2) {
      polylines.add(
        Polyline(
          points: route,
          strokeWidth: 6,
          color: ColorConstant.PRIMARY,
          borderStrokeWidth: 2,
          borderColor: ColorConstant.WHITE,
        ),
      );
    }

    return polylines;
  }

  void _stopMapAnimation() {
    _mapAnimation?.dispose();
    _mapAnimation = null;
  }

  void _jumpMapTo(LatLng center, double zoom) {
    _stopMapAnimation();
    mapController.move(center, zoom);
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _stopMapAnimation();
    final latTween = Tween<double>(
        begin: mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _mapAnimation = controller;
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          identical(_mapAnimation, controller)) {
        _stopMapAnimation();
      }
    });

    controller.forward();
  }

  void animationCenterPosition(LatLng ll) {
    _animatedMapMove(ll, MAP_LOCATION_ZOOM);
  }

  void animationCenterRoute(List<LatLng> points) {
    final fittedCamera = fitRouteCamera(
      mapController.camera,
      points,
      topInset: MediaQuery.paddingOf(context).top,
    );
    _animatedMapMove(fittedCamera.center, fittedCamera.zoom);
  }

  /// Builds the home page widget on the given build [context]
  @override
  Widget build(BuildContext context) {
    var findFareColumn = Column(
      children: [
        Obx(
          () => tripController.isTripSupported()
              ? Column(
                  children: [
                    CustomSVGContainer(
                      svg: tripController.cars[0],
                      text: 'home_small_car'.tr,
                      amount: tripController.smallTaxiFee.value,
                      fillColor: tripController.enumTaxiSize.value == 1
                          ? ColorConstant.YELLOW
                          : null,
                      borderColor: tripController.enumTaxiSize.value == 1
                          ? ColorConstant.PRIMARY
                          : null,
                      onTap: () => tripController.enumTaxiSize.value = 1,
                    ),
                    const SizedBox(height: 10),
                    CustomSVGContainer(
                      svg: tripController.cars[1],
                      text: 'home_large_car'.tr,
                      amount: tripController.largeTaxiFee.value,
                      fillColor: tripController.enumTaxiSize.value == 2
                          ? ColorConstant.YELLOW
                          : null,
                      borderColor: tripController.enumTaxiSize.value == 2
                          ? ColorConstant.PRIMARY
                          : null,
                      onTap: () => tripController.enumTaxiSize.value = 2,
                    ),
                  ],
                )
              : Container(
                  width: double.infinity,
                  padding: getPadding(left: 24, top: 14, right: 24, bottom: 14),
                  decoration: BoxDecoration(
                    color: ColorConstant.WHITE1,
                    border: Border.all(color: ColorConstant.RED),
                    borderRadius: BorderRadius.circular(
                      getHorizontalSize(24.00),
                    ),
                  ),
                  child: Text(
                    "location_support".tr,
                    style: CustomTextStyle.txtBody1(
                        color: ColorConstant.BLACK1,
                        height: 1.7,
                        weight: FontWeight.w400),
                  )),
        ),
        const Divider(),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: CustomTextButton(
                  onPressed: () => Get.toNamed(PAYMENTSELECT),
                  child: Row(
                    children: [
                      Icon(IconConstant.CreditCard,
                          color: ColorConstant.BLACK1),
                      const SizedBox(width: 10),
                      Text('home_payment'.tr,
                          style: CustomTextStyle.txtBody1()),
                      const SizedBox(width: 5),
                      Icon(IconConstant.ArrowForward,
                          size: 16, color: ColorConstant.BLACK1)
                    ],
                  ),
                ),
              ),
              Padding(
                padding: getPadding(right: 12),
                child: Obx(
                  () => Text(tripController.getPaymentMethodText(),
                      style: CustomTextStyle.txtBody1(
                          color: ColorConstant.BLACK3)),
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => CustomTap(
            color: tripController.isTripSupported()
                ? customerController.getIsDefaultCardExist() || DEMO_MODE
                    ? ColorConstant.PRIMARY
                    : ColorConstant.GREY2
                : ColorConstant.GREY2,
            onTap: () async => tripController.isTripSupported()
                ? customerController.getIsDefaultCardExist() || DEMO_MODE
                    ? await tripController.confirmTrip()
                    : null
                : null,
            child: Text("home_find_button".tr,
                style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
          ),
        ),
      ],
    );
    var settingColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("home_where_are_you_going".tr, style: CustomTextStyle.txtTitle1()),
        const SizedBox(height: 20),

        Obx(
          () => CustomAlert(
            bgColor: ColorConstant.RED1,
            color: ColorConstant.RED,
            icon: IconConstant.Location,
            text: 'location_permission_required'.tr,
            visible: locationController.locationStatus.value ==
                EnumLocationControllerStatus.Error,
          ),
        ),

        // from location input
        Obx(
          () => CustomTextFormField(
            controller: tripController.startLocationController.value,
            text: 'home_set_start'.tr,
            validate: validateText,
            onChanged: (text) => tripController.setError(""),
            readOnly: true,
            onTap: () {
              tripController.setFocusStart();
              Get.toNamed(TRIPSETTING);
            },
            suffixIcon: IconButton(
              icon: Icon(IconConstant.MyLocation),
              onPressed: () async {
                tripController.isLoading.value = true;
                await locationController.setCurrentLocation();
                final currentLocation =
                    locationController.currentLocation.value;
                if (currentLocation != null) {
                  await tripController.setStartWithLocation(currentLocation);
                }
                // startFocusNode.unfocus();
                tripController.isLoading.value = false;
              },
            ),
          ),
        ),

        //padding
        const SizedBox(height: 10),

        //destination input
        Obx(
          () => CustomTextFormField(
            controller: tripController.endLocationController.value,
            text: 'home_set_end'.tr,
            validate: validatePassword,
            onChanged: (text) => setState(
              () => tripController.setError(""),
            ),
            readOnly: true,
            onTap: () {
              tripController.setFocusEnd();
              Get.toNamed(TRIPSETTING);
            },
            suffixIcon: IconButton(
              icon: Icon(IconConstant.MyLocation),
              onPressed: () async {
                tripController.isLoading.value = true;
                await locationController.setCurrentLocation();
                final currentLocation =
                    locationController.currentLocation.value;
                if (currentLocation == null) {
                  tripController.isLoading.value = false;
                  return;
                }
                await tripController.setEndWithLocation(currentLocation);
                // startFocusNode.unfocus();
                var isSuccess = await tripController.makeNewTrip();
                if (isSuccess) {
                  await tripController.setEstimatedRoute(
                      tripController.getStartLatLng(),
                      tripController.getEndLatLng());
                }
                tripController.disposeSelection();
                tripController.isLoading.value = false;
              },
            ),
          ),
        ),

        //saved location icons
        Row(
          children: [
            //home icon - onclick, set src:current, dst:home_location
            CustomSavedLocation(
              icon: Icon(IconConstant.Home, color: ColorConstant.PRIMARY),
              text: "home".tr,
              onPressed: () async {
                if (customerController.customer.value!.getHome() != null) {
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
                } else {
                  Get.toNamed(SAVEDLOCATIONS);
                }
              },
            ),

            //work icon - onclick, set src:current, dst:work_location
            CustomSavedLocation(
              icon: Icon(IconConstant.Work, color: ColorConstant.PRIMARY),
              text: "company".tr,
              onPressed: () async {
                if (customerController.customer.value!.getWork() != null) {
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
                } else {
                  Get.toNamed(SAVEDLOCATIONS);
                }
              },
            ),
            CustomSavedLocation(
              icon: Icon(IconConstant.Star, color: ColorConstant.PRIMARY),
              text: "mylocation".tr,
              onPressed: () => Get.toNamed(SAVEDLOCATIONS),
            ),

            //add an icon to add more (saved locations) - maybe not for mvp
          ],
        ),
      ],
    );
    var matchingColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Obx(
              () => Padding(
                padding: getPadding(),
                child: SvgPicture.asset(
                  tripController.cars[tripController.enumTaxiSize.value - 1],
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Obx(
            //   () => Text('home_estimated_time'.tr + tripController.getDurationString(),
            //       style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3)),
            // ),
          ],
        ),
        const SizedBox(height: 10),
        Text('home_finding_driver'.tr, style: CustomTextStyle.txtTitle1()),
        const SizedBox(height: 5),
        SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: ColorConstant.WHITE,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorConstant.PRIMARY,
                          width: 2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: ColorConstant.PRIMARY,
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: ColorConstant.PRIMARY,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tripController.startLocation.value?.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CustomTextStyle.txtBody1(),
                      ),
                      Text(
                        tripController.endLocation.value?.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CustomTextStyle.txtBody1(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('home_payment'.tr,
                    style: CustomTextStyle.txtCaption2(
                        color: ColorConstant.BLACK1)),
                const SizedBox(
                  height: 20,
                  child: VerticalDivider(thickness: 1),
                ),
                Obx(
                  () => SizedBox(
                    width: 150,
                    child: Text(
                      tripController.getPaymentMethodText(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: CustomTextStyle.txtCaption2(
                          color: ColorConstant.BLACK1),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: getPadding(all: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('home_payment_amount'.tr,
                      style: CustomTextStyle.txtCaption2(
                          color: ColorConstant.BLACK3)),
                  const SizedBox(
                    height: 20,
                    child: VerticalDivider(thickness: 1),
                  ),
                  Obx(
                    () => Text(
                      tripController.enumTaxiSize.value == 1
                          ? tripController.smallTaxiFee.value
                          : tripController.largeTaxiFee.value,
                      style: CustomTextStyle.txtTitle2(
                          color: ColorConstant.BLACK1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    var waitingColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('home_driver_coming'.tr,
            style: CustomTextStyle.txtTitle1(color: ColorConstant.BLACK1)),
        Obx(
          () => tripController.driver.value != null
              ? CustomDriverCard(
                  licensePlate: tripController.driver.value!.licensePlate,
                  carAndColor:
                      '${tripController.driver.value!.carModel} ${tripController.driver.value!.carColor}',
                  companyName: tripController.driver.value!.companyName,
                  driverName: tripController.driver.value!.driverName,
                  phoneNumber: tripController.driver.value!.phoneNumber,
                  photo: 'photo',
                  isFull: false,
                )
              : const Center(),
        ),
        Obx(
          () => CustomAlert(
            bgColor: ColorConstant.YELLOW,
            color: ColorConstant.PRIMARY,
            icon: IconConstant.Clock,
            text:
                '${'home_minutes_approximate'.tr} ${tripController.getDurationString()} ${'home_minutes_left'.tr}',
            visible: true,
          ),
        ),
      ],
    );

    return Stack(
      children: [
        Scaffold(
          key: scaffoldKey,
          backgroundColor: ColorConstant.WHITE,

          // hidden drawer component; hidden until hamburger button clicked
          drawer: Drawer(
            child: ListView(
              children: [
                SizedBox(
                  height: 100,
                  child: DrawerHeader(
                    margin: null,
                    //padding: getPadding(all: 0),
                    //decoration: BoxDecoration(color: Colors.blue),
                    child: Obx(
                      () => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customerController.customer.value!.fullname!,
                              style: CustomTextStyle.txtTitle1(
                                  color: ColorConstant.BLACK1)),
                          const SizedBox(height: 10),
                          Text(customerController.customer.value!.phoneNumber!,
                              style: CustomTextStyle.txtBody1(
                                  color: ColorConstant.BLACK3)),
                        ],
                      ),
                    ),
                  ),
                ),
                for (var item in menuItemsOne)
                  ListTile(
                    title: Text(item[0],
                        style: CustomTextStyle.txtBody3(
                            color: ColorConstant.BLACK1)),
                    onTap: () {
                      closeDrawer();
                      Get.toNamed(item[1]);
                    },
                  ),
                const Divider(),
                for (var item in menuItemsTwo)
                  ListTile(
                    title: Text(item[0],
                        style: CustomTextStyle.txtBody3(
                            color: ColorConstant.BLACK3)),
                    onTap: () {
                      closeDrawer();
                      Get.toNamed(item[1]);
                    },
                  ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
          floatingActionButton: Obx(
            () => tripController.tripStatus.value != EnumTripStatus.GOINGTODEST
                ? FloatingActionButton(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    onPressed: () {},
                    child: Container(
                      decoration: BoxDecoration(
                          color: ColorConstant.WHITE,
                          borderRadius: BorderRadius.circular(25)),
                      child: IconButton(
                        icon: Obx(
                          () => Icon(
                            tripController.isTripSet()
                                ? IconConstant.ArrowBack
                                : IconConstant.Menu,
                            color: ColorConstant.BLACK,
                          ),
                        ),
                        onPressed: floatingActionButtonClick,
                      ),
                    ),
                  )
                : const Center(),
          ),

          // main container; map and input menu
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Map
              Expanded(
                flex: 1,
                child: Obx(
                  () => Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter:
                              locationController.getCurrentLocation(),
                          initialZoom: MAP_LOCATION_ZOOM,
                          onMapReady: () {
                            mapReady(true);
                            final route = tripController.estimatedRoute.value;
                            if (route != null && route.length >= 2) {
                              animationCenterRoute(route);
                            } else if (locationController
                                    .currentLocation.value !=
                                null) {
                              _jumpMapTo(
                                locationController.getCurrentLocation(),
                                MAP_LOCATION_ZOOM,
                              );
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: MAP_TILE_URL_TEMPLATE,
                            userAgentPackageName:
                                'com.woochangchang.hanintaxi.rider',
                          ),
                          PolylineLayer(polylines: getPolylines()),
                          MarkerLayer(markers: getFlutterMarkers()),
                        ],
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Material(
                          color: ColorConstant.WHITE.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              launchUrl(
                                Uri.parse(
                                    'https://www.openstreetmap.org/copyright'),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 3),
                              child: Text(
                                '© OpenStreetMap',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (locationController.locationStatus.value ==
                          EnumLocationControllerStatus.Loading)
                        const Positioned(
                          top: 12,
                          right: 12,
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              //input menu
              IntrinsicHeight(
                child: Container(
                  width: SIZE.width,
                  padding: getPadding(left: 16, top: 24, right: 16, bottom: 32),
                  decoration: BoxDecoration(
                    color: ColorConstant.WHITE,
                    borderRadius: const BorderRadiusDirectional.vertical(
                        top: Radius.circular(25.0)),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstant.BLACK1.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: Obx(
                    () => tripController.isTripSet()
                        ? tripController.tripStatus.value ==
                                EnumTripStatus.CUSTOMERSEARCHING
                            ? findFareColumn
                            : tripController.tripStatus.value ==
                                    EnumTripStatus.MATCHING
                                ? matchingColumn
                                : tripController.tripStatus.value ==
                                        EnumTripStatus.PICKINGUPCUSTOMER
                                    ? waitingColumn
                                    : const Center()
                        : settingColumn,
                  ),
                ),
              )
            ],
          ),
        ),

        Obx(
          () => tripController.tripStatus.value ==
                  EnumTripStatus.PICKINGUPCUSTOMER
              ? Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: getPadding(top: 24, right: 12),
                    child: Container(
                      decoration: BoxDecoration(
                          color: ColorConstant.WHITE1,
                          borderRadius: BorderRadius.circular(25)),
                      child: TextButton.icon(
                        onPressed: () {
                          customCancelDialog(
                            okayClick: () async {
                              EmailService.sendEmailToHanin(
                                  message:
                                      tripController.complaintController.text,
                                  screen: "Refund",
                                  tripID: tripController.tripID.value);
                              Get.back();
                            }, //Send to API
                            title: 'trip_refund'.tr,
                            contentText: 'trip_refund_body'.tr,
                            cancelText: 'trip_report_close'.tr,
                            okayText: 'trip_report'.tr,
                            isContent: true,
                            hintText: 'trip_refund_hint'.tr,
                            controller: tripController.complaintController,
                          );
                        },
                        icon: Icon(IconConstant.CarReport,
                            color: ColorConstant.BLACK3),
                        label: Text("trip_refund".tr,
                            style: CustomTextStyle.txtCaption2(
                                color: ColorConstant.BLACK3)),
                      ),
                    ),
                  ),
                )
              : const Center(),
        ),

        // Loading dialog
        Obx(
          () {
            if (tripController.isLoading.value) {
              return CustomLoadingDialog();
            } else {
              return const Center();
            }
          },
        ),
      ],
    );
  }
}
