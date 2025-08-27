import 'package:flutter/material.dart';

class ProductFormWidget extends StatefulWidget {
  const ProductFormWidget({super.key});

  @override
  State<ProductFormWidget> createState() => _ProductFormWidgetState();
}

class _ProductFormWidgetState extends State<ProductFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _skuController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedBrand;
  
  final List<String> _categories = [
    'Mode & Accessoires',
    'Électronique',
    'Maison & Jardin',
    'Sport & Loisirs',
    'Beauté & Santé',
    'Livres & Médias',
    'Automobile',
    'Jouets & Jeux',
    'Alimentation',
    'Autres',
  ];
  
  final List<String> _conditions = [
    'Neuf',
    'Comme neuf',
    'Très bon état',
    'Bon état',
    'État correct',
    'Usé',
  ];
  
  final List<String> _brands = [
    'Sans marque',
    'Nike',
    'Adidas',
    'Apple',
    'Samsung',
    'Sony',
    'LG',
    'Canon',
    'Nikon',
    'Autre',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Nom du produit
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du produit *',
              hintText: 'Ex: T-shirt en coton bio',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shopping_bag),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom du produit est requis';
              }
              if (value.trim().length < 3) {
                return 'Le nom doit contenir au moins 3 caractères';
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
              labelText: 'Description détaillée *',
              hintText: 'Décrivez votre produit en détail...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              helperText: 'Minimum 20 caractères, maximum 1000',
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La description est requise';
              }
              if (value.trim().length < 20) {
                return 'La description doit contenir au moins 20 caractères';
              }
              if (value.trim().length > 1000) {
                return 'La description ne peut pas dépasser 1000 caractères';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Catégorie
          DropdownButtonFormField<String>(
            value: _selectedCategory,
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
              setState(() => _selectedCategory = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Veuillez sélectionner une catégorie';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // État du produit
          DropdownButtonFormField<String>(
            value: _selectedCondition,
            decoration: const InputDecoration(
              labelText: 'État du produit *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.star),
            ),
            items: _conditions.map((condition) {
              return DropdownMenuItem(
                value: condition,
                child: Text(condition),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCondition = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Veuillez sélectionner l\'état du produit';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Marque
          DropdownButtonFormField<String>(
            value: _selectedBrand,
            decoration: const InputDecoration(
              labelText: 'Marque',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.branding_watermark),
              helperText: 'Laissez vide si sans marque',
            ),
            items: _brands.map((brand) {
              return DropdownMenuItem(
                value: brand,
                child: Text(brand),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedBrand = value);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Modèle
          TextFormField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Modèle',
              hintText: 'Ex: iPhone 13, Nike Air Max',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.model_training),
              helperText: 'Laissez vide si non applicable',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // SKU/Code produit
          TextFormField(
            controller: _skuController,
            decoration: const InputDecoration(
              labelText: 'Code produit (SKU)',
              hintText: 'Ex: TSH-001, PHONE-13',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code),
              helperText: 'Code unique pour identifier votre produit',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Caractéristiques techniques
          _buildTechnicalSpecs(),
          
          const SizedBox(height: 16),
          
          // Tags/Mots-clés
          _buildTagsSection(),
        ],
      ),
    );
  }

  Widget _buildTechnicalSpecs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Caractéristiques techniques',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Matériaux
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Matériaux',
                hintText: 'Ex: Coton 100%, Acier inoxydable',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dimensions
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Longueur (cm)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Largeur (cm)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Hauteur (cm)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Poids
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Poids (g)',
                hintText: 'Ex: 250',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 16),
            
            // Couleur
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Couleur(s)',
                hintText: 'Ex: Bleu, Rouge, Noir',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.palette),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tag,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tags et mots-clés',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des mots-clés pour améliorer la visibilité de votre produit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'Ex: mode, tendance, confortable, durable',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
                helperText: 'Séparez les tags par des virgules',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tags suggérés
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Mode',
                'Tendance',
                'Confortable',
                'Durable',
                'Écologique',
                'Design',
                'Premium',
                'Sport',
                'Casual',
                'Élégant',
              ].map((tag) => ActionChip(
                label: Text(tag),
                onPressed: () {
                  // TODO: Ajouter le tag au champ
                },
                backgroundColor: Colors.grey.shade100,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
