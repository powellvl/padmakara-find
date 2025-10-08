import { Controller } from "@hotwired/stimulus";

// Contrôleur pour la gestion des fichiers du texte (style Google Drive)
export default class extends Controller {
  static targets = [
    "fileInput",
    "filesList",
    "fileItem",
    "tagsContainer",
    "tagModal",
    "availableTags",
  ];

  connect() {
    console.log("📁 Text files controller connected");
    this.textId = this.element.dataset.textId;
    this.currentFileId = null; // Pour la gestion des tags
    this.draggedElement = null; // Pour le drag & drop
    console.log("📁 Text ID:", this.textId);
  }

  // === GESTION DU DRAG & DROP (invisible mais fonctionnel) ===

  handleDragOver(event) {
    event.preventDefault();
    event.stopPropagation();
    // Indication visuelle subtile sur toute la section
    this.element.classList.add("bg-blue-50", "border-blue-200");
  }

  handleDragLeave(event) {
    event.preventDefault();
    event.stopPropagation();
    // Vérifier si on quitte vraiment la zone
    if (!this.element.contains(event.relatedTarget)) {
      this.element.classList.remove("bg-blue-50", "border-blue-200");
    }
  }

  handleDrop(event) {
    event.preventDefault();
    event.stopPropagation();

    this.element.classList.remove("bg-blue-50", "border-blue-200");

    const files = event.dataTransfer.files;
    if (files.length > 0) {
      this.uploadFiles(files);
    }
  }

  // === SÉLECTION DE FICHIERS ===

  openFileSelector() {
    this.fileInputTarget.click();
  }

  handleFileSelect(event) {
    const files = event.target.files;
    if (files.length > 0) {
      this.uploadFiles(files);
    }
  }

  // === UPLOAD DE FICHIERS ===

