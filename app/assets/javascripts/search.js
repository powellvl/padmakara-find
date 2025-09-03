/**
 * ===== SYSTÈME DE RECHERCHE PADMAKARA =====
 * Gestion de l'interface de recherche avec filtres dynamiques
 * Compatible avec Turbo/Turbolinks pour Rails
 */

// === CONFIGURATION ===

// Couleurs pour les différents types de contenus
const CONTENT_TYPE_COLORS = {
  texts: "#1E40AF", // blue-800
  versions: "#059669", // emerald-600
  files: "#7C3AED", // violet-600
};

// Palette de couleurs pour les pills de filtres
const FILTER_PILL_COLORS = [
  "#3B82F6",
  "#A855F7",
  "#EC4899",
  "#6366F1",
  "#14B8A6",
  "#F97316",
  "#EF4444",
  "#10B981",
  "#06B6D4",
  "#8B5CF6",
];

// === ÉTAT GLOBAL ===
window.padmakaraSearch = window.padmakaraSearch || {
  initialized: false,
  timeout: null,
  cleanup: function () {
    if (this.timeout) {
      clearTimeout(this.timeout);
      this.timeout = null;
    }
    this.initialized = false;
  },
};

// === UTILITAIRES ===

/**
 * Obtient une couleur basée sur le texte pour la consistance
 * @param {string} text - Le texte pour générer la couleur
 * @returns {string} Code couleur hexadécimal
 */
function getColorFromText(text) {
  let hash = 0;
  for (let i = 0; i < text.length; i++) {
    const char = text.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash;
  }
  const index = Math.abs(hash) % FILTER_PILL_COLORS.length;
  return FILTER_PILL_COLORS[index];
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

// === GESTION DES FILTRES ===

/**
 * Initialise une pill de filtre
 * @param {HTMLElement} pill - L'élément pill
 */
function initializeFilterPill(pill) {
  try {
    const checkbox = pill.querySelector(".pill-checkbox");
    const pillContent = pill.querySelector(".pill-content");

    if (!checkbox || !pillContent) return null;

    // Générer une couleur basée sur le texte de la pill
    const pillText = pillContent.textContent.trim();
    const category = pill.getAttribute("data-category");

    let pillColor;
    if (category === "content-type") {
      // Pour les types de contenu, utiliser les couleurs spécifiques
      const contentType = checkbox.value;
      pillColor = CONTENT_TYPE_COLORS[contentType] || FILTER_PILL_COLORS[0];
    } else {
      // Pour les autres catégories, utiliser la couleur basée sur le texte
      pillColor = getColorFromText(pillText);
    }

    // Nettoyer les anciens listeners
    const newPill = cleanEventListeners(pill);
    const newCheckbox = newPill.querySelector(".pill-checkbox");
    const newPillContent = newPill.querySelector(".pill-content");

    // Stocker la couleur sur l'élément
    newPill.dataset.pillColor = pillColor;

    // Fonction pour mettre à jour l'apparence de la pill
    function updatePillAppearance() {
      if (newCheckbox.checked) {
        newPillContent.style.backgroundColor = pillColor;
        newPillContent.style.color = "#FFFFFF";
        newPillContent.style.borderColor = pillColor;
        newPill.classList.add("active");
      } else {
        newPillContent.style.backgroundColor = "#f3f4f6";
        newPillContent.style.color = "#4b5563";
        newPillContent.style.borderColor = "#e5e7eb";
        newPill.classList.remove("active");
      }
    }

    // Appliquer l'état initial
    updatePillAppearance();

    // Gérer le clic
    newPill.addEventListener("click", function (e) {
      e.preventDefault();
      newCheckbox.checked = !newCheckbox.checked;
      updatePillAppearance();
    });

    return newPill;
  } catch (error) {
    console.error("❌ Erreur dans initializeFilterPill:", error);
    return null;
  }
}

/**
 * Initialise toutes les pills de filtres
 */
function initializeAllFilterPills() {
  const pillFilters = document.querySelectorAll(".pill-filter");
  pillFilters.forEach(initializeFilterPill);
}

// === GESTION DU TOGGLE DES FILTRES ===

/**
 * Met à jour l'état visuel du bouton toggle
 * @param {HTMLElement} filtersSection - Section des filtres
 * @param {HTMLElement} filterText - Texte du bouton
 * @param {HTMLElement} chevronDown - Icône chevron
 */
function updateToggleButtonState(filtersSection, filterText, chevronDown) {
  try {
    const isHidden = filtersSection.style.display === "none";

    if (filterText) {
      filterText.textContent = isHidden ? "Show Filters" : "Hide Filters";
    }

    if (chevronDown) {
      chevronDown.style.transform = isHidden
        ? "rotate(0deg)"
        : "rotate(180deg)";
    }
  } catch (error) {
    console.error("❌ Erreur dans updateToggleButtonState:", error);
  }
}

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
  newToggleButton.addEventListener("click", function (e) {
    e.preventDefault();
    e.stopPropagation();

    const isHidden = filtersSection.style.display === "none";
    filtersSection.style.display = isHidden ? "block" : "none";
    updateToggleButtonState(filtersSection, filterText, chevronDown);
  });

  return newToggleButton;
}

