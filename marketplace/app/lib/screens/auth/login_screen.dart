import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/theme_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                
                // Logo et titre
                _buildHeader(),
                const SizedBox(height: 48),
                
                // Formulaire de connexion
                _buildLoginForm(),
                const SizedBox(height: 24),
                
                // Bouton de connexion
                _buildLoginButton(),
                const SizedBox(height: 24),
                
                // Options supplémentaires
                _buildAdditionalOptions(),
                const SizedBox(height: 32),
                
                // Séparateur
                _buildDivider(),
                const SizedBox(height: 32),
                
                // Bouton d'inscription
                _buildRegisterButton(),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.store,
            size: 50,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Titre
        Text(
          'Bienvenue !',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Sous-titre
        Text(
          'Connectez-vous à votre compte',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Champ email
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'votre@email.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'email est requis';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Veuillez entrer un email valide';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Champ mot de passe
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            hintText: 'Votre mot de passe',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le mot de passe est requis';
            }
            if (value.length < 6) {
              return 'Le mot de passe doit contenir au moins 6 caractères';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Options de connexion
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
            ),
            const Text('Se souvenir de moi'),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigation vers la récupération de mot de passe
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Récupération de mot de passe à implémenter')),
                );
              },
              child: const Text('Mot de passe oublié ?'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Se connecter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      children: [
        // Connexion avec Google
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleLogin,
            icon: const Icon(
              Icons.g_mobiledata,
              size: 20,
            ),
            label: const Text('Continuer avec Google'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Connexion avec Apple
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleAppleLogin,
            icon: const Icon(Icons.apple),
            label: const Text('Continuer avec Apple'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.grey.shade300),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.grey.shade300),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Column(
      children: [
        Text(
          'Vous n\'avez pas de compte ?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            context.go('/auth/register');
          },
          child: Text(
            'Créer un compte',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Gestion des erreurs
  void _showError(String message) {
    setState(() {
      _error = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Actions de connexion
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(email, password);
      
      if (mounted) {
        if (success) {
          // Connexion réussie
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion réussie !'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigation vers l'écran principal
          context.go('/home');
        } else {
          // Afficher l'erreur du provider
          final error = authProvider.error ?? 'Erreur de connexion inconnue';
          _showError(error);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur de connexion: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Implémenter la connexion Google avec Google Sign-In
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        _showError('Connexion Google non disponible pour le moment');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur de connexion Google');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Implémenter la connexion Apple avec Sign in with Apple
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        _showError('Connexion Apple non disponible pour le moment');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur de connexion Apple');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}


