/**
 * ===== SYSTÈME DE FILTRES PADMAKARA =====
 * Gestion des filtres sous forme de pills cliquables avec couleurs aléatoires
 * Compatible avec Turbo/Turbolinks pour Rails
 */

// === CONFIGURATION ===

// Palette de couleurs pour les pills
const PILL_COLORS = [
  { bg: "#3B82F6", text: "#FFFFFF", border: "#3B82F6" }, // blue-500
  { bg: "#A855F7", text: "#FFFFFF", border: "#A855F7" }, // purple-500
  { bg: "#EC4899", text: "#FFFFFF", border: "#EC4899" }, // pink-500
  { bg: "#6366F1", text: "#FFFFFF", border: "#6366F1" }, // indigo-500
  { bg: "#14B8A6", text: "#FFFFFF", border: "#14B8A6" }, // teal-500
  { bg: "#F97316", text: "#FFFFFF", border: "#F97316" }, // orange-500
  { bg: "#EF4444", text: "#FFFFFF", border: "#EF4444" }, // red-500
  { bg: "#10B981", text: "#FFFFFF", border: "#10B981" }, // emerald-500
  { bg: "#06B6D4", text: "#FFFFFF", border: "#06B6D4" }, // cyan-500
  { bg: "#8B5CF6", text: "#FFFFFF", border: "#8B5CF6" }, // violet-500
  { bg: "#F43F5E", text: "#FFFFFF", border: "#F43F5E" }, // rose-500
  { bg: "#84CC16", text: "#FFFFFF", border: "#84CC16" }, // lime-500
];

// Styles par défaut pour les pills inactives
const INACTIVE_PILL_STYLES = {
  backgroundColor: "#F3F4F6", // gray-100
  color: "#4B5563", // gray-600
  borderColor: "#E5E7EB", // gray-200
};

// === ÉTAT GLOBAL ===

// Variables globales pour éviter les conflits globaux
window.padmakaraFilters = window.padmakaraFilters || {
  initialized: false,
  timeout: null,
  cleanup: function () {
    // Nettoyer les anciens timers et références
    if (this.timeout) {
      clearTimeout(this.timeout);
      this.timeout = null;
    }
    this.initialized = false;
  },
};

// === UTILITAIRES ===

/**
 * Obtient une couleur déterministe basée sur une chaîne de caractères
 * @param {string} text - Le texte pour générer la couleur
 * @returns {Object} Objet couleur avec bg, text, border
 */
function getColorFromText(text) {
  // Créer un hash simple du texte
  let hash = 0;
  for (let i = 0; i < text.length; i++) {
    const char = text.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash; // Convertir en 32 bits
  }

  // Utiliser le hash pour sélectionner une couleur de manière déterministe
  const index = Math.abs(hash) % PILL_COLORS.length;
  return PILL_COLORS[index];
}

/**
 * Obtient une couleur aléatoire de la palette (fonction de fallback)
 * @returns {Object} Objet couleur avec bg, text, border
 */
function getRandomColor() {
  return PILL_COLORS[Math.floor(Math.random() * PILL_COLORS.length)];
}

/**
 * Applique le style actif à une pill
 * @param {HTMLElement} pillContent - L'élément contenu de la pill
 * @param {Object} color - L'objet couleur à appliquer
 */
function applyActivePillStyle(pillContent, color) {
  try {
    // Appliquer les styles directement
    pillContent.style.backgroundColor = color.bg;
    pillContent.style.color = color.text;
    pillContent.style.borderColor = color.border;

    // Ajouter les classes CSS
    pillContent.classList.add("pill-active");
    pillContent.classList.remove("pill-inactive");
  } catch (error) {
    console.error("❌ Erreur dans applyActivePillStyle:", error);
  }
}

/**
 * Applique le style inactif à une pill
 * @param {HTMLElement} pillContent - L'élément contenu de la pill
 */
function applyInactivePillStyle(pillContent) {
  try {
    // Remettre les styles par défaut
    pillContent.style.backgroundColor = INACTIVE_PILL_STYLES.backgroundColor;
    pillContent.style.color = INACTIVE_PILL_STYLES.color;
    pillContent.style.borderColor = INACTIVE_PILL_STYLES.borderColor;

    // Ajouter les classes CSS
    pillContent.classList.add("pill-inactive");
    pillContent.classList.remove("pill-active");
  } catch (error) {
    console.error("❌ Erreur dans applyInactivePillStyle:", error);
  }
}

/**
 * Met à jour l'état visuel du bouton toggle
 * @param {HTMLElement} filtersSection - Section des filtres
 * @param {HTMLElement} filterText - Texte du bouton
 * @param {HTMLElement} chevronDown - Icône chevron
 */
