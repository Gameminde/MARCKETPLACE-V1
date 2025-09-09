import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to access localized strings
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static method to load localized strings
  static Future<AppLocalizations> load(Locale locale) async {
    final AppLocalizations localizations = AppLocalizations(locale);
    await localizations.loadTranslations();
    return localizations;
  }

  // Map to store localized strings
  late Map<String, String> _localizedStrings;

  // Load localized strings from JSON files
  Future<void> loadTranslations() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/l10n/${locale.languageCode}.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings =
          jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // Fallback to empty map if file not found
      _localizedStrings = {};
    }
  }

  // Get translated string
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Generated getters for all localization keys
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get home => translate('home');
  String get categories => translate('categories');
  String get cart => translate('cart');
  String get profile => translate('profile');
  String get search => translate('search');
  String get settings => translate('settings');
  String get language => translate('language');
  String get currency => translate('currency');
  String get notifications => translate('notifications');
  String get help => translate('help');
  String get about => translate('about');
  String get logout => translate('logout');
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirm_password');
  String get forgotPassword => translate('forgot_password');
  String get resetPassword => translate('reset_password');
  String get sendResetLink => translate('send_reset_link');
  String get backToLogin => translate('back_to_login');
  String get createAccount => translate('create_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get signIn => translate('sign_in');
  String get products => translate('products');
  String get productDetails => translate('product_details');
  String get description => translate('description');
  String get reviews => translate('reviews');
  String get addToCart => translate('add_to_cart');
  String get buyNow => translate('buy_now');
  String get price => translate('price');
  String get quantity => translate('quantity');
  String get total => translate('total');
  String get checkout => translate('checkout');
  String get shippingAddress => translate('shipping_address');
  String get paymentMethod => translate('payment_method');
  String get orderSummary => translate('order_summary');
  String get placeOrder => translate('place_order');
  String get orderPlaced => translate('order_placed');
  String get orderConfirmation => translate('order_confirmation');
  String get thankYou => translate('thank_you');
  String get orderNumber => translate('order_number');
  String get continueShopping => translate('continue_shopping');
  String get myOrders => translate('my_orders');
  String get orderHistory => translate('order_history');
  String get support => translate('support');
  String get contactUs => translate('contact_us');
  String get faq => translate('faq');
  String get privacyPolicy => translate('privacy_policy');
  String get termsConditions => translate('terms_conditions');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get ok => translate('ok');
  String get yes => translate('yes');
  String get no => translate('no');
  String get retry => translate('retry');
  String get tryAgain => translate('try_again');
  String get error => translate('error');
  String get success => translate('success');
  String get loading => translate('loading');
  String get noData => translate('no_data');
  String get noInternet => translate('no_internet');
  String get connectionError => translate('connection_error');
  String get somethingWentWrong => translate('something_went_wrong');
  String get tryLater => translate('try_later');
  String get featureComingSoon => translate('feature_coming_soon');
  String get algerianDinar => translate('algerian_dinar');
  String get dzd => translate('dzd');
}
