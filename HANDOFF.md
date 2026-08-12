# Padmakara Find — Compte rendu de passation

_Dernière mise à jour : 2026-08-12 · Branche : `feat/triage-dossier-vision`_

Ce document explique **où en est le projet**, **comment il fonctionne**, et **comment le
continuer**. Il est autosuffisant : un développeur (ou une nouvelle session Claude Code)
doit pouvoir reprendre le projet avec ce seul fichier + le code.

---

## 1. Le but du projet

Padmakara est un éditeur de textes bouddhistes tibétains. Ils ont un **NAS** (~des milliers
de fichiers : PDF, Word, InDesign…) accumulé sur 20 ans, **très mal rangé** (doublons,
dossiers « Archives », « OLD », « Travail », copies de vieux ordinateurs, mêmes textes
éparpillés).

L'application est un **pont virtuel** au-dessus de ce NAS : elle le scanne en **lecture
seule**, comprend le contenu de chaque fichier, et le range dans un **catalogue propre et
navigable** selon le modèle métier :

```
Text (l'ŒUVRE, une prière identifiée par son titre tibétain)
 └── Translation (une par LANGUE : français, anglais, tibétain, espagnol…)
      └── Version (une ÉDITION/format/révision)
           └── CataloguedFile (le(s) fichier(s) réel(s) sur le NAS)
```

Le NAS reste la **source de vérité** ; la base de données est une **projection organisée**
par-dessus. L'app n'écrit jamais sur le NAS (pour l'instant).

---

## 2. Stack technique

- **Rails 8**, **PostgreSQL** (extensions `pg_trgm` + `pgvector` activées).
- **Solid Queue** pour les jobs (tourne dans Puma en dev : `SOLID_QUEUE_IN_PUMA=true`).
- **IA multimodale** via un adaptateur swappable (`AI_PROVIDER` dans `.env`).
  Actuellement **Mistral** (`mistral-small-latest`). Claude et OpenAI sont supportés
  (voir `app/services/ai_adapter/`) — il suffit d'une clé API et de changer `AI_PROVIDER`.
- **poppler** requis sur la machine (`pdftoppm`, `pdfinfo`) pour rendre les PDF en images.
- Front : ERB + Tailwind, Stimulus. Direction visuelle dans `.claude/design/visual-direction.md`.

Variables `.env` : `AI_PROVIDER`, `MISTRAL_API_KEY`, `RAILS_ENV`, `SOLID_QUEUE_IN_PUMA`,
`NAS_SOURCE_ROOT` (racine du NAS ; défaut en dev : `tmp/nas_sample`).

---

## 3. Historique des phases (voir `.claude/phases/`)

- **Phase 01 — Inventaire** ✅ : scan du NAS, fichiers adressés par empreinte SHA-256
  (`CataloguedFile`) + emplacements (`FileLocation`). Survit aux déplacements/renommages.
- **Phase 02 — Extraction & recherche plein-texte** ✅ : extraction PDF/Word/RTF/txt,
  recherche PostgreSQL `tsvector` + `pg_trgm`.
- **Phase 03 — Triage IA & catalogage** ✅ (entièrement refondu, voir §4).
- **Phase 04 — Recherche à facettes** ⬜ (pas commencée, reportée).
- **Phase 05 — Réorganisation physique du NAS** ⬜ (précondition non remplie, volontaire).
- **Phase 06 — Plateforme éditoriale** ⬜ (futur lointain).

---

## 4. Le cœur : le pipeline de triage par dossier (Phase 03 refondue)

> Historique important : une première version faisait « 1 analyse IA par fichier » et créait
> **un texte par fichier** sans regrouper. Elle a été **remplacée** par une approche
> **« par dossier »** qui exploite le fait que le NAS est déjà organisé par dossier/langue.

Le pipeline en 4 étapes, du NAS au catalogue :

### Étape 1 — Scan (`NasScanJob` → `NasScanner`)
Parcourt le NAS en lecture seule, crée/actualise `CataloguedFile` + `FileLocation`.

### Étape 2 — Carte par fichier (`FileCardService`)
Pour chaque fichier, produit une **« carte »** JSON (stockée dans
`catalogued_files.ai_file_card`) : titre tibétain/wylie/traduit, langue, auteurs, déités,
type de document, indice de version.

**Point clé (et décision majeure)** : pour les **PDF**, on n'utilise PAS le texte extrait
(le tibétain dans les PDF est presque toujours mal encodé, illisible). On **rend les pages
en images** (`PdfPageRenderer`) et on les envoie au **modèle vision**, qui lit le tibétain
bien mieux qu'un OCR classique et comprend la mise en page. On lit **la couverture + les
premières pages intérieures + la dernière page** (`opening_and_last`) car le titre tibétain
est souvent sur une page de titre intérieure, pas sur la couverture traduite.
Les fichiers non-PDF avec texte extrait utilisent ce texte.

### Étape 3 — Triage par dossier (`FolderTriageService` → `FolderTriageProposal`)
Un **appel IA par dossier** : on donne au modèle les fichiers du dossier + leurs cartes +
les textes déjà existants, et il propose des **groupes** Text/Translation/Version.
Produit une `FolderTriageProposal` (statut `proposed`) **en attente de review humaine**.
Ne touche PAS au catalogue.
- Garde-fous **déterministes avant l'IA** : extensions bruit exclues (`.ttf`, `.zip`,
  `.db`, `.indd`…), radical de nom commun (`X.docx`+`X.pdf` = même version), motif
  d'imposition (`1_8`, `p.31` = fragment).
