import { Controller } from "@hotwired/stimulus";

// Contrôleur général pour la gestion des tags sur tous types de fichiers
export default class extends Controller {
  static targets = ["container", "tagModal", "availableTags"];

  connect() {
    console.log("🏷️ File tags controller connected");
    this.currentFileId = null;
    this.currentFileType = null;
    this.currentResourceType = null; // text, version, etc.
    this.currentResourceId = null;
  }

  // === GESTION DE LA MODAL DES TAGS ===

  showTagSelector(event) {
    const button = event.currentTarget;
    this.currentFileId = button.dataset.fileId;
    this.currentFileType = button.dataset.fileType;

    // Déterminer le type de ressource et l'ID depuis l'URL ou les données
    this.determineResourceInfo();

    // Charger les tags disponibles
    this.loadAvailableTags();

    // Réinitialiser les checkboxes
    this.resetCheckboxes();

    // Afficher la modal
    this.showModal();
  }

  closeTagModal(event) {
    if (event) event.preventDefault();
    const modal = document.getElementById("fileTagSelectorModal");
    if (modal) {
      modal.classList.add("hidden");
    }
    this.currentFileId = null;
    this.currentFileType = null;
  }

  stopPropagation(event) {
    event.stopPropagation();
  }

  // === GESTION DES TAGS ===

  async applyTags() {
    if (!this.currentFileId) return;

    const selectedTags = [];
    const modal = document.getElementById("fileTagSelectorModal");
    const checkboxes = modal.querySelectorAll('input[type="checkbox"]:checked');

    checkboxes.forEach((checkbox) => {
      selectedTags.push({
        id: checkbox.dataset.tagId,
        name: checkbox.dataset.tagName,
      });
    });

    if (selectedTags.length === 0) {
      this.closeTagModal();
      return;
    }

    try {
      const response = await this.sendTagRequest("add", {
        tag_ids: selectedTags.map((tag) => tag.id),
      });

      if (response.ok) {
        const result = await response.json();
        this.updateFileTagsDisplay(
          this.currentFileId,
          result.tags || selectedTags
        );
        this.closeTagModal();
      } else {
        throw new Error("Erreur lors de l'ajout des tags");
      }
    } catch (error) {
      console.error("Erreur ajout tags:", error);
      this.showError("Erreur lors de l'ajout des tags");
    }
  }

  async removeTag(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const tagId = button.dataset.tagId;
    const fileId = button.dataset.fileId;

    try {
      const response = await this.sendTagRequest("remove", null, tagId, fileId);

      if (response.ok) {
        // Supprimer visuellement le tag
        const tagElement = button.closest("span");
        tagElement.remove();
      } else {
        throw new Error("Erreur lors de la suppression du tag");
      }
    } catch (error) {
      console.error("Erreur suppression tag:", error);
      this.showError("Erreur lors de la suppression du tag");
    }
  }

  // === MÉTHODES UTILITAIRES ===

  determineResourceInfo() {
    // Analyser l'URL pour déterminer le contexte
    const pathParts = window.location.pathname.split("/");

    if (pathParts.includes("texts")) {
      const textIndex = pathParts.indexOf("texts");
      this.textId = pathParts[textIndex + 1];

      if (pathParts.includes("versions")) {
        const versionIndex = pathParts.indexOf("versions");
        const translationIndex = pathParts.indexOf("translations");
        this.currentResourceType = "version";
        this.currentResourceId = pathParts[versionIndex + 1];
        this.translationId = pathParts[translationIndex + 1];
      } else if (pathParts.includes("translations")) {
        this.currentResourceType = "text";
        this.currentResourceId = this.textId;
      } else {
        this.currentResourceType = "text";
        this.currentResourceId = this.textId;
      }
    }
  }

