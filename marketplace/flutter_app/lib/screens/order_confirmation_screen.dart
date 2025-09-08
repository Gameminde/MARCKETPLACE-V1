import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/config/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/particle_background.dart';
import '../models/order.dart';

/// Enhanced order confirmation screen with comprehensive tracking information
class OrderConfirmationScreen extends StatefulWidget {
  final Order? order;
  final String? orderNumber;
  final String? trackingNumber;
  
  const OrderConfirmationScreen({
    super.key,
    this.order,
    this.orderNumber,
    this.trackingNumber,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Order _order;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Use provided order or create a sample one
    _order = widget.order ?? MockOrders.createSampleOrder();
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.detail(
        title: 'Order Confirmed',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: () => _shareOrder(),
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: ParticleBackground.subtle(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _animationController,
                  child: Column(
                    children: [
                      // Success Animation
                      _buildSuccessAnimation(),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Order Details
                      _buildOrderDetails(),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Tracking Information
                      _buildTrackingInfo(),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Order Summary
                      _buildOrderSummary(),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Action Buttons
                      _buildActionButtons(),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Additional Information
                      _buildAdditionalInfo(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
        ),
      ),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Icon(
          Icons.check_circle,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  Widget _buildOrderDetails() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildDetailRow('Order Number', _order.displayOrderNumber),
            _buildDetailRow('Order Date', _formatDate(_order.orderDate)),
            _buildDetailRow('Total Amount', '\$${_order.totalAmount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingInfo() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracking Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildDetailRow(
              'Tracking Number',
              _order.trackingNumber ?? 'Not available',
              isHighlighted: true,
            ),
            const SizedBox(height: AppConstants.spacingM),
            if (_order.trackingNumber != null)
              TextButton.icon(
                onPressed: _copyTrackingNumber,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Tracking Number'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return GlassmorphicContainer.card(
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
            ...(_order.items.take(3).map((item) {
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
            }).toList()),
            if (_order.items.length > 3)
              Text(
                '... and ${_order.items.length - 3} more items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_order.canBeTracked)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _trackOrder(),
              icon: const Icon(Icons.track_changes),
              label: const Text('Track Your Order'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 56),
              ),
            ),
          ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewOrderDetails(),
                icon: const Icon(Icons.receipt_long),
                label: const Text('View Details'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _continueShopping(),
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Shop More'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      children: [
        GlassmorphicContainer.card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.email_outlined,
                  'Order confirmation sent to your email',
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildInfoRow(
                  Icons.support_agent,
                  'Need help? Contact our 24/7 support team',
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildInfoRow(
                  Icons.security,
                  'Your payment is secure and protected',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        if (_order.canBeCancelled)
          TextButton.icon(
            onPressed: () => _showCancelOrderDialog(),
            icon: Icon(
              Icons.cancel_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              'Cancel Order',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false, bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        isHighlighted
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingS,
                  vertical: AppConstants.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isAmount ? FontWeight.bold : FontWeight.w600,
                  color: isAmount ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
      ],
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _shareOrder() {
    Clipboard.setData(ClipboardData(text: 'Order ${_order.displayOrderNumber} placed successfully!'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order details copied to clipboard')),
    );
  }

  void _copyTrackingNumber() {
    if (_order.trackingNumber != null) {
      Clipboard.setData(ClipboardData(text: _order.trackingNumber!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tracking number copied to clipboard')),
      );
    }
  }

  void _trackOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening order tracking...')),
    );
  }

  void _viewOrderDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order details feature coming soon')),
    );
  }

  void _continueShopping() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showCancelOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order ${_order.displayOrderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order cancellation requested')),
              );
            },
            child: Text(
              'Cancel Order',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}