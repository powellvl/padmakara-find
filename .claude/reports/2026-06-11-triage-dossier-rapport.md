# Rapport — Expérience de triage par dossier avec extraction vision

Date : 2026-06-11
Subset : 108 fichiers, 15 racines de dossiers représentatives (multilingue, dossiers frères,
fourre-tout multi-textes, fichiers de travail, bruit, espagnol, archives).
Modèle : `mistral-small-latest` (cartes vision + texte) — provider configuré dans `.env`.

## Résultat brut

| Métrique | Valeur |
|---|---|
| Cartes IA produites | 91 (17 « échecs » = fichiers sans contenu analysable : jpg, ttf, indd, rtf vide — attendu) |
| Dossiers triés | 23 appliqués, 1 échec JSON |
| Catalogue créé | 47 Texts, 50 Translations, 70 Versions, 72 fichiers liés |
| Fichiers écartés (working/fragment/noise/unassigned) | ~31, listés dans les proposals |

Consultable dans l'UI : `/texts` (racine). Audit détaillé : `bin/rails runner tmp/audit_catalog.rb`.

## Ce qui marche très bien (validé)

1. **L'extraction vision des PDF** — l'hypothèse utilisateur est confirmée. Les couvertures
   livrent des titres tibétains en Uchen + Wylie + titre traduit + auteurs + édition
   (ex. Text #40 « མྱུར་མེད་གྲོལ་བའི་ལམ་བཟང་། / The Excellent Path of Liberation /
   Editions Padmakara 2009 »). Impossible à obtenir par extraction de texte PDF.
2. **Le tri bruit/travail/versions** — fontes .ttf, Thumbs.db, codes-barres, étiquettes,
   biographies, .indd, .zip correctement écartés ; « NE PAS UTILISER », « OLD » compris.