- Gros dossiers (>20 fichiers analysables) **découpés en sous-lots** pour éviter la
  troncature du JSON de réponse.

### Étape 4 — Application au catalogue (`FolderCatalogApplier`)
Quand un humain **valide** une proposition (écran `/triage/folders`), ce service crée les
`Text`/`Translation`/`Version` et lie les `CataloguedFile`.
- **Regroupement inter-dossiers** : cherche un `Text` existant par **titre tibétain
  normalisé** (`TibetanText.normalize`) dans **tout le catalogue** — donc deux dossiers
  différents portant le même titre tibétain atterrissent dans le même Text.
- Nettoyages : max 3 déités/auteurs par texte, rejet des catégories génériques
  (« gods », « rey de los nagas »…), jamais de texte nommé d'après un dossier de travail.
- Marque le texte `archived` s'il ne vient que de dossiers d'archive (voir §6 bibliothèque).

### Étape complémentaire — Consolidation inter-langues (`CatalogConsolidationService`)
Passe qui fusionne les `Text` qui sont la même œuvre : **proposer** (modèle fort compare les
titres sémantiquement) → **vérifier** (`MergeVerificationService` compare les premières pages
en vision, ou le texte extrait) → **fusionner** (`TextMergeService`).
La vérification indépendante est essentielle : le modèle texte seul **sur-fusionne** (il
regroupe toutes les prières à une même déité). La vision tranche correctement.

---

## 5. Inventaire des fichiers importants

**Services (`app/services/`)**
| Fichier | Rôle |
|---|---|
| `nas_scanner.rb` | Scan NAS lecture seule |
| `text_extractor*.rb` | Extraction texte PDF/Word/RTF/txt |
| `pdf_page_renderer.rb` | Rend les pages PDF en images (vision) |
| `file_card_service.rb` | Carte IA par fichier (vision) |
| `folder_triage_service.rb` | Triage par dossier → proposition |
| `folder_catalog_applier.rb` | Applique une proposition au catalogue |
| `catalog_consolidation_service.rb` | Fusion inter-langues (propose→vérifie) |
| `merge_verification_service.rb` | Vérification vision/texte d'une fusion |
| `text_merge_service.rb` | Fusionne deux Text |
| `tibetan_text.rb` | Normalisation + validation des titres tibétains/Wylie |
| `text_relevance.rb` | Décide si un Text est « archive » (masqué par défaut) |
| `generate_nas_cover.rb` / `pdf_page_preview.rb` | Vignettes de couverture / aperçu review |
| `ai_adapter/` | Adaptateur IA swappable (Claude / OpenAI-compatible) |

