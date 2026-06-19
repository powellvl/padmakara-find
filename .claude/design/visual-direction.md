# Direction artistique — Padmakara Find

Établie le 2026-06-08. Toujours consulter ce fichier avant de modifier une vue utilisateur.

---

## Principe directeur

Interface épurée, chaleureuse, orientée contenu. L'utilisateur cherche des textes de prières tibétaines — l'interface doit évoquer le papier, le parchemin, la bibliothèque physique. Pas de chrome inutile, pas de couleurs vives. Le script tibétain est l'identifiant visuel principal de chaque carte.

Inspiration : application de librairie (ref fournie par l'utilisateur) — reprise du fond crème, de la typographie aérée, des cartes minimalistes, de la navigation iconique latérale. Adapté au corpus bouddhiste tibétain.

---

## Palette de couleurs

| Rôle                | Valeur        | Tailwind équivalent        |
|---------------------|---------------|----------------------------|
| Fond principal      | `#F7F0E3`     | custom `bg-parchment`      |
| Fond secondaire     | `#FFFFFF`     | `bg-white`                 |
| **Accent**          | `#C4622D`     | custom `text-saffron` / `bg-saffron` |
| Texte principal     | `#1C1917`     | `text-stone-950`           |
| Texte secondaire    | `#78716C`     | `text-stone-500`           |
| Texte tertiaire     | `#A8A29E`     | `text-stone-400`           |
| Bordures            | `#E7E0D5`     | custom `border-parchment-dark` |
| Hover léger         | `#EDE6D8`     | custom `bg-parchment-hover`|

> **Jamais** d'orange vif (#FF6B00 etc.). L'accent est ocre/terracotta, pas électrique.

---

## Typographie

```
Titres de section  : text-xs font-bold uppercase tracking-widest text-stone-400
Titre carte        : font-semibold text-stone-900 (titre phonétique)
Sous-titre carte   : text-sm text-stone-500 (langue, auteur)
Script tibétain    : font-normal text-stone-700 (toujours présent si disponible)
Labels/badges      : text-xs font-medium rounded-full px-2 py-0.5
```

---

## Composants clés

### TextCard (carte d'un texte)
- Ratio couverture : portrait 3/4 (ex. w-40 h-52)
- Si pas de couverture → placeholder gradient (`from-stone-200 to-stone-300`) avec initiale tibétaine centrée
- Contenu sous l'image : titre tibétain (gris foncé, petit) + titre phonétique (gras) + langue (badge)
- Hover : légère élévation `shadow-md`, pas de border coloré

### Sections de la home utilisateur
1. **Recherche** — barre centrée et proéminente, fond blanc, shadow subtile
2. **Récemment ajoutés** — scroll horizontal, header `RÉCENTS · Voir tout`
3. **Par déité** — sections horizontales par déité (Tara, Chenrezig, Vajrasattva…)
4. **Par langue** — Tibétain / Français / Anglais

### Navigation (utilisateurs)
- Pas de top navbar lourde
- Sidebar iconique gauche (5 icônes max) ou header minimal logo + search + avatar
- Accent saffron sur l'icône active

---

## Ce qu'on NE fait PAS

- Pas de fond blanc pur pour les pages principales (toujours `#F7F0E3`)
- Pas de boutons bleu/indigo pour les actions utilisateur (réservé aux interfaces admin)
- Pas de filtres en sidebar visible par défaut — toggle sur demande
- Pas de tableau ou liste dense pour les textes — toujours cards/grille

---

## Périmètre d'application

| Vue                      | Direction artistique | Statut        |
|--------------------------|----------------------|---------------|
| `texts#index`            | ✅ Oui               | À implémenter |
| `texts#show` / traductions | ✅ Oui             | À implémenter |
| `search#index`           | ✅ Oui               | À implémenter |
| `inventory#index`        | ❌ Non (admin)       | Style actuel  |
| `triage#index/show`      | ❌ Non (admin)       | Style actuel  |
| Admin dashboard          | ❌ Non (admin)       | Style actuel  |

---

## Config Tailwind à ajouter lors de l'implémentation

```js
// tailwind.config.js — couleurs custom
extend: {
  colors: {
    parchment: {
      DEFAULT: '#F7F0E3',
      hover:   '#EDE6D8',
      dark:    '#E7E0D5',
    },
    saffron: {
      DEFAULT: '#C4622D',
      light:   '#D97348',
      dark:    '#A3501F',
    }
  }
}
```
