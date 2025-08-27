import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/api_provider.dart';
import '../../widgets/image_picker_widget.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId; // null pour création, non-null pour édition

  const ProductFormScreen({
    super.key,
    this.productId,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _brandController = TextEditingController();
  final _stockController = TextEditingController();
  
  String _selectedCategory = '';
  List<String> _selectedTags = [];
  List<String> _images = [];
  bool _isLoading = false;
  bool _isEditing = false;
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

  final List<String> _availableTags = [
    'Nouveau', 'Populaire', 'Promotion', 'Éco-responsable',
    'Fait main', 'Vintage', 'Luxueux', 'Économique',
    'Rapide', 'Durable', 'Tendance', 'Classique',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.productId != null;
    if (_isEditing) {
      _loadProductData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _brandController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    // TODO: Charger les données du produit depuis l'API
    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler le chargement
      await Future.delayed(const Duration(seconds: 1));
      
      // Données simulées
      _nameController.text = 'Produit existant';
      _descriptionController.text = 'Description du produit existant';
      _priceController.text = '29.99';
      _originalPriceController.text = '39.99';
      _brandController.text = 'Marque existante';
      _stockController.text = '50';
      _selectedCategory = 'Mode & Accessoires';
      _selectedTags = ['Nouveau', 'Populaire'];
      _images = [
        'https://via.placeholder.com/300x300?text=Image+1',
        'https://via.placeholder.com/300x300?text=Image+2',
      ];
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Modifier' : 'Créer'),
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
              // Images du produit
              _buildImageSection(),
              const SizedBox(height: 32),
              
              // Informations de base
              _buildBasicInfoSection(),
              const SizedBox(height: 32),
              
              // Prix et stock
              _buildPricingStockSection(),
              const SizedBox(height: 32),
              
              // Catégorie et tags
              _buildCategoryTagsSection(),
              const SizedBox(height: 32),
              
              // Aperçu du produit
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images du produit',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoutez des images de haute qualité pour attirer les clients',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Sélecteur d'images
        ImagePickerWidget(
          images: _images,
          onImagesChanged: (images) {
            setState(() {
              _images = images;
            });
          },
          maxImages: 10,
        ),
        
        if (_images.isEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ajoutez au moins une image pour publier votre produit',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        
        // Nom du produit
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du produit *',
            hintText: 'Ex: Sac à main élégant en cuir',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.shopping_bag),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom du produit est requis';
            }
            if (value.trim().length < 5) {
              return 'Le nom doit contenir au moins 5 caractères';
            }
            if (value.trim().length > 100) {
              return 'Le nom ne peut pas dépasser 100 caractères';
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
            hintText: 'Décrivez votre produit en détail',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          maxLength: 1000,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La description est requise';
            }
            if (value.trim().length < 30) {
              return 'La description doit contenir au moins 30 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Marque
        TextFormField(
          controller: _brandController,
          decoration: const InputDecoration(
            labelText: 'Marque',
            hintText: 'Ex: Nike, Apple, Chanel',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.branding_watermark),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prix et stock',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            // Prix actuel
            Expanded(
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix actuel *',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                  suffixText: '€',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le prix est requis';
                  }
                  final price = double.tryParse(value.replaceAll(',', '.'));
                  if (price == null || price <= 0) {
                    return 'Le prix doit être un nombre positif';
                  }
                  if (price > 999999.99) {
                    return 'Le prix ne peut pas dépasser 999999.99€';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            // Prix original
            Expanded(
              child: TextFormField(
                controller: _originalPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix original',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: '€',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final price = double.tryParse(value.replaceAll(',', '.'));
                    if (price == null || price <= 0) {
                      return 'Prix invalide';
                    }
                    final currentPrice = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
                    if (price <= currentPrice) {
                      return 'Le prix original doit être supérieur au prix actuel';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Stock
        TextFormField(
          controller: _stockController,
          decoration: const InputDecoration(
            labelText: 'Stock disponible *',
            hintText: '0',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.inventory),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le stock est requis';
            }
            final stock = int.tryParse(value);
            if (stock == null || stock < 0) {
              return 'Le stock doit être un nombre positif';
            }
            if (stock > 999999) {
              return 'Le stock ne peut pas dépasser 999999';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie et tags',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Catégorie
        DropdownButtonFormField<String>(
          value: _selectedCategory.isEmpty ? null : _selectedCategory,
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
              _selectedCategory = value ?? '';
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
        
        // Tags
        Text(
          'Tags (optionnel)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!_selectedTags.contains(tag)) {
                      _selectedTags.add(tag);
                    }
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu du produit',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image principale
                if (_images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _images.first,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Informations du produit
                Text(
                  _nameController.text.isEmpty
                      ? 'Nom du produit'
                      : _nameController.text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                if (_brandController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Marque: ${_brandController.text}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Prix
                Row(
                  children: [
                    if (_priceController.text.isNotEmpty) ...[
                      Text(
                        '${_priceController.text}€',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_originalPriceController.text.isNotEmpty &&
                          double.tryParse(_originalPriceController.text.replaceAll(',', '.')) != null &&
                          double.tryParse(_originalPriceController.text.replaceAll(',', '.'))! >
                              double.tryParse(_priceController.text.replaceAll(',', '.'))!) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${_originalPriceController.text}€',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ] else
                      Text(
                        'Prix à définir',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                
                if (_descriptionController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _descriptionController.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                if (_selectedTags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: _selectedTags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_images.isEmpty) {
      setState(() {
        _error = 'Veuillez ajouter au moins une image';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simuler la sauvegarde
      await Future.delayed(const Duration(seconds: 2));
      
      // TODO: Appel API pour sauvegarder le produit
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.replaceAll(',', '.')),
        'originalPrice': _originalPriceController.text.isNotEmpty
            ? double.parse(_originalPriceController.text.replaceAll(',', '.'))
            : null,
        'brand': _brandController.text.trim(),
        'stock': int.parse(_stockController.text),
        'category': _selectedCategory,
        'tags': _selectedTags,
        'images': _images,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Produit modifié avec succès !'
                  : 'Produit créé avec succès !',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigation de retour
        Navigator.pop(context, productData);
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la sauvegarde: ${e.toString()}';
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
