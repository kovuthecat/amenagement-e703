# SPEC_OUTIL_AGENCEMENT.md

Spécification de l'outil interactif de saisie d'agencement **`agencement.html`**.
Conçue avec Opus pour être **implémentée telle quelle par Sonnet**. Lire aussi `GUIDE_AGENCEMENT.md`
(source du contenu) et `PROJECT_MAP.md` (données logement).

> Statut : **codé — 2026-06-07**. Fichier `agencement.html` créé dans ce dossier.

---

## 1. Objectif

Un **fichier HTML unique, autonome et hors-ligne** qui permet de :
1. **Dérouler la méthode du `GUIDE_AGENCEMENT.md`** pièce par pièce (6 étapes + questions des fiches).
2. **Collecter des visuels d'inspiration** rangés par pièce.
3. **Exporter ses décisions** dans un format structuré exploitable par une IA (Markdown), pièce par
   pièce et global, pour enrichir la réflexion ensuite.

Cible d'usage : Thibault, sur Windows (Edge/Chrome), depuis le SynologyDrive. Pas de serveur.

---

## 2. Contraintes techniques (non négociables)

- **Un seul fichier `agencement.html`** : HTML + CSS + JS **inline**. Aucune dépendance externe,
  **aucun CDN** (doit marcher 100 % hors-ligne, double-clic depuis le Drive).
- **Vanilla JS** (pas de framework, pas de build). Code lisible, commenté en français.
- **Persistance auto = IndexedDB** (gère les images/blobs et la capacité). localStorage seulement
  pour des préférences légères (thème, dernière pièce ouverte).
- Sauvegarde **automatique** à chaque modification (debounce ~500 ms), avec indicateur visuel
  « Enregistré » / « Enregistrement… ».
- Responsive raisonnable (utilisé surtout sur desktop, mais ne pas casser sur tablette).
- Thème **clair/sombre** (toggle, mémorisé).

---

## 3. Modèle de données

