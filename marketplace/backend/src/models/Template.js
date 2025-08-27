const mongoose = require('mongoose');
const Joi = require('joi');

// Schema de validation Joi pour les templates
const templateValidationSchema = Joi.object({
  id: Joi.string().required().min(3).max(50).pattern(/^[a-z0-9_-]+$/),
  name: Joi.string().required().min(3).max(100),
  description: Joi.string().max(500),
  target_persona: Joi.string().max(200),
  psychology: Joi.string().max(300),
  color_palette: Joi.object({
    primary: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).required(),
    secondary: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).required(),
    accent: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).required(),
    background: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).required(),
    surface: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).required(),
    text: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).required(),
    success: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
    warning: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/),
    error: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/)
  }).required(),
  typography: Joi.object({
    font_primary: Joi.string().required().max(50),
    font_secondary: Joi.string().max(50),
    weight_heading: Joi.number().integer().min(100).max(900).default(600),
    weight_body: Joi.number().integer().min(100).max(900).default(400),
    size_scale: Joi.number().min(0.8).max(2.0).default(1.2),
    line_height: Joi.number().min(1.0).max(2.0).default(1.5)
  }).required(),
  layout: Joi.object({
    grid_system: Joi.string().valid('symmetrical', 'asymmetrical', 'geometric', 'fluid').required(),
    spacing: Joi.string().valid('compact', 'comfortable', 'spacious').required(),
    border_radius: Joi.number().integer().min(0).max(50).default(8),
    card_shadow: Joi.string().valid('none', 'soft', 'sharp', 'dramatic').default('soft'),
    animation_style: Joi.string().valid('none', 'gentle', 'snappy', 'bouncy').default('gentle'),
    max_width: Joi.number().integer().min(320).max(1920).default(1200)
  }).required(),
  components: Joi.object({
    header: Joi.string().max(100).default('standard'),
    product_cards: Joi.string().max(100).default('standard'),
    buttons: Joi.string().max(100).default('standard'),
    navigation: Joi.string().max(100).default('standard'),
    footer: Joi.string().max(100).default('standard'),
    forms: Joi.string().max(100).default('standard')
  }).required(),
  features: Joi.array().items(Joi.string().max(100)).default([]),
  is_active: Joi.boolean().default(true),
  version: Joi.string().pattern(/^\d+\.\d+\.\d+$/).default('1.0.0'),
  created_by: Joi.string().max(100).default('system'),
  tags: Joi.array().items(Joi.string().max(50)).default([])
});

