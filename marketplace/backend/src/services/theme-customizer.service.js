const Joi = require('joi');
const redisClientService = require('./redis-client.service');
const structuredLogger = require('./structured-logger.service');

class ThemeCustomizerService {
  constructor() {
    this.cacheKeyPrefix = 'theme:';
    this.cacheTTL = 1800; // 30 minutes
    this.redisClient = null; // Initialisation lazy
    
    // Configuration des palettes de couleurs prédéfinies
    this.colorPalettes = {
      feminine: {
        primary: '#FF69B4',
        secondary: '#FFC0CB',
        accent: '#FF1493',
        background: '#FFF5F5',
        surface: '#FFFFFF',
        text: '#333333'
      },
      masculine: {
        primary: '#2C3E50',
        secondary: '#34495E',
        accent: '#3498DB',
        background: '#F8F9FA',
        surface: '#FFFFFF',
        text: '#2C3E50'
      },
      minimal: {
        primary: '#000000',
        secondary: '#666666',
        accent: '#333333',
        background: '#FFFFFF',
        surface: '#FAFAFA',
        text: '#000000'
      },
      urban: {
        primary: '#FF6B35',
        secondary: '#1A1A1A',
        accent: '#FFD23F',
        background: '#F8F8F8',
        surface: '#FFFFFF',
        text: '#1A1A1A'
      },
      neutral: {
        primary: '#4A90E2',
        secondary: '#7B7B7B',
        accent: '#50E3C2',
        background: '#F5F5F5',
        surface: '#FFFFFF',
        text: '#333333'
      }
    };

    // Configuration des polices prédéfinies
    this.fontFamilies = {
      poppins: {
        name: 'Poppins',
        weights: [300, 400, 500, 600, 700],
        category: 'sans-serif'
      },
      roboto: {
        name: 'Roboto',
        weights: [300, 400, 500, 700],
        category: 'sans-serif'
      },
      inter: {
        name: 'Inter',
        weights: [300, 400, 500, 600, 700],
        category: 'sans-serif'
      },
      oswald: {
        name: 'Oswald',
        weights: [300, 400, 500, 600, 700],
        category: 'sans-serif'
      },
      playfair: {
        name: 'Playfair Display',
        weights: [400, 500, 600, 700],
        category: 'serif'
      }
    };

    // Configuration des layouts prédéfinis
    this.layoutPresets = {
      compact: {
        spacing: 'compact',
        border_radius: 4,
        card_shadow: 'soft',
        max_width: 1000
      },
      comfortable: {
        spacing: 'comfortable',
        border_radius: 8,
        card_shadow: 'soft',
        max_width: 1200
      },
      spacious: {
        spacing: 'spacious',
        border_radius: 12,
        card_shadow: 'sharp',
        max_width: 1400
      }
    };
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
   * Schema de validation pour les customisations de thème
   */
  getCustomizationSchema() {
    return Joi.object({
      colors: Joi.object({
        primary: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
        secondary: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
        accent: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
        background: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
        surface: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
        text: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
        success: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
        warning: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
        error: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/)
      }),
      fonts: Joi.object({
        primary: Joi.string().valid(...Object.keys(this.fontFamilies)),
        secondary: Joi.string().valid(...Object.keys(this.fontFamilies)),
        heading_weight: Joi.number().integer().min(100).max(900),
        body_weight: Joi.number().integer().min(100).max(900),
        size_scale: Joi.number().min(0.8).max(2.0)
      }),
      layout: Joi.object({
        spacing: Joi.string().valid('compact', 'comfortable', 'spacious'),
        border_radius: Joi.number().integer().min(0).max(50),
        card_shadow: Joi.string().valid('none', 'soft', 'sharp', 'dramatic'),
        max_width: Joi.number().integer().min(320).max(1920),
        animation_style: Joi.string().valid('none', 'gentle', 'snappy', 'bouncy')
      }),
      branding: Joi.object({
        logo_url: Joi.string().uri(),
        favicon_url: Joi.string().uri(),
        hero_image_url: Joi.string().uri(),
        custom_css: Joi.string().max(10000)
      })
    });
  }

  /**
   * Valider les customisations de thème
   */
  validateCustomizations(customizations) {
    try {
      const schema = this.getCustomizationSchema();
      const { error, value } = schema.validate(customizations, { 
        abortEarly: false,
        allowUnknown: false
      });

      if (error) {
        const validationErrors = error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message,
          value: detail.context?.value
        }));