  async uploadFiles(files) {
    const formData = new FormData();

    // Ajouter chaque fichier au FormData
    Array.from(files).forEach((file) => {
      formData.append("text[files][]", file);
    });

    // Ajouter le token CSRF
    const csrfToken = document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute("content");
    formData.append("authenticity_token", csrfToken);

    try {
      // Afficher un indicateur de chargement
      this.showLoadingState();

      const response = await fetch(`/texts/${this.textId}/upload_files`, {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": csrfToken,
          Accept: "application/json",
        },
      });

      if (response.ok) {
        // Recharger la page pour afficher les nouveaux fichiers
        window.location.reload();
      } else {
        throw new Error("Erreur lors de l'upload");
      }
    } catch (error) {
      console.error("Erreur upload:", error);
      this.showError("Erreur lors de l'upload des fichiers");
    } finally {
      this.hideLoadingState();
    }
  }

  // === ACTIONS SUR LES FICHIERS ===

  previewFile(event) {
    const fileUrl = event.currentTarget.dataset.fileUrl;
    if (fileUrl) {
      window.open(fileUrl, "_blank");
    }
  }

  async deleteFile(event) {
    const fileId = event.currentTarget.dataset.fileId;
    const fileItem = event.currentTarget.closest(
      '[data-text-files-target="fileItem"]'
    );

    if (!confirm("Êtes-vous sûr de vouloir supprimer ce fichier ?")) {
      return;
    }

    try {
      const csrfToken = document
        .querySelector('meta[name="csrf-token"]')
        .getAttribute("content");

      const response = await fetch(
        `/texts/${this.textId}/delete_file/${fileId}`,
        {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": csrfToken,
            Accept: "application/json",
          },
        }
      );

      if (response.ok) {
        // Supprimer l'élément de la liste avec une animation
        fileItem.style.transition = "all 0.3s ease-out";
        fileItem.style.opacity = "0";
        fileItem.style.transform = "translateX(-100%)";

        setTimeout(() => {
          fileItem.remove();
          this.updateFileCount();
        }, 300);
      } else {
        throw new Error("Erreur lors de la suppression");
      }
    } catch (error) {
      console.error("Erreur suppression:", error);
      this.showError("Erreur lors de la suppression du fichier");
    }
  }

  // === RÉORGANISATION (DRAG & DROP ENTRE FICHIERS) ===

  handleFileDragStart(event) {
    this.draggedElement = event.currentTarget;
    event.dataTransfer.setData(
      "text/plain",
      this.draggedElement.dataset.fileId
    );
    event.dataTransfer.effectAllowed = "move";

    this.draggedElement.style.opacity = "0.5";
    this.draggedElement.classList.add("dragging");
  }

  handleFileDragEnd(event) {
    if (this.draggedElement) {
      this.draggedElement.style.opacity = "1";
      this.draggedElement.classList.remove("dragging");
      this.draggedElement = null;
    }

    // Nettoyer tous les indicateurs de drop
    this.fileItemTargets.forEach((item) => {
      item.classList.remove("drop-target-above", "drop-target-below");
    });
  }

  handleFileDragOver(event) {
    if (!this.draggedElement) return;

    event.preventDefault();
    event.stopPropagation();

    const targetElement = event.currentTarget;
    if (targetElement === this.draggedElement) return;

    // Déterminer si on doit insérer au-dessus ou en-dessous
    const rect = targetElement.getBoundingClientRect();
    const midY = rect.top + rect.height / 2;
    const isAbove = event.clientY < midY;

    // Nettoyer les classes précédentes
    this.fileItemTargets.forEach((item) => {
      item.classList.remove("drop-target-above", "drop-target-below");
    });

    // Ajouter la classe appropriée
    if (isAbove) {
      targetElement.classList.add("drop-target-above");
    } else {
      targetElement.classList.add("drop-target-below");
    }
  }

  handleFileDrop(event) {
    if (!this.draggedElement) return;

    event.preventDefault();
    event.stopPropagation();

    const targetElement = event.currentTarget;
    if (targetElement === this.draggedElement) return;

    // Déterminer la position d'insertion
    const rect = targetElement.getBoundingClientRect();
    const midY = rect.top + rect.height / 2;
    const isAbove = event.clientY < midY;

    // Réorganiser les éléments dans le DOM
    if (isAbove) {
      targetElement.parentNode.insertBefore(this.draggedElement, targetElement);
    } else {
      targetElement.parentNode.insertBefore(
        this.draggedElement,
        targetElement.nextSibling
      );
    }

    // Envoyer la nouvelle ordre au serveur
    this.updateFileOrder();
  }

  // === GESTION DE L'AFFICHAGE ===

  toggleView() {
    // Pour l'instant, on garde la vue liste
    // Cette méthode pourrait implémenter une vue grille plus tard
    console.log("Toggle view - à implémenter");
  }

  showLoadingState() {
    // Afficher un indicateur discret dans l'en-tête
    const addButton = this.element.querySelector(
      'button[data-action*="openFileSelector"]'
    );
    if (addButton) {
      addButton.innerHTML = `
        <svg class="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        Upload...
      `;
      addButton.disabled = true;
    }
  }

  hideLoadingState() {
    // Restaurer le bouton d'ajout
    const addButton = this.element.querySelector(
      'button[data-action*="openFileSelector"]'
    );
    if (addButton) {
      addButton.innerHTML = `
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
        </svg>
        Ajouter
      `;
      addButton.disabled = false;
    }
  }

  showError(message) {
    // Afficher une notification d'erreur (à implémenter selon votre système de notifications)
    alert(message);
  }

  updateFileCount() {
    const fileCount = this.fileItemTargets.length;
    const countElement = this.element.querySelector(
      "span.text-sm.text-gray-500"
    );
    if (countElement) {
      countElement.textContent = `(${fileCount})`;
    }
  }

  // === GESTION DES TAGS ===

  showTagSelector(event) {
    this.currentFileId = event.currentTarget.dataset.fileId;

    // Réinitialiser les checkboxes
    const checkboxes = this.tagModalTarget.querySelectorAll(
      'input[type="checkbox"]'
    );
    checkboxes.forEach((checkbox) => (checkbox.checked = false));

    // Afficher la modal
    this.tagModalTarget.classList.remove("hidden");
  }

  closeTagModal(event) {
    event.preventDefault();
    this.tagModalTarget.classList.add("hidden");
    this.currentFileId = null;
  }

  stopPropagation(event) {
    event.stopPropagation();
  }

  async applyTags() {
    if (!this.currentFileId) return;

    const selectedTags = [];
    const checkboxes = this.tagModalTarget.querySelectorAll(
      'input[type="checkbox"]:checked'
    );

    checkboxes.forEach((checkbox) => {
      selectedTags.push({
        id: checkbox.dataset.tagId,
        name: checkbox.dataset.tagName,
      });
    });

    if (selectedTags.length === 0) {
      this.closeTagModal({ preventDefault: () => {} });
      return;
    }

    try {
      const csrfToken = document
        .querySelector('meta[name="csrf-token"]')
        .getAttribute("content");

      const response = await fetch(
        `/texts/${this.textId}/files/${this.currentFileId}/add_tags`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken,
            Accept: "application/json",
          },
          body: JSON.stringify({
            tag_ids: selectedTags.map((tag) => tag.id),
          }),
        }
      );

      if (response.ok) {
        // Mettre à jour l'affichage des tags
        this.updateFileTagsDisplay(this.currentFileId, selectedTags);
        this.closeTagModal({ preventDefault: () => {} });
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
    const tagElement = event.currentTarget;
    const tagId = tagElement.dataset.tagId;
    const fileId = tagElement.closest(
      '[data-text-files-target="tagsContainer"]'
    ).dataset.fileId;

    try {
      const csrfToken = document
        .querySelector('meta[name="csrf-token"]')
        .getAttribute("content");

      const response = await fetch(
        `/texts/${this.textId}/files/${fileId}/remove_tag/${tagId}`,
        {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": csrfToken,
            Accept: "application/json",
          },
        }
      );

      if (response.ok) {
        // Supprimer visuellement le tag
        tagElement.remove();
      } else {
        throw new Error("Erreur lors de la suppression du tag");
      }
    } catch (error) {
      console.error("Erreur suppression tag:", error);
      this.showError("Erreur lors de la suppression du tag");
    }
  }

  updateFileTagsDisplay(fileId, newTags) {
    const tagsContainer = this.element.querySelector(
      `[data-text-files-target="tagsContainer"][data-file-id="${fileId}"]`
    );
    if (!tagsContainer) return;

    // Ajouter les nouveaux tags avant le bouton d'ajout
    const addButton = tagsContainer.querySelector(
      'button[data-action*="showTagSelector"]'
    );

    newTags.forEach((tag) => {
      const tagElement = document.createElement("span");
      tagElement.className =
        "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700 hover:bg-blue-200 transition-colors cursor-pointer";
      tagElement.dataset.tagId = tag.id;
      tagElement.dataset.action = "click->text-files#removeTag";
      tagElement.title = "Cliquer pour retirer";
      tagElement.innerHTML = `
        #${tag.name}
        <svg class="ml-1 h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      `;

      if (addButton) {
        tagsContainer.insertBefore(tagElement, addButton);
      } else {
        tagsContainer.appendChild(tagElement);
      }
    });
  }

  // === MISE À JOUR DE L'ORDRE DES FICHIERS ===

  async updateFileOrder() {
    const fileIds = this.fileItemTargets.map((item) => item.dataset.fileId);

    try {
      const csrfToken = document
        .querySelector('meta[name="csrf-token"]')
        .getAttribute("content");

      const response = await fetch(`/texts/${this.textId}/reorder_files`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          Accept: "application/json",
        },
        body: JSON.stringify({
          file_ids: fileIds,
        }),
      });

      if (!response.ok) {
        throw new Error("Erreur lors de la réorganisation");
      }
    } catch (error) {
      console.error("Erreur réorganisation:", error);
      this.showError("Erreur lors de la réorganisation des fichiers");
    }
  }
}
