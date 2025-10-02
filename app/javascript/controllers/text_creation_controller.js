import { Controller } from "@hotwired/stimulus";

// Import des librairies tibétaines
import { EwtsConverter } from "tibetan-ewts-converter";
import { TibetanToPhonetics } from "tibetan-to-phonetics";
import { TibetanUnicodeConverter } from "tibetan-unicode-converter";

// Connects to data-controller="text-creation"
export default class extends Controller {
  static targets = [
    "translationsContainer",
    "translationTemplate",
    "versionTemplate",
    "form",
    "submitBtn",
    "tibetanInput",
    "phoneticsInput",
    "wylieInput",
  ];

  static values = {
    translationIndex: Number,
    versionCounters: Object,
  };

  connect() {
    console.log("🎯 TextCreation controller connected");

    this.translationIndexValue = this.translationIndexValue || 0;
    this.versionCountersValue = this.versionCountersValue || {};
    this.fileStores = new Map();

    // Initialiser les convertisseurs tibétains
    this.ewts = new EwtsConverter();
    this.phonetics = new TibetanToPhonetics({
      capitalize: true,
    });

    this.initializeExistingTranslations();
    this.setupDropZones();
    this.setupTibetanInputs();

    if (this.hasFormTarget) {
      this.formTarget.addEventListener("submit", this.handleSubmit.bind(this));
    }
  }

  disconnect() {
    console.log("🎯 TextCreation controller disconnected");
    this.fileStores.clear();
  }

  initializeExistingTranslations() {
    const existingTranslations =
      this.element.querySelectorAll(".translation-item");
    existingTranslations.forEach((translation) => {
      const index = parseInt(translation.getAttribute("data-index"));
      this.translationIndexValue = Math.max(this.translationIndexValue, index);
      this.versionCountersValue[index] = 1;

      this.addContentChangeListeners(translation);
    });
  }

  addContentChangeListeners(translation) {
    const inputs = translation.querySelectorAll("input, select");
    inputs.forEach((input) => {
      input.addEventListener("input", () =>
        this.updateTranslationStyle(translation)
      );
      input.addEventListener("change", () =>
        this.updateTranslationStyle(translation)
      );
    });

    const fileInputs = translation.querySelectorAll('input[type="file"]');
    fileInputs.forEach((input) => {
      input.addEventListener("change", () =>
        this.updateTranslationStyle(translation)
      );
    });
  }

  updateTranslationStyle(translation) {
    const versions = translation.querySelectorAll(".version-item");
    let hasContent = false;

    versions.forEach((version) => {
      const nameInput = version.querySelector(".version-name-input");
      const titleInput = version.querySelector(".version-title-input");
      const versionFiles = version.querySelector(".version-files-input");

      if (
        nameInput?.value.trim() ||
        titleInput?.value.trim() ||
        versionFiles?.files.length > 0
      ) {
        hasContent = true;
      }
    });

    const translationFiles = translation.querySelector(
      ".translation-files-dropzone .file-input"
    );
    if (translationFiles?.files.length > 0) {
      hasContent = true;
    }

    if (hasContent) {
      translation.classList.remove("empty");
    } else {
      translation.classList.add("empty");
    }
  }

  addTranslation() {
    if (
      !this.hasTranslationsContainerTarget ||
      !this.hasTranslationTemplateTarget
    )
      return;

    const clone = this.translationTemplateTarget.content.cloneNode(true);
    const translationItem = clone.querySelector(".translation-item");

    this.translationIndexValue++;
    translationItem.setAttribute("data-index", this.translationIndexValue);
    this.versionCountersValue[this.translationIndexValue] = 0;

    this.updateTranslationFieldNames(clone, this.translationIndexValue);

    const title = clone.querySelector(".translation-title");
    title.textContent = `Traduction ${this.translationIndexValue}`;

    this.translationsContainerTarget.appendChild(clone);
    this.setupTranslationDropZone(translationItem);
    this.addVersion({ currentTarget: translationItem });
  }

  addVersion(event) {
    const translationItem = event.currentTarget.closest(".translation-item");
    const translationIndex = translationItem.getAttribute("data-index");
    const versionsContainer = translationItem.querySelector(
      ".versions-container"
    );

    if (!versionsContainer || !this.hasVersionTemplateTarget) return;

    this.versionCountersValue[translationIndex]++;
    const versionIndex = this.versionCountersValue[translationIndex];

    const clone = this.versionTemplateTarget.content.cloneNode(true);
    const versionItem = clone.querySelector(".version-item");

    versionItem.setAttribute("data-version-index", versionIndex);
    this.updateVersionFieldNames(clone, translationIndex, versionIndex);

    versionsContainer.appendChild(clone);
    this.setupVersionDropZone(versionItem);
    this.addContentChangeListeners(translationItem);
  }

