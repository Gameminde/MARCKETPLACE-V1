const express = require('express');
const router = express.Router();
const templateController = require('../controllers/template.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/auth.middleware');

// ===== ROUTES TEMPLATES (Publiques) =====

/**
 * GET /api/templates
 * Récupérer tous les templates actifs
 * Accessible à tous
 */
router.get('/', templateController.getAllTemplates);

/**
 * GET /api/templates/popular
 * Récupérer les templates populaires
 * Accessible à tous
 */
router.get('/popular', templateController.getPopularTemplates);

/**
 * GET /api/templates/search
 * Rechercher des templates par critères
 * Accessible à tous
 */
router.get('/search', templateController.searchTemplates);

/**
 * GET /api/templates/:id
 * Récupérer un template par ID
 * Accessible à tous
 */
router.get('/:id', templateController.getTemplateById);

/**
 * POST /api/templates/:id/preview
 * Générer un preview de template
 * Accessible à tous
 */
router.post('/:id/preview', templateController.generateTemplatePreview);

/**
 * GET /api/templates/stats
 * Obtenir les statistiques des templates
 * Accessible à tous
 */
router.get('/stats', templateController.getTemplateStats);

// ===== ROUTES THÈMES (Publiques) =====

/**
 * GET /api/themes/color-palettes
 * Obtenir les palettes de couleurs disponibles
 * Accessible à tous
 */
router.get('/themes/color-palettes', templateController.getColorPalettes);

/**
 * GET /api/themes/fonts
 * Obtenir les polices disponibles
 * Accessible à tous
 */
router.get('/themes/fonts', templateController.getAvailableFonts);

/**
 * GET /api/themes/layouts
 * Obtenir les layouts disponibles
 * Accessible à tous
 */
router.get('/themes/layouts', templateController.getAvailableLayouts);

/**
 * POST /api/themes/apply-color-palette
 * Appliquer une palette de couleurs
 * Accessible à tous
 */
router.post('/themes/apply-color-palette', templateController.applyColorPalette);

/**
 * POST /api/themes/apply-font
 * Appliquer une configuration de police
 * Accessible à tous
 */
router.post('/themes/apply-font', templateController.applyFontPreset);

/**
 * POST /api/themes/apply-layout
 * Appliquer une configuration de layout
 * Accessible à tous
 */
router.post('/themes/apply-layout', templateController.applyLayoutPreset);

/**
 * POST /api/themes/generate-css
 * Générer du CSS personnalisé
 * Accessible à tous
 */
router.post('/themes/generate-css', templateController.generateCustomCSS);

/**
 * POST /api/themes/generate-preview
 * Générer un preview HTML personnalisé
 * Accessible à tous
 */
router.post('/themes/generate-preview', templateController.generateThemePreview);

// ===== ROUTES TEMPLATES (Authentifiées) =====

/**
 * POST /api/templates
 * Créer un nouveau template
 * Requiert authentification + rôle admin
 */
router.post('/', 
  authMiddleware, 
  requireRole('admin'), 
  templateController.createTemplate
);

/**
 * PUT /api/templates/:id
 * Mettre à jour un template existant
 * Requiert authentification + rôle admin
 */
router.put('/:id', 
  authMiddleware, 
  requireRole('admin'), 
  templateController.updateTemplate
);

/**
 * DELETE /api/templates/:id
 * Supprimer un template (soft delete)
 * Requiert authentification + rôle admin
 */
router.delete('/:id', 
  authMiddleware, 
  requireRole('admin'), 
  templateController.deleteTemplate
);

/**
 * POST /api/templates/import
 * Importer des templates depuis JSON
 * Requiert authentification + rôle admin
 */
router.post('/import', 
  authMiddleware, 
  requireRole('admin'), 
  templateController.importTemplates
);

// ===== MIDDLEWARE DE VALIDATION =====

// Validation des paramètres d'ID
router.param('id', (req, res, next, id) => {
  // Vérifier que l'ID est valide (format attendu)
  if (!/^[a-z0-9_-]+$/.test(id)) {
    return res.status(400).json({
      success: false,
      code: 'INVALID_TEMPLATE_ID',
      message: 'ID de template invalide. Format attendu: lettres minuscules, chiffres, tirets et underscores uniquement.'
    });
  }
  next();
});

// ===== GESTION D'ERREURS SPÉCIFIQUE AUX TEMPLATES =====

// Middleware pour gérer les erreurs 404 sur les routes de templates
router.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    code: 'TEMPLATE_ROUTE_NOT_FOUND',
    message: 'Route de template non trouvée',
    availableRoutes: [
      'GET /api/templates',
      'GET /api/templates/popular',
      'GET /api/templates/search',
      'GET /api/templates/:id',
      'POST /api/templates/:id/preview',
      'GET /api/templates/stats',
      'GET /api/themes/color-palettes',
      'GET /api/themes/fonts',
      'GET /api/themes/layouts',
      'POST /api/themes/apply-color-palette',
      'POST /api/themes/apply-font',
      'POST /api/themes/apply-layout',
      'POST /api/themes/generate-css',
      'POST /api/themes/generate-preview',
      'POST /api/templates (admin)',
      'PUT /api/templates/:id (admin)',
      'DELETE /api/templates/:id (admin)',
      'POST /api/templates/import (admin)'
    ]
  });
});

module.exports = router;



