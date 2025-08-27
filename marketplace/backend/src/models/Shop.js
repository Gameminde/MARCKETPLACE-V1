const mongoose = require('mongoose');
const Joi = require('joi');

// Schema de validation Joi pour les boutiques
const shopValidationSchema = Joi.object({
  name: Joi.string().required().min(2).max(100),
  slug: Joi.string().required().min(3).max(50).pattern(/^[a-z0-9-]+$/),
  description: Joi.string().max(1000),
  owner_id: Joi.string().required(),
  template_id: Joi.string().required(),
  customizations: Joi.object({
    colors: Joi.object({
      primary: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
      secondary: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
      accent: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
      background: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
      surface: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
      text: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/)
    }),
    fonts: Joi.object({
      primary: Joi.string().max(50),
      secondary: Joi.string().max(50),
      heading_weight: Joi.number().integer().min(100).max(900),
      body_weight: Joi.number().integer().min(100).max(900)
    }),
    layout: Joi.object({
      spacing: Joi.string().valid('compact', 'comfortable', 'spacious'),
      border_radius: Joi.number().integer().min(0).max(50),
      card_shadow: Joi.string().valid('none', 'soft', 'sharp', 'dramatic'),
      max_width: Joi.number().integer().min(320).max(1920)
    }),
    branding: Joi.object({
      logo_url: Joi.string().uri(),
      favicon_url: Joi.string().uri(),
      hero_image_url: Joi.string().uri(),
      custom_css: Joi.string().max(10000).custom((value, helpers) => {
        if (value && typeof value === 'string') {
          // Sanitisation CSS complète - bloquer TOUTES les propriétés dangereuses
          const dangerousCSS = [
            'javascript:', 'vbscript:', 'expression(', 'eval(', 'import(', 'url(',
            'behavior:', 'binding:', 'filter:', 'progid:', 'mso-', 'zoom:',
            'expression', 'javascript', 'vbscript', 'onload', 'onerror', 'onclick',
            'onmouseover', 'onfocus', 'onblur', 'onchange', 'onsubmit',
            'background-image:url(', 'background:url(', 'list-style-image:url(',
            'cursor:url(', 'border-image:url(', 'content:url(',
            'calc(', 'attr(', 'counter(', 'counters(', 'var(',
            'linear-gradient(', 'radial-gradient(', 'conic-gradient(',
            'repeating-linear-gradient', 'repeating-radial-gradient'
          ];
          
          const lowerValue = value.toLowerCase();
          for (const dangerous of dangerousCSS) {
            if (lowerValue.includes(dangerous)) {
              return helpers.error('custom_css.dangerous_property');
            }
          }
          
          // Bloquer les URLs externes (seulement data: et relative)
          if (lowerValue.includes('url(') && 
              !lowerValue.includes('url("data:') && 
              !lowerValue.includes('url(\'data:') &&
              !lowerValue.includes('url(./') &&
              !lowerValue.includes('url(../') &&
              !lowerValue.includes('url(/')) {
            return helpers.error('custom_css.external_url');
          }
          
          // Bloquer les propriétés CSS dangereuses
          const dangerousProperties = [
            'position:fixed', 'position:absolute', 'z-index:999999',
            'opacity:0', 'visibility:hidden', 'display:none',
            'clip:rect(', 'overflow:hidden', 'text-indent:-9999px'
          ];
          
          for (const prop of dangerousProperties) {
            if (lowerValue.includes(prop)) {
              return helpers.error('custom_css.dangerous_property');
            }
          }
        }
        return value;
      }, 'CSS sanitization')
    })
  }),
  settings: Joi.object({
    is_public: Joi.boolean().default(true),
    allow_reviews: Joi.boolean().default(true),
    require_approval: Joi.boolean().default(false),
    auto_publish: Joi.boolean().default(true),
    seo_enabled: Joi.boolean().default(true),
    analytics_enabled: Joi.boolean().default(true)
  }),
  contact: Joi.object({
    email: Joi.string().email(),
    phone: Joi.string().max(20),
    address: Joi.object({
      street: Joi.string().max(200),
      city: Joi.string().max(100),
      state: Joi.string().max(100),
      country: Joi.string().max(100),
      postal_code: Joi.string().max(20)
    }),
    social_media: Joi.object({
      facebook: Joi.string().uri(),
      instagram: Joi.string().uri(),
      twitter: Joi.string().uri(),
      linkedin: Joi.string().uri()
    })
  }),
  categories: Joi.array().items(Joi.string().max(100)),
  tags: Joi.array().items(Joi.string().max(50)),
  status: Joi.string().valid('draft', 'active', 'suspended', 'archived').default('draft')
});

