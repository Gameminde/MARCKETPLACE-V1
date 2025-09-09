import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../core/config/app_constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/particle_background.dart';
import '../widgets/loading_states.dart';

/// Comprehensive registration screen with email verification flow,
/// password strength validation, and social registration options
class RegistrationScreen extends StatefulWidget {
  final Function()? onRegistrationSuccess;
  final Function()? onNavigateToLogin;
  
  const RegistrationScreen({
    super.key,
    this.onRegistrationSuccess,
    this.onNavigateToLogin,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _slideController;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Email verification
  final _verificationCodeController = TextEditingController();
  bool _showEmailVerification = false;
  Timer? _resendTimer;
  int _resendCountdown = 0;
  
  // Form state
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _subscribeToNewsletter = true;
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  
  // Step management
  int _currentStep = 0;
  final List<RegistrationStep> _steps = [
    const RegistrationStep(
      title: 'Personal Info',
      subtitle: 'Basic details',
      icon: Icons.person,
    ),
    const RegistrationStep(
      title: 'Account Setup',
      subtitle: 'Email & password',
      icon: Icons.security,
    ),
    const RegistrationStep(
      title: 'Verification',
      subtitle: 'Verify email',
      icon: Icons.verified_user,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar.detail(
        title: 'Create Account',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: ParticleBackground.subtle(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _animationController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: Column(
                      children: [
                        const SizedBox(height: AppConstants.spacingXL),
                        _buildHeader(),
                        const SizedBox(height: AppConstants.spacingXL),
                        if (!_showEmailVerification) ...[
                          _buildStepIndicator(),
                          const SizedBox(height: AppConstants.spacingL),
                          _buildRegistrationForm(),
                        ] else ...[
                          _buildEmailVerificationForm(),
                        ],
                        const SizedBox(height: AppConstants.spacingL),
                        if (!_showEmailVerification) _buildSocialRegistration(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildFooterLinks(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_add,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              _showEmailVerification ? 'Verify Your Email' : 'Join Marketplace',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              _showEmailVerification
                  ? 'Enter the verification code sent to ${_emailController.text}'
                  : 'Create your account to start shopping with exclusive deals',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    return GlassmorphicContainer.card(
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
  
  Widget _buildRegistrationForm() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_currentStep == 0) _buildPersonalInfoStep(),
              if (_currentStep == 1) _buildAccountSetupStep(),
              const SizedBox(height: AppConstants.spacingXL),
              _buildStepNavigation(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'First name must be at least 2 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Last name must be at least 2 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number (Optional)',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
            _PhoneNumberFormatter(),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAccountSetupStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildPasswordField(
          controller: _passwordController,
          label: 'Password',
          isVisible: _isPasswordVisible,
          onVisibilityToggle: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          onChanged: (value) {
            setState(() {
              _passwordStrength = _calculatePasswordStrength(value);
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            if (_passwordStrength == PasswordStrength.weak) {
              return 'Password is too weak';
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spacingS),
        _buildPasswordStrengthIndicator(),
        const SizedBox(height: AppConstants.spacingM),
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          isVisible: _isConfirmPasswordVisible,
          onVisibilityToggle: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spacingL),
        _buildCheckboxTile(
          value: _agreeToTerms,
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          title: 'I agree to the Terms of Service and Privacy Policy',
          isRequired: true,
        ),
        _buildCheckboxTile(
          value: _subscribeToNewsletter,
          onChanged: (value) => setState(() => _subscribeToNewsletter = value ?? false),
          title: 'Subscribe to newsletter for exclusive offers',
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization? textCapitalization,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      validator: validator,
      onChanged: onChanged,
    );
  }
  
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onVisibilityToggle,
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      ),
      obscureText: !isVisible,
      validator: validator,
      onChanged: onChanged,
    );
  }
  
  Widget _buildPasswordStrengthIndicator() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Password Strength: ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _passwordStrength.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _passwordStrength.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        LinearProgressIndicator(
          value: _passwordStrength.strength,
          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(_passwordStrength.color),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          _passwordStrength.requirements,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCheckboxTile({
    required bool value,
    required Function(bool?) onChanged,
    required String title,
    bool isRequired = false,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(text: title),
            if (isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
  
  Widget _buildStepNavigation() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              child: const Text('Previous'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final isLastStep = _currentStep == _steps.length - 2;
              return ElevatedButton(
                onPressed: authProvider.isLoading ? null : () => _handleStepNavigation(authProvider),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isLastStep ? 'Create Account' : 'Next'),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmailVerificationForm() {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Check Your Email',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'We\'ve sent a 6-digit verification code to ${_emailController.text}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXL),
            
            // Verification Code Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildCodeDigitField(index)),
            ),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Resend Code
            if (_resendCountdown > 0)
              Text(
                'Resend code in $_resendCountdown seconds',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              TextButton(
                onPressed: _resendVerificationCode,
                child: const Text('Resend Code'),
              ),
            
            const SizedBox(height: AppConstants.spacingXL),
            
            // Verify Button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading || _verificationCodeController.text.length < 6
                        ? null
                        : () => _verifyEmail(authProvider),
                    child: authProvider.isLoading
                        ? const LoadingStates(
                            type: LoadingType.spinner,
                            size: LoadingSize.small,
                          )
                        : const Text('Verify Email'),
                  ),
                );
              },
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Change Email
            TextButton(
              onPressed: () {
                setState(() {
                  _showEmailVerification = false;
                  _currentStep = 1;
                });
              },
              child: const Text('Change Email Address'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCodeDigitField(int index) {
    return Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Update verification code
            final currentCode = _verificationCodeController.text;
            final newCode = currentCode.padRight(6, ' ');
            final codeList = newCode.split('');
            codeList[index] = value;
            _verificationCodeController.text = codeList.join().trim();
            
            // Move to next field
            if (index < 5) {
              FocusScope.of(context).nextFocus();
            } else {
              FocusScope.of(context).unfocus();
            }
          } else {
            // Move to previous field on backspace
            if (index > 0) {
              FocusScope.of(context).previousFocus();
            }
          }
        },
      ),
    );
  }
  
  Widget _buildSocialRegistration() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
              child: Text(
                'or sign up with',
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
        const SizedBox(height: AppConstants.spacingL),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                'Google',
                Icons.g_mobiledata,
                () => _handleSocialRegistration('google'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildSocialButton(
                'Apple',
                Icons.apple,
                () => _handleSocialRegistration('apple'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        SizedBox(
          width: double.infinity,
          child: _buildSocialButton(
            'Facebook',
            Icons.facebook,
            () => _handleSocialRegistration('facebook'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSocialButton(
    String platform,
    IconData icon,
    VoidCallback onPressed,
  ) {
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
                platform,
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
  
  Widget _buildFooterLinks() {
    return Column(
      children: [
        Text(
          'Already have an account?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: widget.onNavigateToLogin ?? () => Navigator.pop(context),
          child: Text(
            'Sign In',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
  
  // Event handlers
  void _handleStepNavigation(AuthProvider authProvider) async {
    if (_currentStep == 0) {
      if (_validatePersonalInfo()) {
        setState(() {
          _currentStep = 1;
        });
      }
    } else if (_currentStep == 1) {
      if (_formKey.currentState?.validate() ?? false) {
        if (!_agreeToTerms) {
          _showErrorSnackBar('Please agree to the Terms of Service and Privacy Policy');
          return;
        }
        
        // Send verification email
        await _sendVerificationEmail(authProvider);
      }
    }
  }
  
  bool _validatePersonalInfo() {
    if (_firstNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your first name');
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your last name');
      return false;
    }
    return true;
  }
  
  Future<void> _sendVerificationEmail(AuthProvider authProvider) async {
    try {
      await authProvider.sendEmailVerification(_emailController.text.trim());
      
      setState(() {
        _showEmailVerification = true;
      });
      
      _startResendTimer();
      
      _showSuccessSnackBar('Verification code sent to ${_emailController.text}');
    } catch (e) {
      _showErrorSnackBar('Failed to send verification code: $e');
    }
  }
  
  Future<void> _verifyEmail(AuthProvider authProvider) async {
    try {
      await authProvider.verifyEmailAndRegister(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        verificationCode: _verificationCodeController.text,
        subscribeToNewsletter: _subscribeToNewsletter,
      );
      
      _showSuccessSnackBar('Account created successfully!');
      
      // Navigate to success or main app
      widget.onRegistrationSuccess?.call();
      
    } catch (e) {
      _showErrorSnackBar('Verification failed: $e');
    }
  }
  
  void _resendVerificationCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.sendEmailVerification(_emailController.text.trim());
      _startResendTimer();
      _showSuccessSnackBar('Verification code resent');
    } catch (e) {
      _showErrorSnackBar('Failed to resend code: $e');
    }
  }
  
  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
    });
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCountdown--;
      });
      
      if (_resendCountdown <= 0) {
        timer.cancel();
      }
    });
  }
  
  void _handleSocialRegistration(String platform) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.socialLogin(platform).then((_) {
      widget.onRegistrationSuccess?.call();
    }).catchError((error) {
      _showErrorSnackBar('$platform registration failed: $error');
    });
  }
  
  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    if (score >= 4) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Supporting classes
class RegistrationStep {
  final String title;
  final String subtitle;
  final IconData icon;

  const RegistrationStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

enum PasswordStrength {
  weak,
  medium,
  strong,
}

extension PasswordStrengthExtension on PasswordStrength {
  String get displayName {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
  
  Color get color {
    switch (this) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }
  
  double get strength {
    switch (this) {
      case PasswordStrength.weak:
        return 0.3;
      case PasswordStrength.medium:
        return 0.6;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
  
  String get requirements {
    switch (this) {
      case PasswordStrength.weak:
        return 'Use 8+ characters with mixed case, numbers & symbols';
      case PasswordStrength.medium:
        return 'Add more complexity for better security';
      case PasswordStrength.strong:
        return 'Excellent! Your password is secure';
    }
  }
}

// Phone number formatter
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (text.length <= 3) {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } else if (text.length <= 6) {
      return TextEditingValue(
        text: '(${text.substring(0, 3)}) ${text.substring(3)}',
        selection: TextSelection.collapsed(offset: text.length + 2),
      );
    } else {
      return TextEditingValue(
        text: '(${text.substring(0, 3)}) ${text.substring(3, 6)}-${text.substring(6, text.length.clamp(6, 10))}',
        selection: TextSelection.collapsed(offset: text.length + 4),
      );
    }
  }
}