  async sendTagRequest(action, data = null, tagId = null, fileId = null) {
    const csrfToken = document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute("content");

    let url, method, body;

    if (action === "add") {
      if (this.currentResourceType === "text") {
        url = `/texts/${this.currentResourceId}/files/${this.currentFileId}/add_tags`;
      } else if (this.currentResourceType === "version") {
        url = `/texts/${this.textId}/translations/${this.translationId}/versions/${this.currentResourceId}/files/${this.currentFileId}/add_tags`;
      }
      method = "POST";
      body = JSON.stringify(data);
    } else if (action === "remove") {
      if (this.currentResourceType === "text") {
        url = `/texts/${this.currentResourceId}/files/${fileId}/remove_tag/${tagId}`;
      } else if (this.currentResourceType === "version") {
        url = `/texts/${this.textId}/translations/${this.translationId}/versions/${this.currentResourceId}/files/${fileId}/remove_tag/${tagId}`;
      }
      method = "DELETE";
    }

    return fetch(url, {
      method: method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        Accept: "application/json",
      },
      body: body,
    });
  }

  async loadAvailableTags() {
    try {
      const response = await fetch("/admin/tags/available.json");
      const tags = await response.json();
      this.populateTagsModal(tags);
    } catch (error) {
      console.error("Erreur chargement tags:", error);
      // Fallback: utiliser les tags déjà présents dans la page
      this.useExistingTags();
    }
  }

  populateTagsModal(tags) {
    const modal = this.getOrCreateModal();
    const tagsContainer = modal.querySelector('[data-target="availableTags"]');

    tagsContainer.innerHTML = tags
      .map(
        (tag) => `
      <label class="flex items-center p-2 hover:bg-gray-50 rounded cursor-pointer">
        <input type="checkbox" 
               class="mr-3 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
               data-tag-id="${tag.id}"
               data-tag-name="${tag.name}">
        <span class="text-sm text-gray-900">#${tag.name}</span>
      </label>
    `
      )
      .join("");
  }

  useExistingTags() {
    // Utiliser les tags déjà présents dans la page
    const modal = this.getOrCreateModal();
    const tagsContainer = modal.querySelector('[data-target="availableTags"]');

    // Cette méthode peut être étendue pour récupérer les tags depuis le DOM
    tagsContainer.innerHTML =
      '<p class="text-sm text-gray-500 text-center py-4">Chargement des tags...</p>';
  }

  getOrCreateModal() {
    let modal = document.getElementById("fileTagSelectorModal");

    if (!modal) {
      modal = this.createModal();
      document.body.appendChild(modal);
    }

    return modal;
  }

  createModal() {
    const modal = document.createElement("div");
    modal.id = "fileTagSelectorModal";
    modal.className =
      "fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50 hidden";
    modal.innerHTML = `
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-medium text-gray-900">Ajouter un tag</h3>
          <button type="button" 
                  class="text-gray-400 hover:text-gray-600"
                  onclick="this.closest('#fileTagSelectorModal').classList.add('hidden')">
            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
        
        <div class="max-h-64 overflow-y-auto">
          <div class="space-y-2" data-target="availableTags">
            <!-- Tags will be loaded here -->
          </div>
        </div>
        
        <div class="flex justify-end space-x-2 mt-4 pt-4 border-t">
          <button type="button" 
                  class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors"
                  onclick="this.closest('#fileTagSelectorModal').classList.add('hidden')">
            Annuler
          </button>
          <button type="button" 
                  class="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md transition-colors"
                  onclick="window.fileTagsController.applyTags()">
            Ajouter
          </button>
        </div>
      </div>
    `;

    // Fermer en cliquant sur le backdrop
    modal.addEventListener("click", (e) => {
      if (e.target === modal) {
        modal.classList.add("hidden");
      }
    });

    return modal;
  }

  showModal() {
    const modal = this.getOrCreateModal();
    modal.classList.remove("hidden");

    // Stocker la référence pour les boutons
    window.fileTagsController = this;
  }

  resetCheckboxes() {
    const modal = this.getOrCreateModal();
    const checkboxes = modal.querySelectorAll('input[type="checkbox"]');
    checkboxes.forEach((checkbox) => (checkbox.checked = false));
  }

  updateFileTagsDisplay(fileId, newTags) {
    const container = document.querySelector(
      `[data-file-tags-target="container"][data-file-id="${fileId}"]`
    );
    if (!container) return;

    // Ajouter les nouveaux tags avant le bouton d'ajout
    const addButton = container.querySelector(
      'button[data-action*="showTagSelector"]'
    );

    newTags.forEach((tag) => {
      // Vérifier si le tag n'existe pas déjà
      const existingTag = container.querySelector(`[data-tag-id="${tag.id}"]`);
      if (existingTag) return;

      const tagElement = document.createElement("span");
      tagElement.className =
        "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700 hover:bg-blue-200 transition-colors cursor-pointer group";
      tagElement.dataset.tagId = tag.id;
      tagElement.title = "Cliquer pour retirer";
      tagElement.innerHTML = `
        #${tag.name}
        <button type="button" 
                class="ml-1 opacity-0 group-hover:opacity-100 transition-opacity"
                data-action="click->file-tags#removeTag"
                data-file-id="${fileId}"
                data-tag-id="${tag.id}">
          <svg class="h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      `;

      if (addButton) {
        container.insertBefore(tagElement, addButton);
      } else {
        container.appendChild(tagElement);
      }
    });
  }

  showError(message) {
    alert(message); // À remplacer par votre système de notifications
  }
}