// Schema MongoDB pour les boutiques
const shopSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  slug: {
    type: String,
    required: true,
    unique: true,
    index: true,
    validate: {
      validator: function(v) {
        return /^[a-z0-9-]+$/.test(v);
      },
      message: 'Slug doit contenir uniquement des lettres minuscules, chiffres et tirets'
    }
  },
  description: {
    type: String,
    maxlength: 1000,
    trim: true
  },
  owner_id: {
    type: String,
    required: true,
    index: true
  },
  template_id: {
    type: String,
    required: true,
    ref: 'Template',
    index: true
  },
  customizations: {
    colors: {
      primary: {
        type: String,
        validate: {
          validator: function(v) {
            return !v || /^#[0-9A-Fa-f]{6}$/.test(v);
          },
          message: 'Couleur primaire doit être un code hexadécimal valide'
        }
      },
      secondary: {
        type: String,
        validate: {
          validator: function(v) {
            return !v || /^#[0-9A-Fa-f]{6}$/.test(v);
          },
          message: 'Couleur secondaire doit être un code hexadécimal valide'
        }
      },
      accent: {
        type: String,
        validate: {
          validator: function(v) {
            return !v || /^#[0-9A-Fa-f]{6}$/.test(v);
          },
          message: 'Couleur d\'accent doit être un code hexadécimal valide'
        }
      },
      background: {
        type: String,
        validate: {
          validator: function(v) {
            return !v || /^#[0-9A-Fa-f]{6}$/.test(v);
          },
          message: 'Couleur de fond doit être un code hexadécimal valide'
        }
      },
      surface: {
        type: String,
        validate: {
          validator: function(v) {
            return !v || /^#[0-9A-Fa-f]{6}$/.test(v);
          },
          message: 'Couleur de surface doit être un code hexadécimal valide'
        }
      },
      text: {
        type: String,
        validate: {
          validator: function(v) {
            return !v || /^#[0-9A-Fa-f]{6}$/.test(v);
          },
          message: 'Couleur de texte doit être un code hexadécimal valide'
        }
      }
    },
    fonts: {
      primary: {
        type: String,
        maxlength: 50
      },
      secondary: {
        type: String,
        maxlength: 50
      },
      heading_weight: {
        type: Number,
        min: 100,
        max: 900
      },
      body_weight: {
        type: Number,
        min: 100,
        max: 900
      }
    },
    layout: {
      spacing: {
        type: String,
        enum: ['compact', 'comfortable', 'spacious']
      },
      border_radius: {
        type: Number,
        min: 0,
        max: 50
      },
      card_shadow: {
        type: String,
        enum: ['none', 'soft', 'sharp', 'dramatic']
      },
      max_width: {
        type: Number,
        min: 320,
        max: 1920
      }
    },
    branding: {
      logo_url: {
        type: String,
        validate: {
          validator: function(v) {
            return !v || /^https?:\/\/.+/.test(v);
          },
          message: 'Logo URL doit être une URL valide'
        }
      },
      favicon_url: {
        type: String,
        validate: {
          validator: function(v) {
            return !v || /^https?:\/\/.+/.test(v);
          },
          message: 'Favicon URL doit être une URL valide'
        }
      },
      hero_image_url: {
        type: String,
        validate: {
          validator: function(v) {
            return !v || /^https?:\/\/.+/.test(v);
          },
          message: 'Hero image URL doit être une URL valide'
        }
      },
              custom_css: {
          type: String,
          maxlength: 10000,
          validate: {
            validator: function(v) {
              if (!v) return true;
              
              // Sanitisation CSS - bloquer les propriétés dangereuses
              const dangerousCSS = [
                'javascript:', 'expression(', 'eval(', 'import(', 'url(',
                'behavior:', 'binding:', 'filter:', 'progid:', 'mso-',
                'expression', 'javascript', 'vbscript', 'onload', 'onerror'
              ];
              
              const lowerValue = v.toLowerCase();
              for (const dangerous of dangerousCSS) {
                if (lowerValue.includes(dangerous)) {
                  return false;
                }
              }
              
              // Bloquer les URLs externes
              if (lowerValue.includes('url(') && !lowerValue.includes('url("data:')) {
                return false;
              }
              
              return true;
            },
            message: 'CSS contains dangerous properties or external URLs'
          }
        }
    }
  },
  settings: {
    is_public: {
      type: Boolean,
      default: true,
      index: true
    },
    allow_reviews: {
      type: Boolean,
      default: true
    },
    require_approval: {
      type: Boolean,
      default: false
    },
    auto_publish: {
      type: Boolean,
      default: true
    },
    seo_enabled: {
      type: Boolean,
      default: true
    },
    analytics_enabled: {
      type: Boolean,
      default: true
    }
  },
  contact: {
    email: {
      type: String,
      validate: {
        validator: function(v) {
          return !v || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
        },
        message: 'Email doit être valide'
      }
    },
    phone: {
      type: String,
      maxlength: 20
    },
    address: {
      street: {
        type: String,
        maxlength: 200
      },
      city: {
        type: String,
        maxlength: 100
      },
      state: {
        type: String,
        maxlength: 100
      },
      country: {
        type: String,
        maxlength: 100
      },
      postal_code: {
        type: String,
        maxlength: 20
      }
    },
    social_media: {
      facebook: String,
      instagram: String,
      twitter: String,
      linkedin: String
    }
  },
  categories: [{
    type: String,
    maxlength: 100
  }],
  tags: [{
    type: String,
    maxlength: 50
  }],
  status: {
    type: String,
    enum: ['draft', 'active', 'suspended', 'archived'],
    default: 'draft',
    index: true
  },
  stats: {
    total_products: {
      type: Number,
      default: 0,
      min: 0
    },
    total_orders: {
      type: Number,
      default: 0,
      min: 0
    },
    total_revenue: {
      type: Number,
      default: 0,
      min: 0
    },
    total_views: {
      type: Number,
      default: 0,
      min: 0
    },
    rating: {
      average: {
        type: Number,
        default: 0,
        min: 0,
        max: 5
      },
      count: {
        type: Number,
        default: 0,
        min: 0
      }
    }
  },
  permissions: [{
    user_id: {
      type: String,
      required: true
    },
    role: {
      type: String,
      enum: ['owner', 'admin', 'editor', 'viewer'],
      default: 'viewer'
    },
    granted_at: {
      type: Date,
      default: Date.now
    },
    granted_by: {
      type: String,
      required: true
    }
  }],
  seo: {
    meta_title: {
      type: String,
      maxlength: 60
    },
    meta_description: {
      type: String,
      maxlength: 160
    },
    meta_keywords: [{
      type: String,
      maxlength: 50
    }],
    canonical_url: String,
    og_image: String
  },
  published_at: Date,
  last_modified: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Index composés pour performance
