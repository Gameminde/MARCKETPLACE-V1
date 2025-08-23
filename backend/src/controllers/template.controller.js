const templateService = require('../services/template.service');
const themeCustomizerService = require('../services/theme-customizer.service');
const structuredLogger = require('../services/structured-logger.service');

class TemplateController {
  /**
   * Récupérer tous les templates
   * GET /api/templates
   */
  async getAllTemplates(req, res) {
    try {
      const { 
        tags, 
        persona, 
        sortBy, 
        limit, 
        page 
      } = req.query;

      const options = {
        tags: tags ? tags.split(',') : undefined,
        persona,
        sortBy,
        limit: limit ? parseInt(limit) : undefined,
        page: page ? parseInt(page) : undefined
      };

      const templates = await templateService.getAllTemplates(options);
      
      structuredLogger.logInfo('TEMPLATE_FETCH_ALL', { 
        userId: req.user?.sub, 
        count: templates.length,
        filters: options
      });

      res.json({
        success: true,
        data: templates,
        count: templates.length
      });
    } catch (error) {
      structuredLogger.logError('TEMPLATE_FETCH_ALL_ERROR', {
        userId: req.user?.sub,
        error: error.message
      });

      res.status(500).json({
        success: false,
        code: 'TEMPLATE_FETCH_ERROR',
        message: 'Erreur lors de la récupération des templates',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Récupérer un template par ID
   * GET /api/templates/:id
   */
  async getTemplateById(req, res) {
    try {
      const { id } = req.params;
      
      const template = await templateService.getTemplateById(id);
      
      structuredLogger.logInfo('TEMPLATE_FETCH_BY_ID', { 
        userId: req.user?.sub, 
        templateId: id 
      });

      res.json({
        success: true,
        data: template
      });
    } catch (error) {
      structuredLogger.logError('TEMPLATE_FETCH_BY_ID_ERROR', {
        userId: req.user?.sub,
        templateId: req.params.id,
        error: error.message
      });

      if (error.message.includes('non trouvé')) {
        return res.status(404).json({
          success: false,
          code: 'TEMPLATE_NOT_FOUND',
          message: 'Template non trouvé'
        });
      }

      res.status(500).json({
        success: false,
        code: 'TEMPLATE_FETCH_ERROR',
        message: 'Erreur lors de la récupération du template',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Récupérer les templates populaires
   * GET /api/templates/popular
   */
  async getPopularTemplates(req, res) {
    try {
      const { limit = 10 } = req.query;
      
      const templates = await templateService.getPopularTemplates(parseInt(limit));
      
      structuredLogger.logInfo('TEMPLATE_FETCH_POPULAR', { 
        userId: req.user?.sub, 
        limit: parseInt(limit),
        count: templates.length
      });

      res.json({
        success: true,
        data: templates,
        count: templates.length
      });
    } catch (error) {
      structuredLogger.logError('TEMPLATE_FETCH_POPULAR_ERROR', {
        userId: req.user?.sub,
        error: error.message
      });

      res.status(500).json({
        success: false,
        code: 'TEMPLATE_POPULAR_ERROR',
        message: 'Erreur lors de la récupération des templates populaires',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Rechercher des templates
   * GET /api/templates/search
   */
  async searchTemplates(req, res) {
    try {
      const {
        query,
        tags,
        persona,
        layout,
        colors,
        sortBy,
        limit = 20,
        page = 1
      } = req.query;

      const searchCriteria = {
        query,
        tags: tags ? tags.split(',') : undefined,
        persona,
        layout,
        colors: colors ? colors.split(',') : undefined,
        sortBy,
        limit: parseInt(limit),
        page: parseInt(page)
      };

      const result = await templateService.searchTemplates(searchCriteria);
      
      structuredLogger.logInfo('TEMPLATE_SEARCH', { 
        userId: req.user?.sub, 
        query,
        results: result.templates.length,
        total: result.pagination.total
      });

      res.json({
        success: true,
        data: result.templates,
        pagination: result.pagination
      });
    } catch (error) {
      structuredLogger.logError('TEMPLATE_SEARCH_ERROR', {
        userId: req.user?.sub,
        searchCriteria: req.query,
        error: error.message
      });

      res.status(500).json({
        success: false,
        code: 'TEMPLATE_SEARCH_ERROR',
        message: 'Erreur lors de la recherche de templates',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Créer un nouveau template
   * POST /api/templates
   */
  async createTemplate(req, res) {
    try {
      const templateData = req.body;
      const createdBy = req.user?.sub || 'system';
      
      const template = await templateService.createTemplate(templateData, createdBy);
      
      structuredLogger.logInfo('TEMPLATE_CREATED', { 
        userId: req.user?.sub, 
        templateId: template.id,
        createdBy
      });

      res.status(201).json({
        success: true,
        message: 'Template créé avec succès',
        data: template
      });
    } catch (error) {
      structuredLogger.logError('TEMPLATE_CREATE_ERROR', {
        userId: req.user?.sub,
        templateData: req.body,
        error: error.message
      });

      if (error.message.includes('Validation')) {
        return res.status(400).json({
          success: false,
          code: 'TEMPLATE_VALIDATION_ERROR',
          message: 'Données de template invalides',
          error: error.message
        });
      }

      res.status(500).json({
        success: false,
        code: 'TEMPLATE_CREATE_ERROR',
        message: 'Erreur lors de la création du template',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Mettre à jour un template
   * PUT /api/templates/:id
   */
  async updateTemplate(req, res) {
    try {
      const { id } = req.params;
      const updateData = req.body;
      const updatedBy = req.user?.sub || 'system';
      
      const template = await templateService.updateTemplate(id, updateData, updatedBy);
      
      structuredLogger.logInfo('TEMPLATE_UPDATED', { 
        userId: req.user?.sub, 
        templateId: id,
        updatedBy
      });

      res.json({
        success: true,
        message: 'Template mis à jour avec succès',
        data: template
      });
    } catch (error) {
      structuredLogger.logError('TEMPLATE_UPDATE_ERROR', {
        userId: req.user?.sub,
        templateId: req.params.id,
        updateData: req.body,
        error: error.message
      });

      if (error.message.includes('non trouvé')) {
        return res.status(404).json({
          success: false,
          code: 'TEMPLATE_NOT_FOUND',
          message: 'Template non trouvé'
        });
      }

      if (error.message.includes('Validation')) {
        return res.status(400).json({
          success: false,
          code: 'TEMPLATE_VALIDATION_ERROR',
          message: 'Données de mise à jour invalides',
          error: error.message
        });
      }

      res.status(500).json({
        success: false,
        code: 'TEMPLATE_UPDATE_ERROR',
        message: 'Erreur lors de la mise à jour du template',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Supprimer un template
   * DELETE /api/templates/:id
   */
  async deleteTemplate(req, res) {
    try {
      const { id } = req.params;
      const deletedBy = req.user?.sub || 'system';
      
      const result = await templateService.deleteTemplate(id, deletedBy);
      
      structuredLogger.logInfo('TEMPLATE_DELETED', { 
        userId: req.user?.sub, 
        templateId: id,
        deletedBy
      });

      res.json({
        success: true,
        message: result.message,
        data: result
      });
    } catch (error) {
      structuredLogger.logError('TEMPLATE_DELETE_ERROR', {
        userId: req.user?.sub,
        templateId: req.params.id,
        error: error.message
      });

      if (error.message.includes('non trouvé')) {
        return res.status(404).json({
          success: false,
          code: 'TEMPLATE_NOT_FOUND',
          message: 'Template non trouvé'
        });
      }

      res.status(500).json({
        success: false,
        code: 'TEMPLATE_DELETE_ERROR',
        message: 'Erreur lors de la suppression du template',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
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
      
      structuredLogger.logInfo('TEMPLATE_PREVIEW_GENERATED', { 
        userId: req.user?.sub, 
        templateId: id,
        customizations: Object.keys(customizations)
      });

      res.json({
        success: true,
        data: preview
      });
    } catch (error) {
      structuredLogger.logError('TEMPLATE_PREVIEW_ERROR', {
        userId: req.user?.sub,
        templateId: req.params.id,
        customizations: req.body.customizations,
        error: error.message
      });

      if (error.message.includes('non trouvé')) {
        return res.status(404).json({
          success: false,
          code: 'TEMPLATE_NOT_FOUND',
          message: 'Template non trouvé'
        });
      }

      res.status(500).json({
        success: false,
        code: 'TEMPLATE_PREVIEW_ERROR',
        message: 'Erreur lors de la génération du preview',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Obtenir les statistiques des templates
   * GET /api/templates/stats
   */
  async getTemplateStats(req, res) {
    try {
      const stats = await templateService.getTemplateStats();
      
      structuredLogger.logInfo('TEMPLATE_STATS_FETCHED', { 
        userId: req.user?.sub 
      });

      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      structuredLogger.logError('TEMPLATE_STATS_ERROR', {
        userId: req.user?.sub,
        error: error.message
      });

      res.status(500).json({
        success: false,
        code: 'TEMPLATE_STATS_ERROR',
        message: 'Erreur lors de la récupération des statistiques',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
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
      
      structuredLogger.logInfo('TEMPLATE_IMPORT_COMPLETED', { 
        userId: req.user?.sub, 
        importedBy,
        results
      });

      res.json({
        success: true,
        message: 'Import des templates terminé',
        data: results
      });
    } catch (error) {
      structuredLogger.logError('TEMPLATE_IMPORT_ERROR', {
        userId: req.user?.sub,
        templatesCount: req.body.templates?.length,
        error: error.message
      });

      res.status(500).json({
        success: false,
        code: 'TEMPLATE_IMPORT_ERROR',
        message: 'Erreur lors de l\'import des templates',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
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
      
      structuredLogger.logInfo('THEME_COLOR_PALETTES_FETCHED', { 
        userId: req.user?.sub,
        count: palettes.length
      });

      res.json({
        success: true,
        data: palettes,
        count: palettes.length
      });
    } catch (error) {
      structuredLogger.logError('THEME_COLOR_PALETTES_ERROR', {
        userId: req.user?.sub,
        error: error.message
      });

      res.status(500).json({
        success: false,
        code: 'THEME_COLOR_PALETTES_ERROR',
        message: 'Erreur lors de la récupération des palettes de couleurs',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Obtenir les polices disponibles
   * GET /api/themes/fonts
   */
  async getAvailableFonts(req, res) {
    try {
      const fonts = themeCustomizerService.getAvailableFonts();
      
      structuredLogger.logInfo('THEME_FONTS_FETCHED', { 
        userId: req.user?.sub,
        count: fonts.length
      });

      res.json({
        success: true,
        data: fonts,
        count: fonts.length
      });
    } catch (error) {
      structuredLogger.logError('THEME_FONTS_ERROR', {
        userId: req.user?.sub,
        error: error.message
      });

      res.status(500).json({
        success: false,
        code: 'THEME_FONTS_ERROR',
        message: 'Erreur lors de la récupération des polices',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Obtenir les layouts disponibles
   * GET /api/themes/layouts
   */
  async getAvailableLayouts(req, res) {
    try {
      const layouts = themeCustomizerService.getAvailableLayouts();
      
      structuredLogger.logInfo('THEME_LAYOUTS_FETCHED', { 
        userId: req.user?.sub,
        count: layouts.length
      });

      res.json({
        success: true,
        data: layouts,
        count: layouts.length
      });
    } catch (error) {
      structuredLogger.logError('THEME_LAYOUTS_ERROR', {
        userId: req.user?.sub,
        error: error.message
      });

      res.status(500).json({
        success: false,
        code: 'THEME_LAYOUTS_ERROR',
        message: 'Erreur lors de la récupération des layouts',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
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
      
      structuredLogger.logInfo('THEME_COLOR_PALETTE_APPLIED', { 
        userId: req.user?.sub,
        paletteName
      });

      res.json({
        success: true,
        message: `Palette '${paletteName}' appliquée avec succès`,
        data: result
      });
    } catch (error) {
      structuredLogger.logError('THEME_COLOR_PALETTE_APPLY_ERROR', {
        userId: req.user?.sub,
        paletteName: req.body.paletteName,
        error: error.message
      });

      if (error.message.includes('non trouvée')) {
        return res.status(404).json({
          success: false,
          code: 'PALETTE_NOT_FOUND',
          message: error.message
        });
      }

      res.status(500).json({
        success: false,
        code: 'THEME_COLOR_PALETTE_APPLY_ERROR',
        message: 'Erreur lors de l\'application de la palette',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
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
      
      structuredLogger.logInfo('THEME_FONT_APPLIED', { 
        userId: req.user?.sub,
        fontName
      });

      res.json({
        success: true,
        message: `Police '${fontName}' appliquée avec succès`,
        data: result
      });
    } catch (error) {
      structuredLogger.logError('THEME_FONT_APPLY_ERROR', {
        userId: req.user?.sub,
        fontName: req.body.fontName,
        error: error.message
      });

      if (error.message.includes('non trouvée')) {
        return res.status(404).json({
          success: false,
          code: 'FONT_NOT_FOUND',
          message: error.message
        });
      }

      res.status(500).json({
        success: false,
        code: 'THEME_FONT_APPLY_ERROR',
        message: 'Erreur lors de l\'application de la police',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
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
      
      structuredLogger.logInfo('THEME_LAYOUT_APPLIED', { 
        userId: req.user?.sub,
        presetName
      });

      res.json({
        success: true,
        message: `Layout '${presetName}' appliqué avec succès`,
        data: result
      });
    } catch (error) {
      structuredLogger.logError('THEME_LAYOUT_APPLY_ERROR', {
        userId: req.user?.sub,
        presetName: req.body.presetName,
        error: error.message
      });

      if (error.message.includes('non trouvé')) {
        return res.status(404).json({
          success: false,
          code: 'LAYOUT_NOT_FOUND',
          message: error.message
        });
      }

      res.status(500).json({
        success: false,
        code: 'THEME_LAYOUT_APPLY_ERROR',
        message: 'Erreur lors de l\'application du layout',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
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
      
      structuredLogger.logInfo('THEME_CSS_GENERATED', { 
        userId: req.user?.sub,
        templateId,
        customizations: Object.keys(customizations)
      });

      res.json({
        success: true,
        data: {
          css,
          customizations: themeCustomizerService.validateCustomizations(customizations)
        }
      });
    } catch (error) {
      structuredLogger.logError('THEME_CSS_GENERATION_ERROR', {
        userId: req.user?.sub,
        customizations: req.body.customizations,
        templateId: req.body.templateId,
        error: error.message
      });

      if (error.message.includes('Validation')) {
        return res.status(400).json({
          success: false,
          code: 'THEME_VALIDATION_ERROR',
          message: 'Customisations invalides',
          error: error.message
        });
      }

      res.status(500).json({
        success: false,
        code: 'THEME_CSS_GENERATION_ERROR',
        message: 'Erreur lors de la génération du CSS',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
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

      const html = themeCustomizerService.generatePreviewHTML(customizations, template);
      const css = themeCustomizerService.generateCustomCSS(customizations, template);
      
      structuredLogger.logInfo('THEME_PREVIEW_GENERATED', { 
        userId: req.user?.sub,
        templateId,
        customizations: Object.keys(customizations)
      });

      res.json({
        success: true,
        data: {
          html,
          css,
          customizations: themeCustomizerService.validateCustomizations(customizations)
        }
      });
    } catch (error) {
      structuredLogger.logError('THEME_PREVIEW_GENERATION_ERROR', {
        userId: req.user?.sub,
        customizations: req.body.customizations,
        templateId: req.body.templateId,
        error: error.message
      });

      if (error.message.includes('Validation')) {
        return res.status(400).json({
          success: false,
          code: 'THEME_VALIDATION_ERROR',
          message: 'Customisations invalides',
          error: error.message
        });
      }

      res.status(500).json({
        success: false,
        code: 'THEME_PREVIEW_GENERATION_ERROR',
        message: 'Erreur lors de la génération du preview',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = new TemplateController();