  removeVersion(event) {
    const versionItem = event.currentTarget.closest(".version-item");
    const versionsContainer = versionItem.parentElement;
    const versionCount =
      versionsContainer.querySelectorAll(".version-item").length;

    if (versionCount <= 1) {
      alert("Une traduction doit avoir au moins une version.");
      return;
    }

    if (confirm("Êtes-vous sûr de vouloir supprimer cette version ?")) {
      versionItem.remove();
    }
  }

  removeTranslation(event) {
    if (
      confirm(
        "Êtes-vous sûr de vouloir supprimer cette traduction et toutes ses versions ?"
      )
    ) {
      const translationItem = event.currentTarget.closest(".translation-item");
      const translationIndex = translationItem.getAttribute("data-index");
      delete this.versionCountersValue[translationIndex];
      translationItem.remove();
    }
  }

  updateTranslationFieldNames(clone, translationIndex) {
    const languageSelect = clone.querySelector(".language-select");
    languageSelect.setAttribute(
      "name",
      `text_creation_service[translations_attributes][${translationIndex}][language_id]`
    );

    const fileInput = clone.querySelector(".file-input");
    fileInput.setAttribute(
      "name",
      `text_creation_service[translations_attributes][${translationIndex}][files][]`
    );
  }

  updateVersionFieldNames(clone, translationIndex, versionIndex) {
    const titleInput = clone.querySelector(".version-title-input");
    const nameInput = clone.querySelector(".version-name-input");
    const fileInput = clone.querySelector(".version-files-input");

    titleInput.setAttribute(
      "name",
      `text_creation_service[translations_attributes][${translationIndex}][versions_attributes][${versionIndex}][title]`
    );
    nameInput.setAttribute(
      "name",
      `text_creation_service[translations_attributes][${translationIndex}][versions_attributes][${versionIndex}][name]`
    );
    fileInput.setAttribute(
      "name",
      `text_creation_service[translations_attributes][${translationIndex}][versions_attributes][${versionIndex}][files][]`
    );
  }

  updateTranslationTitle(event) {
    const translationItem = event.currentTarget.closest(".translation-item");
    const languageSelect = event.currentTarget;
    const title = translationItem.querySelector(".translation-title");
    const selectedOption = languageSelect.options[languageSelect.selectedIndex];

    if (selectedOption && selectedOption.value) {
      title.textContent = `Traduction ${selectedOption.text}`;
    } else {
      const index = translationItem.getAttribute("data-index");
      title.textContent = `Traduction ${index}`;
    }
  }

  setupDropZones() {
    this.setupMainDropZone();

    document.querySelectorAll(".translation-item").forEach((item) => {
      this.setupTranslationDropZone(item);
      item.querySelectorAll(".version-item").forEach((versionItem) => {
        this.setupVersionDropZone(versionItem);
      });
    });
  }

  setupMainDropZone() {
    const dropZone = document.getElementById("text-files-dropzone");
    const fileInput = document.getElementById("text_direct_files");

    if (!dropZone || !fileInput) return;
    this.setupDropZoneEvents(dropZone, fileInput);
  }

  setupTranslationDropZone(translationItem) {
    const dropZone = translationItem.querySelector(
      ".translation-files-dropzone"
    );
    const fileInput = translationItem.querySelector(".file-input");

    if (!dropZone || !fileInput) return;
    this.setupDropZoneEvents(dropZone, fileInput);
  }

  setupVersionDropZone(versionItem) {
    const dropZone = versionItem.querySelector(".version-files-dropzone");
    const fileInput = versionItem.querySelector(".version-files-input");

    if (!dropZone || !fileInput) return;
    this.setupDropZoneEvents(dropZone, fileInput);
  }

