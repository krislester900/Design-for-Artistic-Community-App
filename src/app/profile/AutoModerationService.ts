/**
 * AutoModerationService — Validation automatique des soumissions.
 * Un "robot" qui vérifie les critères de qualité et approuve
 * automatiquement les contenus valides.
 */

export interface ModerationCriteria {
  /** Titre minimum length */
  minTitleLength: number;
  /** Description / Medium minimum length */
  minDescriptionLength: number;
  /** Image URL must be present */
  requireImage: boolean;
  /** Image URL must start with http/https */
  requireValidUrl: boolean;
  /** Maximum words in title to avoid spam */
  maxTitleWords: number;
  /** Blocked keywords (spam, offensive) */
  blockedKeywords: string[];
}

export interface ModerationResult {
  approved: boolean;
  reason: string;
}

const DEFAULT_CRITERIA: ModerationCriteria = {
  minTitleLength: 3,
  minDescriptionLength: 2,
  requireImage: true,
  requireValidUrl: true,
  maxTitleWords: 30,
  blockedKeywords: [
    "spam", "viagra", "casino", "buy now", "click here",
    "free money", "xxx", "porn", "escort",
  ],
};

export class AutoModerationService {
  private criteria: ModerationCriteria;

  constructor(criteria: Partial<ModerationCriteria> = {}) {
    this.criteria = { ...DEFAULT_CRITERIA, ...criteria };
  }

  setCriteria(criteria: Partial<ModerationCriteria>) {
    this.criteria = { ...this.criteria, ...criteria };
  }

  getCriteria(): ModerationCriteria {
    return { ...this.criteria };
  }

  /**
   * Vérifie une soumission et retourne si elle est approuvée automatiquement
   */
  moderate(params: {
    title: string;
    description?: string;
    imageUrl?: string;
    category?: string;
    authorName?: string;
  }): ModerationResult {
    const { title, description, imageUrl, category } = params;

    // 1. Vérifier le titre
    if (!title || title.trim().length < this.criteria.minTitleLength) {
      return {
        approved: false,
        reason: `Le titre doit contenir au moins ${this.criteria.minTitleLength} caractères.`,
      };
    }

    if (title.trim().split(/\s+/).length > this.criteria.maxTitleWords) {
      return {
        approved: false,
        reason: `Le titre est trop long (max ${this.criteria.maxTitleWords} mots).`,
      };
    }

    // 2. Vérifier les mots interdits
    const lowerTitle = title.toLowerCase();
    const lowerDesc = (description || "").toLowerCase();
    const allText = `${lowerTitle} ${lowerDesc}`;

    for (const keyword of this.criteria.blockedKeywords) {
      if (allText.includes(keyword)) {
        return {
          approved: false,
          reason: `Contenu non autorisé détecté.`,
        };
      }
    }

    // 3. Vérifier l'image
    if (this.criteria.requireImage) {
      if (!imageUrl || !imageUrl.trim()) {
        return {
          approved: false,
          reason: "Une URL d'image est requise.",
        };
      }

      if (this.criteria.requireValidUrl) {
        const url = imageUrl.trim().toLowerCase();
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
          return {
            approved: false,
            reason: "L'URL de l'image doit être valide (commencer par http:// ou https://).",
          };
        }
      }
    }

    // 4. Vérifier la catégorie
    if (!category || category === "all") {
      return {
        approved: false,
        reason: "Veuillez sélectionner une catégorie valide.",
      };
    }

    // 5. Vérifier la description / medium
    if (description && description.trim().length < this.criteria.minDescriptionLength) {
      return {
        approved: false,
        reason: `La description doit contenir au moins ${this.criteria.minDescriptionLength} caractères.`,
      };
    }

    // Tout est bon → approuvé automatiquement
    return {
      approved: true,
      reason: "Validation automatique réussie.",
    };
  }

  /**
   * Score de qualité (0-100) pour aider l'admin à prioriser
   */
  calculateQualityScore(params: {
    title: string;
    description?: string;
    imageUrl?: string;
  }): number {
    let score = 50; // Base

    const { title, description, imageUrl } = params;

    // Bonus titre
    if (title.length > 10) score += 10;
    if (title.length > 20) score += 5;
    if (title.split(/\s+/).length >= 3) score += 5;

    // Bonus description
    if (description && description.length > 20) score += 10;
    if (description && description.length > 50) score += 5;

    // Bonus image
    if (imageUrl && imageUrl.startsWith("https://")) score += 10;
    if (imageUrl && imageUrl.includes("unsplash")) score += 5;

    return Math.min(100, Math.max(0, score));
  }
}

// Singleton exporté pour utilisation dans l'app
export const autoModerator = new AutoModerationService();