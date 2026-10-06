import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:driverapp/screens/select_location_screen.dart';
import 'package:driverapp/screens/trip_history_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'bindings/home_binding.dart';
import 'screens/home_screen.dart';
import 'screens/initial_screen.dart';
import 'screens/login_screen.dart';
import 'screens/trip_screen.dart';
import 'utils/constants.dart';
import 'utils/languages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'HaninTaxi_Key',
        channelName: 'HaninTaxi_Notification',
        channelDescription: "HaninTaxi Notifications",
        playSound: true,
        importance: NotificationImportance.High,
        //soundSource:
      ),
    ],
    debug: kDebugMode,
  );
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Hanin Driver',
      debugShowCheckedModeBanner: false,
      translations: Languages(),
      locale: Get.deviceLocale,
      fallbackLocale: KOREAN, //default language
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialBinding: HomeBinding(),
      getPages: [
        GetPage(name: INITIAL, page: () => const InitialScreen()),
        GetPage(name: LOGIN, page: () => const LoginScreen()),
        // GetPage(name: REGISTER, page: () => const RegisterScreen(), transition: Transition.rightToLeft),
        // GetPage(name: PHONE, page: () => const PhoneVerificationScreen(), transition: Transition.rightToLeft),
        GetPage(name: HOME, page: () => const HomeScreen()),
        // GetPage(name: TRIPSETTING, page: () => const TripSettingScreen(), transition: Transition.downToUp),
        // GetPage(name: PAYMENTSELECT, page: () => const PaymentSelectScreen(), transition: Transition.downToUp),
        // GetPage(name: CARDADD, page: () => const CardAddScreen(), transition: Transition.rightToLeft),
        // GetPage(name: POINTADD, page: () => const PointAddScreen(), transition: Transition.rightToLeft),
        GetPage(
            name: TRIP,
            page: () => const TripScreen(),
            transition: Transition.fadeIn),
        GetPage(
            name: TRIPHISTORY,
            page: () => const TripHistoryScreen(),
            transition: Transition.rightToLeft),
        // GetPage(name: SAVEDLOCATIONS, page: () => const SavedLocationsScreen(), transition: Transition.rightToLeft),
        GetPage(
            name: SELECTLOCATION,
            page: () => const SelectLocationScreen(),
            transition: Transition.rightToLeft),
      ],
      initialRoute: INITIAL,
    );
  }
}
