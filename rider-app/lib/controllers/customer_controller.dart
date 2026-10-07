import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:tax_app/models/register_request.dart';
import 'package:tax_app/services/customer_service.dart';
import 'package:tax_app/models/user_location.dart';

import '../models/customer.dart';
import '../models/user_login.dart';
import '../services/login_service.dart';
import '../services/hub_service.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';
import '../utils/terms.dart';

class CustomerController extends GetxController {
  final isLoading = false.obs;
  final customer = (null as Customer?).obs;
  final errorResponse = "".obs;
  final isRefreshSuccess = (null as bool?).obs;
  final language = 1.obs;
  final termsCheck = [false, false].obs;
  final terms = [
    ['terms_use'.tr, TERMSOFUSE],
    ['terms_marketing'.tr, '']
  ];

  ////////// Getters //////////
  String? getFullName() => customer.value?.fullname ?? "";

  bool getIsDefaultCardExist() =>
      customer.value?.defaultCardID != null &&
      customer.value?.defaultCardID != 0;

  bool checkedRequiredTerms() => termsCheck[0] == true;

  ////////// Setters //////////
  void setError(String err) => errorResponse(err);

  ////////// API Calls //////////
  Future<void> register(RegisterRequest register) async {
    isLoading(true);

    try {
      final response = await LoginServices.postRegister(register);
      customer(response.customer);
      errorResponse(response.response);
      await updateLanguage(response.customer);
    } catch (e) {
    } finally {
      isLoading(false);
    }
  }

  Future<void> editPhone(String number, {bool isVerified = false}) async {
    isLoading(true);

    try {
      final response = await LoginServices.putPhoneUpdate(number, isVerified);
      if (response.item1 != null) {
        if (!isVerified) {
          customer.update((val) {
            val!.phoneNumber = number;
          });
        }
        setError("");
      } else {
        errorResponse(response.item2);
      }
    } catch (e) {
    } finally {
      isLoading(false);
    }
  }

  Future<void> verifyPhone(String otp,
      {bool isVerified = false, String phoneNumber = ""}) async {
    isLoading(true);

    try {
      final response = await LoginServices.putPhoneVerification(
          otp, isVerified, phoneNumber);
      if (response.item1 != null) {
        customer.update((val) {
          if (phoneNumber != "") val!.phoneNumber = phoneNumber;
          val!.isVerified = true;
        });
        setError("");
      } else {
        errorResponse(response.item2);
      }
    } catch (e) {
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateCustomer(
      String firstName, String lastName, String email) async {
    bool ret = false;
    try {
      ret = await CustomerServices.updateCustomer(firstName, lastName, email);
      if (ret) {
        customer.update((val) {
          val!.firstName = firstName;
          val.lastName = lastName;
          val.email = email;
          val.fullname = "$firstName $lastName";
        });
      }
    } catch (e) {
      ret = false;
    }
    return ret;
  }

  Future<void> login(UserLogin userLogin) async {
    isLoading(true);

    try {
      final response = await LoginServices.postLoginCustomer(userLogin);
      customer(response.customer);
      errorResponse(response.response);
      await updateLanguage(response.customer);
    } catch (e) {
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshToken() async {
    isLoading(true);

    try {
      final response = await LoginServices.postRefreshToken();
      customer(response.customer);
      errorResponse(response.response);
      isRefreshSuccess(response.customer != null);
      await updateLanguage(response.customer);
    } catch (e) {
    } finally {
      isLoading(false);
    }
  }

  Future<void> logout() async {
    isLoading(true);

    try {
      await LoginServices.postLogout();
    } catch (e) {
    } finally {
      customer.value = null;
      try {
        await Future.wait([
          StorageService.deleteAllSecureData(),
          HubService.stop(),
        ]);
      } finally {
        refresh();
        isLoading(false);
      }
    }
  }

  Future<bool> saveCustomerCard(
      PaymentMethod paymentMethod, bool isdefault) async {
    var ret = false;
    isLoading(true);
    var cardsWithError =
        await CustomerServices.saveCustomerCard(paymentMethod, isdefault);
    if (cardsWithError.item1 == null) {
      setError(cardsWithError.item2 ?? "Saving Customer Card Error");
    } else {
      customer.update((val) {
        val!.savedCards = cardsWithError.item1!;
      });
      var defaultcard =
          cardsWithError.item1!.where((element) => element.isDefault!).first;
      customer.update((val) => val!.defaultCardID = defaultcard.customerCardID);
      ret = true;
    }
    isLoading(false);
    return ret;
  }

  Future<bool> updateDefaultCard(int customerCardID) async {
    var ret = false;
    isLoading(true);
    var cardsWithError =
        await CustomerServices.updateDefaultCard(customerCardID);
    if (cardsWithError.item1 == null) {
      setError(cardsWithError.item2 ?? "Updating Customer Card Error");
    } else {
      customer.update((val) {
        val!.savedCards = cardsWithError.item1!;
      });
      var defaultcard =
          cardsWithError.item1!.where((element) => element.isDefault!).first;
      customer.update((val) => val!.defaultCardID = defaultcard.customerCardID);
      ret = true;
    }
    isLoading(false);
    return ret;
  }

  Future<bool> deleteCard(int customerCardID) async {
    var ret = false;
    isLoading(true);
    var cardsWithError = await CustomerServices.deleteCard(customerCardID);
    if (cardsWithError.item1 == null) {
      setError(cardsWithError.item2 ?? "Deleting Customer Card Error");
    } else {
      customer.update((val) {
        val!.savedCards = cardsWithError.item1!;
      });
      var defaultcard =
          cardsWithError.item1!.where((element) => element.isDefault!).first;
      customer.update((val) => val!.defaultCardID = defaultcard.customerCardID);
      ret = true;
    }
    isLoading(false);
    return ret;
  }

  Future updateLanguage(Customer? customer) async {
    if (customer != null) {
      await Get.updateLocale(LANGUAGEMAP[customer.language]);
    }
  }

  Future updateLanguageWithLanguage() async {
    await Get.updateLocale(LANGUAGEMAP[language.value]);
  }

  void getInitialLocale() {
    var locale = Get.locale == KOREAN
        ? 2
        : Get.locale == ENGLISH
            ? 1
            : Get.locale == SPANISH
                ? 3
                : 1;
    language(locale);
  }
}
