const { Template } = require('../models/Template');
const redisClientService = require('./redis-client.service');
const structuredLogger = require('./structured-logger.service');

class TemplateService {
  constructor() {
    this.cacheKeyPrefix = 'template:';
    this.cacheTTL = 3600; // 1 heure
    this.redisClient = null; // Initialisation lazy
  }

  _getRedisClient() {
    if (!this.redisClient) {
      try {
        this.redisClient = redisClientService.getClient();
      } catch (error) {
        // Redis non disponible, on continue sans cache
        return null;
      }
    }
    return this.redisClient;
  }

  /**
   * Récupérer tous les templates actifs
   */
  async getAllTemplates(options = {}) {
    try {
      const cacheKey = `${this.cacheKeyPrefix}all:${JSON.stringify(options)}`;
      
      // Vérifier le cache Redis
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        structuredLogger.logInfo('TEMPLATE_CACHE_HIT', { cacheKey });
        return cached;
      }

      const query = { is_active: true };
      
      // Filtres optionnels
      if (options.tags && options.tags.length > 0) {
        query.tags = { $in: options.tags };
      }
      
      if (options.persona) {
        query.target_persona = { $regex: options.persona, $options: 'i' };
      }

      const templates = await Template.find(query)
        .sort(options.sortBy || { name: 1 })
        .limit(options.limit || 50);

      // Mettre en cache
      await this.setCache(cacheKey, templates);
      
      structuredLogger.logInfo('TEMPLATE_FETCHED', { 
        count: templates.length, 
        filters: options 
      });

      return templates;
    } catch (error) {
      structuredLogger.logError('TEMPLATE_FETCH_ERROR', { 
        error: error.message, 
        options 
      });
      throw new Error(`Erreur lors de la récupération des templates: ${error.message}`);
    }
  }

  /**
   * Récupérer un template par ID
   */
  async getTemplateById(templateId) {
    try {
      const cacheKey = `${this.cacheKeyPrefix}id:${templateId}`;
      
      // Vérifier le cache Redis
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        structuredLogger.logInfo('TEMPLATE_CACHE_HIT', { templateId });
        return cached;
      }

      const template = await Template.findOne({ 
        id: templateId, 
        is_active: true 
      });

      if (!template) {
        throw new Error(`Template avec l'ID '${templateId}' non trouvé`);
      }

      // Mettre en cache
      await this.setCache(cacheKey, template);
      
      structuredLogger.logInfo('TEMPLATE_FETCHED_BY_ID', { templateId });
      return template;
    } catch (error) {
      structuredLogger.logError('TEMPLATE_FETCH_BY_ID_ERROR', { 
        templateId, 
        error: error.message 
      });
      throw error;
    }
  }

  /**
   * Récupérer les templates populaires
   */
  async getPopularTemplates(limit = 10) {
    try {
      const cacheKey = `${this.cacheKeyPrefix}popular:${limit}`;
      
      // Vérifier le cache Redis
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return cached;
      }

      const templates = await Template.findPopular(limit);
      
      // Mettre en cache
      await this.setCache(cacheKey, templates);
      
      structuredLogger.logInfo('TEMPLATE_POPULAR_FETCHED', { count: templates.length });
      return templates;
    } catch (error) {
      structuredLogger.logError('TEMPLATE_POPULAR_FETCH_ERROR', { 
        error: error.message, 
        limit 
      });
      throw new Error(`Erreur lors de la récupération des templates populaires: ${error.message}`);
    }
  }

  /**
   * Créer un nouveau template
   */
  async createTemplate(templateData, createdBy = 'system') {
    try {
      // Validation des données
      const template = new Template({
        ...templateData,
        created_by: createdBy
      });

      await template.save();
      
      // Invalider le cache
      await this.invalidateCache();
      
      structuredLogger.logInfo('TEMPLATE_CREATED', { 
        templateId: template.id, 
        createdBy 
      });

      return template;
    } catch (error) {
      structuredLogger.logError('TEMPLATE_CREATE_ERROR', { 
        error: error.message, 
        templateData 
      });
      throw new Error(`Erreur lors de la création du template: ${error.message}`);
    }
  }

  /**
   * Mettre à jour un template existant
   */
  async updateTemplate(templateId, updateData, updatedBy = 'system') {
    try {
      const template = await Template.findOne({ id: templateId });
      
      if (!template) {
        throw new Error(`Template avec l'ID '${templateId}' non trouvé`);
      }

      // Mise à jour des champs
      Object.assign(template, updateData);
      template.last_modified = new Date();
      
      await template.save();
      
      // Invalider le cache
      await this.invalidateCache();
      
      structuredLogger.logInfo('TEMPLATE_UPDATED', { 
        templateId, 
        updatedBy 
      });

      return template;
    } catch (error) {
      structuredLogger.logError('TEMPLATE_UPDATE_ERROR', { 
        templateId, 
        error: error.message, 
        updateData 
      });
      throw new Error(`Erreur lors de la mise à jour du template: ${error.message}`);
    }
  }

  /**
   * Supprimer un template (soft delete)
   */
  async deleteTemplate(templateId, deletedBy = 'system') {
    try {
      const template = await Template.findOne({ id: templateId });
      
      if (!template) {
        throw new Error(`Template avec l'ID '${templateId}' non trouvé`);
      }

      // Soft delete
      template.is_active = false;
      template.status = 'archived';
      await template.save();
      
      // Invalider le cache
      await this.invalidateCache();
      
      structuredLogger.logInfo('TEMPLATE_DELETED', { 
        templateId, 
        deletedBy 
      });

      return { success: true, message: 'Template supprimé avec succès' };
    } catch (error) {
      structuredLogger.logError('TEMPLATE_DELETE_ERROR', { 
        templateId, 
        error: error.message 
      });
      throw new Error(`Erreur lors de la suppression du template: ${error.message}`);
    }
  }

  /**
   * Rechercher des templates par critères
   */
  async searchTemplates(searchCriteria) {
    try {
      const {
        query,
        tags,
        persona,
        layout,
        colors,
        sortBy = 'name',
        limit = 20,
        page = 1
      } = searchCriteria;

      const cacheKey = `${this.cacheKeyPrefix}search:${JSON.stringify(searchCriteria)}`;
      
      // Vérifier le cache Redis
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return cached;
      }

      const filterQuery = { is_active: true };

      // Recherche textuelle
      if (query) {
        filterQuery.$or = [
          { name: { $regex: query, $options: 'i' } },
          { description: { $regex: query, $options: 'i' } },
          { target_persona: { $regex: query, $options: 'i' } }
        ];
      }

      // Filtres par tags
      if (tags && tags.length > 0) {
        filterQuery.tags = { $in: tags };
      }

      // Filtre par persona
      if (persona) {
        filterQuery.target_persona = { $regex: persona, $options: 'i' };
      }

      // Filtre par layout
      if (layout) {
        filterQuery['layout.grid_system'] = layout;
      }

      // Filtre par couleurs
      if (colors && colors.length > 0) {
        const colorQuery = { $or: [] };
        colors.forEach(color => {
          colorQuery.$or.push(
            { 'color_palette.primary': color },
            { 'color_palette.secondary': color },
            { 'color_palette.accent': color }
          );
        });
        filterQuery.$and = [colorQuery];
      }

      // Pagination
      const skip = (page - 1) * limit;
      
      const [templates, total] = await Promise.all([
        Template.find(filterQuery)
          .sort(sortBy)
          .skip(skip)
          .limit(limit),
        Template.countDocuments(filterQuery)
      ]);

      const result = {
        templates,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit),
          hasNext: page * limit < total,
          hasPrev: page > 1
        }
      };

      // Mettre en cache
      await this.setCache(cacheKey, result);
      
      structuredLogger.logInfo('TEMPLATE_SEARCH', { 
        query, 
        results: templates.length, 
        total 
      });

      return result;
    } catch (error) {
      structuredLogger.logError('TEMPLATE_SEARCH_ERROR', { 
        error: error.message, 
        searchCriteria 
      });
      throw new Error(`Erreur lors de la recherche de templates: ${error.message}`);
    }
  }

  /**
   * Récupérer les statistiques des templates
   */
  async getTemplateStats() {
    try {
      const cacheKey = `${this.cacheKeyPrefix}stats`;
      
      // Vérifier le cache Redis
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return cached;
      }

      const stats = await Template.aggregate([
        { $match: { is_active: true } },
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            totalUsage: { $sum: '$usage_count' },
            avgRating: { $avg: '$rating.average' },
            totalRatings: { $sum: '$rating.count' }
          }
        },
        {
          $project: {
            _id: 0,
            total: 1,
            totalUsage: 1,
            avgRating: { $round: ['$avgRating', 2] },
            totalRatings: 1
          }
        }
      ]);

      const result = stats[0] || {
        total: 0,
        totalUsage: 0,
        avgRating: 0,
        totalRatings: 0
      };

      // Mettre en cache (TTL plus court pour les stats)
      await this.setCache(cacheKey, result, 1800); // 30 minutes
      
      return result;
    } catch (error) {
      structuredLogger.logError('TEMPLATE_STATS_ERROR', { 
        error: error.message 
      });
      throw new Error(`Erreur lors de la récupération des statistiques: ${error.message}`);
    }
  }

  /**
   * Importer des templates depuis un fichier JSON
   */
  async importTemplatesFromJSON(templatesData, importedBy = 'system') {
    try {
      const results = {
        imported: 0,
        updated: 0,
        errors: 0,
        details: []
      };

      for (const templateData of templatesData) {
        try {
          const existingTemplate = await Template.findOne({ id: templateData.id });
          
          if (existingTemplate) {
            // Mise à jour
            Object.assign(existingTemplate, templateData);
            existingTemplate.last_modified = new Date();
            await existingTemplate.save();
            results.updated++;
            results.details.push({
              id: templateData.id,
              action: 'updated',
              success: true
            });
          } else {
            // Création
            const newTemplate = new Template({
              ...templateData,
              created_by: importedBy
            });
            await newTemplate.save();
            results.imported++;
            results.details.push({
              id: templateData.id,
              action: 'created',
              success: true
            });
          }
        } catch (error) {
          results.errors++;
          results.details.push({
            id: templateData.id,
            action: 'failed',
            success: false,
            error: error.message
          });
        }
      }

      // Invalider le cache après import
      if (results.imported > 0 || results.updated > 0) {
        await this.invalidateCache();
      }

      structuredLogger.logInfo('TEMPLATE_IMPORT_COMPLETED', { 
        results, 
        importedBy 
      });

      return results;
    } catch (error) {
      structuredLogger.logError('TEMPLATE_IMPORT_ERROR', { 
        error: error.message, 
        templatesCount: templatesData.length 
      });
      throw new Error(`Erreur lors de l'import des templates: ${error.message}`);
    }
  }

  /**
   * Générer un preview HTML pour un template
   */
  async generateTemplatePreview(templateId, customizations = {}) {
    try {
      const template = await this.getTemplateById(templateId);
      if (!template) {
        throw new Error(`Template non trouvé: ${templateId}`);
      }

      // Fusionner les customisations avec le template de base
      const mergedTemplate = this.mergeCustomizations(template, customizations);
      
      // Générer le HTML du preview
      const previewHTML = this.generatePreviewHTML(mergedTemplate);
      
      // Générer le CSS personnalisé
      const customCSS = this.generateCustomCSS(mergedTemplate);
      
      const preview = {
        html: previewHTML,
        css: customCSS,
        template: mergedTemplate,
        generated_at: new Date().toISOString()
      };

      structuredLogger.logInfo('TEMPLATE_PREVIEW_GENERATED', { 
        templateId, 
        customizations: Object.keys(customizations) 
      });

      return preview;
    } catch (error) {
      structuredLogger.logError('TEMPLATE_PREVIEW_ERROR', { 
        templateId, 
        error: error.message 
      });
      throw new Error(`Erreur lors de la génération du preview: ${error.message}`);
    }
  }

  /**
   * Fusionner les customisations avec le template de base
   */
  mergeCustomizations(template, customizations) {
    const merged = JSON.parse(JSON.stringify(template.toObject()));
    
    if (customizations.colors) {
      Object.assign(merged.color_palette, customizations.colors);
    }
    
    if (customizations.fonts) {
      Object.assign(merged.typography, customizations.fonts);
    }
    
    if (customizations.layout) {
      Object.assign(merged.layout, customizations.layout);
    }
    
    return merged;
  }

  /**
   * Générer le HTML du preview
   */
  generatePreviewHTML(template) {
    return `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Preview - ${template.name}</title>
    <link href="https://fonts.googleapis.com/css2?family=${template.typography.font_primary}:wght@${template.typography.weight_heading},${template.typography.weight_body}&display=swap" rel="stylesheet">
    <style id="template-preview-css"></style>
</head>
<body>
    <div class="template-preview" data-template-id="${template.id}">
        <header class="preview-header">
            <h1>${template.name}</h1>
            <p>${template.description || 'Aperçu du template'}</p>
        </header>
        
        <main class="preview-content">
            <section class="preview-hero">
                <h2>Section Hero</h2>
                <p>Cette section présente votre boutique de manière attractive</p>
            </section>
            
            <section class="preview-products">
                <h2>Produits</h2>
                <div class="product-grid">
                    <div class="product-card">
                        <div class="product-image"></div>
                        <h3>Produit Exemple</h3>
                        <p>Description du produit</p>
                        <span class="price">€29.99</span>
                    </div>
                    <div class="product-card">
                        <div class="product-image"></div>
                        <h3>Autre Produit</h3>
                        <p>Description du produit</p>
                        <span class="price">€39.99</span>
                    </div>
                </div>
            </section>
        </main>
        
        <footer class="preview-footer">
            <p>&copy; 2024 ${template.name}</p>
        </footer>
    </div>
    
    <script>
        // Injection du CSS personnalisé
        document.addEventListener('DOMContentLoaded', function() {
            const styleElement = document.getElementById('template-preview-css');
            // Le CSS sera injecté par le service
        });
    </script>
</body>
</html>`;
  }

  /**
   * Générer le CSS personnalisé
   */
  generateCustomCSS(template) {
    const css = `
:root {
  --primary-color: ${template.color_palette.primary};
  --secondary-color: ${template.color_palette.secondary};
  --accent-color: ${template.color_palette.accent};
  --background-color: ${template.color_palette.background};
  --surface-color: ${template.color_palette.surface};
  --text-color: ${template.color_palette.text};
  --font-primary: "${template.typography.font_primary}";
  --font-secondary: "${template.typography.font_secondary || template.typography.font_primary}";
  --font-heading-weight: ${template.typography.weight_heading};
  --font-body-weight: ${template.typography.weight_body};
  --border-radius: ${template.layout.border_radius}px;
  --max-width: ${template.layout.max_width}px;
  --spacing: ${template.layout.spacing};
}

.template-preview {
  font-family: var(--font-primary), sans-serif;
  background-color: var(--background-color);
  color: var(--text-color);
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 20px;
}

.preview-header {
  text-align: center;
  margin-bottom: 40px;
}

.preview-header h1 {
  font-weight: var(--font-heading-weight);
  color: var(--primary-color);
  margin-bottom: 10px;
}

.preview-content {
  margin-bottom: 40px;
}

.preview-hero {
  background-color: var(--surface-color);
  padding: 40px;
  border-radius: var(--border-radius);
  margin-bottom: 40px;
  text-align: center;
}

.preview-hero h2 {
  color: var(--primary-color);
  font-weight: var(--font-heading-weight);
  margin-bottom: 20px;
}

.product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.product-card {
  background-color: var(--surface-color);
  padding: 20px;
  border-radius: var(--border-radius);
  box-shadow: ${this.getShadowStyle(template.layout.card_shadow)};
  transition: transform 0.3s ease;
}

.product-card:hover {
  transform: translateY(-5px);
}

.product-image {
  width: 100%;
  height: 200px;
  background-color: var(--secondary-color);
  border-radius: calc(var(--border-radius) / 2);
  margin-bottom: 15px;
}

.product-card h3 {
  color: var(--primary-color);
  font-weight: var(--font-heading-weight);
  margin-bottom: 10px;
}

.price {
  color: var(--accent-color);
  font-weight: bold;
  font-size: 1.2em;
}

.preview-footer {
  text-align: center;
  padding: 20px;
  border-top: 1px solid var(--secondary-color);
  color: var(--text-color);
}

@media (max-width: 768px) {
  .template-preview {
    padding: 10px;
  }
  
  .preview-hero {
    padding: 20px;
  }
  
  .product-grid {
    grid-template-columns: 1fr;
  }
}`;

    return css;
  }

  /**
   * Obtenir le style d'ombre selon la configuration
   */
  getShadowStyle(shadowType) {
    const shadows = {
      'none': 'none',
      'soft': '0 2px 8px rgba(0,0,0,0.1)',
      'sharp': '0 4px 12px rgba(0,0,0,0.15)',
      'dramatic': '0 8px 25px rgba(0,0,0,0.2)'
    };
    return shadows[shadowType] || shadows.soft;
  }

  // Méthodes de cache Redis
  async getFromCache(key) {
    try {
      const client = this._getRedisClient();
      if (!client) return null;
      
      const cached = await client.get(key);
      return cached ? JSON.parse(cached) : null;
    } catch (error) {
      structuredLogger.logWarn('TEMPLATE_CACHE_READ_ERROR', { key, error: error.message });
      return null;
    }
  }

  async setCache(key, data, ttl = this.cacheTTL) {
    try {
      const client = this._getRedisClient();
      if (!client) return;
      
      await client.setex(key, ttl, JSON.stringify(data));
    } catch (error) {
      structuredLogger.logWarn('TEMPLATE_CACHE_WRITE_ERROR', { key, error: error.message });
    }
  }

  async invalidateCache() {
    try {
      const client = this._getRedisClient();
      if (!client) return;
      
      const keys = await client.keys(`${this.cacheKeyPrefix}*`);
      if (keys.length > 0) {
        await client.del(...keys);
        structuredLogger.logInfo('TEMPLATE_CACHE_INVALIDATED', { keysCount: keys.length });
      }
    } catch (error) {
      structuredLogger.logWarn('TEMPLATE_CACHE_INVALIDATION_ERROR', { error: error.message });
    }
  }
}

module.exports = new TemplateService();
