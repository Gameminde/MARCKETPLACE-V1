// ========================================
// CSS COMPILER SERVICE - PHASE 4 WEEK 2
// SCSS-lite → CSS, critical CSS, purge simple, responsive helpers
// ========================================

class CSSCompilerService {
  // Compilation SCSS-lite → CSS (support variables et nesting simple)
  async compile(source = '') {
    // Très léger: remplace les variables CSS custom et aplatit quelques patterns
    const css = source
      .replace(/\$([a-zA-Z0-9_-]+)\s*:\s*([^;]+);/g, '') // ignore SCSS vars (we rely on CSS vars)
      .replace(/&:/g, ':') // minimal nesting support for pseudo
      .replace(/\s{2,}/g, ' ') // normalize
      .trim();
    return css;
  }

  // Extraction CSS critique (heuristique: prend les premières règles clés)
  async extractCritical(css = '') {
    const lines = css.split('}');
    const critical = lines.slice(0, Math.min(20, lines.length)).join('}') + '}';
    return critical;
  }

  // Purge des classes non utilisées (heuristique sur liste fournie)
  async purgeUnused(css = '', usedSelectors = []) {
    if (!usedSelectors || usedSelectors.length === 0) return css;
    const blocks = css.split('}');
    const keep = blocks.filter(b => usedSelectors.some(sel => b.includes(sel)));
    return keep.join('}') + '}';
  }

  // Helpers responsive
  responsiveHelpers() {
    return `@media (max-width:768px){.hidden-sm{display:none!important}}`;
  }
}

module.exports = new CSSCompilerService();