// Schema MongoDB pour les templates
const templateSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true,
    index: true,
    validate: {
      validator: function(v) {
        return /^[a-z0-9_-]+$/.test(v);
      },
      message: 'ID doit contenir uniquement des lettres minuscules, chiffres, tirets et underscores'
    }
  },
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  description: {
    type: String,
    maxlength: 500,
    trim: true
  },
  target_persona: {
    type: String,
    maxlength: 200,
    trim: true
  },
  psychology: {
    type: String,
    maxlength: 300,
    trim: true
  },
  color_palette: {
    primary: {
      type: String,
      required: true,
      validate: {
        validator: function(v) {
          return /^#[0-9A-Fa-f]{6}$/.test(v);
        },
        message: 'Couleur primaire doit être un code hexadécimal valide'
      }
    },
    secondary: {
      type: String,
      required: true,
      validate: {
        validator: function(v) {
          return /^#[0-9A-Fa-f]{6}$/.test(v);
        },
        message: 'Couleur secondaire doit être un code hexadécimal valide'
      }
    },
    accent: {
      type: String,
      required: true,
      validate: {
        validator: function(v) {
          return /^#[0-9A-Fa-f]{6}$/.test(v);
        },
        message: 'Couleur d\'accent doit être un code hexadécimal valide'
      }
    },
    background: {
      type: String,
      required: true,
      validate: {
        validator: function(v) {
          return /^#[0-9A-Fa-f]{6}$/.test(v);
        },
        message: 'Couleur de fond doit être un code hexadécimal valide'
      }
    },
    surface: {
      type: String,
      required: true,
      validate: {
        validator: function(v) {
          return /^#[0-9A-Fa-f]{6}$/.test(v);
        },
        message: 'Couleur de surface doit être un code hexadécimal valide'
      }
    },
    text: {
      type: String,
      required: true,
      validate: {
        validator: function(v) {
          return /^#[0-9A-Fa-f]{6}$/.test(v);
        },
        message: 'Couleur de texte doit être un code hexadécimal valide'
      }
    },
    success: String,
    warning: String,
    error: String
  },
  typography: {
    font_primary: {
      type: String,
      required: true,
      trim: true,
      maxlength: 50
    },
    font_secondary: {
      type: String,
      trim: true,
      maxlength: 50
    },
    weight_heading: {
      type: Number,
      min: 100,
      max: 900,
      default: 600
    },
    weight_body: {
      type: Number,
      min: 100,
      max: 900,
      default: 400
    },
    size_scale: {
      type: Number,
      min: 0.8,
      max: 2.0,
      default: 1.2
    },
    line_height: {
      type: Number,
      min: 1.0,
      max: 2.0,
      default: 1.5
    }
  },
  layout: {
    grid_system: {
      type: String,
      required: true,
      enum: ['symmetrical', 'asymmetrical', 'geometric', 'fluid']
    },
    spacing: {
      type: String,
      required: true,
      enum: ['compact', 'comfortable', 'spacious']
    },
    border_radius: {
      type: Number,
      min: 0,
      max: 50,
      default: 8
    },
    card_shadow: {
      type: String,
      enum: ['none', 'soft', 'sharp', 'dramatic'],
      default: 'soft'
    },
    animation_style: {
      type: String,
      enum: ['none', 'gentle', 'snappy', 'bouncy'],
      default: 'gentle'
    },
    max_width: {
      type: Number,
      min: 320,
      max: 1920,
      default: 1200
    }
  },
  components: {
    header: {
      type: String,
      maxlength: 100,
      default: 'standard'
    },
    product_cards: {
      type: String,
      maxlength: 100,
      default: 'standard'
    },
    buttons: {
      type: String,
      maxlength: 100,
      default: 'standard'
    },
    navigation: {
      type: String,
      maxlength: 100,
      default: 'standard'
    },
    footer: {
      type: String,
      maxlength: 100,
      default: 'standard'
    },
    forms: {
      type: String,
      maxlength: 100,
      default: 'standard'
    }
  },
  features: [{
    type: String,
    maxlength: 100
  }],
  is_active: {
    type: Boolean,
    default: true,
    index: true
  },
  version: {
    type: String,
    default: '1.0.0',
    validate: {
      validator: function(v) {
        return /^\d+\.\d+\.\d+$/.test(v);
      },
      message: 'Version doit être au format X.Y.Z'
    }
  },
  created_by: {
    type: String,
    maxlength: 100,
    default: 'system'
  },
  tags: [{
    type: String,
    maxlength: 50
  }],
  usage_count: {
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
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Index composés pour performance
templateSchema.index({ is_active: 1, tags: 1 });
templateSchema.index({ 'rating.average': -1, usage_count: -1 });
templateSchema.index({ created_at: -1 });

// Méthodes statiques
templateSchema.statics.findByTags = function(tags) {
  return this.find({
    is_active: true,
    tags: { $in: tags }
  });
};

templateSchema.statics.findPopular = function(limit = 10) {
  return this.find({ is_active: true })
    .sort({ 'rating.average': -1, usage_count: -1 })
    .limit(limit);
};

templateSchema.statics.findByPersona = function(persona) {
  return this.find({
    is_active: true,
    target_persona: { $regex: persona, $options: 'i' }
  });
};

// Méthodes d'instance
templateSchema.methods.incrementUsage = function() {
  this.usage_count += 1;
  return this.save();
};

templateSchema.methods.addRating = function(rating) {
  if (rating < 0 || rating > 5) {
    throw new Error('Rating doit être entre 0 et 5');
  }
  
  const totalRating = this.rating.average * this.rating.count + rating;
  this.rating.count += 1;
  this.rating.average = totalRating / this.rating.count;
  
  return this.save();
};

// Validation avant sauvegarde
templateSchema.pre('save', function(next) {
  const validation = templateValidationSchema.validate(this.toObject());
  if (validation.error) {
    return next(new Error(`Validation template échouée: ${validation.error.details[0].message}`));
  }
  next();
});

// Virtual pour l'URL du template
templateSchema.virtual('preview_url').get(function() {
  return `/api/templates/${this.id}/preview`;
});

// Virtual pour le CSS généré
templateSchema.virtual('css_variables').get(function() {
  return {
    '--primary-color': this.color_palette.primary,
    '--secondary-color': this.color_palette.secondary,
    '--accent-color': this.color_palette.accent,
    '--background-color': this.color_palette.background,
    '--surface-color': this.color_palette.surface,
    '--text-color': this.color_palette.text,
    '--font-primary': this.typography.font_primary,
    '--font-secondary': this.typography.font_secondary,
    '--border-radius': `${this.layout.border_radius}px`,
    '--max-width': `${this.layout.max_width}px`
  };
});

const Template = mongoose.model('Template', templateSchema);

module.exports = {
  Template,
  templateValidationSchema
};
