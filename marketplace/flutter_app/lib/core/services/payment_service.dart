import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService extends ChangeNotifier {
  static const String _paymentMethodKey = 'selected_payment_method';
  static const String _defaultPaymentMethod = 'CIB'; // Default to CIB card
  
  late String _currentPaymentMethod;
  
  // Supported payment methods in Algeria
  static const List<Map<String, String>> supportedPaymentMethods = [
    {
      'id': 'CIB',
      'name': 'بطاقة CIB',
      'name_en': 'CIB Card',
      'name_fr': 'Carte CIB',
      'icon': '💳',
    },
    {
      'id': 'EDAHABIA',
      'name': 'البريد الجزائري',
      'name_en': 'Algerie Poste',
      'name_fr': 'Poste Algérienne',
      'icon': '✉️',
    },
    {
      'id': 'MOBILIS',
      'name': 'مبليس',
      'name_en': 'Mobilis',
      'name_fr': 'Mobilis',
      'icon': '📱',
    },
    {
      'id': 'DJAZZ',
      'name': 'الدجيز',
      'name_en': 'Djezzy',
      'name_fr': 'Djezzy',
      'icon': '📶',
    },
    {
      'id': 'OOREDOO',
      'name': 'أوريدو',
      'name_en': 'Ooredoo',
      'name_fr': 'Ooredoo',
      'icon': '📡',
    },
    {
      'id': 'COD',
      'name': 'الدفع عند الاستلام',
      'name_en': 'Cash on Delivery',
      'name_fr': 'Paiement à la livraison',
      'icon': '💵',
    },
    {
      'id': 'STRIPE',
      'name': 'البطاقات الدولية',
      'name_en': 'International Cards',
      'name_fr': 'Cartes Internationales',
      'icon': '🌐',
    },
  ];
  
  String get currentPaymentMethod => _currentPaymentMethod;
  
  PaymentService() {
    _loadSavedPaymentMethod();
  }
  
  // Load saved payment method from shared preferences
  void _loadSavedPaymentMethod() {
    _currentPaymentMethod = _defaultPaymentMethod;
  }
  
  // Change payment method
  Future<void> changePaymentMethod(String newPaymentMethodId) async {
    if (supportedPaymentMethods.any((method) => method['id'] == newPaymentMethodId)) {
      _currentPaymentMethod = newPaymentMethodId;
      
      // Save payment method preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_paymentMethodKey, newPaymentMethodId);
      
      notifyListeners();
    }
  }
  
  // Get payment method details
  Map<String, String>? getPaymentMethodDetails(String methodId) {
    try {
      return supportedPaymentMethods.firstWhere(
        (method) => method['id'] == methodId,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Get current payment method details
  Map<String, String>? get currentPaymentMethodDetails {
    return getPaymentMethodDetails(_currentPaymentMethod);
  }
  
  // Process payment (simplified for demonstration)
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String currency,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real implementation, this would integrate with actual payment gateways
    // For now, we'll simulate success/failure based on payment method
    
    // For demonstration, we'll assume all local payment methods succeed
    final localMethods = ['CIB', 'EDAHABIA', 'MOBILIS', 'DJAZZ', 'OOREDOO', 'COD'];
    final isSuccess = localMethods.contains(paymentMethod) || 
                     (paymentMethod == 'STRIPE' && paymentDetails.containsKey('cardNumber'));
    
    return {
      'success': isSuccess,
      'transactionId': isSuccess ? 'TXN_${DateTime.now().millisecondsSinceEpoch}' : null,
      'message': isSuccess ? 'Payment successful' : 'Payment failed',
    };
  }
}