function updateToggleButtonState(
  filtersSection,
  filtersContent,
  filterText,
  chevronDown
) {
  try {
    const isHidden = filtersSection.classList.contains("hidden");

    if (isHidden) {
      filterText.textContent = "Show Filters";
      chevronDown.style.transform = "rotate(0deg)";
    } else {
      filterText.textContent = "Hide Filters";
      chevronDown.style.transform = "rotate(180deg)";
    }
  } catch (error) {
    console.error("❌ Erreur dans updateToggleButtonState:", error);
  }
}

/**
 * Nettoie les event listeners d'un élément en le clonant
 * @param {HTMLElement} element - L'élément à nettoyer
 * @returns {HTMLElement} Le nouvel élément sans event listeners
 */
function cleanEventListeners(element) {
  const newElement = element.cloneNode(true);
  element.parentNode.replaceChild(newElement, element);
  return newElement;
}

// === INITIALISATION DES PILLS ===

/**
 * Initialise une pill individuelle
 * @param {HTMLElement} pill - L'élément pill
 * @param {number} index - Index de la pill pour le debug
 */
function initializePill(pill, index) {
  try {
    const checkbox = pill.querySelector(".pill-checkbox");
    const pillContent = pill.querySelector(".pill-content");

    if (!checkbox || !pillContent) {
      return null;
    }

    // Générer une couleur basée sur le texte de la pill pour qu'elle reste constante
    const pillText = pillContent.textContent.trim();
    const pillColor = getColorFromText(pillText);

    // Nettoyer les anciens listeners en clonant l'élément
    const newPill = cleanEventListeners(pill);

    // Récupérer les nouveaux éléments après clonage
    const newCheckbox = newPill.querySelector(".pill-checkbox");
    const newPillContent = newPill.querySelector(".pill-content");

    // Stocker la couleur directement sur l'élément
    newPill.dataset.pillColor = JSON.stringify(pillColor);

    // Appliquer l'état initial
    if (newCheckbox.checked) {
      applyActivePillStyle(newPillContent, pillColor);
    } else {
      applyInactivePillStyle(newPillContent);
    }

    // Gérer le clic (nouveau listener)
    newPill.addEventListener("click", function (e) {
      try {
        e.preventDefault();

        // Toggle le checkbox
        newCheckbox.checked = !newCheckbox.checked;

        // Récupérer la couleur stockée
        const storedColor = JSON.parse(newPill.dataset.pillColor);

        // Appliquer le style
        if (newCheckbox.checked) {
          applyActivePillStyle(newPillContent, storedColor);
        } else {
          applyInactivePillStyle(newPillContent);
        }
      } catch (error) {
        console.error("❌ Erreur dans pill click:", error);
      }
    });

    return newPill;
  } catch (error) {
    return null;
  }
}

/**
 * Initialise toutes les pills
 */
function initializePills() {
  const pillFilters = document.querySelectorAll(".pill-filter");

  pillFilters.forEach((pill, index) => {
    initializePill(pill, index);
  });
}

// === GESTION DES BOUTONS ===

/**
 * Initialise le bouton toggle des filtres
 * @param {HTMLElement} toggleButton - Bouton toggle
 * @param {HTMLElement} filtersSection - Section des filtres
 * @param {HTMLElement} filterText - Texte du bouton
 * @param {HTMLElement} chevronDown - Icône chevron
 */
function initializeToggleButton(
  toggleButton,
  filtersSection,
  filterText,
  chevronDown
) {
  // Nettoyer les anciens listeners
  const newToggleButton = cleanEventListeners(toggleButton);

  // Ajouter le nouveau listener
  newToggleButton.addEventListener("click", function () {
    try {
      const isHidden = filtersSection.classList.contains("hidden");

      if (isHidden) {
        filtersSection.classList.remove("hidden");
      } else {
        filtersSection.classList.add("hidden");
      }

      updateToggleButtonState(filtersSection, filterText, chevronDown);
    } catch (error) {
      console.error("❌ Erreur dans toggle:", error);
    }
  });

  return newToggleButton;
}

/**
 * Initialise le bouton clear filters
 * @param {HTMLElement} clearFiltersBtn - Bouton clear
 * @param {string} clearUrl - URL pour le clear
 */
function initializeClearButton(clearFiltersBtn, clearUrl) {
  // Nettoyer les anciens listeners
  const newClearButton = cleanEventListeners(clearFiltersBtn);

  // Ajouter le nouveau listener
  newClearButton.addEventListener("click", function () {
    try {
      const timestamp = new Date().getTime();
      window.location.href = clearUrl + "?_=" + timestamp;
    } catch (error) {
      console.error("❌ Erreur dans clearAllFilters:", error);
    }
  });

  return newClearButton;
}

