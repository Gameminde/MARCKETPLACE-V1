import 'package:flutter/material.dart';

import '../core/config/app_constants.dart';
import '../models/shop.dart';
import '../widgets/glassmorphic_container.dart';

/// Shop creation wizard with template selection and step-by-step setup
class ShopCreationWizardScreen extends StatefulWidget {
  const ShopCreationWizardScreen({super.key});

  @override
  State<ShopCreationWizardScreen> createState() => _ShopCreationWizardScreenState();
}

class _ShopCreationWizardScreenState extends State<ShopCreationWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Form data
  String? _selectedTemplate;
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  ShopCategory _selectedCategory = ShopCategory.electronics;
  ShopBranding _branding = ShopBranding.defaultBranding();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _acceptTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    _shopNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Shop'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildTemplateSelectionStep(),
                _buildBasicInfoStep(),
                _buildCategoryStep(),
                _buildBrandingStep(),
                _buildContactInfoStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        children: [
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelectionStep() {
    final templates = [
      const ShopTemplate(
        id: 'electronics',
        name: 'Electronics Store',
        description: 'Perfect for selling gadgets, phones, and tech accessories',
        icon: Icons.devices,
        color: Colors.blue,
        features: ['Tech product showcase', 'Warranty tracking', 'Comparison tools'],
      ),
      const ShopTemplate(
        id: 'fashion',
        name: 'Fashion Boutique',
        description: 'Ideal for clothing, accessories, and fashion items',
        icon: Icons.checkroom,
        color: Colors.pink,
        features: ['Size guides', 'Style recommendations', 'Seasonal collections'],
      ),
      const ShopTemplate(
        id: 'books',
        name: 'Bookstore',
        description: 'Great for books, educational materials, and media',
        icon: Icons.menu_book,
        color: Colors.brown,
        features: ['Book reviews', 'Author profiles', 'Reading lists'],
      ),
      const ShopTemplate(
        id: 'general',
        name: 'General Store',
        description: 'Flexible template for any type of products',
        icon: Icons.store,
        color: Colors.green,
        features: ['Multi-category support', 'Flexible layout', 'Custom sections'],
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Shop Template',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Select a template that best matches your business type. You can customize it later.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXL),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.spacingM,
              mainAxisSpacing: AppConstants.spacingM,
              childAspectRatio: 0.8,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = _selectedTemplate == template.id;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedTemplate = template.id),
                child: GlassmorphicContainer.card(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(
                        color: isSelected ? template.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppConstants.spacingM),
                              decoration: BoxDecoration(
                                color: template.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                template.icon,
                                color: template.color,
                                size: 32,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: template.color,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Text(
                          template.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        Text(
                          template.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        ...template.features.take(2).map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: template.color,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Shop Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Tell us about your shop. This information will be visible to customers.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXL),
          
          GlassmorphicContainer.card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(
                      labelText: 'Shop Name *',
                      hintText: 'Enter your shop name',
                      prefixIcon: Icon(Icons.store),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => 
                        value?.isEmpty == true ? 'Shop name is required' : null,
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Shop Description *',
                      hintText: 'Describe what you sell and what makes your shop special',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => 
                        value?.isEmpty == true ? 'Description is required' : null,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingL),
          
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Text(
                    'Tip: A good shop name is memorable and reflects your brand. The description helps customers understand what you offer.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop Category',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Choose the primary category that best describes your products.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXL),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.spacingM,
              mainAxisSpacing: AppConstants.spacingM,
              childAspectRatio: 1.2,
            ),
            itemCount: ShopCategory.values.length,
            itemBuilder: (context, index) {
              final category = ShopCategory.values[index];
              final isSelected = _selectedCategory == category;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: GlassmorphicContainer.card(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category.icon,
                          size: 48,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Text(
                          category.displayName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop Branding',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Customize your shop\'s appearance to match your brand.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXL),
          
          GlassmorphicContainer.card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color Scheme',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  
                  Wrap(
                    spacing: AppConstants.spacingM,
                    runSpacing: AppConstants.spacingM,
                    children: [
                      _buildColorOption('Blue', Colors.blue),
                      _buildColorOption('Green', Colors.green),
                      _buildColorOption('Purple', Colors.purple),
                      _buildColorOption('Orange', Colors.orange),
                      _buildColorOption('Red', Colors.red),
                      _buildColorOption('Teal', Colors.teal),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.spacingXL),
                  
                  Text(
                    'Logo & Banner',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _uploadLogo,
                          icon: const Icon(Icons.image),
                          label: const Text('Upload Logo'),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _uploadBanner,
                          icon: const Icon(Icons.panorama),
                          label: const Text('Upload Banner'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingL),
          
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Text(
                    'You can always change your branding later in shop settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(String name, Color color) {
    final isSelected = _branding.primaryColor == color;
    
    return GestureDetector(
      onTap: () => setState(() {
        _branding = _branding.copyWith(
          primaryColor: color,
          secondaryColor: color.withOpacity(0.7),
        );
      }),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Provide contact details for customer inquiries and order management.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXL),
          
          GlassmorphicContainer.card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      hintText: 'your.shop@email.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+1 (555) 123-4567',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Business Address',
                      hintText: 'Street, City, State, ZIP Code',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingL),
          
          CheckboxListTile(
            value: _acceptTerms,
            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
            title: const Text('I accept the Terms of Service and Privacy Policy'),
            subtitle: const Text('Required to create your shop'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              child: Text(_currentStep == _totalSteps - 1 ? 'Create Shop' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedTemplate != null;
      case 1:
        return _shopNameController.text.isNotEmpty && 
               _descriptionController.text.isNotEmpty;
      case 2:
        return true; // Category is pre-selected
      case 3:
        return true; // Branding is optional
      case 4:
        return _emailController.text.isNotEmpty && _acceptTerms;
      default:
        return false;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createShop();
    }
  }

  void _uploadLogo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo upload functionality would be implemented here')),
    );
  }

  void _uploadBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Banner upload functionality would be implemented here')),
    );
  }

  void _createShop() {
    // Here you would typically send the data to your backend
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Your shop "${_shopNameController.text}" has been created successfully!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Continue to Dashboard'),
          ),
        ],
      ),
    );
  }
}

/// Shop template model for template selection
class ShopTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;

  const ShopTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
  });
}