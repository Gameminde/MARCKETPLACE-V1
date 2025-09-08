import 'package:flutter/material.dart';

/// Constantes de l'application pour éviter les valeurs hardcodées
class AppConstants {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color secondaryColor = Color(0xFF74B9FF);
  static const Color accentColor = Color(0xFF00CEC9);
  static const Color warningColor = Color(0xFFFDCB6E);
  static const Color dangerColor = Color(0xFFE17055);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  
  // Dimensions
  static const double defaultPadding = 20.0;
  static const double smallPadding = 10.0;
  static const double largePadding = 30.0;
  static const double categoryHeight = 120.0;
  static const double productCardAspectRatio = 0.75;
  static const double borderRadius = 15.0;
  static const double largeBorderRadius = 20.0;
  static const double buttonBorderRadius = 25.0;
  
  // Tailles de police
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 20.0;
  static const double bodyFontSize = 16.0;
  static const double smallFontSize = 12.0;
  static const double largeFontSize = 32.0;
  
  // Icônes
  static const double iconSize = 24.0;
  static const double smallIconSize = 18.0;
  static const double largeIconSize = 40.0;
  
  // Animations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  // Shadows
  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 5),
    ),
  ];
}

/// Strings de l'application
class AppStrings {
  // Navigation
  static const String home = 'Home';
  static const String search = 'Search';
  static const String cart = 'Cart';
  static const String profile = 'Profile';
  
  // Home Screen
  static const String searchHint = 'Search products...';
  static const String forYou = 'For You';
  static const String trendingProducts = 'Trending Products';
  static const String recentlyViewed = 'Recently Viewed';
  
  // Categories
  static const String fashion = 'Fashion';
  static const String electronics = 'Electronics';
  static const String computers = 'Computers';
  static const String beauty = 'Beauty';
  static const String sports = 'Sports';
  
  // Cart
  static const String cartEmpty = 'Your cart is empty.';
  static const String startShopping = 'Start Shopping';
  static const String saveForLater = 'Save for Later';
  static const String proceedToCheckout = 'Proceed to Checkout';
  static const String continueShopping = 'Continue Shopping';
  
  // Product Detail
  static const String addToCart = 'Add to Cart';
  static const String added = 'Added!';
  static const String tryWithAR = 'Try with AR';
  static const String productDescription = 'Product Description';
  static const String readMore = 'Read More';
  static const String customerReviews = 'Customer Reviews';
  static const String youMayAlsoLike = 'You may also like';
  static const String reviews = 'reviews';
  
  // Checkout
  static const String checkout = 'Checkout';
  static const String shipping = 'Shipping';
  static const String payment = 'Payment';
  static const String review = 'Review';
  static const String complete = 'Complete';
  static const String shippingAddress = 'Shipping Address';
  static const String paymentMethod = 'Payment Method';
  static const String orderSummary = 'Order Summary';
  static const String placeOrder = 'Place Order';
  static const String continueToPayment = 'Continue to Payment';
  static const String continueToReview = 'Continue to Review';
  static const String securePayment = 'Secure Payment';
  
  // Profile
  static const String orders = 'Orders';
  static const String wishlist = 'Wishlist';
  static const String settings = 'Settings';
  static const String addresses = 'Addresses';
  static const String notifications = 'Notifications';
  static const String emailPreferences = 'Email Preferences';
  static const String password = 'Password';
  static const String paymentInfo = 'Payment Info';
  static const String signOut = 'Sign Out';
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Check your connection.';
  static const String errorImageLoad = 'Failed to load image';
}
