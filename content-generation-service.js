// ========================================
// CONTENT GENERATION SERVICE - PHASE 4 WEEK 2 DAY 9
// OpenAI integration pour génération automatique de contenu
// SEO optimization, title enhancement, meta tags, social media
// ========================================

const structuredLogger = require('./structured-logger.service');

class ContentGenerationService {
  constructor() {
    this.openaiEnabled = process.env.OPENAI_API_KEY ? true : false;
    this.generationCache = new Map();
  }

  /**
   * Génère description SEO-optimisée si manquante ou améliore existante
   * @param {Object} productData - Données produit
   * @returns {Promise<Object>} Description optimisée avec metadata
   */
  async generateSEODescription(productData) {
    const cacheKey = `desc_${this._hash(productData.title + productData.category)}`;
    
    if (this.generationCache.has(cacheKey)) {
      return this.generationCache.get(cacheKey);
    }

    try {
      let description;
      
      if (this.openaiEnabled) {
        description = await this._openaiGenerateDescription(productData);
      } else {
        description = await this._fallbackGenerateDescription(productData);
      }

      const result = {
        original: productData.description || '',
        generated: description.text,
        seoScore: description.seoScore,
        keywords: description.keywords,
        improvements: description.improvements,
        wordCount: description.text.split(' ').length,
        timestamp: new Date().toISOString()
      };

      // Cache for 24 hours
      this.generationCache.set(cacheKey, result);
      setTimeout(() => this.generationCache.delete(cacheKey), 86400000);

      return result;

    } catch (error) {
      structuredLogger.error('Keyword extraction failed', { error: error.message });
      return this._fallbackExtractKeywords(content, options);
    }
  }

  /**
   * Génère balises SEO complètes (title, description, keywords)
   * @param {Object} productData - Données produit
   * @returns {Promise<Object>} Balises SEO optimisées
   */
  async generateMetaTags(productData) {
    try {
      const keywords = await this.extractKeywords(
        `${productData.title} ${productData.description}`,
        { category: productData.category }
      );

      const improvedTitle = await this.improveTitleEngagement(
        productData.title,
        { category: productData.category, price: productData.price }
      );

      const seoDescription = await this.generateSEODescription(productData);

      return {
        title: {
          content: improvedTitle.improved,
          length: improvedTitle.improved.length,
          optimal: improvedTitle.improved.length >= 10 && improvedTitle.improved.length <= 60
        },
        description: {
          content: this._truncateMetaDescription(seoDescription.generated),
          length: seoDescription.generated.length,
          optimal: seoDescription.generated.length >= 120 && seoDescription.generated.length <= 160
        },
        keywords: {
          primary: keywords.primary.slice(0, 3),
          secondary: keywords.secondary.slice(0, 5),
          longtail: keywords.longtail.slice(0, 3),
          content: keywords.primary.slice(0, 10).join(', ')
        },
        openGraph: {
          title: improvedTitle.improved,
          description: this._truncateMetaDescription(seoDescription.generated),
          type: 'product',
          image: productData.images?.[0] || null
        },
        twitter: {
          card: 'summary_large_image',
          title: improvedTitle.improved,
          description: this._truncateMetaDescription(seoDescription.generated),
          image: productData.images?.[0] || null
        },
        schema: this._generateProductSchema(productData, improvedTitle.improved, seoDescription.generated)
      };

    } catch (error) {
      structuredLogger.error('Meta tags generation failed', { error: error.message });
      return this._fallbackMetaTags(productData);
    }
  }

  /**
   * Crée contenu pour réseaux sociaux (Instagram, Facebook)
   * @param {Object} product - Données produit
   * @returns {Promise<Object>} Posts optimisés par plateforme
   */
  async createSocialMediaContent(product) {
    try {
      const hashtags = await this._generateHashtags(product.category, product.title);
      
      return {
        instagram: {
          caption: this._createInstagramCaption(product, hashtags.instagram),
          hashtags: hashtags.instagram,
          story: this._createInstagramStory(product)
        },
        facebook: {
          post: this._createFacebookPost(product),
          description: this._createFacebookDescription(product)
        },
        twitter: {
          tweet: this._createTwitterTweet(product, hashtags.twitter),
          thread: this._createTwitterThread(product)
        },
        pinterest: {
          title: this._createPinterestTitle(product),
          description: this._createPinterestDescription(product)
        }
      };

    } catch (error) {
      structuredLogger.error('Social media content generation failed', { error: error.message });
      return this._fallbackSocialContent(product);
    }
  }

