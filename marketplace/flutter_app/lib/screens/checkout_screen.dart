import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_constants.dart';
import '../models/address.dart';
import '../models/payment_method.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/particle_background.dart';
import 'order_confirmation_screen.dart';

/// Comprehensive multi-step checkout screen with glassmorphic design,
/// address selection, payment methods, and order review
class CheckoutScreen extends StatefulWidget {
  final bool enableGuestCheckout;
  final Function()? onOrderComplete;
  
  const CheckoutScreen({
    super.key,
    this.enableGuestCheckout = true,
    this.onOrderComplete,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;
  
  int _currentStep = 0;
  bool _isProcessing = false;
  
  // Checkout data
  Address? _selectedAddress;
  PaymentMethod? _selectedPaymentMethod;
  final String _promoCode = '';
  final double _discountAmount = 0;
  
  final List<CheckoutStep> _steps = [
    const CheckoutStep(
      title: 'Shipping',
      subtitle: 'Address & delivery',
      icon: Icons.local_shipping,
    ),
    const CheckoutStep(
      title: 'Payment',
      subtitle: 'Select method',
      icon: Icons.payment,
    ),
    const CheckoutStep(
      title: 'Review',
      subtitle: 'Confirm order',
      icon: Icons.assignment,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pageController = PageController();
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar.detail(
        title: 'Checkout',
        onBackPressed: () => _handleBackPress(),
      ),
      body: ParticleBackground.subtle(
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(),
            
            // Step Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _animationController,
                        child: _buildStepContent(index),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Bottom Actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: EdgeInsets.only(
        top: AppConstants.spacingXL + MediaQuery.of(context).padding.top,
        left: AppConstants.spacingM,
        right: AppConstants.spacingM,
        bottom: AppConstants.spacingL,
      ),
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            children: [
              Row(
                children: List.generate(_steps.length, (index) {
                  final isActive = index <= _currentStep;
                  final isCompleted = index < _currentStep;
                  
                  return Expanded(
                    child: Row(
                      children: [
                        _buildStepCircle(index, isActive, isCompleted),
                        if (index < _steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppConstants.spacingM),
              Row(
                children: List.generate(_steps.length, (index) {
                  final step = _steps[index];
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: index <= _currentStep ? FontWeight.w600 : FontWeight.normal,
                            color: index <= _currentStep
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          step.subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepCircle(int index, bool isActive, bool isCompleted) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? Theme.of(context).colorScheme.primary
            : isActive
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Theme.of(context).colorScheme.surfaceVariant,
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        isCompleted
            ? Icons.check
            : _steps[index].icon,
        size: 20,
        color: isCompleted
            ? Theme.of(context).colorScheme.onPrimary
            : isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildStepContent(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return _buildShippingStep();
      case 1:
        return _buildPaymentStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildShippingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipping Address',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          // Address Selection
          ...MockAddresses.userAddresses.map((address) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
              child: GlassmorphicContainer.card(
                child: RadioListTile<Address>(
                  value: address,
                  groupValue: _selectedAddress,
                  onChanged: (value) {
                    setState(() {
                      _selectedAddress = value;
                    });
                  },
                  title: Text(
                    address.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(address.shortAddress),
                      if (address.phone != null) ...[
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          address.phone!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                      ],
                      if (address.isDefault) ...[
                        Container(
                          margin: const EdgeInsets.only(top: AppConstants.spacingXS),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingS,
                            vertical: AppConstants.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          child: Text(
                            'Default',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  secondary: IconButton(
                    onPressed: () => _editAddress(address),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ),
            );
          }),
          
          // Add New Address
          GlassmorphicContainer.card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                'Add New Address',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Add a new shipping address'),
              onTap: () => _addNewAddress(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          // Payment Methods
          ...MockPaymentMethods.userPaymentMethods.map((paymentMethod) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
              child: GlassmorphicContainer.card(
                child: RadioListTile<PaymentMethod>(
                  value: paymentMethod,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                  title: Text(
                    paymentMethod.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(paymentMethod.type.name),
                  secondary: Icon(paymentMethod.icon),
                ),
              ),
            );
          }),
          
          // Add New Payment Method
          GlassmorphicContainer.card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                'Add Payment Method',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Add credit card, digital wallet, etc.'),
              onTap: () => _addPaymentMethod(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Review',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Order Summary
              GlassmorphicContainer.card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      
                      // Cart Items
                      ...cartProvider.items.take(3).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                ),
                                child: const Icon(Icons.shopping_bag_outlined),
                              ),
                              const SizedBox(width: AppConstants.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Qty: ${item.quantity}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${item.totalPrice.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      if (cartProvider.items.length > 3)
                        Text(
                          '... and ${cartProvider.items.length - 3} more items',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      
                      const Divider(height: AppConstants.spacingL),
                      
                      // Price Breakdown
                      _buildPriceRow('Subtotal', '\$${cartProvider.totalPrice.toStringAsFixed(2)}'),
                      _buildPriceRow('Shipping', cartProvider.shippingCost > 0 ? '\$${cartProvider.shippingCost.toStringAsFixed(2)}' : 'FREE'),
                      _buildPriceRow('Tax', '\$${cartProvider.taxAmount.toStringAsFixed(2)}'),
                      if (_discountAmount > 0)
                        _buildPriceRow('Discount', '-\$${_discountAmount.toStringAsFixed(2)}', isDiscount: true),
                      
                      const Divider(height: AppConstants.spacingL),
                      
                      _buildPriceRow(
                        'Total',
                        '\$${(cartProvider.finalTotal - _discountAmount).toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingM),
              
              // Selected Address
              if (_selectedAddress != null)
                GlassmorphicContainer.card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Shipping Address'),
                    subtitle: Text(_selectedAddress!.shortAddress),
                  ),
                ),
              
              const SizedBox(height: AppConstants.spacingM),
              
              // Selected Payment Method
              if (_selectedPaymentMethod != null)
                GlassmorphicContainer.card(
                  child: ListTile(
                    leading: Icon(_selectedPaymentMethod!.icon),
                    title: const Text('Payment Method'),
                    subtitle: Text(_selectedPaymentMethod!.displayName),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildPriceRow(String label, String amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isDiscount
                  ? Theme.of(context).colorScheme.secondary
                  : isTotal
                      ? Theme.of(context).colorScheme.primary
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _handlePrevious,
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppConstants.spacingM),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isProcessing || !_canProceed() ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_getButtonText()),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continue to Payment';
      case 1:
        return 'Review Order';
      case 2:
        return 'Place Order';
      default:
        return 'Continue';
    }
  }
  
  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedAddress != null;
      case 1:
        return _selectedPaymentMethod != null;
      case 2:
        return true;
      default:
        return false;
    }
  }
  
  void _handleBackPress() {
    if (_currentStep > 0) {
      _handlePrevious();
    } else {
      Navigator.pop(context);
    }
  }
  
  void _handlePrevious() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _handleNext() async {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Place order
      await _placeOrder();
    }
  }
  
  Future<void> _placeOrder() async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Simulate order processing
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Navigate to order confirmation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderConfirmationScreen(),
          ),
        ).then((_) {
          widget.onOrderComplete?.call();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  void _editAddress(Address address) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit address feature coming soon')),
    );
  }
  
  void _addNewAddress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add new address feature coming soon')),
    );
  }
  
  void _addPaymentMethod() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add payment method feature coming soon')),
    );
  }
}
