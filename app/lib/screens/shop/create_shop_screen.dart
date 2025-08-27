import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/api_provider.dart';
import '../../widgets/template_selector_widget.dart';

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedTemplate = 'feminine';
  bool _isLoading = false;
  String? _error;

  final List<String> _categories = [
    'Mode & Accessoires',
    'Beauté & Santé',
    'Maison & Jardin',
    'Sport & Loisirs',
    'Technologie',
    'Livres & Médias',
    'Jouets & Jeux',
    'Automobile',
    'Alimentation',
    'Autres',
  ];

  @override
  void dispose() {
    _shopNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une boutique'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélecteur de template
              _buildTemplateSection(),
              const SizedBox(height: 32),
              
              // Informations de base
              _buildBasicInfoSection(),
              const SizedBox(height: 32),
              
              // Catégorie et localisation
              _buildCategoryLocationSection(),
              const SizedBox(height: 32),
              
              // Aperçu de la boutique
              _buildPreviewSection(),
              
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez un template',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez un design qui correspond à votre style',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        TemplateSelector(
          selectedTemplate: _selectedTemplate,
          onTemplateSelected: (template) {
            setState(() {
              _selectedTemplate = template;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de base',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Nom de la boutique
        TextFormField(
          controller: _shopNameController,
          decoration: const InputDecoration(
            labelText: 'Nom de la boutique *',
            hintText: 'Ex: Boutique Élégance',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom de la boutique est requis';
            }
            if (value.trim().length < 3) {
              return 'Le nom doit contenir au moins 3 caractères';
            }
            if (value.trim().length > 50) {
              return 'Le nom ne peut pas dépasser 50 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            hintText: 'Décrivez votre boutique et vos produits',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          maxLength: 500,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La description est requise';
            }
            if (value.trim().length < 20) {
              return 'La description doit contenir au moins 20 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie et localisation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Catégorie
        DropdownButtonFormField<String>(
          value: _categoryController.text.isEmpty ? null : _categoryController.text,
          decoration: const InputDecoration(
            labelText: 'Catégorie *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _categoryController.text = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner une catégorie';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Localisation
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Localisation',
            hintText: 'Ex: Paris, France',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          validator: (value) {
            if (value != null && value.trim().isNotEmpty && value.trim().length < 3) {
              return 'La localisation doit contenir au moins 3 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu de votre boutique',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          elevation: 4,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _getTemplateGradient(),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _shopNameController.text.isEmpty
                                  ? 'Nom de votre boutique'
                                  : _shopNameController.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_categoryController.text.isNotEmpty)
                              Text(
                                _categoryController.text,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_descriptionController.text.isNotEmpty)
                    Text(
                      _descriptionController.text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  LinearGradient _getTemplateGradient() {
    switch (_selectedTemplate) {
      case 'feminine':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
        );
      case 'masculine':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4169E1), Color(0xFF000080)],
        );
      case 'neutral':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF808080), Color(0xFF696969)],
        );
      case 'urban':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF32CD32), Color(0xFF228B22)],
        );
      case 'minimal':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F5F5), Color(0xFFD3D3D3)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
        );
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simuler la création de la boutique
      await Future.delayed(const Duration(seconds: 2));
      
      // TODO: Appel API pour créer la boutique
      final shopData = {
        'name': _shopNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text,
        'location': _locationController.text.trim(),
        'template': _selectedTemplate,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Succès - navigation vers la boutique créée
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Boutique "${shopData['name']}" créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigation vers la boutique créée
        Navigator.pop(context, shopData);
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la création: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