  // ===== OPENAI INTEGRATION METHODS =====

  async _openaiGenerateDescription(productData) {
    // TODO: Real OpenAI API integration
    // For now, return mock response
    await this._sleep(1000);
    
    const category = productData.category || 'produit';
    const title = productData.title || 'article';
    
    return {
      text: `Découvrez ${title.toLowerCase()}, un ${category} d'exception qui allie qualité premium et design moderne. Fabriqué avec les meilleurs matériaux, ce produit vous offre une expérience unique. Livraison rapide et service client français. Garantie satisfaction ou remboursé.`,
      seoScore: 85,
      keywords: ['qualité', 'premium', 'livraison', 'garantie', category],
      improvements: ['Ajout de mots-clés SEO', 'Structure optimisée', 'Call-to-action intégré']
    };
  }

  async _openaiImproveTitle(title, context) {
    // TODO: Real OpenAI API integration
    await this._sleep(800);
    
    const variations = [
      `${title} - Qualité Premium`,
      `${title} | Livraison 24h`,
      `💎 ${title} - Exclusif`,
      `${title} ⚡ Stock Limité`,
      `TOP ${title} 2025`
    ];

    return {
      bestTitle: variations[0],
      variations: variations.slice(1),
      engagementScore: 78,
      changes: ['Ajout indication qualité', 'Optimisation CTR', 'Urgence perçue']
    };
  }

  async _openaiExtractKeywords(content, options) {
    // TODO: Real OpenAI API integration
    await this._sleep(600);
    
    const words = content.toLowerCase().split(/\s+/).filter(w => w.length > 3);
    const category = options.category || 'general';
    
    return {
      primary: [...new Set(words)].slice(0, 5),
      secondary: [`${category} pas cher`, `${category} qualité`, `${category} livraison`],
      longtail: [`meilleur ${category} 2025`, `${category} français premium`, `acheter ${category} en ligne`],
      confidence: 0.85
    };
  }

  // ===== FALLBACK METHODS =====

  async _fallbackGenerateDescription(productData) {
    const category = productData.category || 'produit';
    const title = productData.title || 'article';
    const price = productData.price;
    
    let description = `${title} - ${category} de qualité. `;
    
    if (price && price < 50) {
      description += 'Prix accessible pour tous. ';
    } else if (price && price > 100) {
      description += 'Produit haut de gamme. ';
    }
    
    description += 'Livraison rapide en France. Service client réactif.';
    
    return {
      text: description,
      seoScore: 65,
      keywords: ['qualité', 'livraison', 'France', category],
      improvements: ['Description basique générée']
    };
  }

  async _fallbackImproveTitle(title, context) {
    const variations = [
      `${title} ⭐`,
      `${title} - NOUVEAU`,
      `${title} | Qualité`,
      `TOP: ${title}`
    ];

    return {
      bestTitle: variations[0],
      variations: variations.slice(1),
      engagementScore: 60,
      changes: ['Ajout emoji', 'Indication nouveauté']
    };
  }

  async _fallbackExtractKeywords(content, options) {
    const words = content.toLowerCase()
      .replace(/[^\w\s]/g, '')
      .split(/\s+/)
      .filter(word => word.length > 3)
      .filter(word => !/^(le|la|les|de|du|des|un|une|et|ou|mais|pour|avec|dans|sur)$/.test(word));
    
    const frequency = {};
    words.forEach(word => frequency[word] = (frequency[word] || 0) + 1);
    
    const sorted = Object.entries(frequency)
      .sort((a, b) => b[1] - a[1])
      .map(([word]) => word);

    const category = options.category || 'produit';
    
    return {
      primary: sorted.slice(0, 5),
      secondary: [`${category}`, 'qualité', 'livraison', 'france'],
      longtail: [`${category} pas cher`, `meilleur ${category}`, `acheter ${category}`],
      confidence: 0.6
    };
  }