  setupDropZoneEvents(dropZone, fileInput) {
    if (dropZone.hasAttribute("data-configured")) return;

    console.log(
      `🔧 Configuration du dropzone: ${dropZone.id || dropZone.className}`
    );

    const dropZoneId =
      dropZone.id ||
      `dropzone-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    if (!dropZone.id) {
      dropZone.id = dropZoneId;
    }

    this.fileStores.set(dropZoneId, []);

    const preventDefaults = (e) => {
      e.preventDefault();
      e.stopPropagation();
    };

    ["dragenter", "dragover", "dragleave", "drop"].forEach((eventName) => {
      dropZone.addEventListener(eventName, preventDefaults, false);
    });

    const highlight = () => dropZone.classList.add("dragover");
    const unhighlight = () => dropZone.classList.remove("dragover");

    ["dragenter", "dragover"].forEach((eventName) => {
      dropZone.addEventListener(eventName, highlight, false);
    });
    ["dragleave", "drop"].forEach((eventName) => {
      dropZone.addEventListener(eventName, unhighlight, false);
    });

    dropZone.addEventListener(
      "drop",
      (e) => {
        const files = e.dataTransfer.files;
        this.addFilesToStore(dropZoneId, files);
      },
      false
    );

    if (fileInput) {
      fileInput.removeEventListener("change", fileInput._textCreationHandler);

      const handler = (e) => {
        console.log(`📥 Input change: ${e.target.files.length} fichiers`);
        if (e.target.files.length > 0) {
          this.addFilesToStore(dropZoneId, e.target.files);
        }
      };

      fileInput._textCreationHandler = handler;
      fileInput.addEventListener("change", handler);
    }

    dropZone.setAttribute("data-configured", "true");
    console.log(`✅ DropZone ${dropZoneId} configurée`);
  }

  addFilesToStore(dropZoneId, files) {
    if (!files || files.length === 0) return;

    console.log(`📁 Ajout de ${files.length} fichiers au store ${dropZoneId}`);

    let store = this.fileStores.get(dropZoneId) || [];

    const newFiles = Array.from(files).map((file) => ({
      id: `${file.name}_${file.size}_${Date.now()}`,
      name: file.name,
      size: file.size,
      tags: [],
      file: file,
    }));

    const existingSignatures = store.map((f) => `${f.name}_${f.size}`);
    const uniqueFiles = newFiles.filter((newFile) => {
      const signature = `${newFile.name}_${newFile.size}`;
      return !existingSignatures.includes(signature);
    });

    if (uniqueFiles.length === 0) {
      console.log("⚠️ Tous les fichiers existent déjà");
      return;
    }

    store = [...store, ...uniqueFiles];
    this.fileStores.set(dropZoneId, store);

    console.log(`✅ Store mis à jour: ${store.length} fichiers total`);
    this.refreshDropZoneDisplay(dropZoneId);
  }

  displayFilesInDropZone(dropZone, files) {
    const content = dropZone.querySelector(".drop-zone-content");
    const defaultContent = content.querySelector(".drop-zone-default");

    const oldContainer = dropZone.querySelector(".files-container");
    if (oldContainer) {
      oldContainer.remove();
    }

    console.log(`🎨 Affichage de ${files.length} fichiers`);

    if (files.length === 0) {
      if (defaultContent) {
        defaultContent.style.display = "block";
      }
      return;
    }

    if (defaultContent) {
      defaultContent.style.display = "none";
    }

    const filesContainer = document.createElement("div");
    filesContainer.className = "files-container";

    files.forEach((fileData) => {
      const fileItem = this.createFileItemFromStore(fileData, dropZone.id);
      filesContainer.appendChild(fileItem);
    });

    const addMoreBtn = document.createElement("button");
    addMoreBtn.type = "button";
    addMoreBtn.className = "add-more-files-btn";
    addMoreBtn.innerHTML = "+ Ajouter plus de fichiers";
    addMoreBtn.onclick = () => this.openFileSelector(dropZone.id);

    filesContainer.appendChild(addMoreBtn);
    content.appendChild(filesContainer);
  }

  openFileSelector(dropZoneId) {
    console.log(`📂 Ouverture du sélecteur pour ${dropZoneId}`);
    const dropZone = document.getElementById(dropZoneId);
    const fileInput = dropZone?.querySelector(".file-input");

    if (fileInput) {
      fileInput.value = "";
      fileInput.click();
    }
  }

  createFileItemFromStore(fileData, dropZoneId) {
    const fileItem = document.createElement("div");
    fileItem.className = "file-item";
    fileItem.setAttribute("data-file-id", fileData.id);
    fileItem.setAttribute("data-filename", fileData.name);

    console.log(
      `🏗️ Création d'un item pour: ${fileData.name} (ID: ${fileData.id})`
    );

    const fileTags = fileData.tags || [];