Objet racine sérialisable en JSON (= ce qu'on exporte/importe pour le backup) :

```jsonc
{
  "meta": {
    "appName": "Agencement E703",
    "version": 1,
    "lastModified": "2026-06-07T10:00:00.000Z"
  },
  "rooms": {
    "<roomId>": {
      "id": "cuisine",
      "name": "Cuisine",
      "area": null,                  // m² (number|null) — voir seed §7
      "order": 1,
      // Étape 1 — Usages & besoins
      "usages": "texte libre",
      "needs": [                      // liste de besoins priorisés
        { "id": "...", "label": "Plan de travail mini 1,2 m", "priority": "indispensable" }
        // priority ∈ "indispensable" | "souhaite" | "bonus"
      ],
      "ambiance": "texte libre",
      // Étape 2 — Contraintes
      "constraints": "texte libre",
      // Étape 3 — Zones & circulation
      "zones": "texte libre",
      // Étape 4 — Implantation : variantes comparées
      "variants": [
        { "id": "...", "name": "Variante A", "desc": "...", "pros": "...", "cons": "...", "chosen": false }
      ],
      // Étape 5 — Mobilier sur mesure
      "furniture": [
        { "id": "...", "label": "Meuble TV", "dims": "240×40×50", "notes": "..." }
      ],
      // Étape 6 — Validation (checklist, voir §7)
      "validation": { "<checkItemId>": true/false },
      // Questions propres à la fiche (pré-remplies, voir §7)
      "answers": { "<questionId>": "réponse libre" },
      // Notes / décisions libres
      "notes": "texte libre",
      // Visuels d'inspiration
      "images": [
        {
          "id": "...",
          "caption": "Cuisine bois clair façade sans poignée",
          "source": "https://...",   // URL d'origine (optionnel)
          "tags": ["bois", "épuré"],
          "addedAt": "ISO",
          "blobRef": "<key IndexedDB>" // l'image elle-même est en IndexedDB (store séparé)
        }
      ]
    }
  }
}
```

- Les **images binaires** vivent dans un store IndexedDB séparé (`images`), clé = `blobRef`.
  Le JSON ci-dessus référence par `blobRef`. **À l'export backup**, inliner les images en
  **base64 data-URL** (champ `dataUrl`) pour que le `.json` soit autoportant ; à l'import,
  re-séparer vers IndexedDB.
- Tous les `id` : `crypto.randomUUID()`.

---

## 4. Interface

### 4.1 Layout
- **Sidebar gauche** : titre « Agencement E703 », bouton **Tableau de bord**, puis la **liste des
  pièces** (dans l'ordre de traitement conseillé, §7), chacune avec sa surface et une **barre/%
  d'avancement**. Pièce active surlignée.
- **Zone centrale** : contenu de la pièce sélectionnée (ou le tableau de bord).
- **Barre supérieure** : recherche, toggle thème, bouton **Mémo ergonomie**, menu **Export**,
  bouton **Import**, indicateur de sauvegarde.

### 4.2 Vue « Pièce »
En-tête : nom + surface (éditable) + % d'avancement + bouton « Exporter cette pièce ».
Puis les **6 étapes en sections dépliables** (accordéon, plusieurs ouvrables) :

1. **Usages & besoins** : zone de texte `usages`, **liste de besoins** (ajout/suppression,
   sélecteur de priorité avec pastille couleur : indispensable=rouge, souhaité=ambre, bonus=gris),
   champ `ambiance`.
2. **Contraintes** : zone de texte (placeholder rappelant : portes/sens, eau, élec, radiateurs,
   gaine, faux-plafond, porteurs).
3. **Zones & circulation** : zone de texte.
4. **Implantation — variantes** : cartes de variantes (nom, description, avantages, inconvénients,
   case « variante retenue »). Ajout/suppression.
5. **Mobilier sur mesure** : liste d'items (intitulé, dimensions L×P×H, notes).
6. **Validation** : checklist cochable (§7). % de validation affiché.

Sous les étapes :
- **Questions de la fiche** : les questions pré-remplies (§7), chacune avec un champ réponse.
- **Notes / décisions** : zone de texte libre.
- **Visuels d'inspiration** : voir §4.4.

### 4.3 Vue « Tableau de bord »
- Grille de cartes (une par pièce) : nom, surface, **% d'avancement**, nb de besoins indispensables,
  nb de visuels, nb de cases de validation cochées.
- **% d'avancement d'une pièce** = moyenne pondérée simple de la complétion des 6 étapes
  (une étape « texte » comptée remplie si non vide ; étape 1 remplie si ≥1 besoin ; étape 4 si ≥1
  variante ; étape 6 = ratio de cases cochées). Garder le calcul simple et documenté en commentaire.
- Bouton **Tout exporter (Markdown)** et **Backup JSON**.

### 4.4 Visuels d'inspiration
Trois moyens d'ajout, tous vers la pièce courante :
- **Glisser-déposer** un/plusieurs fichiers image sur une zone dédiée.
- **Coller (Ctrl+V)** une image depuis le presse-papier (capture web).
- **Par URL** (champ + bouton ; tenter le fetch, sinon stocker l'URL en référence distante).
Chaque visuel : vignette, **légende** éditable, **lien source** (optionnel), **tags**.
Clic → **lightbox** (agrandissement, navigation gauche/droite, légende). Suppression possible.
Réduire/redimensionner les images à l'ajout (max ~1600 px de côté, qualité ~0.85) pour limiter le poids.

### 4.5 Mémo ergonomie
Panneau latéral coulissant (ou modale) ouvrable à tout moment, contenant **tous les tableaux de la
Partie C** du guide (Circulation, Cuisine, Repas, Salon, Chambre, SDB/SDE/WC, Entrée & rangement,
Matériaux). Données figées en dur dans le JS (recopier depuis `GUIDE_AGENCEMENT.md` Partie C).
Recherche/filtre rapide dans le mémo = bonus.

---

## 5. Export / Import

### 5.1 Backup JSON (sauvegarde complète)
- **Export** : télécharge `agencement-E703-backup-AAAA-MM-JJ.json` = tout le modèle §3 **avec images
  inlinées en base64**. C'est le fichier à poser sur le SynologyDrive pour synchroniser entre machines.
- **Import** : sélection d'un `.json`, **remplace** l'état après confirmation (proposer aussi une
  fusion = bonus, sinon remplacement simple). Re-séparer les images vers IndexedDB.

### 5.2 Export « décisions » Markdown (pour IA)  ← demandé explicitement
Génère un **Markdown structuré et lisible**, **sans images** (ou avec leurs légendes+sources en liste),
pensé pour être collé dans une IA afin d'enrichir la réflexion.
- **Par pièce** : bouton sur la vue pièce → `decisions-<piece>.md`.
- **Global** : bouton tableau de bord → `decisions-E703.md` (toutes les pièces concaténées + un
  en-tête de contexte logement repris de `PROJECT_MAP.md` : T5, 106,62 m² + terrasse 36,56 m²).

Gabarit Markdown par pièce (n'inclure que les sections renseignées) :

```markdown
## <Nom pièce> (<surface> m²) — avancement <xx> %

### Usages & besoins
<usages>
Besoins :
- [INDISPENSABLE] ...
- [SOUHAITÉ] ...
- [BONUS] ...
Ambiance : <ambiance>

### Contraintes
<constraints>

### Zones & circulation
<zones>

### Implantation — variantes
- **Variante A** (retenue) — <desc> · + <pros> · − <cons>
- ...

### Mobilier sur mesure
- <label> — dims <dims> — <notes>

### Réponses aux questions
- <question> : <réponse>

### Validation
- [x] / [ ] <intitulé checklist>

### Notes / décisions
<notes>

### Visuels d'inspiration
- <légende> (<source>) [tags: ...]
```

---

## 6. Comportements divers
- Sauvegarde auto + restauration au chargement depuis IndexedDB.
- Au tout premier lancement (base vide) : initialiser avec le **seed §7** (12 pièces, questions,
  checklist préremplies, surfaces).
- Recherche globale : filtre les pièces de la sidebar et surligne les correspondances (nom, besoins,
  notes, réponses, légendes).
- Raccourcis : `Ctrl+V` (coller image dans la pièce courante), `Échap` (fermer lightbox/panneau).
- Confirmation avant suppression (pièce hors-scope : on ne supprime pas de pièce ; mais besoins,
  variantes, mobilier, visuels = suppression confirmée).
- Gérer proprement le quota IndexedDB (message si l'écriture échoue).

---

## 7. Données initiales (seed) — à coder en dur

### 7.1 Pièces (ordre = ordre de traitement conseillé du guide)
| order | id | name | area (m²) |
|---|---|---|---|
| 1 | cuisine | Cuisine | null *(intégrée au séjour)* |
| 2 | entree | Entrée | 5.71 |
| 3 | degagement | Dégagement (DGT) | 4.80 |
| 4 | sejour | Séjour | 29.94 |
| 5 | chambre1 | Chambre 1 | 15.01 |
| 6 | chambre4 | Chambre 4 | 15.09 |
| 7 | chambre2 | Chambre 2 | 12.02 |
| 8 | chambre3 | Chambre 3 | 10.67 |
| 9 | sdb | Salle de bain (SDB) | 5.37 |
| 10 | sde | Salle d'eau (SDE) | 5.97 |
| 11 | wc | WC | 2.04 |
| 12 | terrasse | Terrasse | 36.56 |

### 7.2 Questions pré-remplies par pièce (champ `answers`)
- **cuisine** : Cuisine ouverte assumée ou semi-fermée ? · Lave-vaisselle ? · Besoin d'un plan de
  travail mini (longueur) ? · Coin repas / îlot / bar côté séjour ?
- **entree** : Banc d'assise pour se chausser ? · Miroir ? · Rangement saisonnier ? · Penderie +
  chaussures + vide-poche : quels volumes ?
- **degagement** : Placard technique / linge ? · Quoi y ranger en priorité ?
- **sejour** : Combien de places à table (courant / max) ? · Distance canapé-TV souhaitée ? ·
  Zone bureau intégrée ou non ? · Bibliothèque murale ?
- **chambre1** : Lit 140 / 160 / 180 ? · Dressing fermé ou penderie ouverte ? · Bureau ? ·
  Tête de lit avec rangements ?
- **chambre4** : Fonction principale (enfant / ami / bureau) ? · Un ou deux couchages ?
- **chambre2** : Lit simple ou double ? · Besoin d'un bureau ?
- **chambre3** : Usage (chambre / bureau / multifonction) ? · Lit gain de place / escamotable ?
- **sdb** : Conserver la baignoire ? · Meuble vasque simple ou double ? · Colonne de rangement / niche ?
- **sde** : Intégrer lave-linge / sèche-linge ? · Meuble vasque ? · Dimensions douche visées ?
- **wc** : Rangement haut ? · Lave-mains compact ?
- **terrasse** : Zone repas + zone détente ? · Combien de places ? · Ombrage ? · Végétalisation /
  potager ? · Brise-vue / vis-à-vis ?

### 7.3 Checklist de validation (champ `validation`, identique pour toutes les pièces — Étape 6 du guide)
1. Tous les besoins « indispensables » sont couverts ?
2. Circulation ≥ aux mini de la Partie C partout ?
3. Aucune collision meuble ↔ porte / fenêtre / radiateur ?
4. Ouverture des tiroirs / portes possible sans gêne ?
5. Rangement suffisant pour les besoins listés ?
6. Cohérent avec les contraintes techniques (eau, élec, HSP) ?
7. Fabricable et transportable (manutention R+7) ?

### 7.4 Mémo ergonomie
Recopier intégralement les tableaux de la **Partie C** de `GUIDE_AGENCEMENT.md` (Circulation,
Cuisine, Repas, Salon, Chambre, SDB/SDE/WC, Entrée & rangement, Matériaux) en structures de données
rendues sous forme de tableaux HTML dans le panneau Mémo.

---

## 8. Critères d'acceptation
- [x] `agencement.html` s'ouvre en double-clic, fonctionne hors-ligne, aucun appel réseau.
- [x] Les 12 pièces sont préchargées avec leurs questions, checklist et surfaces.
- [x] Saisie persistée automatiquement (survit à un refresh / fermeture).
- [x] Ajout de visuels par drag&drop, Ctrl+V et URL ; lightbox OK.
- [x] Mémo ergonomie consultable à tout moment.
- [x] Variantes d'implantation + tableau de bord d'avancement fonctionnels.
- [x] Export backup JSON (avec images) + réimport fidèle.
- [x] Export Markdown « décisions » pièce par pièce **et** global, propre et lisible par une IA.
- [x] Thème clair/sombre mémorisé.