**Jobs (`app/jobs/`)** : `nas_scan_job`, `extract_text_job`, `folder_ingest_job`
(carte + triage d'un dossier, retry sur erreurs transitoires).
⚠️ `triage_file_job.rb` et `ai_triage_service.rb`/`auto_triage_service.rb` sont l'**ancien**
pipeline par fichier, **déprécié** — ne pas réutiliser.

**Écrans / routes**
| Route | Écran |
|---|---|
| `/texts` (racine) | Bibliothèque (cartes de textes) |
| `/triage/folders` | **Review humaine** des propositions par dossier |
| `/files/:id` | Streaming lecture seule d'un fichier NAS (pont) |
| `/inventory` | Dashboard d'inventaire |
| `/search` | Recherche plein-texte |

**Tâches rake (`lib/tasks/folder_triage.rake`)**
- `triage:folder_experiment` — triage d'un sous-ensemble de dossiers (expérimentation)
- `triage:enqueue_all_folders` — enfile un `FolderIngestJob` par dossier restant
- `triage:consolidate` (`DRY_RUN=1`) — passe de consolidation inter-langues
- `triage:regenerate_catalog` — **purge et régénère** le catalogue depuis les propositions
  déjà stockées, **sans aucun appel IA** (gratuit, sert à corriger les règles et rejouer)

---

## 6. La bibliothèque (`/texts`)

- Cartes de textes avec **vraie couverture** (1re page du PDF), titre tibétain + traduit,
  badges déité/école.
- **Filtre pertinence** : les textes venant uniquement de dossiers d'archive/obsolètes sont
  **masqués par défaut** (`texts.archived`, calculé par `TextRelevance`), avec un bouton
  « afficher » (`?show_archived=1`). Rien n'est supprimé.
- Pagination (60/page).
- Chaque fichier affiche une **pill de date** (dernière modification, `FileLocation#mtime`).

---

## 7. État actuel du catalogue (2026-08-12)

- **136 textes** (dont 26 archivés/masqués → **110 visibles**), 143 traductions, 213 versions.
- **217 fichiers** catalogués sur 5741 inventoriés (2015 extraits, 656 avec carte IA).
- Propositions par dossier : **49 en attente de review**, 45 appliquées, 1 en échec.
- Langues présentes : français, anglais, tibétain, sanskrit, espagnol, finnois (+ allemand/
  italien gérés).
- **73 tests** verts (services + jobs + controllers ciblés).

> Le catalogue actuel est issu d'un **sous-ensemble** du NAS traité en paliers (les branches
> « Livrets », « Recueil », quelques Sadhanas/Prières). **~280 dossiers restent à traiter.**

---

## 8. Décisions d'architecture (le « pourquoi »)

1. **Vision plutôt qu'OCR** pour le tibétain dans les PDF — le texte extrait est illisible.
2. **Triage par dossier, pas par fichier** — le NAS est déjà organisé, on s'en sert comme
   signal fort ; 1 appel IA par dossier au lieu de par fichier.
3. **Human-in-the-loop** — rien n'entre au catalogue sans validation humaine (écran de
   review). Un premier essai d'auto-acceptation avait produit du déchet.
4. **Review par la PREUVE** — l'écran de review montre la **vignette du document réel** à
   côté du titre proposé, pour qu'un relecteur **non-tibétophone** puisse juger. Aucun
   indice de confiance auto-déclaré par l'IA n'est affiché (il s'est révélé non fiable).
5. **Régénération gratuite** — les propositions IA sont stockées ; on peut purger et rejouer
   le catalogue sans re-payer d'appels IA. Permet d'itérer sur les règles.
6. **Toujours vérifier un regroupement IA** par un signal indépendant (vision/texte) avant
   de fusionner — le jugement texte seul sur-fusionne.

---

## 9. Problèmes connus / limites assumées

1. **Regroupement des œuvres éparpillées — LE point dur, non résolu.**
   La même prière dans plusieurs dossiers/langues apparaît en plusieurs `Text` au lieu d'un
   seul. La jointure se fait par **titre tibétain normalisé exact**, or :
   - seuls ~31 % des groupes ont un titre tibétain lu ;
   - même lu, les éditions d'une même œuvre le formulent différemment (transcription/édition
     variables) → **clés distinctes** (démontré sur le cas « 16 Arhat » : 3 éditions,
     3 titres tibétains différents).
   La lecture vision en profondeur (§4 étape 2) a **amélioré la couverture** des titres mais
   **pas la fiabilité du regroupement**.
   👉 **Piste de solution (non implémentée, décision produit en attente)** : appariement
   **flou/sémantique** — soit similarité `pg_trgm` sur les titres tibétains normalisés,
   soit **clé d'œuvre canonique** (titre pivot en anglais attribué par un modèle fort) comme
   2e clé de jointure, avec vérification. C'est le vrai levier si le regroupement devient
   prioritaire.