        throw new Error(`Validation des customisations échouée: ${JSON.stringify(validationErrors)}`);
      }

      return value;
    } catch (error) {
      structuredLogger.logError('THEME_CUSTOMIZATION_VALIDATION_ERROR', {
        error: error.message,
        customizations
      });
      throw error;
    }
  }

  /**
   * Appliquer une palette de couleurs prédéfinie
   */
  applyColorPalette(paletteName, baseCustomizations = {}) {
    try {
      if (!this.colorPalettes[paletteName]) {
        throw new Error(`Palette de couleurs '${paletteName}' non trouvée`);
      }

      const palette = this.colorPalettes[paletteName];
      
      return {
        ...baseCustomizations,
        colors: {
          ...baseCustomizations.colors,
          ...palette
        }
      };
    } catch (error) {
      structuredLogger.logError('THEME_COLOR_PALETTE_ERROR', {
        paletteName,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Appliquer une configuration de police prédéfinie
   */
  applyFontPreset(fontName, baseCustomizations = {}) {
    try {
      if (!this.fontFamilies[fontName]) {
        throw new Error(`Police '${fontName}' non trouvée`);
      }

      const font = this.fontFamilies[fontName];
      
      return {
        ...baseCustomizations,
        fonts: {
          ...baseCustomizations.fonts,
          primary: fontName,
          heading_weight: 600,
          body_weight: 400
        }
      };
    } catch (error) {
      structuredLogger.logError('THEME_FONT_PRESET_ERROR', {
        fontName,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Appliquer une configuration de layout prédéfinie
   */
  applyLayoutPreset(presetName, baseCustomizations = {}) {
    try {
      if (!this.layoutPresets[presetName]) {
        throw new Error(`Layout '${presetName}' non trouvé`);
      }

      const layout = this.layoutPresets[presetName];
      
      return {
        ...baseCustomizations,
        layout: {
          ...baseCustomizations.layout,
          ...layout
        }
      };
    } catch (error) {
      structuredLogger.logError('THEME_LAYOUT_PRESET_ERROR', {
        presetName,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Générer le CSS personnalisé pour un thème
   */
  generateCustomCSS(customizations, template = null) {
    try {
      const validatedCustomizations = this.validateCustomizations(customizations);
      
      let css = ':root {';
      
      // Variables de couleurs
      if (validatedCustomizations.colors) {
        Object.entries(validatedCustomizations.colors).forEach(([key, value]) => {
          if (value) {
            css += `\n  --${key}-color: ${value};`;
          }
        });
      }
      
      // Variables de polices
      if (validatedCustomizations.fonts) {
        if (validatedCustomizations.fonts.primary) {
          const font = this.fontFamilies[validatedCustomizations.fonts.primary];
          css += `\n  --font-primary: "${font.name}", ${font.category};`;
        }
        
        if (validatedCustomizations.fonts.secondary) {
          const font = this.fontFamilies[validatedCustomizations.fonts.secondary];
          css += `\n  --font-secondary: "${font.name}", ${font.category};`;
        }
        
        if (validatedCustomizations.fonts.heading_weight) {
          css += `\n  --font-heading-weight: ${validatedCustomizations.fonts.heading_weight};`;
        }
        
        if (validatedCustomizations.fonts.body_weight) {
          css += `\n  --font-body-weight: ${validatedCustomizations.fonts.body_weight};`;
        }
        
        if (validatedCustomizations.fonts.size_scale) {
          css += `\n  --font-size-scale: ${validatedCustomizations.fonts.size_scale};`;
        }
      }
      
      // Variables de layout
      if (validatedCustomizations.layout) {
        if (validatedCustomizations.layout.spacing) {
          css += `\n  --spacing: ${validatedCustomizations.layout.spacing};`;
        }
        
        if (validatedCustomizations.layout.border_radius) {
          css += `\n  --border-radius: ${validatedCustomizations.layout.border_radius}px;`;
        }
        
        if (validatedCustomizations.layout.max_width) {
          css += `\n  --max-width: ${validatedCustomizations.layout.max_width}px;`;
        }
        
        if (validatedCustomizations.layout.animation_style) {
          css += `\n  --animation-style: ${validatedCustomizations.layout.animation_style};`;
        }
      }
      
      css += '\n}';
      
      // CSS personnalisé additionnel
      if (validatedCustomizations.branding?.custom_css) {
        css += '\n' + validatedCustomizations.branding.custom_css;
      }
      
      // CSS spécifique au template si fourni
      if (template) {
        css += this.generateTemplateSpecificCSS(template, validatedCustomizations);
      }
      
      // CSS responsive et animations
      css += this.generateResponsiveCSS(validatedCustomizations);
      css += this.generateAnimationCSS(validatedCustomizations);
      
      return css;
    } catch (error) {
      structuredLogger.logError('THEME_CSS_GENERATION_ERROR', {
        error: error.message,
        customizations
      });
      throw error;
    }
  }

  /**
   * Générer le CSS spécifique au template
   */
  generateTemplateSpecificCSS(template, customizations) {
    let css = '';
    
    // Styles spécifiques selon le type de template
    if (template.layout?.grid_system === 'asymmetrical') {
      css += `
.template-asymmetrical .product-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  grid-template-areas: 
    "hero hero hero"
    "main sidebar sidebar"
    "main sidebar sidebar";
  gap: var(--spacing, 20px);
}

.template-asymmetrical .hero-section {
  grid-area: hero;
}

.template-asymmetrical .main-content {
  grid-area: main;
}

.template-asymmetrical .sidebar {
  grid-area: sidebar;
}`;
    }
    
    if (template.layout?.grid_system === 'geometric') {
      css += `
.template-geometric .product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: calc(var(--spacing, 20px) * 1.5);
}

.template-geometric .product-card {
  border: 2px solid var(--secondary-color);
  clip-path: polygon(0 0, 100% 0, 95% 100%, 5% 100%);
}`;
    }
    
    return css;
  }

  /**
   * Générer le CSS responsive
   */
  generateResponsiveCSS(customizations) {
    return `
@media (max-width: 768px) {
  :root {
    --max-width: 100%;
    --spacing: compact;
  }
  
  .product-grid {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  
  .hero-section {
    padding: 20px;
  }
}

@media (max-width: 480px) {
  :root {
    --border-radius: 4px;
  }
  
  .product-card {
    padding: 15px;
  }
}`;
  }

  /**
   * Générer le CSS des animations
   */
  generateAnimationCSS(customizations) {
    const animationStyle = customizations.layout?.animation_style || 'gentle';
    
    const animations = {
      gentle: `
.product-card {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.product-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 20px rgba(0,0,0,0.1);
}`,
      
      snappy: `
.product-card {
  transition: all 0.15s ease-out;
}

.product-card:hover {
  transform: translateY(-4px) scale(1.02);
  box-shadow: 0 8px 25px rgba(0,0,0,0.15);
}`,
      
      bouncy: `
.product-card {
  transition: all 0.4s cubic-bezier(0.68, -0.55, 0.265, 1.55);
}

.product-card:hover {
  transform: translateY(-6px) scale(1.05);
  box-shadow: 0 12px 30px rgba(0,0,0,0.2);
}`,
      
      none: `
.product-card {
  transition: none;
}

.product-card:hover {
  transform: none;
  box-shadow: none;
}`
    };
    
    return animations[animationStyle] || animations.gentle;
  }

  /**
   * Générer un preview HTML avec les customisations
   */
  generatePreviewHTML(customizations, template = null) {
    try {
      const validatedCustomizations = this.validateCustomizations(customizations);
      
      const primaryFont = validatedCustomizations.fonts?.primary || 'inter';
      const font = this.fontFamilies[primaryFont];
      
      let html = `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Preview Thème Personnalisé</title>
    <link href="https://fonts.googleapis.com/css2?family=${font.name}:wght@300,400,500,600,700&display=swap" rel="stylesheet">
    <style id="custom-theme-css"></style>
</head>
<body>
    <div class="theme-preview">
        <header class="preview-header">
            <h1>Votre Boutique</h1>
            <p>Prévisualisation du thème personnalisé</p>
        </header>
        
        <main class="preview-content">
            <section class="preview-hero">
                <h2>Bienvenue dans votre boutique</h2>
                <p>Découvrez nos produits exceptionnels</p>
                <button class="cta-button">Commencer</button>
            </section>
            
            <section class="preview-products">
                <h2>Nos Produits</h2>
                <div class="product-grid">
                    <div class="product-card">
                        <div class="product-image"></div>
                        <h3>Produit Premium</h3>
                        <p>Description du produit</p>
                        <span class="price">€49.99</span>
                    </div>
                    <div class="product-card">
                        <div class="product-image"></div>
                        <h3>Produit Standard</h3>
                        <p>Description du produit</p>
                        <span class="price">€29.99</span>
                    </div>
                    <div class="product-card">
                        <div class="product-image"></div>
                        <h3>Produit Basique</h3>
                        <p>Description du produit</p>
                        <span class="price">€19.99</span>
                    </div>
                </div>
            </section>
        </main>
        
        <footer class="preview-footer">
            <p>&copy; 2024 Votre Boutique</p>
        </footer>
    </div>
    
    <script>
        // Injection du CSS personnalisé
        document.addEventListener('DOMContentLoaded', function() {
            const styleElement = document.getElementById('custom-theme-css');
            // Le CSS sera injecté par le service
        });
    </script>
</body>
</html>`;
      
      return html;
    } catch (error) {
      structuredLogger.logError('THEME_PREVIEW_HTML_ERROR', {
        error: error.message,
        customizations
      });
      throw error;
    }
  }

  /**
   * Obtenir les palettes de couleurs disponibles
   */
  getAvailableColorPalettes() {
    return Object.keys(this.colorPalettes).map(key => ({
      id: key,
      name: this.getPaletteDisplayName(key),
      colors: this.colorPalettes[key],
      description: this.getPaletteDescription(key)
    }));
  }

  /**
   * Obtenir les polices disponibles
   */
  getAvailableFonts() {
    return Object.entries(this.fontFamilies).map(([key, font]) => ({
      id: key,
      name: font.name,
      weights: font.weights,
      category: font.category,
      description: this.getFontDescription(key)
    }));
  }

  /**
   * Obtenir les layouts disponibles
   */
  getAvailableLayouts() {
    return Object.keys(this.layoutPresets).map(key => ({
      id: key,
      name: this.getLayoutDisplayName(key),
      config: this.layoutPresets[key],
      description: this.getLayoutDescription(key)
    }));
  }

  /**
   * Obtenir le nom d'affichage d'une palette
   */
  getPaletteDisplayName(paletteKey) {
    const names = {
      feminine: 'Féminin & Élégant',
      masculine: 'Masculin & Moderne',
      minimal: 'Minimal & Épuré',
      urban: 'Urbain & Dynamique',
      neutral: 'Neutre & Polyvalent'
    };
    return names[paletteKey] || paletteKey;
  }

  /**
   * Obtenir la description d'une palette
   */
  getPaletteDescription(paletteKey) {
    const descriptions = {
      feminine: 'Palette douce et romantique, parfaite pour la mode et la beauté',
      masculine: 'Palette professionnelle et moderne, idéale pour la tech et le business',
      minimal: 'Palette épurée et élégante, pour un design minimaliste',
      urban: 'Palette énergique et contemporaine, parfaite pour le streetwear',
      neutral: 'Palette équilibrée et polyvalente, s\'adapte à tous les secteurs'
    };
    return descriptions[paletteKey] || 'Description non disponible';
  }

  /**
   * Obtenir le nom d'affichage d'une police
   */
  getFontDisplayName(fontKey) {
    const names = {
      poppins: 'Poppins - Moderne & Élégant',
      roboto: 'Roboto - Professionnel & Lisible',
      inter: 'Inter - Contemporain & Flexible',
      oswald: 'Oswald - Impact & Dynamique',
      playfair: 'Playfair Display - Classique & Sophistiqué'
    };
    return names[fontKey] || fontKey;
  }

  /**
   * Obtenir la description d'une police
   */
  getFontDescription(fontKey) {
    const descriptions = {
      poppins: 'Police moderne avec des formes géométriques douces, parfaite pour les titres',
      roboto: 'Police sans-serif très lisible, excellente pour le contenu principal',
      inter: 'Police contemporaine optimisée pour l\'écran, très polyvalente',
      oswald: 'Police condensée avec un impact visuel fort, idéale pour les headers',
      playfair: 'Police serif élégante et sophistiquée, parfaite pour le luxe'
    };
    return descriptions[fontKey] || 'Description non disponible';
  }

  /**
   * Obtenir le nom d'affichage d'un layout
   */
  getLayoutDisplayName(layoutKey) {
    const names = {
      compact: 'Compact - Optimisé pour la densité',
      comfortable: 'Confortable - Équilibre parfait',
      spacious: 'Spacieux - Respiration maximale'
    };
    return names[layoutKey] || layoutKey;
  }

  /**
   * Obtenir la description d'un layout
   */
  getLayoutDescription(layoutKey) {
    const descriptions = {
      compact: 'Layout dense pour maximiser le contenu visible',
      comfortable: 'Layout équilibré pour une lecture agréable',
      spacious: 'Layout aéré pour une expérience premium'
    };
    return descriptions[layoutKey] || 'Description non disponible';
  }

  // Méthodes de cache Redis
  async getFromCache(key) {
    try {
      const client = this._getRedisClient();
      if (!client) return null;
      
      const cached = await client.get(key);
      return cached ? JSON.parse(cached) : null;
    } catch (error) {
      structuredLogger.logWarn('THEME_CACHE_READ_ERROR', { key, error: error.message });
      return null;
    }
  }

  async setCache(key, data, ttl = this.cacheTTL) {
    try {
      const client = this._getRedisClient();
      if (!client) return;
      
      await client.setex(key, ttl, JSON.stringify(data));
    } catch (error) {
      structuredLogger.logWarn('THEME_CACHE_WRITE_ERROR', { key, error: error.message });
    }
  }

  async invalidateCache() {
    try {
      const client = this._getRedisClient();
      if (!client) return;
      
      const keys = await client.keys(`${this.cacheKeyPrefix}*`);
      if (keys.length > 0) {
        await client.del(...keys);
        structuredLogger.logInfo('THEME_CACHE_INVALIDATED', { keysCount: keys.length });
      }
    } catch (error) {
      structuredLogger.logWarn('THEME_CACHE_INVALIDATION_ERROR', { error: error.message });
    }
  }
}

module.exports = new ThemeCustomizerService();