shopSchema.index({ owner_id: 1, status: 1 });
shopSchema.index({ template_id: 1, status: 1 });
shopSchema.index({ slug: 1, status: 1 });
shopSchema.index({ categories: 1, status: 1 });
shopSchema.index({ 'stats.total_revenue': -1 });
shopSchema.index({ 'stats.rating.average': -1 });

// Méthodes statiques
shopSchema.statics.findByOwner = function(ownerId, status = 'active') {
  return this.find({
    owner_id: ownerId,
    status: status
  }).sort({ created_at: -1 });
};

shopSchema.statics.findByTemplate = function(templateId, status = 'active') {
  return this.find({
    template_id: templateId,
    status: status
  }).sort({ created_at: -1 });
};

shopSchema.statics.findByCategory = function(category, status = 'active') {
  return this.find({
    categories: category,
    status: status
  }).sort({ 'stats.rating.average': -1 });
};

shopSchema.statics.findPopular = function(limit = 10) {
  return this.find({ status: 'active' })
    .sort({ 'stats.total_revenue': -1, 'stats.rating.average': -1 })
    .limit(limit);
};

// Méthodes d'instance
shopSchema.methods.addPermission = function(userId, role, grantedBy) {
  const existingPermission = this.permissions.find(p => p.user_id === userId);
  if (existingPermission) {
    existingPermission.role = role;
    existingPermission.granted_at = new Date();
    existingPermission.granted_by = grantedBy;
  } else {
    this.permissions.push({
      user_id: userId,
      role: role,
      granted_by: grantedBy
    });
  }
  return this.save();
};