// === FONCTION PRINCIPALE D'INITIALISATION ===

/**
 * Fonction principale d'initialisation des filtres
 * @param {string} clearUrl - URL pour le clear des filtres
 */
function initializeFilters(clearUrl) {
  // Nettoyer l'état précédent
  window.padmakaraFilters.cleanup();

  window.padmakaraFilters.timeout = setTimeout(() => {
    try {
      // === RÉCUPÉRATION DES ÉLÉMENTS DOM ===
      const toggleButton = document.getElementById("toggleFilters");
      const filtersSection = document.getElementById("filtersSection");
      const filterText = document.getElementById("filterText");
      const chevronDown = document.getElementById("chevronDown");
      const clearFiltersBtn = document.getElementById("clearFiltersBtn");

      // Vérification que tous les éléments existent
      if (
        !toggleButton ||
        !filtersSection ||
        !filterText ||
        !chevronDown ||
        !clearFiltersBtn
      ) {
        return;
      }

      // Marquer que l'initialisation a commencé
      window.padmakaraFilters.initialized = true;

      // === INITIALISATION DE L'ÉTAT DES FILTRES ===

      // Vérifier s'il y a des filtres actifs
      const hasActiveFiltersStr = filtersSection.dataset.hasActiveFilters;
      const hasActiveFilters = hasActiveFiltersStr === "true";

      // Initialiser l'état des filtres au chargement
      if (hasActiveFilters) {
        filtersSection.classList.remove("hidden");
      } else {
        filtersSection.classList.add("hidden");
      }
      updateToggleButtonState(filtersSection, filterText, chevronDown);

      // === INITIALISATION DES COMPOSANTS ===

      // Initialiser le bouton toggle
      initializeToggleButton(
        toggleButton,
        filtersSection,
        filterText,
        chevronDown
      );

      // Initialiser le bouton clear
      initializeClearButton(clearFiltersBtn, clearUrl);

      // Initialiser les pills
      initializePills();
    } catch (error) {
      window.padmakaraFilters.cleanup();
    }
  }, 50); // Petit délai pour éviter les doublons
}

// === GESTIONNAIRES D'ÉVÉNEMENTS ===

/**
 * Configure tous les event listeners pour l'initialisation
 * @param {string} clearUrl - URL pour le clear des filtres
 */
function setupEventListeners(clearUrl) {
  // Cas 1: Chargement initial de la page
  document.addEventListener("DOMContentLoaded", function () {
    initializeFilters(clearUrl);
  });

  // Cas 2: Turbo (Rails 7+)
  if (typeof Turbo !== "undefined") {
    // Nettoyage avant navigation
    document.addEventListener("turbo:before-render", function () {
      window.padmakaraFilters.cleanup();
    });

    document.addEventListener("turbo:load", function () {
      initializeFilters(clearUrl);
    });

    document.addEventListener("turbo:render", function () {
      initializeFilters(clearUrl);
    });

    document.addEventListener("turbo:frame-load", function () {
      initializeFilters(clearUrl);
    });
  }

  // Cas 3: Turbolinks (Rails 6 et versions antérieures)
  document.addEventListener("turbolinks:load", function () {
    initializeFilters(clearUrl);
  });

  // Cas 4: Submission de formulaire (pour capturer l'Apply Filters)
  document.addEventListener("submit", function (e) {
    if (e.target.closest("#filtersForm")) {
      window.padmakaraFilters.cleanup();
    }
  });

  // Cas 5: Backup avec plusieurs tentatives
  let backupAttempts = 0;
  const maxBackupAttempts = 3;

  function tryBackupInitialization() {
    if (
      backupAttempts < maxBackupAttempts &&
      document.readyState === "complete"
    ) {
      backupAttempts++;

      if (
        !window.padmakaraFilters.initialized ||
        !document.getElementById("toggleFilters")
      ) {
        initializeFilters(clearUrl);
      }
    }
  }

  // Backup immédiat
  setTimeout(tryBackupInitialization, 100);
  // Backup avec délai plus long
  setTimeout(tryBackupInitialization, 500);
  // Backup final
  setTimeout(tryBackupInitialization, 1000);
}

// === API PUBLIQUE ===

// Exposer l'API publique
const PadmakaraFilters = {
  init: function (clearUrl) {
    setupEventListeners(clearUrl);
  },

  // Méthodes utilitaires pour usage externe si nécessaire
  getState: function () {
    return window.padmakaraFilters;
  },

  cleanup: function () {
    window.padmakaraFilters.cleanup();
  },
};

// Export pour ES6 modules
window.PadmakaraFilters = PadmakaraFilters;

// Export par défaut pour l'importmap
export { PadmakaraFilters };
