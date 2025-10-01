import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="filters"
export default class extends Controller {
  static targets = [
    "toggleButton",
    "filtersSection",
    "filterText",
    "chevronDown",
    "clearButton",
  ];

  static values = {
    clearUrl: String,
    hasActiveFilters: Boolean,
  };

  // Palette de couleurs pour les pills
  static pillColors = [
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
  static inactivePillStyles = {
    backgroundColor: "#F3F4F6", // gray-100
    color: "#4B5563", // gray-600
    borderColor: "#E5E7EB", // gray-200
  };

  connect() {
    console.log("🎯 Filters controller connected");

    this.initializeFilters();
    this.initializePills();
  }

  initializeFilters() {
    // Initialiser l'état des filtres
    if (this.hasActiveFiltersValue) {
      this.filtersSectionTarget.classList.remove("hidden");
    } else {
      this.filtersSectionTarget.classList.add("hidden");
    }

    this.updateToggleButtonState();
  }

  initializePills() {
    const pillFilters = this.element.querySelectorAll(".pill-filter");
    pillFilters.forEach((pill) => {
      this.initializePill(pill);
    });
  }

  initializePill(pill) {
    const checkbox = pill.querySelector(".pill-checkbox");
    const pillContent = pill.querySelector(".pill-content");

    if (!checkbox || !pillContent) return;

    // Générer une couleur basée sur le texte de la pill
    const pillText = pillContent.textContent.trim();
    const pillColor = this.getColorFromText(pillText);

    // Stocker la couleur sur l'élément
    pill.dataset.pillColor = JSON.stringify(pillColor);

    // Appliquer l'état initial
    if (checkbox.checked) {
      this.applyActivePillStyle(pillContent, pillColor);
    } else {
      this.applyInactivePillStyle(pillContent);
    }
  }

  // Action: Toggle filters visibility
  toggleFilters() {
    const isHidden = this.filtersSectionTarget.classList.contains("hidden");

    if (isHidden) {
      this.filtersSectionTarget.classList.remove("hidden");
    } else {
      this.filtersSectionTarget.classList.add("hidden");
    }

    this.updateToggleButtonState();
  }

  // Action: Clear all filters
  clearFilters() {
    const timestamp = new Date().getTime();
    window.location.href = this.clearUrlValue + "?_=" + timestamp;
  }

  // Action: Toggle pill state
  togglePill(event) {
    event.preventDefault();

    const pill = event.currentTarget;
    const checkbox = pill.querySelector(".pill-checkbox");
    const pillContent = pill.querySelector(".pill-content");

    if (!checkbox || !pillContent) return;

    // Toggle le checkbox
    checkbox.checked = !checkbox.checked;

    // Récupérer la couleur stockée
    const storedColor = JSON.parse(pill.dataset.pillColor);

    // Appliquer le style
    if (checkbox.checked) {
      this.applyActivePillStyle(pillContent, storedColor);
    } else {
      this.applyInactivePillStyle(pillContent);
    }
  }

  // Utilitaires

  getColorFromText(text) {
    // Créer un hash simple du texte
    let hash = 0;
    for (let i = 0; i < text.length; i++) {
      const char = text.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash; // Convertir en 32 bits
    }

    // Utiliser le hash pour sélectionner une couleur de manière déterministe
    const index = Math.abs(hash) % this.constructor.pillColors.length;
    return this.constructor.pillColors[index];
  }

  applyActivePillStyle(pillContent, color) {
    try {
      pillContent.style.backgroundColor = color.bg;
      pillContent.style.color = color.text;
      pillContent.style.borderColor = color.border;
      pillContent.classList.add("pill-active");
      pillContent.classList.remove("pill-inactive");
    } catch (error) {
      console.error("❌ Erreur dans applyActivePillStyle:", error);
    }
  }

  applyInactivePillStyle(pillContent) {
    try {
      const styles = this.constructor.inactivePillStyles;
      pillContent.style.backgroundColor = styles.backgroundColor;
      pillContent.style.color = styles.color;
      pillContent.style.borderColor = styles.borderColor;
      pillContent.classList.add("pill-inactive");
      pillContent.classList.remove("pill-active");
    } catch (error) {
      console.error("❌ Erreur dans applyInactivePillStyle:", error);
    }
  }

  updateToggleButtonState() {
    const isHidden = this.filtersSectionTarget.classList.contains("hidden");

    if (isHidden) {
      this.filterTextTarget.textContent = "Show Filters";
      this.chevronDownTarget.style.transform = "rotate(0deg)";
    } else {
      this.filterTextTarget.textContent = "Hide Filters";
      this.chevronDownTarget.style.transform = "rotate(180deg)";
    }
  }
}
