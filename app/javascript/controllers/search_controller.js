import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="search"
export default class extends Controller {
  static targets = [
    "toggleButton",
    "filtersSection",
    "filterText",
    "chevronDown",
  ];

  static values = {
    hasActiveFilters: Boolean,
  };

  // Configuration couleurs
  static contentTypeColors = {
    texts: "#1E40AF", // blue-800
    versions: "#059669", // emerald-600
    files: "#7C3AED", // violet-600
  };

  static filterPillColors = [
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

  connect() {
    console.log("🎯 Search controller connected");
    this.initializeFilters();
    this.initializeFilterPills();
  }

  initializeFilters() {
    // Configurer l'affichage initial
    if (this.hasActiveFiltersValue) {
      this.filtersSectionTarget.style.display = "block";
    } else {
      this.filtersSectionTarget.style.display = "none";
    }

    this.updateToggleButtonState();
  }

  initializeFilterPills() {
    const pillFilters = this.element.querySelectorAll(".pill-filter");
    pillFilters.forEach((pill) => {
      this.initializeFilterPill(pill);
    });
  }

  initializeFilterPill(pill) {
    const checkbox = pill.querySelector(".pill-checkbox");
    const pillContent = pill.querySelector(".pill-content");

    if (!checkbox || !pillContent) return;

    // Générer une couleur basée sur le texte ou la catégorie
    const pillText = pillContent.textContent.trim();
    const category = pill.getAttribute("data-category");

    let pillColor;
    if (category === "content-type") {
      const contentType = checkbox.value;
      pillColor =
        this.constructor.contentTypeColors[contentType] ||
        this.constructor.filterPillColors[0];
    } else {
      pillColor = this.getColorFromText(pillText);
    }

    // Stocker la couleur sur l'élément
    pill.dataset.pillColor = pillColor;

    // Appliquer l'état initial
    this.updatePillAppearance(pill, checkbox, pillContent, pillColor);
  }

  // Action: Toggle filters visibility
  toggleFilters() {
    const isHidden = this.filtersSectionTarget.style.display === "none";
    this.filtersSectionTarget.style.display = isHidden ? "block" : "none";
    this.updateToggleButtonState();
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
    const pillColor = pill.dataset.pillColor;

    // Mettre à jour l'apparence
    this.updatePillAppearance(pill, checkbox, pillContent, pillColor);
  }

  // Utilitaires

  getColorFromText(text) {
    let hash = 0;
    for (let i = 0; i < text.length; i++) {
      const char = text.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash;
    }
    const index = Math.abs(hash) % this.constructor.filterPillColors.length;
    return this.constructor.filterPillColors[index];
  }

  updatePillAppearance(pill, checkbox, pillContent, pillColor) {
    if (checkbox.checked) {
      pillContent.style.backgroundColor = pillColor;
      pillContent.style.color = "#FFFFFF";
      pillContent.style.borderColor = pillColor;
      pill.classList.add("active");
    } else {
      pillContent.style.backgroundColor = "#f3f4f6";
      pillContent.style.color = "#4b5563";
      pillContent.style.borderColor = "#e5e7eb";
      pill.classList.remove("active");
    }
  }

  updateToggleButtonState() {
    const isHidden = this.filtersSectionTarget.style.display === "none";

    if (this.hasFilterTextTarget) {
      this.filterTextTarget.textContent = isHidden
        ? "Show Filters"
        : "Hide Filters";
    }

    if (this.hasChevronDownTarget) {
      this.chevronDownTarget.style.transform = isHidden
        ? "rotate(0deg)"
        : "rotate(180deg)";
    }
  }
}