  // ===== SOCIAL MEDIA HELPERS =====

  async _generateHashtags(category, title) {
    const baseHashtags = {
      general: ['#qualité', '#france', '#livraison', '#nouveauté'],
      fashion: ['#mode', '#style', '#fashion', '#ootd', '#trendy'],
      tech: ['#tech', '#innovation', '#gadget', '#electronique'],
      beauty: ['#beauté', '#cosmétique', '#skincare', '#makeup'],
      home: ['#maison', '#déco', '#lifestyle', '#homedecor']
    };

    const specific = baseHashtags[category] || baseHashtags.general;
    
    return {
      instagram: [...specific, '#shopping', '#qualitéprix'].slice(0, 10),
      twitter: specific.slice(0, 3),
      pinterest: [...specific, '#inspiration', '#idée'].slice(0, 8)
    };
  }

  _createInstagramCaption(product, hashtags) {
    return `✨ ${product.title} ✨

${product.description?.substring(0, 100) || 'Découvrez ce produit exceptionnel'}...

🚚 Livraison rapide
💝 Garantie qualité
🇫🇷 Service client français

${hashtags.slice(0, 10).join(' ')}`;
  }

  _createInstagramStory(product) {
    return {
      text: `NOUVEAU ! ${product.title}`,
      cta: 'Voir plus',
      background: '#gradient',
      stickers: ['fire', 'star', 'new']
    };
  }

  _createFacebookPost(product) {
    return `🎉 Découvrez ${product.title} !

${product.description?.substring(0, 150) || 'Un produit qui va vous séduire par sa qualité et son design unique.'}

✅ Qualité premium
✅ Livraison 24-48h
✅ Garantie satisfaction

👆 Cliquez pour découvrir !`;
  }

  _createFacebookDescription(product) {
    return `${product.title} - Produit de qualité avec livraison rapide en France. Service client réactif et garantie satisfaction.`;
  }

  _createTwitterTweet(product, hashtags) {
    const maxLength = 280;
    const hashtagsStr = hashtags.join(' ');
    const availableLength = maxLength - hashtagsStr.length - 10;
    
    let tweet = `🔥 ${product.title} - ${product.description?.substring(0, availableLength) || 'Qualité premium'} ${hashtagsStr}`;
    
    return tweet.substring(0, maxLength);
  }

  _createTwitterThread(product) {
    return [
      `🧵 Thread: Pourquoi choisir ${product.title} ? (1/3)`,
      `✨ Qualité exceptionnelle, design soigné et prix compétitif. Ce produit réunit tout ce qu'on attend ! (2/3)`,
      `🚀 Livraison rapide, service client français et garantie satisfaction. Plus d'excuse pour ne pas craquer ! (3/3)`
    ];
  }

  _createPinterestTitle(product) {
    return `${product.title} - Idée Shopping`;
  }

  _createPinterestDescription(product) {
    return `Découvrez ${product.title}. ${product.description?.substring(0, 100) || 'Produit de qualité'} | Shopping en ligne | Livraison France`;
  }

  // ===== SCHEMA & META HELPERS =====

  _generateProductSchema(product, title, description) {
    return {
      '@context': 'https://schema.org',
      '@type': 'Product',
      'name': title,
      'description': description,
      'image': product.images || [],
      'brand': product.brand || 'Marketplace',
      'offers': {
        '@type': 'Offer',
        'price': product.price || 0,
        'priceCurrency': 'EUR',
        'availability': 'https://schema.org/InStock',
        'seller': {
          '@type': 'Organization',
          'name': product.shopName || 'Boutique'
        }
      },
      'aggregateRating': product.rating ? {
        '@type': 'AggregateRating',
        'ratingValue': product.rating,
        'reviewCount': product.reviewCount || 1
      } : undefined
    };
  }