2. **Sur-fragmentation intra-dossier** : un livret relié contenant plusieurs prières
   distinctes peut donner plusieurs `Text`. Souvent **légitime** (ce SONT des prières
   différentes), donc à traiter avec prudence — reporté.

3. **~280 dossiers non traités.** ⚠️ Les traiter via **Solid Queue avec un worker** (pas via
   un script `perform_now` en boucle) : sinon les jobs en erreur transitoire se ré-enfilent
   dans une file qui ne tourne pas et se perdent silencieusement.

4. **3 gros dossiers** restent « vides » (un fichier lourd y fait expirer la vision à
   répétition) — à traiter à part (augmenter le timeout ou sauter le fichier fautif).

5. **Legacy** : `Version has_many_attached :files` (Active Storage) coexiste avec les
   `catalogued_files` (référence NAS). À nettoyer un jour. L'ancien pipeline par fichier
   (`triage_file_job`, `auto_triage_service`) est mort mais encore présent.

6. **Dates de fichiers sur l'échantillon local** : les `mtime` sont les dates de **copie**,
   pas les vraies dates. Sur le vrai NAS elles seront correctes.

---

## 10. Comment continuer (par priorité suggérée)

**A. Fiabiliser le passage à l'échelle (backend, prioritaire)**
- Lancer `triage:enqueue_all_folders` avec un **worker Solid Queue actif**, traiter les
  ~280 dossiers restants en surveillant les échecs.
- Régler le cas des 3 gros dossiers (timeout vision sur fichier lourd).
- Passer l'IA sur **Claude** (meilleure lecture tibétaine, cf. décision §8.1) si budget :
  ajouter `ANTHROPIC_API_KEY` + `AI_PROVIDER=claude`.

**B. Décision produit : regroupement des œuvres (§9.1)**
- Trancher entre appariement flou (`pg_trgm` sur titres) et clé d'œuvre canonique.
- C'est le sujet qui a le plus d'impact sur la qualité perçue de la bibliothèque.

**C. Phase 04 — Recherche à facettes**
- Facettes maître/déité/école/langue/format combinables, sur la base du catalogue.

**D. Front / design (partie de Luca)**
- Bibliothèque `/texts`, page texte→traductions→versions, écran de review `/triage/folders`.
- Direction visuelle : `.claude/design/visual-direction.md` (fond crème, accent saffron,
  cartes façon livres tibétains). Les vues sont en ERB + Tailwind.

---

## 11. Répartition suggérée des rôles

- **Dev fonctionnel/backend (nouveau)** : §10 A/B/C — mise à l'échelle du triage, décision
  et implémentation du regroupement, recherche à facettes, nettoyage du legacy.
- **Luca (design/front)** : §10 D — refonte visuelle des pages, ergonomie de la review et
  de la navigation. Le backend expose déjà tout ce qu'il faut (routes §5, données §1).

---

## 12. Pour reprendre avec Claude Code

Ce fichier + le dossier `.claude/` (phases, `DECISIONS.md`, `design/`, `reports/`) donnent
tout le contexte. Un bon premier prompt pour une nouvelle session :

> « Lis `HANDOFF.md` et `.claude/` pour le contexte. Je veux [traiter les dossiers restants /
> implémenter le regroupement d'œuvres / la recherche à facettes]. Analyse l'existant et
> propose un plan avant de coder. »

Rapports d'expérience détaillés (chiffres, diagnostics) : `.claude/reports/`.