    fileItem.innerHTML = `
      <div class="file-info">
        <div class="file-name">
          <span class="file-icon">📄</span>
          ${fileData.name}
        </div>
        <button type="button" class="remove-file-btn" title="Supprimer ce fichier">×</button>
      </div>
      <div class="file-tags-section">
        <div class="tags-container">
          ${
            fileTags.length > 0
              ? fileTags
                  .map(
                    (tag) =>
                      `<span class="file-tag">${tag}<button type="button" class="remove-tag-btn">×</button></span>`
                  )
                  .join("")
              : '<span class="no-tags-message">Aucun tag • Ajoutez des tags pour organiser vos fichiers</span>'
          }
        </div>
        <div class="add-tag-section">
          <input type="text" class="tag-input" placeholder="Taper un tag..." maxlength="30" list="tags-datalist">
          <button type="button" class="add-tag-btn" title="Ajouter le tag">+</button>
        </div>
      </div>
    `;

    this.setupFileItemEvents(fileItem, dropZoneId, fileData.id);
    return fileItem;
  }

  setupFileItemEvents(fileItem, dropZoneId, fileId) {
    const removeFileBtn = fileItem.querySelector(".remove-file-btn");
    if (removeFileBtn) {
      removeFileBtn.onclick = (e) => {
        e.preventDefault();
        e.stopPropagation();
        const fileName = fileItem.getAttribute("data-filename");
        console.log(
          `🗑️ Tentative de suppression du fichier: ${fileName} (ID: ${fileId})`
        );
        if (
          confirm(
            `Êtes-vous sûr de vouloir supprimer le fichier "${fileName}" ?`
          )
        ) {
          this.removeFileFromStore(dropZoneId, fileId);
        }
      };
    }

    const addTagBtn = fileItem.querySelector(".add-tag-btn");
    const tagInput = fileItem.querySelector(".tag-input");

    const addTag = () => {
      const tagValue = tagInput.value.trim();
      if (tagValue && tagValue.length >= 2) {
        this.addTagToFileInStore(dropZoneId, fileId, tagValue);
        tagInput.value = "";
      } else if (tagValue.length < 2 && tagValue.length > 0) {
        alert("Le tag doit faire au moins 2 caractères");
        tagInput.focus();
      }
    };

    addTagBtn.onclick = (e) => {
      e.stopPropagation();
      addTag();
    };

    tagInput.onkeypress = (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        addTag();
      }
    };

    fileItem.onclick = (e) => {
      e.stopPropagation();
    };

    fileItem.querySelectorAll(".remove-tag-btn").forEach((btn) => {
      btn.onclick = (e) => {
        e.stopPropagation();
        const tag = btn.closest(".file-tag");
        const tagValue = tag.textContent.replace("×", "").trim();
        this.removeTagFromFileInStore(dropZoneId, fileId, tagValue);
      };
    });
  }

  addTagToFileInStore(dropZoneId, fileId, tagValue) {
    const store = this.fileStores.get(dropZoneId) || [];
    const fileData = store.find((f) => f.id === fileId);

    if (!fileData) return;

    if (fileData.tags.includes(tagValue)) {
      alert("Ce tag existe déjà");
      return;
    }

    if (fileData.tags.length >= 5) {
      alert("Maximum 5 tags par fichier");
      return;
    }

    fileData.tags.push(tagValue);
    this.updateFileTagsDisplay(dropZoneId, fileId);

    const dropZone = document.getElementById(dropZoneId);
    if (dropZone) {
      this.updateInputFileFromStore(dropZone, store);
    }
  }

  removeTagFromFileInStore(dropZoneId, fileId, tagValue) {
    const store = this.fileStores.get(dropZoneId) || [];
    const fileData = store.find((f) => f.id === fileId);

    if (!fileData) return;

    fileData.tags = fileData.tags.filter((tag) => tag !== tagValue);
    this.updateFileTagsDisplay(dropZoneId, fileId);

    const dropZone = document.getElementById(dropZoneId);
    if (dropZone) {
      this.updateInputFileFromStore(dropZone, store);
    }
  }

  updateFileTagsDisplay(dropZoneId, fileId) {
    const dropZone = document.getElementById(dropZoneId);
    if (!dropZone) return;

    const fileItem = dropZone.querySelector(`[data-file-id="${fileId}"]`);
    if (!fileItem) return;

    const store = this.fileStores.get(dropZoneId) || [];
    const fileData = store.find((f) => f.id === fileId);
    if (!fileData) return;

    const tagsContainer = fileItem.querySelector(".tags-container");
    const tagInput = fileItem.querySelector(".tag-input");

    if (!tagsContainer) return;

    const fileTags = fileData.tags || [];

    tagsContainer.innerHTML =
      fileTags.length > 0
        ? fileTags
            .map(
              (tag) =>
                `<span class="file-tag">${tag}<button type="button" class="remove-tag-btn">×</button></span>`
            )
            .join("")
        : '<span class="no-tags-message">Aucun tag • Ajoutez des tags pour organiser vos fichiers</span>';

    tagsContainer.querySelectorAll(".remove-tag-btn").forEach((btn) => {
      btn.onclick = (e) => {
        e.stopPropagation();
        const tag = btn.closest(".file-tag");
        const tagValue = tag.textContent.replace("×", "").trim();
        this.removeTagFromFileInStore(dropZoneId, fileId, tagValue);
      };
    });

    if (tagInput) {
      tagInput.focus();
    }
  }

  updateInputFileFromStore(dropZone, files) {
    const fileInput = dropZone.querySelector(".file-input");
    if (!fileInput) return;

    console.log(`🔄 Mise à jour de l'input avec ${files.length} fichiers`);

    if (files.length === 0) {
      fileInput.value = "";
      return;
    }

    const dt = new DataTransfer();
    files.forEach((fileData) => {
      if (fileData.file) {
        dt.items.add(fileData.file);
      }
    });

    const handler = fileInput._textCreationHandler;
    fileInput.removeEventListener("change", handler);

    fileInput.files = dt.files;

    setTimeout(() => {
      fileInput.addEventListener("change", handler);
    }, 100);
  }

  removeFileFromStore(dropZoneId, fileId) {
    console.log(`🗑️ Suppression du fichier ${fileId} du store ${dropZoneId}`);

    let store = this.fileStores.get(dropZoneId) || [];
    const newStore = store.filter((f) => f.id !== fileId);

    console.log(`📊 Store: ${store.length} -> ${newStore.length} fichiers`);

    this.fileStores.set(dropZoneId, newStore);
    this.refreshDropZoneDisplay(dropZoneId);
  }

  refreshDropZoneDisplay(dropZoneId) {
    const dropZone = document.getElementById(dropZoneId);
    if (!dropZone) {
      console.error(`❌ DropZone ${dropZoneId} non trouvée`);
      return;
    }

    const store = this.fileStores.get(dropZoneId) || [];
    console.log(
      `🔄 Rafraîchissement de ${dropZoneId}: ${store.length} fichiers`
    );

    this.displayFilesInDropZone(dropZone, store);
    this.updateInputFileFromStore(dropZone, store);
  }

  handleSubmit(e) {
    const titleTibetan = document.querySelector(
      'input[name="text_creation_service[title_tibetan]"]'
    );
    const titlePhonetics = document.querySelector(
      'input[name="text_creation_service[title_phonetics]"]'
    );

    if (!titleTibetan?.value.trim()) {
      alert("Le titre en tibétain est requis");
      e.preventDefault();
      return false;
    }

    if (!titlePhonetics?.value.trim()) {
      alert("Le titre en phonétique est requis");
      e.preventDefault();
      return false;
    }

    this.serializeFileTagsData();

    const translations = document.querySelectorAll(".translation-item");
    translations.forEach((translation) => {
      const versions = translation.querySelectorAll(".version-item");
      let hasValidVersion = false;
      let hasFiles = false;

      for (let version of versions) {
        const nameInput = version.querySelector(".version-name-input");
        const titleInput = version.querySelector(".version-title-input");
        const versionFiles = version.querySelector(".version-files-input");

        if (
          nameInput.value.trim() ||
          titleInput.value.trim() ||
          (versionFiles && versionFiles.files.length > 0)
        ) {
          hasValidVersion = true;
          break;
        }
      }

      const translationFiles = translation.querySelector(
        ".translation-files-dropzone .file-input"
      );
      if (translationFiles && translationFiles.files.length > 0) {
        hasFiles = true;
      }

      if (!hasValidVersion && !hasFiles) {
        const inputs = translation.querySelectorAll("input, select");
        inputs.forEach((input) => {
          input.disabled = true;
          input.name = "";
        });
      }
    });

    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = true;
      this.submitBtnTarget.textContent = "Création en cours...";
    }

    return true;
  }

  serializeFileTagsData() {
    const dropzones = document.querySelectorAll(".file-drop-zone");

    dropzones.forEach((dropzone) => {
      const fileItems = dropzone.querySelectorAll(".file-item");
      if (fileItems.length === 0) return;

      const filesData = [];
      fileItems.forEach((item) => {
        const filename = item.getAttribute("data-filename");
        const tags = item.getAttribute("data-tags") || "";

        filesData.push({
          filename: filename,
          tags: tags.split(",").filter((tag) => tag.trim() !== ""),
        });
      });

      if (filesData.length > 0) {
        const hiddenInput = document.createElement("input");
        hiddenInput.type = "hidden";
        hiddenInput.value = JSON.stringify(filesData);

        if (dropzone.id === "text-files-dropzone") {
          hiddenInput.name = "text_creation_service[files_tags_data]";
        } else if (dropzone.classList.contains("translation-files-dropzone")) {
          const translationItem = dropzone.closest(".translation-item");
          const translationIndex = translationItem.getAttribute("data-index");
          hiddenInput.name = `text_creation_service[translations_attributes][${translationIndex}][files_tags_data]`;
        } else if (dropzone.classList.contains("version-files-dropzone")) {
          const versionItem = dropzone.closest(".version-item");
          const translationItem = dropzone.closest(".translation-item");
          const translationIndex = translationItem.getAttribute("data-index");
          const versionIndex = versionItem.getAttribute("data-version-index");
          hiddenInput.name = `text_creation_service[translations_attributes][${translationIndex}][versions_attributes][${versionIndex}][files_tags_data]`;
        }

        if (this.hasFormTarget) {
          this.formTarget.appendChild(hiddenInput);
        }
      }
    });
  }

  // ===== FONCTIONNALITÉS DE CONVERSION TIBÉTAINE =====

  setupTibetanInputs() {
    if (!this.hasTibetanInputTarget) return;

    console.log("🔤 Configuration des inputs tibétains");

    // Gestion du paste avec conversion automatique
    this.tibetanInputTarget.addEventListener(
      "paste",
      this.handleTibetanPaste.bind(this)
    );

    // Gestion des changements d'input
    this.tibetanInputTarget.addEventListener(
      "input",
      this.handleTibetanInput.bind(this)
    );
  }

  handleTibetanPaste(event) {
    event.preventDefault();
    const pastedText = event.clipboardData.getData("text");
    const input = event.target;
    const start = input.selectionStart;
    const end = input.selectionEnd;
    const currentValue = input.value;

    // Déterminer le texte à insérer selon qu'il contient des caractères tibétains ou non
    let textToInsert;
    if (
      pastedText.match(
        /^[^\u{f00}-\u{fda}\u{f021}-\u{f042}\u{f162}-\u{f588}]*$/u
      )
    ) {
      // Pas de caractères tibétains détectés, conversion depuis ANSI
      const converter = new TibetanUnicodeConverter(pastedText);
      textToInsert = converter.convert();
      console.log(
        `🔄 Conversion ANSI vers Unicode: "${pastedText}" -> "${textToInsert}"`
      );
    } else {
      textToInsert = pastedText;
    }

    // Insérer le texte à la position du curseur
    const newValue =
      currentValue.slice(0, start) + textToInsert + currentValue.slice(end);
    input.value = newValue;

    // Mettre à jour la position du curseur après le texte inséré
    const newCursorPosition = start + textToInsert.length;
    input.setSelectionRange(newCursorPosition, newCursorPosition);

    // Mettre à jour les champs dérivés
    this.updateWylie(input.value);
    this.updatePhonetics(input.value);
  }

  handleTibetanInput() {
    const tibetanValue = this.tibetanInputTarget.value;
    this.updateWylie(tibetanValue);
    this.updatePhonetics(tibetanValue);
  }

  updateWylie(tibetanText) {
    if (!this.hasWylieInputTarget || !this.wylieInputTarget) return;

    try {
      const wylieText = this.ewts.to_ewts(tibetanText);
      this.wylieInputTarget.value = wylieText;
      console.log(`📝 Wylie généré: "${wylieText}"`);
    } catch (error) {
      console.warn("⚠️ Erreur lors de la conversion Wylie:", error);
    }
  }

  updatePhonetics(tibetanText) {
    if (!this.hasPhoneticsInputTarget || !this.phoneticsInputTarget) return;

    try {
      const phoneticText = this.phonetics.convert(tibetanText);
      this.phoneticsInputTarget.value = phoneticText;
      console.log(`🔊 Phonétique généré: "${phoneticText}"`);
    } catch (error) {
      console.warn("⚠️ Erreur lors de la conversion phonétique:", error);
    }
  }
}
