import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_constants.dart';
import '../models/payment_method.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';

/// Comprehensive payment method selector with multiple payment options,
/// card input, and validation
class PaymentMethodSelector extends StatefulWidget {
  final List<PaymentMethod> paymentMethods;
  final PaymentMethod? selectedPaymentMethod;
  final Function(PaymentMethod?)? onPaymentMethodSelected;
  final Function()? onAddNewCard;
  final bool enableAddNew;
  final bool showExpressPayment;
  final bool isLoading;
  final String? errorMessage;

  const PaymentMethodSelector({
    super.key,
    required this.paymentMethods,
    this.selectedPaymentMethod,
    this.onPaymentMethodSelected,
    this.onAddNewCard,
    this.enableAddNew = true,
    this.showExpressPayment = true,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showAddCardForm = false;

  // Form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  // Form validation
  final _formKey = GlobalKey<FormState>();
  String? _cardType;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: LoadingStates(
          type: LoadingType.spinner,
          size: LoadingSize.medium,
          message: 'Loading payment methods...',
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animationController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Express Payment Options
              if (widget.showExpressPayment) _buildExpressPayment(),

              // Divider
              if (widget.showExpressPayment) _buildDivider(),

              // Saved Payment Methods
              if (widget.paymentMethods.isNotEmpty) _buildSavedPaymentMethods(),

              // Add New Card
              if (widget.enableAddNew) _buildAddNewCard(),

              // Error Message
              if (widget.errorMessage != null) _buildErrorMessage(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpressPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Express Checkout',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildExpressPaymentButton(
                'Apple Pay',
                Icons.apple,
                () => _handleExpressPayment('apple_pay'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildExpressPaymentButton(
                'Google Pay',
                Icons.account_circle, // Replaced Icons.google with valid icon
                () => _handleExpressPayment('google_pay'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        SizedBox(
          width: double.infinity,
          child: _buildExpressPaymentButton(
            'PayPal',
            Icons.account_balance_wallet,
            () => _handleExpressPayment('paypal'),
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildExpressPaymentButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isFullWidth = false,
  }) {
    return GlassmorphicContainer.card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingL,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardNumberField() {
    return TextFormField(
      controller: _cardNumberController,
      decoration: InputDecoration(
        labelText: 'Card Number',
        hintText: '1234 5678 9012 3456',
        prefixIcon: _cardType != null
            ? _getCardTypeIcon(_cardType!)
            : const Icon(Icons.credit_card),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _CardNumberFormatter(),
      ],
      onChanged: (value) {
        setState(() {
          _cardType = _getCardType(value);
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter card number';
        }
        if (value.replaceAll(' ', '').length < 13) {
          return 'Please enter a valid card number';
        }
        return null;
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.spacingL),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
            child: Text(
              'or pay with card',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Payment Methods',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        ...widget.paymentMethods.map((method) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
            child: _buildPaymentMethodCard(method),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = widget.selectedPaymentMethod == method;

    return GlassmorphicContainer.card(
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: widget.selectedPaymentMethod,
        onChanged: widget.onPaymentMethodSelected,
        title: Row(
          children: [
            Icon(method.icon, size: 24),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (method.type == PaymentType.creditCard &&
                      method.last4Digits != null)
                    Text(
                      'Expires 12/25', // This would come from the payment method
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            if (method.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingS,
                  vertical: AppConstants.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
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
        ),
        secondary: IconButton(
          onPressed: () => _editPaymentMethod(method),
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  Widget _buildAddNewCard() {
    return Column(
      children: [
        const SizedBox(height: AppConstants.spacingM),
        if (!_showAddCardForm)
          GlassmorphicContainer.card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                'Add New Card',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              subtitle: const Text('Add credit or debit card'),
              onTap: () {
                setState(() {
                  _showAddCardForm = true;
                });
              },
            ),
          ),
        if (_showAddCardForm) _buildAddCardForm(),
      ],
    );
  }

  Widget _buildAddCardForm() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Card',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showAddCardForm = false;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Card Number
              _buildCardNumberField(),
              const SizedBox(height: AppConstants.spacingM),

              // Expiry and CVV
              Row(
                children: [
                  Expanded(child: _buildExpiryField()),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(child: _buildCvvField()),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),

              // Cardholder Name
              _buildCardHolderField(),
              const SizedBox(height: AppConstants.spacingL),

              // Security Info
              _buildSecurityInfo(),
              const SizedBox(height: AppConstants.spacingL),

              // Add Card Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addNewCard,
                  child: const Text('Add Card'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryField() {
    return TextFormField(
      controller: _expiryController,
      decoration: InputDecoration(
        labelText: 'MM/YY',
        hintText: '12/25',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
        _ExpiryDateFormatter(),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (value.length < 5) {
          return 'Invalid date';
        }
        return null;
      },
    );
  }

  Widget _buildCvvField() {
    return TextFormField(
      controller: _cvvController,
      decoration: InputDecoration(
        labelText: 'CVV',
        hintText: '123',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        suffixIcon: IconButton(
          onPressed: () => _showCvvInfo(),
          icon: const Icon(Icons.help_outline),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (value.length < 3) {
          return 'Invalid CVV';
        }
        return null;
      },
    );
  }

  Widget _buildCardHolderField() {
    return TextFormField(
      controller: _cardHolderController,
      decoration: InputDecoration(
        labelText: 'Cardholder Name',
        hintText: 'John Doe',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter cardholder name';
        }
        return null;
      },
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              'Your payment information is encrypted and secure',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              widget.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _handleExpressPayment(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$method checkout not implemented yet')),
    );
  }

  void _editPaymentMethod(PaymentMethod method) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit payment method feature coming soon')),
    );
  }

  void _addNewCard() {
    if (_formKey.currentState?.validate() ?? false) {
      final newPaymentMethod = PaymentMethod(
        id: 'pm_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Credit Card',
        type: PaymentType.creditCard,
        last4Digits: _cardNumberController.text.replaceAll(' ', '').substring(
              _cardNumberController.text.replaceAll(' ', '').length - 4,
            ),
        brand: _cardType ?? 'Unknown',
        icon: Icons.credit_card,
      );

      widget.onPaymentMethodSelected?.call(newPaymentMethod);

      setState(() {
        _showAddCardForm = false;
      });

      // Clear form
      _cardNumberController.clear();
      _expiryController.clear();
      _cvvController.clear();
      _cardHolderController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card added successfully')),
      );
    }
  }

  void _showCvvInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What is CVV?'),
        content: const Text(
          'CVV (Card Verification Value) is the 3 or 4 digit number on the back of your card. '
          'It helps verify that you have the physical card.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _getCardTypeIcon(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return const Icon(Icons.credit_card, color: Colors.blue);
      case 'mastercard':
        return const Icon(Icons.credit_card, color: Colors.red);
      case 'american express':
        return const Icon(Icons.credit_card, color: Colors.green);
      default:
        return const Icon(Icons.credit_card);
    }
  }

  String? _getCardType(String cardNumber) {
    final number = cardNumber.replaceAll(' ', '');
    if (number.startsWith('4')) {
      return 'Visa';
    } else if (number.startsWith(RegExp(r'5[1-5]'))) {
      return 'Mastercard';
    } else if (number.startsWith(RegExp(r'3[47]'))) {
      return 'American Express';
    }
    return null;
  }
}

/// Card number formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Expiry date formatter
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length == 2 && oldValue.text.length == 1) {
      return TextEditingValue(
        text: '$text/',
        selection: const TextSelection.collapsed(offset: 3),
      );
    }

    return newValue;
  }
}