3. **Le regroupement de versions** — Kater Dorsem v3.08/v3.09/v3.09,1/v3.09,2 → 1 Text,
   4 Versions (#42). Exactement le modèle cible.
4. **La jonction inter-langues fonctionne quand les titres sont fiables** — Chant de
   compassion de Shabkar (#83) : FR + EN fusionnés depuis des sous-dossiers différents ;
   Riwo Sangchö (#68) : FR + EN fusionnés via le titre tibétain normalisé.
5. **L'adressage par contenu paie** — le même ebook présent à 2 endroits du NAS a été
   catalogué une seule fois avec ses 2 emplacements (#61).

## Problèmes constatés (par gravité)

### P1 — Hallucination de titres tibétains (modèle trop faible)
`mistral-small` invente des titres Uchen/Wylie plausibles quand la page n'en montre pas
clairement. Conséquences :
- Trulshik Nyurcho HHDL : 3 Texts (#58/#59/#60) pour ce qui est vraisemblablement UNE
  prière — 3 Wylie inventés différents, donc pas de fusion. Pire : le .docx et le .pdf du
  MÊME document (« …Tib and Eng V2 ») ont produit 2 Texts différents.
- Tenga Rinpoche FR/EN (#56/#57) : même livret, 2 titres tibétains différents, pas de fusion.
- #81/#82 : du Wylie stocké dans `title_tibetan`, et la couverture seule (#81) séparée du
  PDF complet (#82) du même livret, dans le même dossier.

### P2 — Sur-fragmentation des recueils et pages d'imposition
« Courtes prières à Tara 8 pages » → 12 Texts. Les fichiers `ENG 1_8`, `ENG 2_7`, `ENG 4_5`
sont des paires d'imposition (impression) d'un même livret : la vision (1re + dernière page)
voit deux prières différentes par fichier → titres distincts → textes distincts.
Traitement incohérent : certains marqués `fragment` (corrects), d'autres devenus des Texts.

### P3 — Bug applicatif `enrich_text` (dédup)
#67/#68 portent la MÊME clé `title_tibetan_normalized` : `enrich_text` remplit le titre
tibétain d'un Text existant sans vérifier qu'un autre Text porte déjà cette clé.
Fix : contrôle d'unicité + fusion (ou index unique en base + gestion du conflit).

### P4 — Pollution des référentiels
- Déités : 90+ entrées dont « local deities », « gods », « those of uncertain form »,
  et des lignées entières (#72 : 25 « déités »). Le prompt doit limiter aux yidams
  principaux (1–3 max).
- Auteurs : doublons orthographiques (Shabkar ×3, « Atisha »/« Lord Atisha »,
  Dudjom ×3 graphies). Il faut un référentiel avec alias plutôt que création naïve.
- Langues : un original tibétain classé sous [English] (#60), une phonétique sous [Tibetan] (#84).

### P5 — Divers
- 1 dossier en échec JSON (réponse tronquée, max_tokens 4096) — retry/continuation à ajouter.
- 2 timeouts réseau sur gros PDF (corrigé : read_timeout 180s) — à re-carder.
- Un .zip catalogué comme Version (#65) — à exclure par extension.

## Décisions/correctifs recommandés avant montée en charge

1. **Modèle plus fort pour l'étape dossier** (le raisonnement de groupement est le maillon
   faible, pas la vision) : `mistral-large`, ou Claude (Haiku vision + Sonnet/Opus dossier)
   si une clé ANTHROPIC est ajoutée. Les cartes vision peuvent rester sur un modèle rapide.
2. **Validation systématique des sorties IA** : `title_tibetan` doit matcher \p{Tibetan},
   sinon déplacé vers wylie ; déités ≤ 3 ; pas de Version pour zip/ttf/db ; couverture seule
   rattachée au texte du dossier, jamais Text autonome.
3. **Pré-groupement déterministe par radical de nom de fichier** (même nom, extensions
   differentes = même version) avant l'appel IA — gratuit et élimine la classe d'erreur docx/pdf.
4. **Heuristique imposition** : noms `1_8`, `2_7`, `P\d+` → fragments d'office, signalés
   au modèle dans le prompt.
5. **Fix enrich_text** + index unique sur `title_tibetan_normalized`.
6. **Review humaine au niveau dossier** (UI) avant application réelle — cette expérience
   a appliqué automatiquement pour évaluer ; le flux de production doit repasser par
   l'humain (décision DECISIONS.md « human-in-the-loop »).

## Addendum 2026-06-11 — Passe de consolidation inter-langues (proposer → vérifier)

Réponse au problème P1 (textes doublés par langue). Architecture retenue :
1. **Proposition** (`CatalogConsolidationService`, modèle fort texte) : repère les entrées
   du catalogue qui semblent être le même texte (équivalence sémantique des titres,
   proximité des dossiers).
2. **Vérification vision** (`MergeVerificationService`) : chaque paire proposée est
   contre-vérifiée en comparant les premières pages des deux documents. Indispensable :
   le modèle texte sur-fusionne par thème (toutes les prières à Tara ensemble, Patrul
   fusionné avec Shabkar) même avec un prompt strict, en fabriquant des justifications.
   La vision tranche correctement.
3. **Fusion** (`TextMergeService`) : translations/versions déplacées, titres complétés,
   doublon supprimé. `rake triage:consolidate` (DRY_RUN=1 pour prévisualiser).

Résultat sur le subset : 10 fusions appliquées, 7 refus corrects (sur-fusions bloquées),
catalogue 47 → 37 texts à 70 versions constantes. Le cas signalé par l'utilisateur
(« Courtes louanges à la Vénérable Tara » FR / « Short praises to exalted Tara » EN)
est désormais UN texte avec traductions French + English.

Bug corrigé au passage : `enrich_text` n'estampille plus une clé tibétaine normalisée
déjà portée par un autre Text.

Limites restantes : paires sans image (docx seuls) → verdict « unknown », laissées à la
review humaine ; les fragments d'imposition (ENG 1_8, 2_7…) restent des versions
distinctes au lieu de fichiers d'une même version.

## Coût/temps observés
~115 appels (91 cartes + 24 dossiers) en ~45 min (séquentiel + sleeps), coût négligeable
sur mistral-small. Extrapolation 6 000 fichiers : ~8–10 h en séquentiel, parallélisable.
