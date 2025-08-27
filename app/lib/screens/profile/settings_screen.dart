import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  String _language = 'Français';
  String _currency = 'EUR';
  bool _isLoading = false;

  final List<String> _languages = [
    'Français',
    'English',
    'Español',
    'Deutsch',
    'Italiano',
  ];

  final List<String> _currencies = [
    'EUR',
    'USD',
    'GBP',
    'JPY',
    'CAD',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          // Section Compte
          _buildSectionHeader('Compte'),
          _buildAccountSettings(),
          
          // Section Notifications
          _buildSectionHeader('Notifications'),
          _buildNotificationSettings(),
          
          // Section Apparence
          _buildSectionHeader('Apparence'),
          _buildAppearanceSettings(),
          
          // Section Sécurité
          _buildSectionHeader('Sécurité'),
          _buildSecuritySettings(),
          
          // Section Préférences
          _buildSectionHeader('Préférences'),
          _buildPreferenceSettings(),
          
          // Section Support
          _buildSectionHeader('Support'),
          _buildSupportSettings(),
          
          // Section Données
          _buildSectionHeader('Données'),
          _buildDataSettings(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Modifier le profil'),
            subtitle: const Text('Nom, email, photo de profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigation vers l'édition du profil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Édition du profil à implémenter')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Changer l\'email'),
            subtitle: const Text('john.doe@example.com'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showChangeEmailDialog();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Changer le mot de passe'),
            subtitle: const Text('Mettre à jour votre mot de passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notifications push'),
            subtitle: const Text('Recevoir des notifications sur votre appareil'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveNotificationSettings();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notification_important),
            title: const Text('Types de notifications'),
            subtitle: const Text('Personnaliser les notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showNotificationTypesDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Mode sombre'),
            subtitle: const Text('Activer le thème sombre'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              _saveAppearanceSettings();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Langue'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showLanguageDialog();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Devise'),
            subtitle: Text(_currency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showCurrencyDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Authentification biométrique'),
            subtitle: const Text('Utiliser l\'empreinte digitale ou Face ID'),
            value: _biometricEnabled,
            onChanged: (value) {
              setState(() {
                _biometricEnabled = value;
              });
              _saveSecuritySettings();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Sécurité du compte'),
            subtitle: const Text('Authentification à deux facteurs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showTwoFactorDialog();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Appareils connectés'),
            subtitle: const Text('Gérer les sessions actives'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showDevicesDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Confidentialité'),
            subtitle: const Text('Gérer vos données personnelles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showPrivacyDialog();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Localisation'),
            subtitle: const Text('Autoriser l\'accès à la localisation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showLocationDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Centre d\'aide'),
            subtitle: const Text('FAQ et guides d\'utilisation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showHelpCenter();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Contacter le support'),
            subtitle: const Text('Obtenir de l\'aide personnalisée'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showContactSupport();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Signaler un problème'),
            subtitle: const Text('Signaler un bug ou un dysfonctionnement'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showBugReport();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Exporter mes données'),
            subtitle: const Text('Télécharger vos données personnelles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _exportData();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Supprimer mon compte'),
            subtitle: const Text('Supprimer définitivement votre compte'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showDeleteAccountDialog();
            },
          ),
        ],
      ),
    );
  }

  // Dialogues et actions
  void _showChangeEmailDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer l\'email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre nouvelle adresse email :'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Nouvel email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter le changement d'email
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changement d\'email à implémenter')),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter le changement de mot de passe
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changement de mot de passe à implémenter')),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showNotificationTypesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Types de notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Personnalisation des notifications à implémenter'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final language = _languages[index];
              return ListTile(
                title: Text(language),
                trailing: _language == language
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _language = language;
                  });
                  Navigator.pop(context);
                  _saveAppearanceSettings();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la devise'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _currencies.length,
            itemBuilder: (context, index) {
              final currency = _currencies[index];
              return ListTile(
                title: Text(currency),
                trailing: _currency == currency
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _currency = currency;
                  });
                  Navigator.pop(context);
                  _saveAppearanceSettings();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentification à deux facteurs'),
        content: const Text('Configuration de l\'authentification à deux facteurs à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appareils connectés'),
        content: const Text('Gestion des appareils connectés à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confidentialité'),
        content: const Text('Paramètres de confidentialité à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Localisation'),
        content: const Text('Paramètres de localisation à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Centre d\'aide à implémenter')),
    );
  }

  void _showContactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support à implémenter')),
    );
  }

  void _showBugReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signalement de bug à implémenter')),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export de données à implémenter')),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ? '
          'Cette action est irréversible et toutes vos données seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la suppression du compte
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Suppression de compte à implémenter')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // Sauvegarde des paramètres
  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Sauvegarder les paramètres de notification
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _notificationsEnabled
                  ? 'Notifications activées'
                  : 'Notifications désactivées',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAppearanceSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Sauvegarder les paramètres d'apparence
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres d\'apparence sauvegardés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSecuritySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Sauvegarder les paramètres de sécurité
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _biometricEnabled
                  ? 'Authentification biométrique activée'
                  : 'Authentification biométrique désactivée',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
