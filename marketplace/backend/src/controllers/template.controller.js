const templateService = require('../services/template.service');
const themeCustomizerService = require('../services/theme-customizer.service');
const BaseController = require('./BaseController');
const Joi = require('joi');
const structuredLogger = require('../services/structured-logger.service');
const templateAIService = require('../services/template-ai.service');
const cssCompilerService = require('../services/css-compiler.service');

class TemplateController extends BaseController {
  constructor() {
    super('Template');
    this.templateService = templateService;
    this.validationService = this._createValidationService();
    this.logger = structuredLogger;
  }

  // MANDATORY METHOD 1 - SOLID: Single Responsibility
  async getPopularTemplates(req, res) {
    try {
      // Input validation - MANDATORY
      const limit = this._validatePositiveInteger(
        req.query.limit, 
        { min: 1, max: 100, default: 10 }
      );

      // Business logic - MANDATORY error handling
      const templates = await this.templateService.getPopularTemplates(limit);
      if (!templates || templates.length === 0) {
        return this.handleError(
          new Error('No templates found'), 
          req, 
          res, 
          404
        );
      }

      // Success response - CONSISTENT format
      this.sendSuccess(res, {
        data: templates,
        count: templates.length,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      this.logger.error('getPopularTemplates failed', {
        error: error.message,
        stack: error.stack
      });
      this.handleError(error, req, res);
    }
  }

  // MANDATORY METHOD 2 - SOLID: Single Responsibility
  async searchTemplates(req, res) {
    try {
      // Validation schema - MANDATORY
      const searchCriteria = this._validateSearchCriteria(req.query);
      const results = await this.templateService.searchTemplates(searchCriteria);
      
      this.sendSuccess(res, {
        data: results.templates,
        pagination: results.pagination,
        filters_applied: searchCriteria
      });
    } catch (error) {
      this.logger.error('searchTemplates failed', {
        error: error.message
      });
      this.handleError(error, req, res);
    }
  }

  // MANDATORY METHOD 3 - SOLID: Single Responsibility
  async getTemplateById(req, res) {
    try {
      const { id } = req.params;
      
      // Validation - MANDATORY
      if (!this._isValidObjectId(id)) {
        return this.handleError(
          new Error('Invalid template ID format'),
          req,
          res,
          400
        );
      }

      const template = await this.templateService.getTemplateById(id);
      if (!template) {
        return this.handleError(
          new Error('Template not found'),
          req,
          res,
          404
        );
      }

      this.sendSuccess(res, { data: template });
    } catch (error) {
      this.logger.error('getTemplateById failed', {
        id: req.params.id,
        error: error.message
      });
      this.handleError(error, req, res);
    }
  }

  // MANDATORY METHOD 4 - SOLID: Single Responsibility
  async createTemplate(req, res) {
    try {
      // Authentication check - MANDATORY
      if (!req.user) {
        return this.handleError(
          new Error('Authentication required'),
          req,
          res,
          401
        );
      }

      // Input validation - MANDATORY
      const templateData = this._validateTemplateCreation(req.body);

      // Authorization - MANDATORY
      if (!this._hasPermission(req.user, 'template:create')) {
        return this.handleError(
          new Error('Insufficient permissions'),
          req,
          res,
          403
        );
      }

      const createdBy = req.user.sub;
      const template = await this.templateService.createTemplate(templateData, createdBy);

      this.logger.info('Template created successfully', {
        templateId: template.id,
        createdBy
      });

      this.sendSuccess(res, { data: template }, 201);
    } catch (error) {
      this.logger.error('createTemplate failed', {
        error: error.message
      });
      this.handleError(error, req, res);
    }
  }

  // Helper methods for validation - SOLID: Single Responsibility
  _validatePositiveInteger(value, options = {}) {
    const { min = 1, max = 100, default: defaultValue = 10 } = options;
    
    if (!value) return defaultValue;
    
    const parsed = parseInt(value, 10);
    if (isNaN(parsed) || parsed < min || parsed > max) {
      throw new Error(`Value must be between ${min} and ${max}`);
    }
    
    return parsed;
  }

  _validateSearchCriteria(query) {
    const schema = Joi.object({
      q: Joi.string().max(100).optional(),
      category: Joi.string().max(50).optional(),
      tags: Joi.string().optional(),
      sortBy: Joi.string().valid('name', 'createdAt', 'popularity').default('popularity'),
      order: Joi.string().valid('asc', 'desc').default('desc'),
      limit: Joi.number().integer().min(1).max(50).default(10),
      page: Joi.number().integer().min(1).default(1)
    });

    const { error, value } = schema.validate(query);
    if (error) {
      throw new Error(`Search validation failed: ${error.details[0].message}`);
    }

    return value;
  }

  _validateTemplateCreation(data) {
    const schema = Joi.object({
      name: Joi.string().trim().min(3).max(100).required(),
      description: Joi.string().trim().min(10).max(500).required(),
      category: Joi.string().valid('business', 'portfolio', 'blog', 'ecommerce', 'landing').required(),
      tags: Joi.array().items(Joi.string().max(30)).max(10).optional(),
      layout: Joi.string().max(50).optional(),
      colorPalette: Joi.object().optional(),
      fontPreset: Joi.string().max(50).optional(),
      customCSS: Joi.string().max(10000).optional(),
      isPublic: Joi.boolean().default(true)
    });

    const { error, value } = schema.validate(data);
    if (error) {
      throw new Error(`Template validation failed: ${error.details[0].message}`);
    }

    return value;
  }

  _isValidObjectId(id) {
    return /^[0-9a-fA-F]{24}$/.test(id) || /^[a-zA-Z0-9_-]+$/.test(id);
  }

  _hasPermission(user, permission) {
    // Basic permission check - can be extended
    return user && (user.role === 'admin' || user.permissions?.includes(permission));
  }

  _createValidationService() {
    return {
      validatePositiveInteger: this._validatePositiveInteger.bind(this),
      validateSearchCriteria: this._validateSearchCriteria.bind(this),
      validateTemplateCreation: this._validateTemplateCreation.bind(this),
      isValidObjectId: this._isValidObjectId.bind(this)
    };
  }
  /**
   * Récupérer tous les templates
   * GET /api/templates
   */
  async getAllTemplates(req, res) {
    try {
      // Validation Joi des paramètres de requête
      const { error, value } = Joi.object({
        tags: Joi.string().optional(),
        persona: Joi.string().max(100).optional(),
        sortBy: Joi.string().valid('name', 'createdAt', 'popularity').optional(),
        limit: Joi.number().integer().min(1).max(100).optional(),
        page: Joi.number().integer().min(1).optional()
      }).validate(req.query);
      
      if (error) {
        return res.status(400).json({
          success: false,
          code: 'VALIDATION_ERROR',
          message: error.details[0].message
        });
      }

      const options = {
        tags: value.tags ? value.tags.split(',') : undefined,
        persona: value.persona,
        sortBy: value.sortBy,
        limit: value.limit ? parseInt(value.limit) : undefined,
        page: value.page ? parseInt(value.page) : undefined
      };

      const templates = await templateService.getAllTemplates(options);
      
      res.json({
        success: true,
        data: templates,
        count: templates.length
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Mettre à jour un template
   * PUT /api/templates/:id
   */
  async updateTemplate(req, res) {
    try {
            // Validation Joi des paramètres
      const { error, value } = Joi.object({
        id: Joi.string().required().min(1).max(100)
      }).validate(req.params);
      
      if (error) {
        return res.status(400).json({
          success: false,
          code: 'VALIDATION_ERROR',
          message: error.details[0].message
        });
      }
      
      const { id } = value;
      
      // Validation Joi du body
      const { error: bodyError, value: bodyValue } = Joi.object({
        name: Joi.string().min(1).max(100).optional(),
        description: Joi.string().max(500).optional(),
        category: Joi.string().max(50).optional(),
        tags: Joi.array().items(Joi.string().max(50)).max(10).optional(),
        persona: Joi.string().valid('feminine', 'masculine', 'neutral', 'urban', 'minimal').optional(),
        layout: Joi.string().max(50).optional(),
        colorPalette: Joi.object().optional(),
        fontPreset: Joi.string().max(50).optional(),
        customCSS: Joi.string().max(10000).optional()
      }).validate(req.body);
      
      if (bodyError) {
        return res.status(400).json({
          success: false,
          code: 'VALIDATION_ERROR',
          message: bodyError.details[0].message
        });
      }
      
      const updateData = bodyValue;
      const updatedBy = req.user?.sub || 'system';
      
      const template = await templateService.updateTemplate(id, updateData, updatedBy);
      
      res.json({
        success: true,
        message: 'Template mis à jour avec succès',
        data: template
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Supprimer un template
   * DELETE /api/templates/:id
   */
  async deleteTemplate(req, res) {
    try {
            // Validation Joi des paramètres
      const { error, value } = Joi.object({
        id: Joi.string().required().min(1).max(100)
      }).validate(req.params);
      
      if (error) {
        return res.status(400).json({
          success: false,
          code: 'VALIDATION_ERROR',
          message: error.details[0].message
        });
      }
      
      const { id } = value;
      const deletedBy = req.user?.sub || 'system';
      
      const result = await templateService.deleteTemplate(id, deletedBy);
      
      res.json({
        success: true,
        message: result.message,
        data: result
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Générer un preview de template
   * POST /api/templates/:id/preview
   */
  async generateTemplatePreview(req, res) {
    try {
      const { id } = req.params;
      const { customizations = {} } = req.body;
      
      const preview = await templateService.generateTemplatePreview(id, customizations);
      
      res.json({
        success: true,
        data: preview
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Obtenir les statistiques des templates
   * GET /api/templates/stats
   */
  async getTemplateStats(req, res) {
    try {
      const stats = await templateService.getTemplateStats();
      
      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Importer des templates depuis JSON
   * POST /api/templates/import
   */
  async importTemplates(req, res) {
    try {
      const { templates } = req.body;
      const importedBy = req.user?.sub || 'system';
      
      if (!Array.isArray(templates) || templates.length === 0) {
        return res.status(400).json({
          success: false,
          code: 'INVALID_IMPORT_DATA',
          message: 'Données d\'import invalides'
        });
      }

      const results = await templateService.importTemplatesFromJSON(templates, importedBy);
      
      res.json({
        success: true,
        message: 'Import des templates terminé',
        data: results
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  // ===== ENDPOINTS THÈMES =====

  /**
   * Obtenir les palettes de couleurs disponibles
   * GET /api/themes/color-palettes
   */
  async getColorPalettes(req, res) {
    try {
      const palettes = themeCustomizerService.getAvailableColorPalettes();
      
      res.json({
        success: true,
        data: palettes,
        count: palettes.length
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Obtenir les polices disponibles
   * GET /api/themes/fonts
   */
  async getAvailableFonts(req, res) {
    try {
      const fonts = themeCustomizerService.getAvailableFonts();
      
      res.json({
        success: true,
        data: fonts,
        count: fonts.length
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Obtenir les layouts disponibles
   * GET /api/themes/layouts
   */
  async getAvailableLayouts(req, res) {
    try {
      const layouts = themeCustomizerService.getAvailableLayouts();
      
      res.json({
        success: true,
        data: layouts,
        count: layouts.length
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Appliquer une palette de couleurs
   * POST /api/themes/apply-color-palette
   */
  async applyColorPalette(req, res) {
    try {
      const { paletteName, baseCustomizations = {} } = req.body;
      
      if (!paletteName) {
        return res.status(400).json({
          success: false,
          code: 'MISSING_PALETTE_NAME',
          message: 'Nom de palette requis'
        });
      }

      const result = themeCustomizerService.applyColorPalette(paletteName, baseCustomizations);
      
      res.json({
        success: true,
        message: `Palette '${paletteName}' appliquée avec succès`,
        data: result
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Appliquer une configuration de police
   * POST /api/themes/apply-font
   */
  async applyFontPreset(req, res) {
    try {
      const { fontName, baseCustomizations = {} } = req.body;
      
      if (!fontName) {
        return res.status(400).json({
          success: false,
          code: 'MISSING_FONT_NAME',
          message: 'Nom de police requis'
        });
      }

      const result = themeCustomizerService.applyFontPreset(fontName, baseCustomizations);
      
      res.json({
        success: true,
        message: `Police '${fontName}' appliquée avec succès`,
        data: result
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Appliquer une configuration de layout
   * POST /api/themes/apply-layout
   */
  async applyLayoutPreset(req, res) {
    try {
      const { presetName, baseCustomizations = {} } = req.body;
      
      if (!presetName) {
        return res.status(400).json({
          success: false,
          code: 'MISSING_LAYOUT_NAME',
          message: 'Nom de layout requis'
        });
      }

      const result = themeCustomizerService.applyLayoutPreset(presetName, baseCustomizations);
      
      res.json({
        success: true,
        message: `Layout '${presetName}' appliqué avec succès`,
        data: result
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Générer du CSS personnalisé
   * POST /api/themes/generate-css
   */
  async generateCustomCSS(req, res) {
    try {
      const { customizations, templateId } = req.body;
      
      if (!customizations) {
        return res.status(400).json({
          success: false,
          code: 'MISSING_CUSTOMIZATIONS',
          message: 'Customisations requises'
        });
      }

      let template = null;
      if (templateId) {
        try {
          template = await templateService.getTemplateById(templateId);
        } catch (error) {
          // Template non trouvé, continuer sans template
        }
      }

      const css = themeCustomizerService.generateCustomCSS(customizations, template);
      
      res.json({
        success: true,
        data: { css, template: template ? template.id : null }
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Générer un preview HTML personnalisé
   * POST /api/themes/generate-preview
   */
  async generateThemePreview(req, res) {
    try {
      const { customizations, templateId } = req.body;
      
      if (!customizations) {
        return res.status(400).json({
          success: false,
          code: 'MISSING_CUSTOMIZATIONS',
          message: 'Customisations requises'
        });
      }

      let template = null;
      if (templateId) {
        try {
          template = await templateService.getTemplateById(templateId);
        } catch (error) {
          // Template non trouvé, continuer sans template
        }
      }

      const preview = themeCustomizerService.generateThemePreview(customizations, template);
      
      res.json({
        success: true,
        data: { preview, template: template ? template.id : null }
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Recommandations IA pour templates
   * GET /api/templates/ai-suggestions
   */
  async getAISuggestions(req, res) {
    try {
      const { error, value } = Joi.object({
        name: Joi.string().optional(),
        sector: Joi.string().optional(),
        target: Joi.string().optional(),
        style: Joi.string().optional()
      }).validate(req.query);
      if (error) {
        return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: error.details[0].message });
      }
      const analysis = await templateAIService.analyzeShopContent(value || {});
      const palette = await templateAIService.generateColorPalette(analysis.sector, analysis.target);
      return res.json({ success: true, data: { analysis, palette } });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Génération preview temps réel via AI + CSS compiler
   * POST /api/templates/preview
   */
  async previewWithAI(req, res) {
    try {
      const { error, value } = Joi.object({
        template: Joi.object().default({}),
        customization: Joi.object().default({}),
        usedSelectors: Joi.array().items(Joi.string()).default([])
      }).validate(req.body);
      if (error) {
        return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: error.details[0].message });
      }
      const compiled = await templateAIService.compileDynamicCSS(value.template, value.customization);
      const critical = await cssCompilerService.extractCritical(compiled.css);
      const purged = await cssCompilerService.purgeUnused(compiled.css, value.usedSelectors);
      return res.json({ success: true, data: { css: purged, critical, meta: compiled.meta } });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Créer un test A/B (3 variations)
   * POST /api/templates/ab-test
   */
  async createABTest(req, res) {
    try {
      const { error, value } = Joi.object({
        baseTemplate: Joi.object().default({})
      }).validate(req.body);
      if (error) {
        return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: error.details[0].message });
      }
      const variants = await templateAIService.createABTestVariations(value.baseTemplate);
      return res.status(201).json({ success: true, data: variants });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Analytics de performance d'un template
   * GET /api/templates/analytics
   */
  async getAIAnalytics(req, res) {
    try {
      const { error, value } = Joi.object({
        templateId: Joi.string().required()
      }).validate(req.query);
      if (error) {
        return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: error.details[0].message });
      }
      const analytics = templateAIService.getTemplateAnalytics(value.templateId);
      return res.json({ success: true, data: analytics });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }

  /**
   * Optimisation automatique guidée par IA
   * PUT /api/templates/optimize
   */
  async optimizeTemplate(req, res) {
    try {
      const { error, value } = Joi.object({
        template: Joi.object().required(),
        performance: Joi.object().default({})
      }).validate(req.body);
      if (error) {
        return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: error.details[0].message });
      }
      const result = await templateAIService.optimizeTemplate(value.template, value.performance);
      return res.json({ success: true, data: result });
    } catch (error) {
      this.handleError(error, req, res);
    }
  }
}

module.exports = new TemplateController();