  _truncateMetaDescription(description, maxLength = 160) {
    if (description.length <= maxLength) return description;
    
    const truncated = description.substring(0, maxLength - 3);
    const lastSpace = truncated.lastIndexOf(' ');
    
    return truncated.substring(0, lastSpace > 0 ? lastSpace : maxLength - 3) + '...';
  }

  // ===== FALLBACK RESULTS =====

  _fallbackDescriptionResult(productData) {
    return {
      original: productData.description || '',
      generated: `${productData.title || 'Produit'} de qualité. Livraison rapide en France.`,
      seoScore: 40,
      keywords: ['qualité', 'livraison'],
      improvements: ['Description basique générée'],
      wordCount: 8,
      timestamp: new Date().toISOString()
    };
  }

  _fallbackTitleResult(title) {
    return {
      original: title,
      improved: title + ' ⭐',
      variations: [title + ' - NOUVEAU', title + ' | Qualité'],
      engagementScore: 50,
      improvements: ['Ajout emoji basique'],
      abTestReady: true,
      timestamp: new Date().toISOString()
    };
  }

  _fallbackMetaTags(productData) {
    const title = productData.title || 'Produit';
    const description = productData.description || 'Produit de qualité';
    
    return {
      title: { content: title, length: title.length, optimal: false },
      description: { content: description, length: description.length, optimal: false },
      keywords: { primary: ['produit'], secondary: ['qualité'], longtail: [], content: 'produit, qualité' },
      openGraph: { title, description, type: 'product', image: null },
      twitter: { card: 'summary', title, description, image: null },
      schema: this._generateProductSchema(productData, title, description)
    };
  }

  _fallbackSocialContent(product) {
    const title = product.title || 'Produit';
    
    return {
      instagram: {
        caption: `✨ ${title} ✨\n\nDécouvrez ce produit ! #shopping #qualité`,
        hashtags: ['#shopping', '#qualité'],
        story: { text: title, cta: 'Voir plus' }
      },
      facebook: { post: `Découvrez ${title} !`, description: title },
      twitter: { tweet: `🔥 ${title} #shopping`, thread: [`${title} disponible !`] },
      pinterest: { title: title, description: `Découvrez ${title}` }
    };
  }

  // ===== UTILS =====

  _hash(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash).toString(36);
  }

  _sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

module.exports = new ContentGenerationService();error) {
      structuredLogger.error('Description generation failed', { error: error.message });
      return this._fallbackDescriptionResult(productData);
    }
  }

  /**
   * Améliore titre existant pour +20% CTR
   * @param {String} title - Titre original
   * @param {Object} context - Context produit (catégorie, prix, etc.)
   * @returns {Promise<Object>} Titre optimisé avec variations
   */
  async improveTitleEngagement(title, context = {}) {
    const cacheKey = `title_${this._hash(title + JSON.stringify(context))}`;
    
    if (this.generationCache.has(cacheKey)) {
      return this.generationCache.get(cacheKey);
    }

    try {
      let improvements;
      
      if (this.openaiEnabled) {
        improvements = await this._openaiImproveTitle(title, context);
      } else {
        improvements = await this._fallbackImproveTitle(title, context);
      }

      const result = {
        original: title,
        improved: improvements.bestTitle,
        variations: improvements.variations,
        engagementScore: improvements.engagementScore,
        improvements: improvements.changes,
        abTestReady: improvements.variations.length >= 2,
        timestamp: new Date().toISOString()
      };

      this.generationCache.set(cacheKey, result);
      setTimeout(() => this.generationCache.delete(cacheKey), 86400000);

      return result;

    } catch (error) {
      structuredLogger.error('Title improvement failed', { error: error.message });
      return this._fallbackTitleResult(title);
    }
  }

  /**
   * Extraction intelligente de mots-clés pertinents
   * @param {String} content - Contenu à analyser
   * @param {Object} options - Options (langue, secteur, etc.)
   * @returns {Promise<Object>} Mots-clés avec scores et catégories
   */
  async extractKeywords(content, options = {}) {
    try {
      if (this.openaiEnabled) {
        return await this._openaiExtractKeywords(content, options);
      } else {
        return await this._fallbackExtractKeywords(content, options);
      }
    } catch (