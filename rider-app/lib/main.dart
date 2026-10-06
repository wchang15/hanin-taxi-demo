import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:tax_app/bindings/home_binding.dart';
import 'package:tax_app/screens/card_add.dart';
import 'package:tax_app/screens/customer_service.dart';
import 'package:tax_app/screens/driver_cancel_screen.dart';
import 'package:tax_app/screens/find_id_pwd_screen.dart';
import 'package:tax_app/screens/initial_screen.dart';
import 'package:tax_app/screens/login_screen.dart';
import 'package:tax_app/screens/password_edit_screen.dart';
import 'package:tax_app/screens/payment_select.dart';
import 'package:tax_app/screens/phone_edit_screen.dart';
import 'package:tax_app/screens/phone_verification_screen.dart';
import 'package:tax_app/screens/point_add.dart';
import 'package:tax_app/screens/rate_driver_screen.dart';
import 'package:tax_app/screens/saved_locations_screen.dart';
import 'package:tax_app/screens/select_location_screen.dart';
import 'package:tax_app/screens/register_screen.dart';
import 'package:tax_app/screens/setting_screen.dart';
import 'package:tax_app/screens/trip_screen.dart';
import 'package:tax_app/screens/trip_setting.dart';
import 'package:tax_app/utils/constants.dart';

import 'screens/add_points_from_card.dart';
import 'screens/event_screen.dart';
import 'screens/home_screen.dart';
import 'screens/language_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/term_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/trip_history_screen.dart';
import 'utils/languages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (STRIPEPK.isNotEmpty) {
    Stripe.publishableKey = STRIPEPK;
  }
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'HaninTaxi_Key',
        channelName: 'HaninTaxi_Notification',
        channelDescription: "HaninTaxi Notifications",
      ),
    ],
    debug: kDebugMode,
  );
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Hanin Taxi',
      debugShowCheckedModeBanner: false,
      translations: Languages(),
      locale: Get.deviceLocale,
      fallbackLocale: ENGLISH, //de
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialBinding: HomeBinding(),
      getPages: [
        GetPage(name: INITIAL, page: () => const InitialScreen()),
        GetPage(name: LOGIN, page: () => const LoginScreen()),
        GetPage(
            name: REGISTER,
            page: () => const RegisterScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: PHONE,
            page: () => const PhoneVerificationScreen(),
            transition: Transition.rightToLeft),
        GetPage(name: HOME, page: () => const HomeScreen()),
        GetPage(
            name: TRIPSETTING,
            page: () => const TripSettingScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: PAYMENTSELECT,
            page: () => const PaymentSelectScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: CARDADD,
            page: () => const CardAddScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: POINTADD,
            page: () => const PointAddScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: TRIP,
            page: () => const TripScreen(),
            transition: Transition.fadeIn),
        GetPage(
            name: SAVEDLOCATIONS,
            page: () => const SavedLocationsScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: SELECTLOCATION,
            page: () => const SelectLocationScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: RATEDRIVER,
            page: () => const RateDriverScreen(),
            transition: Transition.fadeIn),
        GetPage(
            name: ADDPOINTSFROMCARD,
            page: () => const AddPointsFromCard(),
            transition: Transition.rightToLeft),
        GetPage(
            name: DRIVERCANCEL,
            page: () => const DriverCancelScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: LANGUAGE,
            page: () => const LanguageScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: TERMS,
            page: () => const TermsScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: TERM,
            page: () => const TermScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: FINDIDPWD,
            page: () => const FindIDPWDScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: EVENT,
            page: () => const EventScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: CUSTOMERSERVICE,
            page: () => const CustomerServiceScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: TRIPHISTORY,
            page: () => const TripHistoryScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: PROFILE,
            page: () => const ProfileScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: PHONEEDIT,
            page: () => const PhoneEditScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: PASSWORDEDIT,
            page: () => const PasswordEditScreen(),
            transition: Transition.rightToLeft),
        GetPage(
            name: SETTING,
            page: () => const SettingScreen(),
            transition: Transition.rightToLeft),
      ],
      initialRoute: INITIAL,
    );
  }
}