shopSchema.methods.removePermission = function(userId) {
  this.permissions = this.permissions.filter(p => p.user_id !== userId);
  return this.save();
};

shopSchema.methods.hasPermission = function(userId, requiredRole) {
  const permission = this.permissions.find(p => p.user_id === userId);
  if (!permission) return false;
  
  const roleHierarchy = {
    'owner': 4,
    'admin': 3,
    'editor': 2,
    'viewer': 1
  };
  
  return roleHierarchy[permission.role] >= roleHierarchy[requiredRole];
};

shopSchema.methods.publish = function() {
  this.status = 'active';
  this.published_at = new Date();
  this.last_modified = new Date();
  return this.save();
};

shopSchema.methods.suspend = function() {
  this.status = 'suspended';
  this.last_modified = new Date();
  return this.save();
};

shopSchema.methods.updateStats = function(statsData) {
  Object.assign(this.stats, statsData);
  this.last_modified = new Date();
  return this.save();
};

// Validation avant sauvegarde
shopSchema.pre('save', function(next) {
  const validation = shopValidationSchema.validate(this.toObject());
  if (validation.error) {
    return next(new Error(`Validation boutique échouée: ${validation.error.details[0].message}`));
  }
  this.last_modified = new Date();
  next();
});

// Virtual pour l'URL publique
shopSchema.virtual('public_url').get(function() {
  return `/shop/${this.slug}`;
});

// Virtual pour l'URL d'administration
shopSchema.virtual('admin_url').get(function() {
  return `/admin/shop/${this.slug}`;
});

// Virtual pour le CSS personnalisé
shopSchema.virtual('custom_css_output').get(function() {
  if (!this.customizations.colors && !this.customizations.fonts && !this.customizations.layout) {
    return '';
  }
  
  let css = ':root {';
  
  if (this.customizations.colors) {
    Object.entries(this.customizations.colors).forEach(([key, value]) => {
      if (value) {
        css += `\n  --${key}-color: ${value};`;
      }
    });
  }
  
  if (this.customizations.fonts) {
    if (this.customizations.fonts.primary) {
      css += `\n  --font-primary: "${this.customizations.fonts.primary}";`;
    }
    if (this.customizations.fonts.secondary) {
      css += `\n  --font-secondary: "${this.customizations.fonts.secondary}";`;
    }
    if (this.customizations.fonts.heading_weight) {
      css += `\n  --font-heading-weight: ${this.customizations.fonts.heading_weight};`;
    }
    if (this.customizations.fonts.body_weight) {
      css += `\n  --font-body-weight: ${this.customizations.fonts.body_weight};`;
    }
  }
  
  if (this.customizations.layout) {
    if (this.customizations.layout.spacing) {
      css += `\n  --spacing: ${this.customizations.layout.spacing};`;
    }
    if (this.customizations.layout.border_radius) {
      css += `\n  --border-radius: ${this.customizations.layout.border_radius}px;`;
    }
    if (this.customizations.layout.max_width) {
      css += `\n  --max-width: ${this.customizations.layout.max_width}px;`;
    }
  }
  
  css += '\n}';
  
  if (this.customizations.branding?.custom_css) {
    css += '\n' + this.customizations.branding.custom_css;
  }
  
  return css;
});

const Shop = mongoose.model('Shop', shopSchema);

module.exports = {
  Shop,
  shopValidationSchema
};