// === INITIALISATION PRINCIPALE ===

/**
 * Fonction principale d'initialisation de la recherche
 */
function initializeSearch() {
  // Nettoyer l'état précédent
  window.padmakaraSearch.cleanup();

  window.padmakaraSearch.timeout = setTimeout(() => {
    try {
      // Récupération des éléments DOM
      const toggleButton = document.getElementById("toggleFilters");
      const filtersSection = document.getElementById("filtersSection");
      const filterText = document.getElementById("filterText");
      const chevronDown = document.getElementById("chevronDown");

      // Vérifier que les éléments existent
      if (!toggleButton || !filtersSection) {
        console.log(
          "🔍 Éléments de recherche non trouvés, initialisation annulée"
        );
        return;
      }

      console.log("🚀 Initialisation du système de recherche Padmakara");

      // Marquer que l'initialisation a commencé
      window.padmakaraSearch.initialized = true;

      // Déterminer l'état initial des filtres
      const hasActiveFilters =
        filtersSection.getAttribute("data-has-active-filters") === "true";

      // Configurer l'affichage initial
      if (hasActiveFilters) {
        filtersSection.style.display = "block";
      } else {
        filtersSection.style.display = "none";
      }

      updateToggleButtonState(filtersSection, filterText, chevronDown);

      // Initialiser le bouton toggle
      initializeToggleButton(
        toggleButton,
        filtersSection,
        filterText,
        chevronDown
      );

      // Initialiser les pills de filtres
      initializeAllFilterPills();

      console.log("✅ Système de recherche Padmakara initialisé avec succès");
    } catch (error) {
      console.error(
        "❌ Erreur lors de l'initialisation de la recherche:",
        error
      );
      window.padmakaraSearch.cleanup();
    }
  }, 50);
}

// === GESTIONNAIRES D'ÉVÉNEMENTS ===

/**
 * Configure tous les event listeners pour l'initialisation
 */
function setupSearchEventListeners() {
  // Cas 1: Chargement initial de la page
  document.addEventListener("DOMContentLoaded", initializeSearch);

  // Cas 2: Turbo (Rails 7+)
  if (typeof Turbo !== "undefined") {
    // Nettoyage avant navigation
    document.addEventListener("turbo:before-render", function () {
      window.padmakaraSearch.cleanup();
    });

    document.addEventListener("turbo:load", initializeSearch);
    document.addEventListener("turbo:render", initializeSearch);
    document.addEventListener("turbo:frame-load", initializeSearch);
  }

  // Cas 3: Turbolinks (Rails 6 et versions antérieures)
  document.addEventListener("turbolinks:load", initializeSearch);

  // Cas 4: Backup avec plusieurs tentatives
  let backupAttempts = 0;
  const maxBackupAttempts = 3;

  function tryBackupInitialization() {
    if (
      backupAttempts < maxBackupAttempts &&
      document.readyState === "complete"
    ) {
      backupAttempts++;

      if (
        !window.padmakaraSearch.initialized ||
        !document.getElementById("toggleFilters")
      ) {
        console.log(
          `🔄 Tentative de backup d'initialisation #${backupAttempts}`
        );
        initializeSearch();
      }
    }
  }

  // Tentatives de backup échelonnées
  setTimeout(tryBackupInitialization, 100);
  setTimeout(tryBackupInitialization, 500);
  setTimeout(tryBackupInitialization, 1000);
}

// === API PUBLIQUE ===

// Exposer l'API publique
const PadmakaraSearch = {
  init: function () {
    setupSearchEventListeners();
  },

  // Méthodes utilitaires pour usage externe si nécessaire
  getState: function () {
    return window.padmakaraSearch;
  },

  cleanup: function () {
    window.padmakaraSearch.cleanup();
  },

  // Réinitialiser manuellement si nécessaire
  reinitialize: function () {
    this.cleanup();
    initializeSearch();
  },
};

// Export pour ES6 modules
window.PadmakaraSearch = PadmakaraSearch;

// Initialisation automatique
document.addEventListener("DOMContentLoaded", function () {
  PadmakaraSearch.init();
});

// Export par défaut pour l'importmap
export { PadmakaraSearch };
